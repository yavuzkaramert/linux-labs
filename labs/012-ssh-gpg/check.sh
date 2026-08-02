#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Accumulator pattern: `set -e` YOK, her kriter bağımsız
# değerlendirilir, FAIL varsa sonunda exit 1.
#
# Bu labda kriterlerin çoğu KULLANICI PERSPEKTİFİNDEN ölçülür: SSH girişi
# gerçekten denenir, GPG işlemleri student olarak çalıştırılır. Dosya
# izinlerine bakmak yetmez — StrictModes reddi yalnız gerçek bir giriş
# denemesinde görünür ve istemci sebebini söylemez.
#
# Hiçbir servis başlatılmaz/durdurulmaz, hiçbir anahtar üretilmez.
set -u

HOME_STUDENT=/home/student
SSH_DIR="$HOME_STUDENT/.ssh"
SSHD_CONF=/etc/ssh/sshd_config
PAKET=/opt/paket
GIZLI="$HOME_STUDENT/gizli.txt"
DUYURU="$HOME_STUDENT/duyuru.txt"
CEVAP="$HOME_STUDENT/cevap-paket.txt"

FAIL=0
ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# `systemctl show -p A -p B --value` çıktıyı systemd'nin kendi sırasında
# basar, verdiğin sırada değil. Bu yüzden her özellik TEK TEK sorulur.
prop() { systemctl show "$1" -p "$2" --value 2>/dev/null; }

# Öğrenci perspektifi: komut student olarak koşar, çıktı ve rc saklanır.
run_student() {
    : > "$TMP/so"; : > "$TMP/se"
    su - student -c "$1" > "$TMP/so" 2> "$TMP/se"
    RC=$?
}

# sshd -T çalışan yapılandırmanın ETKİN değerlerini basar; dosyadaki satırı
# grep'lemekten farklı olarak varsayılanları ve Match bloklarını da hesaba
# katar. Sözdizimi hatası varsa hiç çıktı vermez — o durumda ilgili
# kriterler zaten düşer.
sshd_eff() { sshd -T 2>/dev/null | awk -v k="$1" '$1 == k {print $2; exit}'; }

# --- 1. .ssh dizini izni ve sahipliği -------------------------------------
r=""
if [ ! -d "$SSH_DIR" ]; then
    r="$SSH_DIR dizini yok"
else
    m="$(stat -c %a "$SSH_DIR")"
    o="$(stat -c %U "$SSH_DIR")"
    [ "$m" = "700" ] || r=".ssh izni $m, beklenen 700"
    [ "$o" = "student" ] || r="${r:+$r; }.ssh sahibi $o, beklenen student"
fi
[ -z "$r" ] && ok ".ssh dizini yalnız sahibine açık ve student'a ait" || bad "$r"

# --- 2. authorized_keys ---------------------------------------------------
r=""
AK="$SSH_DIR/authorized_keys"
if [ ! -f "$AK" ]; then
    r="$AK yok"
else
    m="$(stat -c %a "$AK")"
    o="$(stat -c %U "$AK")"
    case "$m" in
        600|400) ;;
        *) r="authorized_keys izni $m, sahibi dışında kimse okuyamamalı (600)" ;;
    esac
    [ "$o" = "student" ] || r="${r:+$r; }authorized_keys sahibi $o, beklenen student"
    if [ -s "$SSH_DIR/id_ed25519.pub" ]; then
        # Anahtar gövdesi (base64 kısmı) karşılaştırılır; yorum alanı ve
        # satır sonu farkları eşleşmeyi bozmasın.
        body="$(awk '{print $2}' "$SSH_DIR/id_ed25519.pub")"
        grep -qF "$body" "$AK" ||
            r="${r:+$r; }authorized_keys student'ın açık anahtarını içermiyor"
    else
        r="${r:+$r; }$SSH_DIR/id_ed25519.pub yok"
    fi
fi
[ -z "$r" ] && ok "authorized_keys doğru izinde, student'a ait ve anahtarı içeriyor" || bad "$r"

# --- 3. Ev dizini yazılabilirliği (StrictModes) ---------------------------
r=""
m="$(stat -c %a "$HOME_STUDENT" 2>/dev/null || echo '')"
if [ -z "$m" ]; then
    r="$HOME_STUDENT okunamıyor"
elif [ $(( 8#$m & 022 )) -ne 0 ]; then
    r="ev dizini izni $m — gruba/diğerlerine yazılabilir, sshd bu durumda girişi reddeder"
fi
[ -z "$r" ] && ok "ev dizini gruba ve diğerlerine yazılabilir değil" || bad "$r"

# --- 4. Anahtarla gerçek giriş --------------------------------------------
# BatchMode: parola sorulursa beklemeden düşer. PasswordAuthentication=no:
# giriş yalnız anahtarla olacak. UserKnownHostsFile=/dev/null: host anahtarı
# doğrulaması bu testin konusu değil.
r=""
run_student "ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no \
    -o ConnectTimeout=10 student@localhost 'echo GIRIS_OK'"
grep -q 'GIRIS_OK' "$TMP/so" ||
    r="student anahtarla giriş yapamıyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
[ -z "$r" ] && ok "student parola kullanmadan yalnız anahtarla giriş yapabiliyor" || bad "$r"

# --- 5. Yapılandırma sözdizimi --------------------------------------------
r=""
if ! sshd -t 2>"$TMP/se"; then
    r="sshd -t hata veriyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
fi
[ -z "$r" ] && ok "sshd yapılandırması sözdizimi sınamasından temiz geçiyor" || bad "$r"

# --- 6. root girişi kapalı ------------------------------------------------
r=""
v="$(sshd_eff permitrootlogin)"
[ "$v" = "no" ] || r="PermitRootLogin etkin değeri '${v:-okunamadi}', beklenen 'no'"
[ -z "$r" ] && ok "root girişi kapalı" || bad "$r"

# --- 7. parola ile giriş kapalı -------------------------------------------
r=""
v="$(sshd_eff passwordauthentication)"
[ "$v" = "no" ] || r="PasswordAuthentication etkin değeri '${v:-okunamadi}', beklenen 'no'"
[ -z "$r" ] && ok "parola ile giriş kapalı" || bad "$r"

# --- 8. Servis ayakta ve yeni yapılandırmayla çalışıyor -------------------
# Dosyayı düzeltip restart etmemek klasik hata: çalışan sshd yapılandırmayı
# yalnız başlangıçta okur. Servisin başlama anı config dosyasının mtime'ından
# YENİ olmalı; değilse diskteki düzeltme henüz uygulanmamıştır.
r=""
a="$(systemctl is-active sshd.service 2>/dev/null || true)"
if [ "$a" != "active" ]; then
    r="sshd.service aktif değil (durum: ${a:-yok})"
else
    svc_us="$(prop sshd.service ExecMainStartTimestampMonotonic)"
    case "$svc_us" in
        ''|*[!0-9]*) r="sshd.service başlangıç zamanı okunamadı" ;;
        *)
            boot_us="$(awk '{printf "%.0f", $1 * 1000000}' /proc/uptime)"
            svc_epoch=$(( $(date +%s) - (boot_us - svc_us) / 1000000 ))
            conf_m="$(stat -c %Y "$SSHD_CONF")"
            [ "$svc_epoch" -ge "$conf_m" ] ||
                r="sshd, yapılandırma dosyası değiştikten sonra yeniden başlatılmamış — diskteki düzeltme uygulanmamış"
            ;;
    esac
fi
[ -z "$r" ] && ok "sshd servisi ayakta ve yeni yapılandırmayla çalışıyor" || bad "$r"

# --- 9. student'ın gizli GPG anahtarı -------------------------------------
r=""
run_student "gpg --batch --list-secret-keys student@lab.local"
[ "$RC" -eq 0 ] ||
    r="student@lab.local kimliğini taşıyan gizli anahtar bulunamadı"
[ -z "$r" ] && ok "student'ın gizli GPG anahtarı var ve doğru kimliği taşıyor" || bad "$r"

# --- 10. gizli.txt.gpg student'ın anahtarına şifrelenmiş ------------------
r=""
if [ ! -s "$GIZLI.gpg" ]; then
    r="$GIZLI.gpg yok"
else
    run_student "gpg --batch --yes --decrypt $GIZLI.gpg"
    [ "$RC" -eq 0 ] ||
        r="$GIZLI.gpg student'ın anahtarıyla çözülemiyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
    cp "$TMP/so" "$TMP/cozulen" 2>/dev/null || true
fi
[ -z "$r" ] && ok "gizli.txt.gpg student'ın anahtarına şifrelenmiş" || bad "$r"

# --- 11. Çözülen içerik orijinaliyle aynı ---------------------------------
r=""
if [ ! -s "$GIZLI" ]; then
    r="$GIZLI yok — karşılaştırma yapılamıyor"
elif [ ! -f "$TMP/cozulen" ]; then
    r="şifreli dosya çözülemediği için içerik karşılaştırılamadı"
elif ! cmp -s "$TMP/cozulen" "$GIZLI"; then
    r="çözülen içerik $GIZLI ile aynı değil"
fi
[ -z "$r" ] && ok "şifreli dosya çözüldüğünde içerik orijinaliyle aynı" || bad "$r"

# --- 12. Yayıncı açık anahtarı student'ın anahtarlığında -----------------
r=""
run_student "gpg --batch --list-keys yayinci@lab.local"
[ "$RC" -eq 0 ] ||
    r="yayıncının açık anahtarı student'ın anahtarlığında değil"
[ -z "$r" ] && ok "yayıncının açık anahtarı student'ın anahtarlığında" || bad "$r"

# --- 13. Sağlam paketin imzası doğrulanıyor ------------------------------
r=""
run_student "gpg --batch --verify $PAKET/surum-a.tar.gz.sig $PAKET/surum-a.tar.gz"
[ "$RC" -eq 0 ] ||
    r="surum-a.tar.gz imzası student olarak doğrulanamıyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
[ -z "$r" ] && ok "sağlam paketin imzası student olarak doğrulanıyor" || bad "$r"

# --- 14. Cevap dosyası kurcalanmış paketi işaretliyor --------------------
r=""
if [ ! -s "$CEVAP" ]; then
    r="$CEVAP yok"
else
    grep -q 'surum-b' "$CEVAP" || r="$CEVAP kurcalanmış paketin adını içermiyor"
    grep -q 'surum-a' "$CEVAP" &&
        r="${r:+$r; }$CEVAP sağlam paketi de işaretlemiş, tek bir cevap bekleniyor"
fi
[ -z "$r" ] && ok "cevap dosyası kurcalanmış paketi doğru işaretliyor" || bad "$r"

# --- 15. duyuru.txt ayrık imza -------------------------------------------
r=""
if [ ! -s "$DUYURU" ]; then
    r="$DUYURU yok"
elif [ ! -s "$DUYURU.sig" ]; then
    r="$DUYURU.sig yok — ayrık imza üretilmemiş"
else
    run_student "gpg --batch --verify $DUYURU.sig $DUYURU"
    [ "$RC" -eq 0 ] ||
        r="$DUYURU.sig doğrulanamıyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
fi
[ -z "$r" ] && ok "duyuru.txt ayrık imzayla imzalanmış ve imza doğrulanıyor" || bad "$r"

exit "$FAIL"
