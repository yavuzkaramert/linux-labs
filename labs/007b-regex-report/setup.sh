#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Lab 007b'nin bozuk durumunu kurar. Idempotent.
#
# 007b, 007a'nın çözülmüş olduğunu varsayar: alan-temelli süzme ve çıkış
# kodu kavramı yerleşmiş kabul edilir. Burada eklenen şey regex derinliği
# (çapa, tekrar, yakalama grubu), awk ilişkisel dizisi ve 006'nın script +
# exit code sözleşmesinin tekrarı.
#
# Sıfır bedava OK: /srv/work altına ÖNCEKİ GECENİN yarım kalmış koşusundan
# eski ve yanlış normal.log + valid.log bırakılır; invalid.log ve ozet.txt
# hiç yoktur. Böylece "dosya var" ile "dosya doğru" ayrımı da sınanır.
# Tek istisna "merged.log değişmedi" korkuluğudur, taze ortamda doğal
# olarak sağlanır.
set -euo pipefail

RAW=/srv/raw
WORK=/srv/work
REPORTS=/srv/reports
CONF=/etc/labs
ORIG=/srv/.orig

# --- 0. Temizlik (idempotens) ---------------------------------------------
rm -rf "$RAW" "$WORK" "$REPORTS" "$CONF" "$ORIG"
rm -f /usr/local/bin/mkreport

# --- 1. Kaynak dizin ------------------------------------------------------
mkdir -p "$RAW"
chown root:root "$RAW"
chmod 0755 "$RAW"

# --- 2. merged.log --------------------------------------------------------
# 70 satır. Tarihlerin yarısı GG/AA/YYYY, yarısı YYYY-AA-GG. Dört satırda
# ayırıcı çevresinde 1-3 boşluk. 12 satır geçersiz, türleri karışık.
#
# TUZAKLAR:
#  A) İki satır (56, 61) geçerli görünen bir kaydın ÖNÜNE serbest metin
#     taşıyor. `^` çapası olmayan regex bunları geçerli sayar.
#  B) İki satır (19, 64) beş alanlı; ilk dört alanı kusursuz. Mesaj alanı
#     `.+$` ile yazılırsa (yani `|` de kabul edilirse) geçerli sayılır.
#     Doğrusu `[^|]+$` — TASK "tam olarak dört alan" diyor.
#  C) Üç GEÇERLİ satırın (16, 17, 35) mesaj alanında bir seviye adı VE bir
#     IP geçiyor. Seviyeyi `grep -c ERROR` ile, tekil IP'yi satırın
#     tamamından toplayan çözüm yanlış sayar. Alan farkındalığı şart.
#
# Geçersiz IP'ler bilinçli olarak 4 HANELİ oktet (10.0.0.9999) ve EKSİK
# oktet (10.0.5) olarak seçildi. TASK "dört sayı" diyor, oktetin 0-255
# aralığında olmasını istemiyor; 10.0.0.999 geçerli sayılırdı.
cat > "$RAW/merged.log" <<'EOF'
01/07/2026|INFO|10.0.0.11|service started
2026-07-01|INFO | 10.0.0.11 |config loaded from disk
01/07/2026|WARN|10.0.1.21|cache miss ratio high
2026-07-02|ERROR|10.0.2.31|database connection refused
02/07/2026|INFO|10.0.0.12|health probe ok
2026-07-02|INFO|10.0.0.13|scheduler tick
02/07/2026 | WARN | 10.0.1.22 | queue depth above limit
2026-07-03|ERROR|10.0.2.32|write timeout on volume one
03/07/2026|INFO|10.0.0.11|session opened
2026-07-03|INFO|10.0.0.14|metrics flushed
2026-07-05|INFO|10.0.1.4
05/07/2026|WARN|10.0.1.23|certificate expires in ten days
2026-07-05|ERROR|10.0.2.33|replica lag exceeded threshold
05/07/2026|INFO|10.0.0.15|backup snapshot created
2026-07-06|INFO|10.0.0.12|index rebuild finished
06/07/2026|WARN|10.0.1.21|retry to 10.9.9.9 after ERROR
2026-07-06|ERROR|10.0.2.31|peer 10.0.1.24 returned WARN twice
07/07/2026|INFO|10.0.0.16|log rotation done
2026-07-08|ERROR|10.0.1.9|disk pressure on node two|extra-column
08/07/2026|INFO|10.0.0.13|worker pool resized
2026-07-08|WARN|10.0.1.24|memory usage at eighty percent
08/07/2026 | ERROR |10.0.2.32| checkpoint failed
2026-07-09|INFO|10.0.0.11|heartbeat received
09/07/2026|INFO|10.0.0.17|feature flag toggled
2026-07-10|TRACE|10.0.2.3|verbose call stack dumped
10/07/2026|WARN|10.0.1.25|slow query detected
2026-07-10|ERROR|10.0.2.34|gateway returned five hundred
10/07/2026|INFO|10.0.0.14|cron job registered
2026-07-11|INFO|10.0.0.18|template cache warmed
11/07/2026|WARN|10.0.1.22|clock drift detected
2026-07-12|error|10.0.2.8|connection reset by peer
12/07/2026|INFO|10.0.0.12|user preferences saved
2026-07-12|ERROR|10.0.2.33|lock contention on table two
12/07/2026 | INFO | 10.0.0.19 | mail queue drained
2026-07-13|INFO|10.0.0.13|failover from 10.9.9.8 logged as ERROR
13/07/2026|WARN|10.0.1.26|thread pool saturated
2026-07-14|WARN|10.0.0.9999|nic error counter rising
14/07/2026|INFO|10.0.0.15|archive uploaded
2026-07-15|INFO|10.0.5|heartbeat received
15/07/2026|ERROR|10.0.2.35|tls handshake failed
2026-07-15|INFO|10.0.0.11|static assets purged
15/07/2026|WARN|10.0.1.23|retry budget exhausted
2026-07-16|INFO|10.0.0.16|schema migration applied
16/07/2026|ERROR|10.0.2.31|primary node unreachable
2026-07-17|WARN|10.0.3.2|
17/07/2026|INFO|10.0.0.17|audit trail exported
2026-07-17|WARN|10.0.1.27|deprecated endpoint called
sistem gunlugu burada kesildi ve yeniden acildi
18/07/2026|INFO|10.0.0.14|token refreshed
2026-07-18|ERROR|10.0.2.32|checksum mismatch on transfer
18/07/2026|WARN|10.0.1.21|api rate limit approaching
2026-07-19|INFO|10.0.0.18|dashboard widget loaded
bu satir tasima sirasinda bozuldu
19/07/2026|ERROR|10.0.2.34|payment webhook rejected
2026-07-19|INFO|10.0.0.15|search index committed
parse hatasi: 2026-07-20|ERROR|10.0.3.7|disk full
20/07/2026|WARN|10.0.1.25|retry queue growing
2026-07-20|INFO|10.0.0.19|report generated
20/07/2026|ERROR|10.0.2.33|smtp relay refused connection
2026-07-21|INFO|10.0.0.12|cache invalidated
orphan kayit -> 2026-07-22|WARN|10.0.4.1|latency spike
22/07/2026|WARN|10.0.1.24|thread starvation warning
2026-07-22|INFO|10.0.0.13|feature rollout completed
2026-07-24|INFO|10.0.4.6|backup finished|0
24/07/2026|ERROR|10.0.2.35|disk quota exceeded
2026-07-25|WARN|10.0.1.26|backlog above limit
25/07/2026|INFO|10.0.0.11|nightly job queued
2026-07-26|WARN|10.0.1.27|ssl cipher deprecated
26/07/2026|INFO|10.0.0.16|cleanup finished
2026-07-27|ERROR|10.0.2.34|final flush failed
EOF
chown root:root "$RAW/merged.log"
chmod 0444 "$RAW/merged.log"

# --- 3. report.conf ------------------------------------------------------
# 20 satır. Satır başında `#`: 6 satır (silinecek). Satır ORTASINDA `#`:
# 1 satır (kalacak — çapasız kalıbın yakalandığı yer). /opt/eski: 4 satırda,
# toplam 5 geçiş (bir satırda iki kez → eksik `g` bayrağı buradan çıkar).
#
# Dizin student'a yazılabilir: vim writebackup aynı dizinde yedek açar,
# dizin yazılamazsa `:w` E509 ile ölür. Dosyanın sahibi root, grubu student.
mkdir -p "$CONF"
chown root:student "$CONF"
chmod 0775 "$CONF"

cat > "$CONF/report.conf" <<'EOF'
# report.conf - gece raporu ayarlari
# bu dosya elle duzenlenir
source_dir = /opt/eski/raw
work_dir = /opt/eski/work
# asagidaki iki yol ayni diske bakiyor
archive_dir = /opt/eski/archive
retention = 90
# eski deger 30 idi, gecici olarak yukseltildi
compress = yes
mail_to = ops@example.com
subject_prefix = nightly # rapor konusu bu onekle baslar
log_level = info
tmp_dir = /opt/eski/tmp ve yedegi /opt/eski/tmp2
max_size_mb = 512
# tarih bicimi degistirilmemeli
date_format = %Y-%m-%d
lock_file = /var/run/report.lock
# son duzenleme 2026-07-19
notify_on_empty = no
timeout_sec = 120
EOF
chown root:student "$CONF/report.conf"
chmod 0664 "$CONF/report.conf"

# --- 4. Calisma ve rapor dizinleri --------------------------------------
mkdir -p "$WORK" "$REPORTS"
chown student:student "$WORK" "$REPORTS"
chmod 0755 "$WORK" "$REPORTS"

# --- 5. Onceki gecenin yarim kalmis kosusu (sifir bedava OK) ------------
# normal.log: yalnız ilk 20 satır, tarihler ÇEVRİLMEMİŞ, boşluklar duruyor.
# valid.log: o yarım dosya üzerinde ÇAPASIZ regex ile üretilmiş.
# invalid.log ve ozet.txt hiç yok.
head -20 "$RAW/merged.log" > "$WORK/normal.log"
grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}\|(INFO|WARN|ERROR)\|' "$WORK/normal.log" \
    > "$WORK/valid.log" || true
chown student:student "$WORK/normal.log" "$WORK/valid.log"
chmod 0644 "$WORK/normal.log" "$WORK/valid.log"

# --- 6. Orijinal kopyalar (check referansi) -----------------------------
# 0700/0400 root: student okuyamaz, kopyalayıp cevap üretemez.
mkdir -p "$ORIG"
cp "$RAW/merged.log" "$ORIG/merged.log"
cp "$CONF/report.conf" "$ORIG/report.conf"
chown -R root:root "$ORIG"
chmod 0700 "$ORIG"
chmod 0400 "$ORIG"/*

# --- 7. Kendi kendini dogrulama -----------------------------------------
err=0
say() { echo "setup HATA: $*" >&2; err=1; }

BODY='[0-9]{4}-[0-9]{2}-[0-9]{2}\|(INFO|WARN|ERROR)\|([0-9]{1,3}\.){3}[0-9]{1,3}\|'
REF_ERE="^${BODY}[^|]+\$"    # doğru kalıp: çapalı ve mesajda `|` yok
LOOSE_A="${BODY}[^|]+"       # çapasız    → satır ortasındaki kaydı yakalar
LOOSE_B="^${BODY}.+\$"       # `.+$`      → beş alanlı satırı geçerli sayar

for f in "$RAW/merged.log" "$CONF/report.conf" "$WORK/normal.log" \
         "$WORK/valid.log" "$ORIG/merged.log" "$ORIG/report.conf"; do
    [ -f "$f" ] || say "$f yok"
done
[ ! -e "$WORK/invalid.log" ] || say "invalid.log var olmamali"
[ ! -e "$WORK/ozet.txt" ]    || say "ozet.txt var olmamali"
[ ! -e "$REPORTS/text-report.txt" ] || say "text-report.txt var olmamali"
[ ! -e /usr/local/bin/mkreport ] || say "mkreport var olmamali"

# Normalleştirilmiş referans; aşağıdaki tüm sayımlar bunun üzerinden.
norm="$(mktemp)"
sed -E -e 's#([0-9]{2})/([0-9]{2})/([0-9]{4})#\3-\2-\1#g' \
       -e 's#[[:space:]]*\|[[:space:]]*#|#g' "$RAW/merged.log" > "$norm"

total=$(wc -l < "$norm")
valid=$(grep -Ec "$REF_ERE" "$norm" || true)
invalid=$((total - valid))
[ "$total" -eq 70 ] || say "merged.log $total satir, 70 bekleniyordu"
[ "$invalid" -ge 10 ] || say "gecersiz satir sayisi $invalid, en az 10 olmali"

# Her tuzak gerçekten çalışıyor mu?
# A) `^` olmadan geçersiz satır geçerli sayılmalı.
loose_a=$(grep -Ec "$LOOSE_A" "$norm" || true)
[ "$loose_a" -gt "$valid" ] ||
    say "capasiz regex tuzagi etkisiz ($loose_a vs $valid)"
# B) `[^|]+$` yerine `.+$` yazılınca beş alanlı satırlar geçerli sayılmalı.
loose_b=$(grep -Ec "$LOOSE_B" "$norm" || true)
[ "$loose_b" -gt "$valid" ] ||
    say "bes alanli satir tuzagi etkisiz ($loose_b vs $valid)"
# C) Mesaj alanında seviye adı geçen geçerli satır olmalı: satır-temelli
#    `grep -c ERROR`, alan-temelli sayımdan fazla vermeli.
grep -E "$REF_ERE" "$norm" > "$norm.v"
line_err=$(grep -c 'ERROR' "$norm.v" || true)
field_err=$(awk -F'|' '$2 == "ERROR"' "$norm.v" | wc -l)
[ "$line_err" -gt "$field_err" ] ||
    say "mesaj icindeki seviye adi tuzagi etkisiz ($line_err vs $field_err)"
# D) Mesaj alanında IP geçen geçerli satır olmalı: satırdan toplanan tekil
#    IP sayısı, 3. alandan toplanandan fazla olmalı.
line_ip=$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$norm.v" | sort -u | wc -l)
field_ip=$(awk -F'|' '{print $3}' "$norm.v" | sort -u | wc -l)
[ "$line_ip" -gt "$field_ip" ] ||
    say "mesaj icindeki IP tuzagi etkisiz ($line_ip vs $field_ip)"
# E) Seviye başına tekil IP sayıları FARKLI olmalı, yoksa 3. görev anlamsız.
u=$(awk -F'|' '{print $2, $3}' "$norm.v" | sort -u | cut -d' ' -f1 |
    uniq -c | awk '{print $1}' | sort -u | wc -l)
lv=$(awk -F'|' '{print $2}' "$norm.v" | sort -u | wc -l)
[ "$u" -eq "$lv" ] || say "seviye basina tekil IP sayilari farkli degil"

# report.conf tuzakları
[ "$(grep -c '^#' "$CONF/report.conf")" -ge 5 ] || say "yeterli ^# satiri yok"
grep -q '#' <(grep -v '^#' "$CONF/report.conf") ||
    say "satir ortasinda # gecen satir yok"
[ "$(grep -o '/opt/eski' "$CONF/report.conf" | wc -l)" -gt \
  "$(grep -c '/opt/eski' "$CONF/report.conf")" ] ||
    say "satir ici cok gecisli /opt/eski satiri yok"
grep -Eq '^retention[[:space:]]*=[[:space:]]*90$' "$CONF/report.conf" ||
    say "retention = 90 satiri yok"

rm -f "$norm" "$norm.v"

[ "$err" -eq 0 ] || exit 1
echo "setup done: 007b-regex-report"
