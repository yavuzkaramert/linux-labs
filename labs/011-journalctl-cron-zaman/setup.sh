#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Lab 011'in bozuk durumunu kurar. Idempotent.
#
# Bu lab systemd'nin PID 1 olduğu bir container ister: journald, crond,
# systemd timer ve chronyd'nin hepsi gerçek birim olarak koşar. İlk
# satırdaki container-systemd işaretini labctl okur ve container'ı
# privileged + /usr/sbin/init ile başlatır.
#
# Konu: kalıcı journal, journalctl ile teşhis, cron ortam tuzağı, systemd
# timer yazma, saat dilimi ve chronyd.
#
# Sıfır bedava OK:
#   - /var/log/journal yok, journald.conf'ta Storage yok  -> günlük volatile
#   - /home/student/cevap-bekci.txt yok
#   - bekci.service iki katmanlı hata ile sonsuz restart döngüsünde, disabled
#   - crond stopped + disabled
#   - /etc/cron.d/yedek: 03:00 zamanlaması + mutlak yolsuz komut
#   - /var/log/yedek/yedek.log ve /var/log/temizlik.log yok
#   - temizlik.service ve temizlik.timer hiç yok
#   - saat dilimi America/New_York
#   - /etc/chrony.conf'ta zaman sunucusu satırı yok
#   - chronyd stopped + disabled, timedated NTP kapalı
set -euo pipefail

UNITS=/etc/systemd/system
LISANS=/etc/bekci/lisans.key
CEVAP=/home/student/cevap-bekci.txt
YEDEK_LOG=/var/log/yedek/yedek.log
TEMIZLIK_LOG=/var/log/temizlik.log

# --- 0. Temizlik (idempotens) ---------------------------------------------
# Öğrencinin yapmış olabileceği her şey geri alınır.
for u in bekci temizlik; do
    systemctl stop "$u.service"    >/dev/null 2>&1 || true
    systemctl disable "$u.service" >/dev/null 2>&1 || true
done
systemctl stop temizlik.timer    >/dev/null 2>&1 || true
systemctl disable temizlik.timer >/dev/null 2>&1 || true
rm -f  "$UNITS/temizlik.service" "$UNITS/temizlik.timer"
rm -rf "$UNITS/temizlik.service.d" "$UNITS/temizlik.timer.d"
rm -f  /run/systemd/system/temizlik.service /run/systemd/system/temizlik.timer
rm -rf /run/systemd/system/temizlik.service.d /run/systemd/system/temizlik.timer.d
rm -rf /etc/bekci
rm -f  "$CEVAP"
rm -rf /var/log/yedek "$TEMIZLIK_LOG"
# Öğrenci işi cron.d yerine kendi crontab'ına da yazmış olabilir.
crontab -r -u student >/dev/null 2>&1 || true
crontab -r -u root    >/dev/null 2>&1 || true
systemctl daemon-reload
systemctl reset-failed >/dev/null 2>&1 || true

# --- 1. Journal'ı volatile'a döndür (görev 1) ------------------------------
# Storage=auto varsayılanı: /var/log/journal VARSA kalıcı, yoksa yalnız
# /run/log/journal. Öğrenci dizini açmış ya da conf'a Storage yazmış olabilir;
# ikisi de geri alınır.
# Rocky 10'da /etc/systemd/journald.conf YOKTUR; varsayılanlar
# /usr/lib/systemd/journald.conf'tan gelir. Öğrenci /etc altında bir override
# ya da drop-in yazmış olabilir — ikisi de temizlenir.
rm -rf /etc/systemd/journald.conf.d
if [ -f /etc/systemd/journald.conf ]; then
    sed -i '/^[[:space:]]*Storage=/d' /etc/systemd/journald.conf
fi
rm -rf /var/log/journal
systemctl restart systemd-journald.service >/dev/null 2>&1 || true

# --- 2. Program gövdeleri --------------------------------------------------
mkdir -p /opt/bekci

cat > /opt/bekci/bekci <<'EOF'
#!/usr/bin/env bash
# Nobet servisi. Lisans dosyasi olmadan calismayi reddeder.
#
# <3> oneki: systemd'nin gunluk akis ayristiricisi satir basindaki <N>
# damgasini okuyup kaydi o oncelikle isler ve oneki cikarir. Boylece bu
# satirlar journalctl -p err ile suzulebilir.
set -u
LIS=/etc/bekci/lisans.key
if [ ! -e "$LIS" ]; then
    echo "<3>FATAL: $LIS bulunamadi" >&2
    exit 3
fi
if ! grep -q '^KEY=' "$LIS"; then
    echo "<3>FATAL: lisans anahtari gecersiz ($LIS icinde KEY= satiri yok)" >&2
    exit 4
fi
while true; do
    echo "bekci: nobet tutuluyor"
    sleep 10
done
EOF

cat > /usr/local/bin/yedekle <<'EOF'
#!/usr/bin/env bash
# Yedekleme isi. Her calismada log dosyasina bir satir ekler.
set -u
LOG=/var/log/yedek/yedek.log
mkdir -p "$(dirname "$LOG")"
printf '%s yedek alindi\n' "$(date '+%F %T')" >> "$LOG"
EOF

cat > /usr/local/bin/temizlik <<'EOF'
#!/usr/bin/env bash
# Bakim isi. Her calismada log dosyasina bir satir ekler.
set -u
LOG=/var/log/temizlik.log
printf '%s temizlik yapildi\n' "$(date '+%F %T')" >> "$LOG"
EOF

chmod 0755 /opt/bekci/bekci /usr/local/bin/yedekle /usr/local/bin/temizlik
chown root:root /opt/bekci/bekci /usr/local/bin/yedekle /usr/local/bin/temizlik

# --- 3. bekci.service — iki katmanlı hata (görev 1) ------------------------
# StartLimitIntervalSec=0: hız sınırı kapalı. Aksi hâlde systemd beş hızlı
# çökmeden sonra birimi failed'a düşürüp denemeyi bırakırdı; burada çökmenin
# SÜRMESİ isteniyor ki öğrenci canlı bir döngü görsün.
# Servis başlatılır ama ENABLE EDİLMEZ: kalıcılık da öğrencinin işi.
cat > "$UNITS/bekci.service" <<'EOF'
[Unit]
Description=Nobet servisi
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=/opt/bekci/bekci
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 "$UNITS/bekci.service"
systemctl daemon-reload
systemctl start bekci.service >/dev/null 2>&1 || true

# --- 4. cron işi — üç bağımsız hata (görev 2) ------------------------------
# (a) crond durdurulmuş ve disabled.
# (b) zamanlama 03:00 — lab süresince hiç tetiklenmez.
# (c) komut mutlak yolsuz. cron'un işlere verdiği PATH /usr/bin:/bin'dir;
#     /usr/local/bin orada YOKTUR, yani komut bulunamaz. Klasik "cron bir
#     giriş kabuğu değildir" tuzağı.
cat > /etc/cron.d/yedek <<'EOF'
# Gecelik yedekleme isi
0 3 * * * root yedekle
EOF
chmod 0644 /etc/cron.d/yedek
chown root:root /etc/cron.d/yedek
systemctl disable crond.service >/dev/null 2>&1 || true
systemctl stop    crond.service >/dev/null 2>&1 || true

# --- 5. Saat dilimi ve chronyd (görev 4) -----------------------------------
# Image /etc/localtime'ı Europe/Istanbul'a bağlar; burada bilerek kaydırılır.
timedatectl set-timezone America/New_York >/dev/null 2>&1 ||
    ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

# chrony.conf tamamen yeniden yazılır: idempotent (tekrar tekrar yorum
# satırı eklemez) ve zaman sunucusu satırı kesin olarak yoktur.
cat > /etc/chrony.conf <<'EOF'
# Lab 011: zaman sunucusu satiri BILEREK silinmis durumda.
driftfile /var/lib/chrony/drift
makestep 1.0 3
logdir /var/log/chrony
EOF
chmod 0644 /etc/chrony.conf

systemctl disable chronyd.service >/dev/null 2>&1 || true
systemctl stop    chronyd.service >/dev/null 2>&1 || true
timedatectl set-ntp false >/dev/null 2>&1 || true

# --- 6. Kendi kendini doğrulama --------------------------------------------
# Type=simple'da start hemen döner; bekci'nin ilk çökmesinin oturması beklenir.
sleep 3

err=0
say() { echo "setup HATA: $*" >&2; err=1; }

is_active()  { systemctl is-active  "$1" 2>/dev/null || true; }
is_enabled() { systemctl is-enabled "$1" 2>/dev/null || true; }

# programlar yerinde mi
[ -x /opt/bekci/bekci ]       || say "/opt/bekci/bekci yok"
[ -x /usr/local/bin/yedekle ] || say "/usr/local/bin/yedekle yok"
[ -x /usr/local/bin/temizlik ]|| say "/usr/local/bin/temizlik yok"

# kriter 1: journal volatile olmalı
[ -e /var/log/journal ] && say "/var/log/journal var olmamali"
[ -f /etc/systemd/journald.conf ] &&
    grep -q '^[[:space:]]*Storage=' /etc/systemd/journald.conf &&
    say "journald.conf'ta Storage satiri kalmis"

# kriter 2: cevap dosyası olmamalı
[ -e "$CEVAP" ] && say "$CEVAP var olmamali"

# kriter 3: bekci çökme döngüsünde ve disabled
[ -e "$LISANS" ] && say "$LISANS var olmamali"
bekci_res="$(systemctl show bekci.service -p Result --value 2>/dev/null || true)"
[ "$bekci_res" = "exit-code" ] ||
    say "bekci.service Result='$bekci_res', beklenen 'exit-code'"
bekci_st="$(systemctl show bekci.service -p ExecMainStatus --value 2>/dev/null || true)"
[ "$bekci_st" = "3" ] ||
    say "bekci.service '$bekci_st' ile degil 3 ile cokmeli"
[ "$(is_enabled bekci.service)" = "enabled" ] && say "bekci.service enabled olmamali"
# günlükte gerçekten görünüyor mu — teşhis görevi bunun üstüne kurulu
journalctl -u bekci.service -n 50 --no-pager 2>/dev/null |
    grep -q "FATAL: $LISANS bulunamadi" ||
    say "bekci'nin hata satiri journal'da gorunmuyor"

# kriter 4: crond durdurulmuş ve disabled
[ "$(is_active  crond.service)" = "active"  ] && say "crond.service aktif olmamali"
[ "$(is_enabled crond.service)" = "enabled" ] && say "crond.service enabled olmamali"

# kriter 5-6: cron tanımı hem yanlış saatte hem mutlak yolsuz
grep -q '^0 3 \* \* \* root yedekle$' /etc/cron.d/yedek ||
    say "/etc/cron.d/yedek beklenen bozuk satiri tasimiyor"

# kriter 7-8: yedek çıktısı ve crond günlüğü olmamalı
[ -e "$YEDEK_LOG" ] && say "$YEDEK_LOG var olmamali"

# kriter 9-14: timer tarafı hiç kurulu olmamalı
systemctl cat temizlik.service >/dev/null 2>&1 &&
    say "temizlik.service systemd tarafindan taniniyor, tanimamali"
systemctl cat temizlik.timer >/dev/null 2>&1 &&
    say "temizlik.timer systemd tarafindan taniniyor, tanimamali"
[ -e "$TEMIZLIK_LOG" ] && say "$TEMIZLIK_LOG var olmamali"

# kriter 15-16: saat dilimi yanlış
tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
[ "$tz" = "Europe/Istanbul" ] && say "saat dilimi hala Europe/Istanbul"
case "$(readlink -f /etc/localtime 2>/dev/null || true)" in
    */Europe/Istanbul) say "/etc/localtime hala Istanbul'a bakiyor" ;;
esac

# kriter 17-19: chrony bozuk
grep -Eq '^[[:space:]]*(pool|server)[[:space:]]+[^[:space:]]+' /etc/chrony.conf &&
    say "chrony.conf'ta zaman sunucusu satiri kalmis"
[ "$(is_active  chronyd.service)" = "active"  ] && say "chronyd.service aktif olmamali"
[ "$(is_enabled chronyd.service)" = "enabled" ] && say "chronyd.service enabled olmamali"
[ "$(timedatectl show -p NTP --value 2>/dev/null || true)" = "yes" ] &&
    say "timedated NTP acik kalmis"

# öğrenci sorgu yapabilmeli (mutasyon icin sudo kullanacak)
# student journal grubunda DEGIL: gunlugu sudo ile okuyacak (gercek sunucu
# davranisi). sudo'suz journalctl "insufficient permissions" der ama yine de
# 0 doner, o yuzden burada ciktinin kendisi sinanir.
su - student -c 'sudo -n journalctl -u bekci.service -n 5 --no-pager' 2>/dev/null |
    grep -q 'FATAL' || say "student sudo ile bekci gunlugunu okuyamiyor"
su - student -c 'timedatectl show -p Timezone --value' >/dev/null 2>&1 ||
    say "student timedatectl sorgusu yapamiyor"
su - student -c 'systemctl list-timers --all' >/dev/null 2>&1 ||
    say "student systemctl list-timers calistiramiyor"

[ "$err" -eq 0 ] || exit 1
echo "setup done: 011-journalctl-cron-zaman"
