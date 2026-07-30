#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Accumulator pattern: `set -e` YOK, her kriter bağımsız
# değerlendirilir, FAIL varsa sonunda exit 1. Eksik birim check'i çökertmez;
# ilgili kriter FAIL verir, koşu devam eder.
#
# Durum systemd'ye SORULUR, dosyadan okunmaz. `systemctl show` çalışan
# sistemin canlı görüşünü verir; öğrenci birim dosyasını yazıp
# daemon-reload yapmadıysa dosya doğru görünür ama sistem onu tanımaz.
#
# Zamanlanmış işler ancak GERÇEKTEN tetiklendiğinde doğrulanabilir. İki log
# dosyası da yoksa tek bir ortak bekleme döngüsü kullanılır (sıralı bekleme
# yok), üst sınır WAIT_MAX saniye.
#
# Hiçbir servis başlatılmaz/durdurulmaz: check sistemin durumunu değiştirmez.
set -u

UNITS=/etc/systemd/system
LISANS=/etc/bekci/lisans.key
CEVAP=/home/student/cevap-bekci.txt
CRONF=/etc/cron.d/yedek
YEDEK_LOG=/var/log/yedek/yedek.log
TEMIZLIK_LOG=/var/log/temizlik.log
WAIT_MAX=90

FAIL=0
ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# `systemctl show -p A -p B --value` çıktıyı systemd'nin kendi sırasında
# basar, verdiğin sırada değil. Bu yüzden her özellik TEK TEK sorulur.
prop() { systemctl show "$1" -p "$2" --value 2>/dev/null; }

# ExecStart değeri "{ path=/x ; argv[]=... }" biçiminde gelir; yalnız yol.
exec_path() {
    prop "$1" ExecStart | sed -n 's/.*path=\([^ ;]*\).*/\1/p' | head -1
}

known() { systemctl cat "$1" >/dev/null 2>&1; }

# Öğrenci perspektifi: sorgular student olarak da çalışmalı.
run_student() {
    : > "$TMP/so"; : > "$TMP/se"
    su - student -c "$1" > "$TMP/so" 2> "$TMP/se"
    RC=$?
}

# cron.d dosyasındaki ilk gerçek iş satırı (yorumlar ve PATH=... atamaları
# elenir). cron.d biçimi: dakika saat gün ay haftagünü KULLANICI komut...
cron_job_line() {
    grep -vE '^[[:space:]]*(#|$)' "$CRONF" 2>/dev/null |
        grep -vE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=' | head -1
}

# --- Ortak bekleme: iki zamanlanmış işin çıktısı ---------------------------
# Zaten varsa anında geçilir. Yoksa ikisi PARALEL beklenir.
have_yedek()    { [ -s "$YEDEK_LOG" ]; }
have_temizlik() { [ -s "$TEMIZLIK_LOG" ]; }

if ! have_yedek || ! have_temizlik; then
    echo "... zamanlanmış işlerin tetiklenmesi bekleniyor (en fazla ${WAIT_MAX}s)"
    waited=0
    while [ "$waited" -lt "$WAIT_MAX" ]; do
        have_yedek && have_temizlik && break
        sleep 5
        waited=$((waited + 5))
    done
fi

# --- 1. Kalıcı günlük -----------------------------------------------------
r=""
if [ ! -d /var/log/journal ]; then
    r="/var/log/journal dizini yok, günlük hâlâ yalnız bellekte"
elif [ -z "$(find /var/log/journal -name '*.journal' -print -quit 2>/dev/null)" ]; then
    r="/var/log/journal var ama içinde günlük dosyası yok (journald oraya yazmıyor)"
else
    # student journal grubunda değil: günlüğü sudo ile okur. İzinsiz
    # journalctl 0 dönüp boş çıktı verdiği için çıktının kendisi sınanır.
    run_student 'sudo -n journalctl -u bekci.service -n 20 --no-pager'
    grep -q 'bekci' "$TMP/so" ||
        r="student sudo ile bekci.service günlüğünü okuyamıyor"
fi
[ -z "$r" ] && ok "kalıcı günlük dizini var ve günlük oraya yazılıyor" || bad "$r"

# --- 2. Cevap dosyası -----------------------------------------------------
r=""
if [ ! -f "$CEVAP" ]; then
    r="$CEVAP yok"
else
    grep -q '/etc/bekci/lisans\.key' "$CEVAP" ||
        r="$CEVAP eksik dosyanın tam yolunu içermiyor"
    grep -Eq '(^|[^0-9])3([^0-9]|$)' "$CEVAP" ||
        r="${r:+$r; }$CEVAP servisin çıkış kodunu içermiyor"
fi
[ -z "$r" ] && ok "cevap dosyasında eksik dosyanın yolu ve çıkış kodu yazılı" || bad "$r"

# --- 3. bekci.service hatasız çalışıyor ve enabled ------------------------
r=""
if ! known bekci.service; then
    r="bekci.service diye bir birim yok"
else
    a="$(systemctl is-active  bekci.service 2>/dev/null || true)"
    en="$(systemctl is-enabled bekci.service 2>/dev/null || true)"
    sub="$(prop bekci.service SubState)"
    res="$(prop bekci.service Result)"
    [ "$a" = "active" ] || r="bekci.service aktif değil (durum: ${a:-yok})"
    [ "$sub" = "running" ] ||
        r="${r:+$r; }bekci.service alt durumu '$sub', beklenen 'running'"
    [ "$res" = "success" ] ||
        r="${r:+$r; }bekci.service Result='$res', servis hâlâ hata ile ölüyor"
    [ "$en" = "enabled" ] ||
        r="${r:+$r; }bekci.service enabled değil (durum: ${en:-yok})"
    [ -s "$LISANS" ] || r="${r:+$r; }$LISANS yok ya da boş"
fi
[ -z "$r" ] && ok "bekci.service hatasız çalışıyor ve enabled" || bad "$r"

# --- 4. crond aktif ve enabled --------------------------------------------
r=""
a="$(systemctl is-active  crond.service 2>/dev/null || true)"
en="$(systemctl is-enabled crond.service 2>/dev/null || true)"
[ "$a"  = "active" ]  || r="crond.service aktif değil (durum: ${a:-yok})"
[ "$en" = "enabled" ] || r="${r:+$r; }crond.service enabled değil (durum: ${en:-yok})"
[ -z "$r" ] && ok "zamanlanmış iş servisi hem aktif hem enabled" || bad "$r"

# --- 5. Yedek işi her dakika --------------------------------------------
job="$(cron_job_line)"
r=""
if [ -z "$job" ]; then
    r="$CRONF içinde çalışan bir iş satırı yok"
else
    # Zamanlama alanları * içerir; glob açılımı kapatılmadan alanlar dosya
    # adlarına genişler (afs, bin, boot...) ve mesajlar anlamsızlaşır.
    set -f
    set -- $job
    set +f
    if [ "$#" -lt 7 ]; then
        r="$CRONF iş satırı eksik alanlı: $job"
    else
        case "$1" in
            '*'|'*/1') ;;
            *) r="dakika alanı '$1', iş her dakika çalışmıyor" ;;
        esac
        for f in "$2" "$3" "$4" "$5"; do
            [ "$f" = '*' ] || r="${r:+$r; }zamanlama alanı '$f' her dakika çalışmayı engelliyor"
        done
    fi
fi
[ -z "$r" ] && ok "yedek işi her dakika çalışacak biçimde tanımlı" || bad "$r"

# --- 6. Komut cron'un ortamında bulunabiliyor -----------------------------
# cron işlere /usr/bin:/bin PATH'i verir. Ya komut mutlak yolla yazılır ya da
# dosyaya /usr/local/bin'i kapsayan bir PATH ataması eklenir.
r=""
if [ -z "$job" ]; then
    r="$CRONF içinde çalışan bir iş satırı yok"
else
    cmd="$(printf '%s\n' "$job" | awk '{print $7}')"
    case "$cmd" in
        /*)
            [ -x "$cmd" ] || r="komut '$cmd' çalıştırılabilir bir dosya değil"
            ;;
        *)
            pathline="$(grep -E '^[[:space:]]*PATH=' "$CRONF" 2>/dev/null | tail -1)"
            if [ -z "$pathline" ]; then
                r="komut '$cmd' mutlak yol değil ve dosyada PATH ataması yok"
            else
                case "${pathline#*=}" in
                    */usr/local/bin*) ;;
                    *) r="PATH ataması /usr/local/bin dizinini kapsamıyor" ;;
                esac
                command -v "$cmd" >/dev/null 2>&1 ||
                    r="${r:+$r; }komut '$cmd' sistemde bulunamıyor"
            fi
            ;;
    esac
    printf '%s\n' "$job" | grep -q 'yedekle' ||
        r="${r:+$r; }iş satırı yedekle programını çağırmıyor"
fi
[ -z "$r" ] && ok "yedek işinin komutu zamanlayıcının ortamında bulunabiliyor" || bad "$r"

# --- 7. Yedek çıktısı -----------------------------------------------------
r=""
if [ ! -f "$YEDEK_LOG" ]; then
    r="$YEDEK_LOG yok — iş hiç çalışmamış"
elif ! grep -q 'yedek alindi' "$YEDEK_LOG"; then
    r="$YEDEK_LOG içinde gerçek bir çalışma satırı yok"
fi
[ -z "$r" ] && ok "yedek log dosyasında gerçek bir çalışma satırı var" || bad "$r"

# --- 8. crond günlüğü işi çalıştırdığını gösteriyor ----------------------
r=""
journalctl -u crond.service --no-pager 2>/dev/null | grep -q 'CMD.*yedekle' ||
    r="journalctl -u crond çıktısında yedekle işini çalıştıran bir CMD kaydı yok"
[ -z "$r" ] && ok "zamanlayıcı servisin günlüğü işi çalıştırdığını gösteriyor" || bad "$r"

# --- 9. temizlik.service tipi ve programı --------------------------------
r=""
if ! known temizlik.service; then
    r="temizlik.service diye bir birim yok"
else
    t="$(prop temizlik.service Type)"
    e="$(exec_path temizlik.service)"
    [ "$t" = "oneshot" ] ||
        r="temizlik.service Type='$t', beklenen 'oneshot' (iş bir kez çalışıp biter)"
    [ "$e" = "/usr/local/bin/temizlik" ] ||
        r="${r:+$r; }temizlik.service ExecStart '$e', beklenen '/usr/local/bin/temizlik'"
    fp="$(prop temizlik.service FragmentPath)"
    case "$fp" in
        "$UNITS"/*) ;;
        *) r="${r:+$r; }temizlik.service $fp konumundan okunuyor, $UNITS altında olmalı" ;;
    esac
fi
[ -z "$r" ] && ok "temizlik.service bir kez çalışan tipte ve doğru programı çağırıyor" || bad "$r"

# --- 10. temizlik.timer enabled ------------------------------------------
r=""
if ! known temizlik.timer; then
    r="temizlik.timer diye bir birim yok"
else
    en="$(systemctl is-enabled temizlik.timer 2>/dev/null || true)"
    [ "$en" = "enabled" ] || r="temizlik.timer enabled değil (durum: ${en:-yok})"
    fp="$(prop temizlik.timer FragmentPath)"
    case "$fp" in
        "$UNITS"/*) ;;
        *) r="${r:+$r; }temizlik.timer $fp konumundan okunuyor, $UNITS altında olmalı" ;;
    esac
fi
[ -z "$r" ] && ok "temizlik.timer enabled" || bad "$r"

# --- 11. temizlik.timer aktif ve bekliyor --------------------------------
r=""
a="$(systemctl is-active temizlik.timer 2>/dev/null || true)"
sub="$(prop temizlik.timer SubState)"
[ "$a" = "active" ] || r="temizlik.timer aktif değil (durum: ${a:-yok})"
case "$sub" in
    waiting|running) ;;
    *) r="${r:+$r; }temizlik.timer alt durumu '$sub', beklenen 'waiting'" ;;
esac
[ -z "$r" ] && ok "temizlik.timer aktif ve tetiklemeyi bekliyor" || bad "$r"

# --- 12. Timer doğru birimi tetikliyor -----------------------------------
r=""
u="$(prop temizlik.timer Unit)"
[ "$u" = "temizlik.service" ] ||
    r="temizlik.timer '$u' birimini tetikliyor, beklenen 'temizlik.service'"
[ -z "$r" ] && ok "temizlik.timer temizlik.service birimini tetikliyor" || bad "$r"

# --- 13. Bir sonraki tetiklemeye en fazla bir dakika ---------------------
# Monotonic timer'da (OnBootSec/OnUnitActiveSec) NextElapseUSecMonotonic,
# takvim timer'ında (OnCalendar) NextElapseUSecRealtime dolu gelir.
# DİKKAT: --value bu özellikleri ham mikrosaniye olarak DEĞİL, insan okur
# biçimde basar ("4d 14h 51min 4.501888s"). Değer ayrıştırılmadan
# karşılaştırılamaz.
dur_to_sec() {
    awk '{
        t = 0
        for (i = 1; i <= NF; i++) {
            f = $i
            if (!match(f, /^[0-9.]+/)) continue
            num  = substr(f, RSTART, RLENGTH)
            unit = substr(f, RSTART + RLENGTH)
            if      (unit == "y")             m = 31557600
            else if (unit == "M")             m = 2629800
            else if (unit == "w")             m = 604800
            else if (unit == "d")             m = 86400
            else if (unit == "h")             m = 3600
            else if (unit == "min" || unit == "m") m = 60
            else if (unit == "s"  || unit == "")   m = 1
            else if (unit == "ms")            m = 0.001
            else if (unit == "us")            m = 0.000001
            else                              m = 0
            t += num * m
        }
        printf "%.0f", t
    }'
}

r=""
now_mono="$(awk '{printf "%.0f", $1}' /proc/uptime 2>/dev/null)"
nm="$(prop temizlik.timer NextElapseUSecMonotonic)"
nr="$(prop temizlik.timer NextElapseUSecRealtime)"
delta=""
if [ -n "$nm" ]; then
    nm_s="$(printf '%s\n' "$nm" | dur_to_sec)"
    [ "${nm_s:-0}" -gt 0 ] && delta=$(( nm_s - now_mono ))
fi
if [ -z "$delta" ] && [ -n "$nr" ]; then
    nr_epoch="$(date -d "$nr" +%s 2>/dev/null || true)"
    [ -n "$nr_epoch" ] && delta=$(( nr_epoch - $(date +%s) ))
fi
if [ -z "$delta" ]; then
    r="temizlik.timer için bir sonraki tetikleme zamanı okunamıyor (timer kurulu mu?)"
elif [ "$delta" -gt 75 ]; then
    r="bir sonraki tetiklemeye ${delta}s var, en fazla bir dakika olmalı"
fi
[ -z "$r" ] && ok "temizlik.timer bir sonraki tetiklemeye en fazla bir dakika var" || bad "$r"

# --- 14. Temizlik çıktısı ------------------------------------------------
r=""
if [ ! -f "$TEMIZLIK_LOG" ]; then
    r="$TEMIZLIK_LOG yok — iş hiç çalışmamış"
elif ! grep -q 'temizlik yapildi' "$TEMIZLIK_LOG"; then
    r="$TEMIZLIK_LOG içinde gerçek bir çalışma satırı yok"
fi
[ -z "$r" ] && ok "temizlik log dosyasında gerçek bir çalışma satırı var" || bad "$r"

# --- 15. Saat dilimi -----------------------------------------------------
r=""
tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
[ "$tz" = "Europe/Istanbul" ] ||
    r="sistem saat dilimi '$tz', beklenen 'Europe/Istanbul'"
[ -z "$r" ] && ok "sistem saat dilimi Europe/Istanbul" || bad "$r"

# --- 16. Saat dilimi kalıcı ----------------------------------------------
# TZ ortam değişkeni yalnız o kabuğu etkiler; kalıcı ayar /etc/localtime'dır.
r=""
lt="$(readlink -f /etc/localtime 2>/dev/null || true)"
case "$lt" in
    */Europe/Istanbul) ;;
    '') r="/etc/localtime okunamıyor" ;;
    *)  r="/etc/localtime '$lt' dosyasına bakıyor, Europe/Istanbul olmalı" ;;
esac
[ -z "$r" ] && ok "saat dilimi kalıcı biçimde ayarlanmış" || bad "$r"

# --- 17. chrony yapılandırması -------------------------------------------
r=""
grep -Eq '^[[:space:]]*(pool|server)[[:space:]]+[^[:space:]#]+' /etc/chrony.conf 2>/dev/null ||
    r="/etc/chrony.conf içinde geçerli bir pool/server satırı yok"
[ -z "$r" ] && ok "chrony yapılandırmasında geçerli bir zaman sunucusu satırı var" || bad "$r"

# --- 18. chronyd aktif ve enabled ----------------------------------------
r=""
a="$(systemctl is-active  chronyd.service 2>/dev/null || true)"
en="$(systemctl is-enabled chronyd.service 2>/dev/null || true)"
[ "$a"  = "active" ]  || r="chronyd.service aktif değil (durum: ${a:-yok})"
[ "$en" = "enabled" ] || r="${r:+$r; }chronyd.service enabled değil (durum: ${en:-yok})"
[ -z "$r" ] && ok "senkron servisi hem aktif hem enabled" || bad "$r"

# --- 19. Sistem saat senkronunu açık raporluyor --------------------------
r=""
ntp="$(timedatectl show -p NTP --value 2>/dev/null || true)"
[ "$ntp" = "yes" ] ||
    r="timedatectl NTP='$ntp', sistem saat senkronunu açık raporlamıyor"
[ -z "$r" ] && ok "sistem saat senkronunu açık olarak raporluyor" || bad "$r"

exit "$FAIL"
