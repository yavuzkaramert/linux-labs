#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Lab 010'un bozuk durumunu kurar. Idempotent.
#
# Bu lab systemd'nin PID 1 olduğu bir container ister; ilk satırdaki
# container-systemd işaretini labctl okur ve container'ı privileged +
# /usr/sbin/init ile başlatır. Normal lablar bu işareti taşımaz.
#
# Konu: unit dosyası yazma, enable/disable, servis teşhisi, After/Requires,
# varsayılan target. journalctl ve timer BİLEREK dışarıda (011'e ait).
#
# Sıfır bedava OK: gorevci.service hiç yok, raporcu.service iki bağımsız
# hatayla kurulu ve failed durumda, api.service bağımlılıksız ve failed,
# veritabani.service durdurulmuş, varsayılan target rescue.target.
# Kalıcı konum kriteri de bedava geçmez: gorevci.service hiç olmadığı için
# FragmentPath boş döner ve o kriter de FAIL verir.
set -euo pipefail

UNITS=/etc/systemd/system
READY=/var/lib/veritabani/.ready

# --- 0. Temizlik (idempotens) ---------------------------------------------
# Öğrencinin yapmış olabileceği her şey geri alınır: unit'ler durdurulur,
# devre dışı bırakılır, oluşturduğu kullanıcı ve dosyalar silinir.
for u in gorevci raporcu api veritabani; do
    systemctl stop "$u.service"    >/dev/null 2>&1 || true
    systemctl disable "$u.service" >/dev/null 2>&1 || true
    rm -f "/run/systemd/system/$u.service"
    rm -rf "/run/systemd/system/$u.service.d" "$UNITS/$u.service.d"
done
rm -f "$UNITS/gorevci.service"
# raporcu kullanıcısı görevin bir parçası: öğrenci oluşturmuş olabilir.
userdel -r raporcu >/dev/null 2>&1 || true
rm -rf /var/lib/veritabani
systemctl daemon-reload
systemctl reset-failed >/dev/null 2>&1 || true

# --- 1. Servis gövdeleri ---------------------------------------------------
# Hepsi ÖN PLANDA kalır (oneshot olan hariç): fork etmez, & kullanmaz.
# Type=simple'ın doğru seçim olmasının sebebi bu.
mkdir -p /opt/app /opt/raporcu/bin /opt/db /opt/api

cat > /opt/app/gorevci <<'EOF'
#!/usr/bin/env bash
# Periyodik is yapan servis govdesi. On planda kalir, arka plana gecmez.
set -u
while true; do
    echo "gorevci: dongu $(date '+%F %T')"
    sleep 5
done
EOF

cat > /opt/raporcu/bin/raporcu <<'EOF'
#!/usr/bin/env bash
# Rapor ureten servis govdesi. On planda kalir.
set -u
while true; do
    echo "raporcu: rapor uretildi $(date '+%F %T')"
    sleep 5
done
EOF

cat > /opt/db/veritabani-init <<'EOF'
#!/usr/bin/env bash
# Bir kez calisir, hazir isaretini birakir ve CIKAR. Surekli calismaz.
set -eu
mkdir -p /var/lib/veritabani
: > /var/lib/veritabani/.ready
echo "veritabani: hazir isareti birakildi"
EOF

cat > /opt/api/api <<'EOF'
#!/usr/bin/env bash
# Veritabani hazir degilse baslamayi reddeder. Hazirsa on planda kalir.
set -u
if [ ! -e /var/lib/veritabani/.ready ]; then
    echo "api: veritabani hazir degil (/var/lib/veritabani/.ready yok)" >&2
    exit 1
fi
while true; do
    echo "api: istek bekleniyor"
    sleep 5
done
EOF

chmod 0755 /opt/app/gorevci /opt/raporcu/bin/raporcu \
           /opt/db/veritabani-init /opt/api/api
chown -R root:root /opt/app /opt/raporcu /opt/db /opt/api

# --- 2. raporcu.service — İKİ bağımsız hata (görev 2) ---------------------
# (a) ExecStart yanlış yola bakıyor: gerçek binary /opt/raporcu/bin/raporcu.
# (b) User=raporcu ama bu kullanıcı sistemde YOK.
# Ölçülmüş davranış: systemd önce 217/USER verir ve 203/EXEC'i maskeler.
# Kullanıcı düzeltilmeden yol hatası görünmez — kasıtlı katmanlı teşhis.
cat > "$UNITS/raporcu.service" <<'EOF'
[Unit]
Description=Raporlama servisi

[Service]
Type=simple
User=raporcu
ExecStart=/usr/local/bin/raporcu

[Install]
WantedBy=multi-user.target
EOF

# --- 3. veritabani.service — sağlam ama durdurulmuş (görev 3) -------------
cat > "$UNITS/veritabani.service" <<'EOF'
[Unit]
Description=Veritabani hazirlik islemi

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/opt/db/veritabani-init

[Install]
WantedBy=multi-user.target
EOF

# --- 4. api.service — bağımlılık YOK (görev 3) ----------------------------
# After/Requires bulunmadığı için veritabani'ndan bağımsız başlar ve
# .ready dosyasını bulamayıp güvenilir biçimde başarısız olur.
cat > "$UNITS/api.service" <<'EOF'
[Unit]
Description=API servisi

[Service]
Type=simple
ExecStart=/opt/api/api

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 "$UNITS"/raporcu.service "$UNITS"/veritabani.service \
           "$UNITS"/api.service
systemctl daemon-reload

# --- 5. Bozuk durumu FİİLEN üret ------------------------------------------
# Unit dosyasını yazmak yetmez; servisler başlatılıp gerçekten failed
# duruma düşürülür ki öğrenci systemctl status ile canlı bir hata görsün.
rm -f "$READY"
systemctl start raporcu.service >/dev/null 2>&1 || true
systemctl start api.service     >/dev/null 2>&1 || true
# Type=simple'da `start` fork eder etmez 0 döner; başarısızlık asenkron
# gelir. Durumu okumadan önce oturmasını bekle.
sleep 2

# --- 6. Varsayılan target bozma (görev 4) ---------------------------------
# set-default yalnız default.target sembolik bağını değiştirir; çalışan
# sistemi rescue'ya DÜŞÜRMEZ, o yüzden container ayakta kalır.
systemctl set-default rescue.target >/dev/null 2>&1

# --- 7. Kendi kendini doğrulama -------------------------------------------
err=0
say() { echo "setup HATA: $*" >&2; err=1; }

is_active()  { systemctl is-active  "$1" 2>/dev/null || true; }
is_enabled() { systemctl is-enabled "$1" 2>/dev/null || true; }

[ -x /opt/app/gorevci ]          || say "/opt/app/gorevci yok"
[ -x /opt/raporcu/bin/raporcu ]  || say "/opt/raporcu/bin/raporcu yok"
[ -x /opt/db/veritabani-init ]   || say "/opt/db/veritabani-init yok"
[ -x /opt/api/api ]              || say "/opt/api/api yok"

# gorevci hiç var olmamalı.
[ -e "$UNITS/gorevci.service" ] && say "gorevci.service var olmamali"
systemctl cat gorevci.service >/dev/null 2>&1 &&
    say "gorevci.service systemd tarafindan taniniyor, tanimamali"

# raporcu gerçekten çökmüş mü, sebebi kullanıcı hatası mı?
[ "$(is_active raporcu.service)" = "failed" ] ||
    say "raporcu.service failed degil: $(is_active raporcu.service)"
rap_status="$(systemctl show raporcu.service -p ExecMainStatus --value 2>/dev/null || true)"
[ "$rap_status" = "217" ] ||
    say "raporcu.service 217/USER ile degil '$rap_status' ile coktu"
getent passwd raporcu >/dev/null 2>&1 && say "raporcu kullanicisi var olmamali"

# api bağımlılıksız ve çökmüş mü?
[ "$(is_active api.service)" = "failed" ] ||
    say "api.service failed degil: $(is_active api.service)"
api_req="$(systemctl show api.service -p Requires --value 2>/dev/null || true)"
case "$api_req" in *veritabani.service*) say "api.service'te Requires zaten var" ;; esac
api_aft="$(systemctl show api.service -p After --value 2>/dev/null || true)"
case "$api_aft" in *veritabani.service*) say "api.service'te After zaten var" ;; esac

# veritabani durdurulmuş, hazır işareti yok.
[ "$(is_active veritabani.service)" = "inactive" ] ||
    say "veritabani.service inactive degil: $(is_active veritabani.service)"
[ ! -e "$READY" ] || say "$READY var olmamali"

# hiçbiri enabled olmamalı.
for u in raporcu api veritabani; do
    [ "$(is_enabled "$u.service")" = "enabled" ] &&
        say "$u.service enabled olmamali"
done

# varsayılan target bozuk mu?
[ "$(systemctl get-default 2>/dev/null || true)" = "rescue.target" ] ||
    say "varsayilan target rescue.target degil"

# öğrenci sorgu yapabilmeli (mutasyon icin sudo kullanacak).
su - student -c 'systemctl is-system-running' >/dev/null 2>&1 || true
su - student -c 'systemctl show api.service -p Id --value' >/dev/null 2>&1 ||
    say "student systemctl sorgusu yapamiyor"

[ "$err" -eq 0 ] || exit 1
echo "setup done: 010-systemd"
