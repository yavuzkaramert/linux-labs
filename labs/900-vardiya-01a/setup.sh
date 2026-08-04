#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Lab 900-vardiya-01a'nın bozuk durumunu kurar. Idempotent.
#
# Bu bir TEKRAR labıdır: altı ayrı ticket, altı ayrı kaynak lab (001-006).
# Her ticket'ın kurulumu kendi bölümünde; hepsi TEK setup.sh çağrısında olur.
#
# DİKKAT:
#  * Ticket 2 ve Ticket 3 aynı dizini (/srv/proje) paylaşır. Ticket 3'ün bozuk
#    içeriği, Ticket 2'nin yanlış sahiplikle kurduğu dizinin ALTINA kurulur —
#    iki ayrı adım değil. Sahiplik zinciri bilerek böyle.
#  * Ticket 5 canlı süreçler başlatır (LABPROC-* işaretli), Ticket 6 ayrı bir
#    servis süreci seti başlatır (vardiya-* comm işaretli). İkisi teknik olarak
#    birbirine bağlı DEĞİL.
#  * Setup başında eski süreçler öldürülür → `labctl reset` kalıntı bırakmaz.
set -euo pipefail

VARDIYA=/vardiya
PROJE=/srv/proje
REPORTS=/srv/reports
GOLDEN=/opt/lab-golden
PROCDIR=/opt/lab-procs
SVCDIR=/usr/local/lib/vardiyaprocs
LOGDIR=/var/log/vardiya
LISTDIR=/etc/vardiya
BINDIR=/usr/local/bin
STUDENT=student

SERVICES="vardiya-web vardiya-worker vardiya-cache"

# --- 0. Önceki koşudan kalanları temizle ------------------------------------
pkill -9 -f 'LABPROC'              2>/dev/null || true
pkill -9 -f "$PROCDIR"             2>/dev/null || true
pkill -9 -f 'nightly-batch-runner' 2>/dev/null || true
for svc in $SERVICES vardiya-queue; do
    pkill -9 -x "$svc" 2>/dev/null || true
done
sleep 1

rm -rf "$VARDIYA" "$PROJE" "$REPORTS" "$GOLDEN" "$PROCDIR" "$SVCDIR" \
       "$LOGDIR" "$LISTDIR"
rm -f "$BINDIR/logsum" "$BINDIR/svccheck" "$BINDIR/report"

# Ticket 2: ayse/mehmet/deploybot hiç yok, developers grubu hiç yok.
for u in ayse mehmet deploybot; do
    userdel -r "$u" >/dev/null 2>&1 || true
done
rm -rf /home/ayse /home/mehmet /home/deploybot
groupdel developers >/dev/null 2>&1 || true
gpasswd -d "$STUDENT" developers >/dev/null 2>&1 || true

# Çıktı dizini: üç ticket buraya yazar, /srv/proje'nin DIŞINDA durur ki
# Ticket 2'nin sahiplik zinciri Ticket 5-6'yı kilitlemesin.
mkdir -p "$REPORTS"
chown "$STUDENT:$STUDENT" "$REPORTS"
chmod 0755 "$REPORTS"

# =============================================================================
# TICKET 1 — Vardiya günlüğü (kaynak: lab 001, permissions)
# =============================================================================
# Dizin 700, dosya 600, ikisi de root:root. student hiçbirine dokunamaz.
# Çözüm chown DEĞİL: "other" bitini açmak.
mkdir -p "$VARDIYA"
cat > "$VARDIYA/gunluk.md" <<'EOF'
# Vardiya Günlüğü — gece nöbeti

Sabaha devrettiklerim. Sırayla git, hepsi bugün bitmeli.

1. Bu günlüğü okuyamıyorsan önce onu çöz. Sahipliği değiştirme,
   bu dosya sistemin, senin değil.
2. İki yeni işe alım var: ayse ve mehmet. Hesaplarını aç, ortak
   proje dizinini onlara hazırla. tolga ayrıldı, hesabı hâlâ duruyor.
3. /srv/proje dağınık. Eski loglar, sıfır byte artıklar, dev dosyalar,
   çalıştırma izni olmayan scriptler.
4. Gece boyunca log biriktik. Hata raporu ve IP dökümü istiyorlar.
5. Üç süreç başıboş kalmış. Biri CPU yiyor, biri kibar sinyali yok
   sayıyor, biri de gece batch'i — o ölmeyecek, yavaşlayacak.
6. Gün ortası özet raporu için script zinciri yarım kaldı.

— gece nöbetçisi
EOF
chown -R root:root "$VARDIYA"
chmod 0700 "$VARDIYA"
chmod 0600 "$VARDIYA/gunluk.md"

# check.sh'in "içerik değişmemiş" kriterini kıyaslayacağı altın kopya.
mkdir -p "$GOLDEN"
cp -a "$VARDIYA/gunluk.md" "$GOLDEN/gunluk.md"
chmod 0600 "$GOLDEN/gunluk.md"

# =============================================================================
# TICKET 2 — İşe alımlar ve proje dizini (kaynak: lab 002, users & groups)
# =============================================================================
# tolga ayrıldı ama hesabı ve ev dizini duruyor.
if ! id tolga >/dev/null 2>&1; then
    useradd -m -s /bin/bash tolga
fi
printf 'devir notlari, 2025 - muhtemelen guncel degil\n' > /home/tolga/notlar.txt
printf '#!/bin/sh\necho "eski deploy script"\n'          > /home/tolga/deploy.sh
chown -R tolga:tolga /home/tolga

# /srv/proje zaten var ama yanlış sahiplik/izinle: root:root, 0700.
# setgid yok, developers grubu yok → ayse/mehmet giremez bile.
mkdir -p "$PROJE"
chown root:root "$PROJE"
chmod 0700 "$PROJE"

# =============================================================================
# TICKET 3 — Proje dizinini temizle (kaynak: lab 003, finding files)
# =============================================================================
# AYNI dizinin altına, aynı çağrıda kuruluyor.
mkdir -p "$PROJE"/{tmp,config/conf.d,reports,scripts/bakim,spool}

# --- Kriter 1: 30 günden eski/yeni .log karışımı ---
echo "gece yedegi tamamlandi"        > "$PROJE/nisan.log"
touch -d "85 days ago"                 "$PROJE/nisan.log"
echo "GET /index.html 200"           > "$PROJE/erisim-eski.log"
touch -d "60 days ago"                 "$PROJE/erisim-eski.log"
echo "yedekleme uyarilarla bitti"    > "$PROJE/reports/yedek-eski.log"
touch -d "45 days ago"                 "$PROJE/reports/yedek-eski.log"

echo "servis calisiyor, sorun yok"   > "$PROJE/guncel.log"
echo "GET /health 200"               > "$PROJE/erisim.log"

# --- Kriter 2: sıfır byte artıklar + benzer isimli dolu yemler ---
: > "$PROJE/tmp/onbellek.tmp"
: > "$PROJE/spool/.keep"
: > "$PROJE/oturum.lock"
: > "$PROJE/reports/taslak.txt"
: > "$PROJE/config/conf.d/bos.conf"
echo "onbellege alinmis kullanici verisi" > "$PROJE/tmp/onbellek.dat"
echo "CREATE TABLE kullanicilar (id int);" > "$PROJE/config/sema.sql"

# --- Kriter 3: tmp içinde büyük/küçük dosya karışımı ---
dd if=/dev/zero of="$PROJE/tmp/buyuk-dokum.bin" bs=1M count=3  status=none
dd if=/dev/zero of="$PROJE/tmp/video-parca.mp4" bs=1M count=2  status=none
dd if=/dev/zero of="$PROJE/tmp/oturum-01.dat"   bs=1K count=20 status=none
dd if=/dev/zero of="$PROJE/tmp/oturum-02.dat"   bs=1K count=100 status=none

# --- Kriter 4: config — karışık izin, sahiplik, eski mtime.
# Metadata korunmadan alınan kopya (düz cp -r) kriteri geçemez.
echo "app_port=8080"     > "$PROJE/config/app.conf"
chmod 640                  "$PROJE/config/app.conf"
touch -d "70 days ago"     "$PROJE/config/app.conf"

echo "db_host=localhost" > "$PROJE/config/db.conf"
chmod 600                  "$PROJE/config/db.conf"
touch -d "40 days ago"     "$PROJE/config/db.conf"

echo "workers=4"         > "$PROJE/config/conf.d/ekstra.conf"
chown "$STUDENT:$STUDENT"  "$PROJE/config/conf.d/ekstra.conf"
chmod 644                  "$PROJE/config/conf.d/ekstra.conf"
touch -d "25 days ago"     "$PROJE/config/conf.d/ekstra.conf"

echo "start_mode=fast"   > "$PROJE/config/baslangic.conf"
chmod 755                  "$PROJE/config/baslangic.conf"
touch -d "90 days ago"     "$PROJE/config/baslangic.conf"

# --- Kriter 5: csv raporlar. ozet.txt hepsinden yeni → "en yeni dosya"
# tuzağı csv olmayanı gösterir. latest linki yok.
printf 'ay,ciro\nmayis,100\n'   > "$PROJE/reports/2026-05.csv"
touch -d "50 days ago"            "$PROJE/reports/2026-05.csv"
printf 'ay,ciro\nhaziran,120\n' > "$PROJE/reports/2026-06.csv"
touch -d "20 days ago"            "$PROJE/reports/2026-06.csv"
printf 'ay,ciro\ntemmuz,150\n'  > "$PROJE/reports/2026-07.csv"
touch -d "2 days ago"             "$PROJE/reports/2026-07.csv"
echo "ozet: her sey yolunda"    > "$PROJE/reports/ozet.txt"

# --- Kriter 6: hepsi 644; rotate.sh alt dizinde saklı, notlar.txt yem ---
printf '#!/bin/sh\necho "deploy ok"\n'    > "$PROJE/scripts/deploy.sh"
printf '#!/bin/sh\necho "saglik ok"\n'    > "$PROJE/scripts/saglik.sh"
printf '#!/bin/sh\necho "rotate ok"\n'    > "$PROJE/scripts/bakim/rotate.sh"
printf 'operasyon notlari - calistirma\n' > "$PROJE/scripts/notlar.txt"
chmod 644 "$PROJE/scripts/deploy.sh" \
          "$PROJE/scripts/saglik.sh" \
          "$PROJE/scripts/bakim/rotate.sh" \
          "$PROJE/scripts/notlar.txt"

# =============================================================================
# TICKET 4 — Log analizi (kaynak: lab 004, text processing)
# =============================================================================
mkdir -p "$PROJE/logs" "$PROJE/etc" "$GOLDEN"
ACCESS="$PROJE/logs/access.log"
APP="$PROJE/logs/app.log"
SETTINGS="$PROJE/etc/settings.conf"
HOSTS="$PROJE/etc/hosts.list"

# access.log alan sırası:  IP - kullanıcı [zaman] "GET /yol HTTP/1.1" DURUM BOYUT
# Durum kodu $(NF-1), boyut $NF. Tuzaklar: boyutu 500 olan 200'ler ve yolunda
# /500 geçen satırlar — düz `grep 500` ikisini de yakalar.
IPS=(10.0.0.1 10.0.0.2 10.0.0.3 10.0.0.4 10.0.0.5 10.0.0.6 10.0.0.7 10.0.0.8 10.0.0.9 10.0.0.10)
CNT=(90 75 60 45 35 25 20 18 15 12)   # ilk 5 farklı → sıralama tek anlamlı
USERS=(ayse mehmet tolga burak deniz ayse)
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
            status=500; size=$((120 + LN % 800)); path="/api/odeme"
        elif (( LN % 13 == 0 )); then
            status=200; size=500;                 path="/index.html"   # tuzak: boyut 500
        elif (( LN % 17 == 0 )); then
            status=200; size=$((200 + LN % 400)); path="/500/ozet"     # tuzak: yolda 500
        elif (( LN % 5 == 0 )); then
            status=404; size=$((60 + LN % 200));  path="/eski/sayfa"
        else
            status=200; size=$((300 + LN % 1500)); path="/home"
        fi
        printf '%s - %s [10/Oct/2026:08:%02d:%02d] "GET %s HTTP/1.1" %s %s\n' \
            "$ip" "$user" "$(((LN / 60) % 60))" "$((LN % 60))" "$path" "$status" "$size" >> "$ACCESS"
    done
done

# app.log: zaman|SEVİYE|mesaj. WARN mesajları | içermez ama virgül/boşluk içerir.
: > "$APP"
j=0
while [ "$j" -lt 80 ]; do
    j=$((j + 1))
    case $((j % 4)) in
        0) lvl=DEBUG; msg="onbellek isabetsiz, anahtar user_$j" ;;
        1) lvl=INFO;  msg="istek ${j}ms icinde islendi" ;;
        2) lvl=WARN;  msg="yavas sorgu, shard $j uzerinde ${j}0ms surdu" ;;
        3) lvl=ERROR; msg="ust sunucu baglantiyi reddetti $j" ;;
    esac
    printf '2026-10-10T08:%02d:%02d|%s|%s\n' "$((j % 60))" "$(((j * 7) % 60))" "$lvl" "$msg" >> "$APP"
done

# Kriter 1: loglar root:root ve 600 — student okuyamasın.
chown root:root "$ACCESS" "$APP"
chmod 0600 "$ACCESS" "$APP"

# settings.conf: etkin debug=true, 3 etkin old-server.local satırı, yorumlarda
# old-server.local ve #debug = true (negatif test yemi — değişmemeli).
cat > "$SETTINGS" <<'EOF'
# Vardiya web uygulamasi yapilandirmasi
# NOT: old-server.local emekliye ayrildi, burada sadece tarihce icin duruyor
#debug = true
debug = true
primary_host = old-server.local
backup_host = old-server.local
db_host = old-server.local
worker_count = 4
# fallback_host = old-server.local
log_level = info
EOF
cp -a "$SETTINGS" "$GOLDEN/settings.conf"   # check.sh'in kıyaslayacağı altın kopya
chmod 0600 "$GOLDEN/settings.conf"

# hosts.list: boş satırlar, # yorumları, gerçek hostlar; bir satırda # var ama
# satır başında değil → o satır silinmemeli.
cat > "$HOSTS" <<'EOF'
# uretim web sunuculari
web01.local
web02.local

# veritabani
db01.local  # birincil db
app01.local


# liste sonu
EOF

chown -R root:root "$PROJE/etc"
chmod 0644 "$SETTINGS" "$HOSTS"

# =============================================================================
# TICKET 5 — Başıboş süreçler (kaynak: lab 005, processes)
# =============================================================================
mkdir -p "$PROCDIR"

# hog: CPU'yu boşuna meşgul eden takılmış süreç. Sinyal yakalamaz → TERM öldürür.
cat > "$PROCDIR/hog.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = LABPROC isareti (komut satirinda gorunmesi icin)
while :; do
    i=0
    while [ "$i" -lt 40000 ]; do i=$((i + 1)); done
    sleep 0.2
done
EOF

# rogue: TERM'i trap ile YOK SAYAR. Kibar sinyal yetmez, KILL şart.
cat > "$PROCDIR/rogue.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = LABPROC isareti. TERM yok sayilir; sadece KILL bu sureci bitirir.
trap '' TERM
trap '' INT
trap '' HUP
while :; do
    sleep 5
done
EOF

# batch: gece batch işi. Çok düşük nice ile başlar, öldürülmemeli.
cat > "$PROCDIR/batch.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = LABPROC isareti
while :; do
    sleep 5
done
EOF

# noise: LABPROC işareti YOK. İsmi batch'e benziyor → yanlış hedef tuzağı.
cat > "$PROCDIR/noise.sh" <<'EOF'
#!/usr/bin/env bash
while :; do
    sleep 7
done
EOF

chmod 0755 "$PROCDIR"/*.sh
chown root:root "$PROCDIR"/*.sh

# setsid → yeni oturum, denetim terminali yok → setup bitince SIGHUP gelmez.
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup nice -n 19 bash $PROCDIR/hog.sh LABPROC-hog >/dev/null 2>&1 </dev/null &"

# rogue: exec -a ile sahte bir çekirdek-thread ismi takar; işaret argümanda kalır.
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash -c 'exec -a kworker/u8:3-events bash $PROCDIR/rogue.sh LABPROC-rogue' >/dev/null 2>&1 </dev/null &"

# batch: nice -n -15 root tarafından uygulanır, yetki student'a düşer. Nice
# değeri fork/exec üzerinden miras kalır → süreç student'a ait ve nice -15.
nice -n -15 su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash $PROCDIR/batch.sh LABPROC-batch >/dev/null 2>&1 </dev/null &"

# gürültü: LABPROC içermeyen sahte süreçler (yanlış süreci öldürme tuzağı).
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash $PROCDIR/noise.sh nightly-batch-runner >/dev/null 2>&1 </dev/null &"
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup sleep 4242 >/dev/null 2>&1 </dev/null &"
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup sleep 4243 >/dev/null 2>&1 </dev/null &"

# =============================================================================
# TICKET 6 — Gün ortası özet raporu (kaynak: lab 006, shell scripting)
# =============================================================================
# Bu ticket'ın servis işaretleri Ticket 5'in LABPROC-* süreçleriyle teknik
# olarak BAĞLI DEĞİL — ayrı bir set, comm (süreç adı) üzerinden taşınır.
mkdir -p "$LOGDIR" "$LISTDIR"
chown root:root "$LOGDIR" "$LISTDIR"
chmod 0755 "$LOGDIR" "$LISTDIR"

# Sayımlar bilerek FARKLI: INFO 17, WARN 9, ERROR 6, DEBUG 8.
# TUZAK: 5 satırın MESAJ GÖVDESİNDE bir seviye adı geçiyor. Alan-farkındalığı
# olmayan `grep -c ERROR` 6 yerine 9 sayar → kriter düşer.
cat > "$LOGDIR/gunluk.log" <<'EOF'
2026-08-03T03:00:01|INFO|servis vardiya-web basladi
2026-08-03T03:00:03|DEBUG|WARN esigi 90 olarak ayarlandi
2026-08-03T03:00:04|INFO|worker havuzu boyutu 8
2026-08-03T03:00:07|WARN|yanit suresi 200ms uzerinde
2026-08-03T03:00:09|INFO|ust sunucudan ERROR sonrasi yeniden deneniyor
2026-08-03T03:00:12|ERROR|disk neredeyse dolu
2026-08-03T03:00:15|INFO|onbellek isinma tamamlandi
2026-08-03T03:00:18|WARN|cache modulu icin DEBUG gunlugu acildi
2026-08-03T03:00:22|INFO|istek 8812 41ms icinde servis edildi
2026-08-03T03:00:25|DEBUG|handler dispatch icine giriliyor
2026-08-03T03:00:29|WARN|baglanti havuzu yuzde 80
2026-08-03T03:00:31|INFO|gunluk ERROR butcesi 25
2026-08-03T03:00:34|ERROR|ust sunucu 5s sonra zaman asimi
2026-08-03T03:00:36|DEBUG|onbellek anahtari user:4471
2026-08-03T03:00:38|INFO|oturum deposuna baglanildi
2026-08-03T03:00:41|WARN|istek 8813 icin yeniden deneme sayisi 2
2026-08-03T03:00:45|INFO|istek 8813 37ms icinde servis edildi
2026-08-03T03:00:49|ERROR|INFO kanali birikimi asildi
2026-08-03T03:00:52|INFO|yapilandirma diskten yeniden yuklendi
2026-08-03T03:00:55|DEBUG|gc duraklamasi 12ms
2026-08-03T03:00:57|WARN|disk kullanimi yuzde 78
2026-08-03T03:01:03|INFO|istek 8814 52ms icinde servis edildi
2026-08-03T03:01:07|ERROR|oturum 4471 yazilamadi
2026-08-03T03:01:11|INFO|kuyruk derinligi 3
2026-08-03T03:01:14|WARN|events tablosunda 1.4s yavas sorgu
2026-08-03T03:01:19|INFO|istek 8815 44ms icinde servis edildi
2026-08-03T03:01:22|DEBUG|soket tamponu 64k
2026-08-03T03:01:27|INFO|saglik kontrolu gecti
2026-08-03T03:01:30|WARN|onbellek isabetsizlik orani 0.42
2026-08-03T03:01:35|INFO|istek 8816 39ms icinde servis edildi
2026-08-03T03:01:38|DEBUG|ERROR handler kaydedildi
2026-08-03T03:01:40|ERROR|vardiya-queue yanit vermiyor
2026-08-03T03:01:44|INFO|metrikler bosaltildi
2026-08-03T03:01:47|WARN|worker yeniden baslatma talebi
2026-08-03T03:01:52|INFO|istek 8817 48ms icinde servis edildi
2026-08-03T03:01:55|DEBUG|thread 7 bosta
2026-08-03T03:02:01|INFO|gecelik rotasyon planlandi
2026-08-03T03:02:05|WARN|saat kaymasi 40ms
2026-08-03T03:02:09|ERROR|rapor uretimi iptal edildi
2026-08-03T03:02:12|DEBUG|bosaltma araligi 30s
EOF
chown root:root "$LOGDIR/gunluk.log"
chmod 0644 "$LOGDIR/gunluk.log"

# Okunamayan log: `[ -f ]` ile `[ -r ]` farkını zorlayan TEK nokta. Silme.
cat > "$LOGDIR/gizli.log" <<'EOF'
2026-08-03T02:59:00|INFO|denetim kanali acildi
2026-08-03T02:59:30|WARN|konsoldan root girisi
EOF
chown root:root "$LOGDIR/gizli.log"
chmod 0600 "$LOGDIR/gizli.log"

# Bozuk logsum. Kusurları (her biri ayrı kriter kırar): shebang yok ·
# çalıştırma izni yok · $1 yok sayılıyor · varsayılan alan ayırıcısı · çıktı
# biçimi SEVIYE:sayı değil · hata mesajı stdout'a gidiyor · kontrol iş bittikten
# SONRA yapılıyor · -r kontrolü hiç yok · her yolda exit 0.
cat > "$BINDIR/logsum" <<'EOF'
# gun ortasi raporu icin log ozeti - devam edilecek
LOG=/var/log/vardiya/gunluk.log
awk '{print $2}' $LOG | sort | uniq -c
if [ ! -f "$LOG" ]; then
  echo "logsum: dosya yok"
fi
exit 0
EOF
chown root:root "$BINDIR/logsum"
chmod 0666 "$BINDIR/logsum"

# Servis süreçleri. vardiya-queue BİLEREK yok: listede var, süreci yok →
# [FAIL] → DEGRADED. Gerçek `sleep` binary'si servis adıyla kopyalanır →
# comm = servis adı, sade `pgrep vardiya-web` bulur. comm 15 karaktere kırpılır;
# en uzun ad vardiya-worker (14) — sığıyor.
install -d -m 755 "$SVCDIR"
for svc in $SERVICES; do
    cp -f /usr/bin/sleep "$SVCDIR/$svc"
    chown root:root "$SVCDIR/$svc"
    chmod 0755 "$SVCDIR/$svc"
done
for svc in $SERVICES; do
    su "$STUDENT" -s /bin/bash -c \
      "setsid nohup $SVCDIR/$svc infinity >/dev/null 2>&1 </dev/null &"
done

# Servis listesi. Boş satır, yorum satırı ve yorumlanmış servis-benzeri satır
# bilerek var. vardiya-legacy süreci YOK; yorum atlanmazsa fazladan [FAIL].
cat > "$LISTDIR/servisler.list" <<'EOF'
# gun ortasi raporunda izlenen servisler
vardiya-web
vardiya-worker

vardiya-queue
#vardiya-legacy
vardiya-cache
EOF
chown root:root "$LISTDIR/servisler.list"
chmod 0644 "$LISTDIR/servisler.list"

sleep 1

# =============================================================================
# Kurulum doğrulaması
# =============================================================================
for mark in LABPROC-hog LABPROC-rogue LABPROC-batch; do
    if ! pgrep -f "$mark" >/dev/null 2>&1; then
        echo "setup HATA: $mark sureci baslatilamadi" >&2
        exit 1
    fi
done
for svc in $SERVICES; do
    if ! pgrep -x "$svc" >/dev/null 2>&1; then
        echo "setup HATA: $svc sureci baslatilamadi (comm eslesmesi yok)" >&2
        exit 1
    fi
done
if pgrep -x vardiya-queue >/dev/null 2>&1; then
    echo "setup HATA: vardiya-queue calisiyor — calismamaliydi" >&2
    exit 1
fi
N="$(ps -eo comm | grep -c '^vardiya-' || true)"
if [ "$N" -ne 3 ]; then
    echo "setup HATA: comm alaninda 3 vardiya-* sureci bekleniyordu, $N bulundu" >&2
    exit 1
fi

echo "setup done"
