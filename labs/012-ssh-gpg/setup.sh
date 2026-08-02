#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Lab 012'nin bozuk durumunu kurar. Idempotent.
#
# Bu lab systemd'nin PID 1 olduğu bir container ister: sshd birim olarak
# koşar, öğrenci onu systemctl ile yeniden başlatacak.
#
# Konu: SSH anahtar kimlik doğrulama ve StrictModes tuzağı, sshd_config
# sertleştirme + sözdizimi sınaması, GPG anahtar üretimi/şifreleme, GPG
# imza doğrulama ve imzalama.
#
# Sıfır bedava OK:
#   - authorized_keys hiç yok, ~/.ssh 0755, ev dizini 0775 (group-writable)
#     -> StrictModes girişi sessizce reddeder
#   - sshd SAĞLAM configle başlatılır, sonra disk bozulur ve RESTART EDİLMEZ:
#     sshd -t düşer, iki yönerge hâlâ yes, config mtime servis başlangıcından
#     yeni (yani değişiklik uygulanmamış)
#   - student'ın GPG anahtarlığı hiç yok: gizli anahtar yok, yayıncı anahtarı
#     içe aktarılmamış, gizli.txt.gpg yok, duyuru.txt.sig yok
#   - cevap-paket.txt yok
set -euo pipefail

HOME_STUDENT=/home/student
SSH_DIR="$HOME_STUDENT/.ssh"
SSHD_CONF=/etc/ssh/sshd_config
PAKET=/opt/paket
ASSETS=/opt/lab-assets/paket
GIZLI="$HOME_STUDENT/gizli.txt"
DUYURU="$HOME_STUDENT/duyuru.txt"
CEVAP="$HOME_STUDENT/cevap-paket.txt"

# --- 0. Temizlik (idempotens) ---------------------------------------------
# Öğrencinin yapmış olabileceği her şey geri alınır.
rm -rf "$SSH_DIR" "$HOME_STUDENT/.gnupg"
rm -f  "$CEVAP" "$GIZLI.gpg" "$DUYURU.sig" "$DUYURU.asc" "$GIZLI.asc"
rm -rf "$PAKET"
systemctl stop sshd.service >/dev/null 2>&1 || true

# --- 1. Host anahtarları ---------------------------------------------------
# Image'da üretilmiyor (reset tertemiz sunucu versin diye). ssh-keygen -A
# eksik olan her tipi üretir, var olanlara dokunmaz — idempotent.
ssh-keygen -A >/dev/null

# --- 2. sshd_config: ÖNCE sağlam sürüm ------------------------------------
# Servis bu sürümle başlatılır. Hikâye gereği sunucu henüz sertleştirilmemiş:
# root girişi ve parola girişi açık. Sözdizimi hatası burada YOK, yoksa
# servis hiç ayağa kalkmaz ve görev 1 test edilemezdi.
cat > "$SSHD_CONF" <<'EOF'
# Lab 012 sunucu yapilandirmasi.
Port 22
AddressFamily any
ListenAddress 0.0.0.0

HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
StrictModes yes

AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
UsePAM yes

PrintMotd no
Subsystem sftp /usr/libexec/openssh/sftp-server
EOF
chmod 0600 "$SSHD_CONF"

sshd -t
systemctl enable sshd.service >/dev/null 2>&1 || true
systemctl start  sshd.service
# Servis ayağa kalkıp portu dinlemeye başlayana kadar bekle.
for _ in $(seq 1 20); do
    ss -ltn 2>/dev/null | grep -q ':22 ' && break
    sleep 1
done

# --- 3. Şimdi diski boz, RESTART ETME (görev 2) ---------------------------
# MaxAuthTrys: MaxAuthTries'ın yazım hatası. sshd -t bunu "Bad configuration
# option" diye yakalar; sınamadan restart edilirse servis düşer.
# Dosya servis başladıktan SONRA değiştiği için mtime > servis başlangıcı:
# check.sh "değişiklik uygulanmamış" durumunu buradan görür.
#
# 3 saniye bekleniyor: karşılaştırma saniye çözünürlüğünde yapılıyor, 1
# saniyelik boşlukta yuvarlama iki damgayı eşitleyip kriteri bedavaya
# geçirebiliyordu (ölçüldü). Aradaki fark tartışmasız olmalı.
sleep 3
cat >> "$SSHD_CONF" <<'EOF'

# Bakim notu: asagidaki satir eklendi, servis henuz yeniden baslatilmadi.
MaxAuthTrys 6
EOF
chmod 0600 "$SSHD_CONF"

# --- 4. student'ın SSH anahtar çifti + bozuk izinler (görev 1) ------------
install -d -o student -g student -m 0755 "$SSH_DIR"
su - student -c "ssh-keygen -t ed25519 -N '' -q -f $SSH_DIR/id_ed25519"
chmod 0600 "$SSH_DIR/id_ed25519"
chmod 0644 "$SSH_DIR/id_ed25519.pub"
chown -R student:student "$SSH_DIR"
# authorized_keys BİLEREK yok: öğrenci onu kendisi kuracak.
# Ev dizini gruba yazılabilir: StrictModes tuzağı. authorized_keys doğru
# izinde olsa bile giriş reddedilir, üstelik istemci sebebini söylemez.
chmod 0775 "$HOME_STUDENT"
chown student:student "$HOME_STUDENT"

# --- 5. GPG tarafı: anahtarlık hiç yok (görev 3 ve 4) ---------------------
cat > "$GIZLI" <<'EOF'
Sunucu devir teslim notu.
Yedek parolasi kasada, oda 3.
Bu dosya sifrelenmeden diskte durmamali.
EOF
cat > "$DUYURU" <<'EOF'
Bakim duyurusu: cumartesi 02:00-04:00 arasi kesinti olacak.
EOF
chown student:student "$GIZLI" "$DUYURU"
chmod 0644 "$GIZLI" "$DUYURU"

# --- 6. Paketler (görev 4) ------------------------------------------------
# Image'dan kopyalanır; setup network'e çıkmaz. Gizli yayıncı anahtarı
# image'da YOK, build sırasında silindi — imza yeniden üretilemez.
install -d -o root -g root -m 0755 "$PAKET"
install -o root -g root -m 0644 "$ASSETS"/surum-a.tar.gz     "$PAKET/"
install -o root -g root -m 0644 "$ASSETS"/surum-a.tar.gz.sig "$PAKET/"
install -o root -g root -m 0644 "$ASSETS"/surum-b.tar.gz     "$PAKET/"
install -o root -g root -m 0644 "$ASSETS"/surum-b.tar.gz.sig "$PAKET/"
install -o root -g root -m 0644 "$ASSETS"/yayinci-acik.asc   "$PAKET/"

# --- 7. Kendi kendini doğrulama -------------------------------------------
err=0
say() { echo "setup HATA: $*" >&2; err=1; }

st() { su - student -c "$1" >/dev/null 2>&1; }

# host anahtarları ve servis
[ -s /etc/ssh/ssh_host_ed25519_key ] || say "host anahtari uretilmemis"
[ "$(systemctl is-active sshd.service 2>/dev/null || true)" = "active" ] ||
    say "sshd.service aktif degil"
ss -ltn 2>/dev/null | grep -q ':22 ' || say "sshd 22 portunu dinlemiyor"

# config gerçekten bozuk mu, iki yönerge hâlâ acik mi
sshd -t >/dev/null 2>&1 && say "sshd -t temiz cikti, sozdizimi hatasi kurulmamis"
grep -q '^PermitRootLogin yes'        "$SSHD_CONF" || say "PermitRootLogin yes yok"
grep -q '^PasswordAuthentication yes' "$SSHD_CONF" || say "PasswordAuthentication yes yok"
# config, servis basladiktan SONRA degismis olmali
conf_m="$(stat -c %Y "$SSHD_CONF")"
svc_us="$(systemctl show sshd.service -p ExecMainStartTimestampMonotonic --value)"
boot_us="$(awk '{printf "%.0f", $1 * 1000000}' /proc/uptime)"
svc_epoch=$(( $(date +%s) - (boot_us - svc_us) / 1000000 ))
[ "$conf_m" -gt "$svc_epoch" ] ||
    say "config mtime servis baslangicindan yeni degil (uygulanmamis durumu kurulamadi)"

# görev 1 bozuk mu
[ -e "$SSH_DIR/authorized_keys" ] && say "authorized_keys var olmamali"
[ -s "$SSH_DIR/id_ed25519" ]      || say "student ssh anahtari uretilmemis"
[ "$(stat -c %a "$SSH_DIR")" = "755" ]      || say ".ssh izni 755 degil"
[ "$(stat -c %a "$HOME_STUDENT")" = "775" ] || say "ev dizini izni 775 degil"
# giriş GERÇEKTEN reddedilmeli
st "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o PasswordAuthentication=no student@localhost true" &&
    say "anahtarla giris zaten calisiyor, bozuk durum kurulmamis"

# görev 3-4 bozuk mu
[ -e "$HOME_STUDENT/.gnupg" ] && say "student .gnupg dizini var olmamali"
st "gpg --list-secret-keys student@lab.local" &&
    say "student'in gizli gpg anahtari zaten var"
[ -e "$GIZLI.gpg" ] && say "$GIZLI.gpg var olmamali"
[ -e "$DUYURU.sig" ] && say "$DUYURU.sig var olmamali"
[ -e "$CEVAP" ] && say "$CEVAP var olmamali"
# yayınci anahtari ice aktarilmadan dogrulama DUSMELI
st "gpg --verify $PAKET/surum-a.tar.gz.sig $PAKET/surum-a.tar.gz" &&
    say "yayinci anahtari ice aktarilmadan imza dogrulanabiliyor"
# paketler yerinde ve student okuyabiliyor
for f in surum-a.tar.gz surum-a.tar.gz.sig surum-b.tar.gz surum-b.tar.gz.sig \
         yayinci-acik.asc; do
    [ -s "$PAKET/$f" ] || say "$PAKET/$f yok"
done
st "cat $PAKET/yayinci-acik.asc" || say "student yayinci-acik.asc okuyamiyor"

[ "$err" -eq 0 ] || exit 1
echo "setup done: 012-ssh-gpg"
