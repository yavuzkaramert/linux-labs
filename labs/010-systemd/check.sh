#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Accumulator pattern: `set -e` YOK, her kriter bağımsız
# değerlendirilir, FAIL varsa sonunda exit 1. Eksik unit check'i çökertmez;
# ilgili kriter FAIL verir, koşu devam eder.
#
# Durum systemd'ye SORULUR, dosyadan okunmaz: `systemctl show` çalışan
# sistemin canlı görüşünü verir. Öğrenci unit dosyasını düzeltip
# daemon-reload yapmadıysa dosya doğru görünür ama sistem eski tanımı
# taşır — bu farkı yalnız systemd'ye sorarak yakalayabiliriz.
#
# Hiçbir servis başlatılmaz/durdurulmaz: check sistemin durumunu değiştirmez.
set -u

UNITS=/etc/systemd/system
READY=/var/lib/veritabani/.ready

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

# Öğrenci perspektifi: systemctl sorguları student olarak da çalışmalı.
run_student() {
    : > "$TMP/so"; : > "$TMP/se"
    su - student -c "$1" > "$TMP/so" 2> "$TMP/se"
    RC=$?
}

# --- 1. gorevci.service dogru tip ve ExecStart ---------------------------
r=""
if ! known gorevci.service; then
    r="gorevci.service diye bir birim yok"
else
    t="$(prop gorevci.service Type)"
    e="$(exec_path gorevci.service)"
    if [ "$t" != "simple" ]; then
        r="gorevci.service Type='$t', beklenen 'simple' (script ön planda kalıyor)"
    elif [ "$e" != "/opt/app/gorevci" ]; then
        r="gorevci.service ExecStart '$e', beklenen '/opt/app/gorevci'"
    fi
fi
[ -z "$r" ] && ok "gorevci.service doğru tip ve doğru ExecStart ile yazılmış" || bad "$r"

# --- 2. gorevci aktif ve enabled ----------------------------------------
r=""
a="$(systemctl is-active  gorevci.service 2>/dev/null || true)"
en="$(systemctl is-enabled gorevci.service 2>/dev/null || true)"
[ "$a"  = "active" ]  || r="gorevci.service aktif değil (durum: ${a:-yok})"
[ "$en" = "enabled" ] || r="${r:+$r; }gorevci.service enabled değil (durum: ${en:-yok})"
[ -z "$r" ] && ok "gorevci.service hem aktif hem enabled" || bad "$r"

# --- 3. gorevci sureci gercekten kosuyor --------------------------------
# Dosyaya ya da ps çıktısına bakılmaz: MainPID ve SubState systemd'nin
# kendi görüşüdür. Sorgu student olarak da yapılabilmeli.
r=""
pid="$(prop gorevci.service MainPID)"
sub="$(prop gorevci.service SubState)"
if [ -z "${pid:-}" ] || [ "$pid" = "0" ]; then
    r="gorevci.service MainPID 0 (systemd'ye göre çalışan süreç yok)"
elif [ "$sub" != "running" ]; then
    r="gorevci.service SubState '$sub', beklenen 'running'"
else
    run_student 'systemctl show gorevci.service -p SubState --value'
    got="$(tr -d '[:space:]' < "$TMP/so")"
    [ "$RC" -eq 0 ] && [ "$got" = "running" ] ||
        r="student olarak sorgulandığında durum doğrulanamıyor: ${got:-$(head -1 "$TMP/se")}"
fi
[ -z "$r" ] && ok "gorevci süreci systemd'ye göre gerçekten koşuyor" || bad "$r"

# --- 4. raporcu ExecStart dogru yol -------------------------------------
r=""
if ! known raporcu.service; then
    r="raporcu.service diye bir birim yok"
else
    e="$(exec_path raporcu.service)"
    [ "$e" = "/opt/raporcu/bin/raporcu" ] ||
        r="raporcu.service ExecStart '$e', beklenen '/opt/raporcu/bin/raporcu'"
fi
[ -z "$r" ] && ok "raporcu.service ExecStart gerçek program yoluna işaret ediyor" ||
    bad "$r"

# --- 5. raporcu User cozulebiliyor --------------------------------------
# İki geçerli çözüm var: raporcu kullanıcısını yaratmak ya da User'ı var
# olan bir kullanıcıya çevirmek (boş User = root). Sınanan şey, systemd'nin
# o kullanıcıyı gerçekten çözebilmesi.
r=""
if ! known raporcu.service; then
    r="raporcu.service diye bir birim yok"
else
    u="$(prop raporcu.service User)"
    if [ -z "$u" ]; then
        :
    elif ! getent passwd "$u" >/dev/null 2>&1; then
        r="raporcu.service User='$u' ama böyle bir kullanıcı sistemde yok"
    fi
fi
[ -z "$r" ] && ok "raporcu.service User var olan bir kullanıcıya işaret ediyor" ||
    bad "$r"

# --- 6. raporcu aktif ve bellekteki tanim taze --------------------------
# NeedDaemonReload, diskteki dosya ile systemd'nin bellekteki kopyası
# ayrıştığında 'yes' döner. daemon-reload atlanmışsa bu kriter FAIL verir.
r=""
a="$(systemctl is-active raporcu.service 2>/dev/null || true)"
nd="$(prop raporcu.service NeedDaemonReload)"
[ "$a" = "active" ] || r="raporcu.service aktif değil (durum: ${a:-yok})"
[ "$nd" = "no" ] ||
    r="${r:+$r; }raporcu.service için daemon-reload gerekiyor (NeedDaemonReload=$nd)"
[ -z "$r" ] && ok "raporcu.service aktif ve systemd bellekteki tanımı tazelenmiş" ||
    bad "$r"

# --- 7. api -> veritabani siralama VE gereklilik ------------------------
# Yalnız After yeterli değildir: After sırayı belirler, ama veritabani hiç
# başlatılmazsa api yine .ready dosyasını bulamaz. Requires onu da çeker.
r=""
if ! known api.service; then
    r="api.service diye bir birim yok"
else
    aft="$(prop api.service After)"
    req="$(prop api.service Requires)"
    case "$aft" in *veritabani.service*) ;; *)
        r="api.service After= veritabani.service içermiyor" ;;
    esac
    case "$req" in *veritabani.service*) ;; *)
        r="${r:+$r; }api.service Requires= veritabani.service içermiyor" ;;
    esac
fi
[ -z "$r" ] && ok "api.service veritabani.service'e sıralama ve gereklilik ile bağlı" ||
    bad "$r"

# --- 8. veritabani tamamlanmis durumda ----------------------------------
# active (exited) = oneshot işini yaptı ve RemainAfterExit sayesinde
# "tamamlandı" olarak duruyor. ExecStart ve .ready da sınanır ki birim
# /bin/true ile taklit edilmesin.
r=""
a="$(systemctl is-active veritabani.service 2>/dev/null || true)"
sub="$(prop veritabani.service SubState)"
e="$(exec_path veritabani.service)"
if [ "$a" != "active" ]; then
    r="veritabani.service aktif değil (durum: ${a:-yok})"
elif [ "$sub" != "exited" ]; then
    r="veritabani.service SubState '$sub', beklenen 'exited'"
elif [ "$e" != "/opt/db/veritabani-init" ]; then
    r="veritabani.service ExecStart '$e', beklenen '/opt/db/veritabani-init'"
elif [ ! -e "$READY" ]; then
    r="$READY yok: veritabani.service işini gerçekten yapmamış"
fi
[ -z "$r" ] && ok "veritabani.service tamamlanmış durumda duruyor" || bad "$r"

# --- 9. api basariyla basliyor ve aktif kaliyor -------------------------
r=""
a="$(systemctl is-active api.service 2>/dev/null || true)"
sub="$(prop api.service SubState)"
res="$(prop api.service Result)"
e="$(exec_path api.service)"
if [ "$e" != "/opt/api/api" ]; then
    r="api.service ExecStart '$e', beklenen '/opt/api/api'"
elif [ "$a" != "active" ]; then
    r="api.service aktif değil (durum: ${a:-yok})"
elif [ "$sub" != "running" ]; then
    r="api.service SubState '$sub', beklenen 'running'"
elif [ "$res" != "success" ]; then
    r="api.service Result '$res', beklenen 'success'"
fi
[ -z "$r" ] && ok "api.service başarıyla başlıyor ve aktif kalıyor" || bad "$r"

# --- 10. varsayilan target ----------------------------------------------
r=""
d="$(systemctl get-default 2>/dev/null || true)"
[ "$d" = "multi-user.target" ] ||
    r="varsayılan target '$d', beklenen 'multi-user.target'"
[ -z "$r" ] && ok "varsayılan target multi-user.target" || bad "$r"

# --- 11. birimler kalici konumda ----------------------------------------
# FragmentPath systemd'nin gerçekten okuduğu dosyadır. /run altındaki
# geçici birimler (systemctl edit --runtime, elle /run/systemd/system)
# reboot'ta kaybolur; RHCSA'nın kalıcılık şartı bunu eler.
r=""
for u in gorevci raporcu api veritabani; do
    fp="$(prop "$u.service" FragmentPath)"
    if [ -z "$fp" ]; then
        r="${r:+$r; }$u.service için birim dosyası bulunamadı"
        continue
    fi
    case "$fp" in
        "$UNITS"/*) ;;
        *) r="${r:+$r; }$u.service $fp konumundan okunuyor, $UNITS altında olmalı" ;;
    esac
done
[ -z "$r" ] && ok "dört servis dosyası da $UNITS altında kalıcı" || bad "$r"

exit "$FAIL"
