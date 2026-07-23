#!/usr/bin/env bash
# Root olarak çalışır. Lab 003'ün bozuk durumunu kurar. Idempotent:
# /srv/data her seferinde sıfırdan yaratılır.
set -euo pipefail

rm -rf /srv/data
mkdir -p /srv/data/{app/logs,app/spool,web/logs/nginx,db/dumps,reports,config/conf.d,scripts/maintenance,tmp}

# --- Kriter 1: eski/yeni log karışımı, 3-4 seviye derinlikte ---
echo "boot sequence complete"        > /srv/data/app/logs/app-2026-04.log
touch -d "85 days ago"                 /srv/data/app/logs/app-2026-04.log
echo "GET /index.html 200"           > /srv/data/web/logs/nginx/access-old.log
touch -d "60 days ago"                 /srv/data/web/logs/nginx/access-old.log
echo "backup finished with warnings" > /srv/data/db/old-backup.log
touch -d "45 days ago"                 /srv/data/db/old-backup.log

echo "app running, all good"         > /srv/data/app/logs/app-current.log
echo "GET /health 200"               > /srv/data/web/logs/nginx/access.log

# --- Kriter 2: sıfır byte artıklar + benzer isimli dolu yemler ---
: > /srv/data/app/cache.tmp
: > /srv/data/app/spool/.keep
: > /srv/data/web/session.lock
: > /srv/data/web/logs/debug.old
: > /srv/data/db/dumps/dump-failed.sql
: > /srv/data/reports/draft.txt
echo "cached user data"              > /srv/data/app/cache.dat
echo "CREATE TABLE users (id int);"  > /srv/data/db/dumps/dump-good.sql

# --- Kriter 3: tmp içinde büyük/küçük dosya karışımı ---
dd if=/dev/zero of=/srv/data/tmp/big-dump.bin   bs=1M count=3   status=none
dd if=/dev/zero of=/srv/data/tmp/video-frag.mp4 bs=1M count=2   status=none
dd if=/dev/zero of=/srv/data/tmp/session-01.dat bs=1K count=20  status=none
dd if=/dev/zero of=/srv/data/tmp/session-02.dat bs=1K count=100 status=none

# --- Kriter 4: config — karışık izin, sahiplik ve eski mtime'lar.
# Metadata korunmadan alınan kopya (düz cp -r) kriteri geçemez.
echo "app_port=8080"        > /srv/data/config/app.conf
chmod 600                     /srv/data/config/app.conf
touch -d "70 days ago"        /srv/data/config/app.conf

echo "db_host=localhost"    > /srv/data/config/db.conf
chmod 600                     /srv/data/config/db.conf
touch -d "40 days ago"        /srv/data/config/db.conf

echo "workers=4"            > /srv/data/config/conf.d/extra.conf
chown student:student         /srv/data/config/conf.d/extra.conf
chmod 644                     /srv/data/config/conf.d/extra.conf
touch -d "25 days ago"        /srv/data/config/conf.d/extra.conf

echo "start_mode=fast"      > /srv/data/config/startup.conf
chmod 755                     /srv/data/config/startup.conf
touch -d "90 days ago"        /srv/data/config/startup.conf

# --- Kriter 5: csv raporlar — en yenisi belli; summary.txt daha da yeni
# olduğundan "en yeni dosya" tuzağı csv olmayanı gösterir. latest yok.
echo "ay,ciro"$'\n'"mayis,100"   > /srv/data/reports/2026-05.csv
touch -d "50 days ago"             /srv/data/reports/2026-05.csv
echo "ay,ciro"$'\n'"haziran,120" > /srv/data/reports/2026-06.csv
touch -d "20 days ago"             /srv/data/reports/2026-06.csv
echo "ay,ciro"$'\n'"temmuz,150"  > /srv/data/reports/2026-07.csv
touch -d "2 days ago"              /srv/data/reports/2026-07.csv
echo "ozet: her sey yolunda"     > /srv/data/reports/summary.txt

# --- Kriter 6: hepsi 644; rotate.sh alt dizinde saklı, notes.txt yem ---
printf '#!/bin/sh\necho "deploy ok"\n'      > /srv/data/scripts/deploy.sh
printf '#!/bin/sh\necho "health ok"\n'      > /srv/data/scripts/healthcheck.sh
printf '#!/bin/sh\necho "rotate ok"\n'      > /srv/data/scripts/maintenance/rotate.sh
printf 'operasyon notlari - calistirma\n'   > /srv/data/scripts/notes.txt
chmod 644 /srv/data/scripts/deploy.sh \
          /srv/data/scripts/healthcheck.sh \
          /srv/data/scripts/maintenance/rotate.sh \
          /srv/data/scripts/notes.txt

echo "setup done"
