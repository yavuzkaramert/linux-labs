#!/usr/bin/env bash
# Root olarak çalışır. Lab 004'ün bozuk durumunu kurar. Idempotent.
set -euo pipefail

ACCESS=/srv/logs/access.log
APP=/srv/logs/app.log
SETTINGS=/etc/webapp/settings.conf
HOSTS=/etc/webapp/hosts.list
GOLDEN=/opt/lab-golden/settings.conf

rm -rf /srv/logs /srv/reports /etc/webapp /opt/lab-golden
mkdir -p /srv/logs /etc/webapp /opt/lab-golden

# --- access.log: ~395 satır, alan sırası:
#     IP - kullanıcı [zaman] "GET /yol HTTP/1.1" DURUM BOYUT
#     Durum kodu $(NF-1), boyut $NF. Tuzaklar: boyutu 500 olan 200'ler ve
#     yolunda /500 geçen satırlar — düz "grep 500" bunları da yakalar.
IPS=(10.0.0.1 10.0.0.2 10.0.0.3 10.0.0.4 10.0.0.5 10.0.0.6 10.0.0.7 10.0.0.8 10.0.0.9 10.0.0.10)
CNT=(90 75 60 45 35 25 20 18 15 12)   # ilk 5 birbirinden farklı → sıralama tek anlamlı
USERS=(alice bob carol dave erin frank)
LN=0
: > "$ACCESS"
for idx in "${!IPS[@]}"; do
    ip="${IPS[$idx]}"
    n="${CNT[$idx]}"
    k=0
    while [ "$k" -lt "$n" ]; do
        k=$((k + 1))
        LN=$((LN + 1))
        if (( LN % 7 == 0 )); then
            user="-"
        else
            user="${USERS[$((LN % 6))]}"
        fi
        if (( LN % 9 == 0 )); then
            status=500; size=$((120 + LN % 800)); path="/api/checkout"
        elif (( LN % 13 == 0 )); then
            status=200; size=500;                path="/index.html"      # tuzak: boyut 500
        elif (( LN % 17 == 0 )); then
            status=200; size=$((200 + LN % 400)); path="/500/summary"    # tuzak: yolda 500
        elif (( LN % 5 == 0 )); then
            status=404; size=$((60 + LN % 200));  path="/old/page"
        else
            status=200; size=$((300 + LN % 1500)); path="/home"
        fi
        printf '%s - %s [10/Oct/2026:13:%02d:%02d] "GET %s HTTP/1.1" %s %s\n' \
            "$ip" "$user" "$(((LN / 60) % 60))" "$((LN % 60))" "$path" "$status" "$size" >> "$ACCESS"
    done
done

# --- app.log: ~80 satır, zaman|SEVİYE|mesaj ; WARN mesajları | içermez
#     ama virgül/boşluk içerir.
: > "$APP"
j=0
while [ "$j" -lt 80 ]; do
    j=$((j + 1))
    case $((j % 4)) in
        0) lvl=DEBUG; msg="cache miss for key user_$j" ;;
        1) lvl=INFO;  msg="request handled in ${j}ms" ;;
        2) lvl=WARN;  msg="slow query, took ${j}0ms on shard $j" ;;
        3) lvl=ERROR; msg="upstream refused connection $j" ;;
    esac
    printf '2026-10-10T13:%02d:%02d|%s|%s\n' "$((j % 60))" "$(((j * 7) % 60))" "$lvl" "$msg" >> "$APP"
done

# Kriter 1: loglar root:root ve 600 — student okuyamasın
chown root:root "$ACCESS" "$APP"
chmod 600 "$ACCESS" "$APP"

# --- settings.conf: etkin debug=true, 3 etkin old-server.local satırı,
#     yorumlarda old-server.local ve #debug=true (negatif test yemi).
cat > "$SETTINGS" <<'EOF'
# Web application configuration
# NOTE: old-server.local was retired, kept here only for history
#debug = true
debug = true
primary_host = old-server.local
backup_host = old-server.local
db_host = old-server.local
worker_count = 4
# fallback_host = old-server.local
log_level = info
EOF
cp -a "$SETTINGS" "$GOLDEN"   # check.sh'in orijinalle kıyaslayacağı altın kopya
chmod 600 "$GOLDEN"

# --- hosts.list: boş satırlar, # yorumları, gerçek hostlar; bir satırda
#     # var ama satır başında değil (silinmemeli).
cat > "$HOSTS" <<'EOF'
# production web hosts
web01.local
web02.local

# database
db01.local  # primary db
app01.local


# end of list
EOF

echo "setup done"
