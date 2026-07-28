#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Lab 007a'nın bozuk durumunu kurar. Idempotent.
#
# Tasarım notu: veri dosyaları SABİT içeriktir (heredoc), rastgele üretilmez.
# Sebep: check.sh beklenen değerleri veriden türetiyor, ama negatif kontroller
# (grep open kaç satır fazla verir, kaç tuzak satır var) ancak içerik
# deterministikse tekrarlanabilir olur.
#
# Sıfır bedava OK: stajyerin beş yanlış cevabı önceden yazılır, notlar.txt
# düzenlenmemiş bırakılır. Tek istisna "veri dosyaları değişmedi" kriteridir;
# o bir korkuluk, taze ortamda doğal olarak sağlanır.
set -euo pipefail

DATA=/srv/data
ORIG=/srv/.orig
ANS=/home/student/cevaplar

# --- 0. Temizlik (idempotens) ---------------------------------------------
rm -rf "$DATA" "$ORIG" "$ANS"

# --- 1. Veri dizini -------------------------------------------------------
# Dizin student'a yazılabilir: vim writebackup dosyayı yazmadan önce aynı
# dizinde yedek açar, dizin yazılamazsa `:w` E509 ile ölür. Bu sürtünme
# hiçbir şey öğretmiyor. Veri dosyalarının kendisi 0444 kalıyor.
mkdir -p "$DATA"
chown root:student "$DATA"
chmod 0775 "$DATA"

# --- 2. tickets.csv -------------------------------------------------------
# 60 veri satırı. durum: open=19 pending=12 closed=29 (adetler farklı).
# oncelik: low=12 normal=24 high=16 urgent=8 (adetler farklı).
# TUZAK: beş KAPALI biletin konu alanında "open" geçiyor (T1006, T1010,
# T1017, T1025, T1037). Satır-temelli `grep open` 24 satır verir, doğru
# cevap 19'dur. Alanlarda `;` yok.
cat > "$DATA/tickets.csv" <<'EOF'
id;tarih;oncelik;durum;atanan;konu
T1001;2026-07-01;low;open;ayse;printer driver missing
T1002;2026-07-01;normal;closed;mehmet;password reset done
T1003;2026-07-02;high;open;ayse;database connection timeout
T1004;2026-07-02;urgent;open;kerem;payment gateway down
T1005;2026-07-02;normal;pending;selin;vpn certificate renewal
T1006;2026-07-03;normal;closed;mehmet;cannot open config file
T1007;2026-07-03;low;closed;ayse;monitor cable replaced
T1008;2026-07-03;high;pending;kerem;backup job fails at midnight
T1009;2026-07-04;normal;open;selin;email quota exceeded
T1010;2026-07-04;high;closed;mehmet;port 8080 still open after restart
T1011;2026-07-05;low;closed;selin;keyboard layout wrong
T1012;2026-07-05;urgent;open;kerem;cluster node unreachable
T1013;2026-07-06;normal;closed;ayse;software license expired
T1014;2026-07-06;high;open;mehmet;slow disk io on node three
T1015;2026-07-07;normal;pending;selin;new laptop request
T1016;2026-07-07;low;open;ayse;screen resolution issue
T1017;2026-07-08;high;closed;kerem;firewall rule opened for port 443
T1018;2026-07-08;normal;closed;mehmet;dns record updated
T1019;2026-07-09;urgent;pending;kerem;storage array degraded
T1020;2026-07-09;normal;open;selin;shared folder access denied
T1021;2026-07-10;low;closed;ayse;mouse not working
T1022;2026-07-10;high;open;mehmet;ssl handshake failure
T1023;2026-07-11;normal;closed;selin;printer queue cleared
T1024;2026-07-11;normal;pending;ayse;phone extension change
T1025;2026-07-12;high;closed;kerem;ticket left open by mistake
T1026;2026-07-12;low;open;mehmet;desktop wallpaper policy
T1027;2026-07-13;urgent;closed;selin;data center power event
T1028;2026-07-13;normal;closed;ayse;account unlocked
T1029;2026-07-14;high;pending;kerem;patch window approval
T1030;2026-07-14;normal;open;mehmet;ldap group sync missing
T1031;2026-07-15;low;closed;selin;usb port dust cleaning
T1032;2026-07-15;high;closed;ayse;memory leak in agent
T1033;2026-07-16;normal;pending;kerem;mailbox migration schedule
T1034;2026-07-16;urgent;open;selin;website returns five hundred
T1035;2026-07-17;normal;closed;mehmet;wifi password rotated
T1036;2026-07-17;low;open;ayse;font rendering blurry
T1037;2026-07-18;high;closed;kerem;session left open on kiosk
T1038;2026-07-18;normal;closed;selin;antivirus definition update
T1039;2026-07-19;normal;pending;mehmet;training account setup
T1040;2026-07-19;high;open;ayse;api rate limit reached
T1041;2026-07-20;low;closed;kerem;chair replacement request
T1042;2026-07-20;urgent;closed;selin;ransomware alert false positive
T1043;2026-07-21;normal;open;mehmet;calendar sync broken
T1044;2026-07-21;high;closed;ayse;log rotation not running
T1045;2026-07-22;normal;pending;kerem;guest wifi voucher
T1046;2026-07-22;low;open;selin;taskbar icons missing
T1047;2026-07-23;high;closed;mehmet;certificate chain incomplete
T1048;2026-07-23;normal;closed;ayse;group policy applied
T1049;2026-07-24;urgent;pending;kerem;primary link flapping
T1050;2026-07-24;normal;open;selin;file share quota warning
T1051;2026-07-25;low;closed;mehmet;docking station firmware
T1052;2026-07-25;high;closed;ayse;cron job duplicated
T1053;2026-07-26;normal;pending;kerem;onboarding checklist
T1054;2026-07-26;urgent;closed;selin;database replica lag
T1055;2026-07-27;normal;closed;mehmet;time sync drift fixed
T1056;2026-07-27;high;open;ayse;queue worker stuck
T1057;2026-07-27;normal;closed;kerem;disk cleanup completed
T1058;2026-07-28;low;pending;selin;headset request
T1059;2026-07-28;normal;closed;mehmet;browser cache issue
T1060;2026-07-28;high;open;ayse;nightly report missing
EOF
chown root:root "$DATA/tickets.csv"
chmod 0444 "$DATA/tickets.csv"

# --- 3. access.log -------------------------------------------------------
# 80 satır. DENIED üç kez geçiyor → görev 4'ün ilk aramasi 0 döner.
cat > "$DATA/access.log" <<'EOF'
2026-07-27 08:01:12 10.0.0.11 GET /index.html 200 1240
2026-07-27 08:01:44 10.0.0.11 GET /style.css 200 3180
2026-07-27 08:02:03 10.0.0.24 GET /index.html 200 1240
2026-07-27 08:02:31 10.0.0.24 GET /logo.png 200 8820
2026-07-27 08:03:09 10.0.0.37 GET /api/status 200 96
2026-07-27 08:03:55 10.0.0.11 POST /api/login 200 312
2026-07-27 08:04:20 10.0.0.52 GET /index.html 200 1240
2026-07-27 08:05:01 10.0.0.52 GET /missing.html 404 512
2026-07-27 08:05:47 10.0.0.37 GET /api/status 200 96
2026-07-27 08:06:12 10.0.0.63 GET /admin ACCESS DENIED
2026-07-27 08:06:40 10.0.0.24 GET /report.pdf 200 44100
2026-07-27 08:07:15 10.0.0.11 GET /api/items 200 2044
2026-07-27 08:08:02 10.0.0.75 GET /index.html 200 1240
2026-07-27 08:08:33 10.0.0.75 GET /style.css 200 3180
2026-07-27 08:09:10 10.0.0.37 GET /api/status 200 96
2026-07-27 08:09:58 10.0.0.52 POST /api/items 201 128
2026-07-27 08:10:26 10.0.0.63 GET /index.html 200 1240
2026-07-27 08:11:04 10.0.0.24 GET /api/items 200 2044
2026-07-27 08:11:49 10.0.0.11 GET /help.html 200 1710
2026-07-27 08:12:22 10.0.0.88 GET /index.html 200 1240
2026-07-27 08:13:07 10.0.0.88 GET /api/status 500 64
2026-07-27 08:13:41 10.0.0.37 GET /api/status 200 96
2026-07-27 08:14:19 10.0.0.52 GET /logo.png 200 8820
2026-07-27 08:15:02 10.0.0.75 POST /api/login 401 88
2026-07-27 08:15:36 10.0.0.75 POST /api/login 200 312
2026-07-27 08:16:11 10.0.0.24 GET /help.html 200 1710
2026-07-27 08:16:55 10.0.0.11 GET /api/items 200 2044
2026-07-27 08:17:30 10.0.0.63 GET /report.pdf 200 44100
2026-07-27 08:18:08 10.0.0.37 GET /api/status 200 96
2026-07-27 08:18:44 10.0.0.99 GET /index.html 200 1240
2026-07-27 08:19:21 10.0.0.99 GET /style.css 200 3180
2026-07-27 08:20:03 10.0.0.52 GET /missing.html 404 512
2026-07-27 08:20:47 10.0.0.88 GET /api/items 200 2044
2026-07-27 08:21:12 10.0.0.11 GET /index.html 200 1240
2026-07-27 08:21:59 10.0.0.24 GET /api/status 200 96
2026-07-27 08:22:35 10.0.0.75 GET /help.html 200 1710
2026-07-27 08:23:14 10.0.0.14 GET /etc/passwd ACCESS DENIED
2026-07-27 08:23:50 10.0.0.37 GET /api/status 200 96
2026-07-27 08:24:26 10.0.0.63 POST /api/items 201 128
2026-07-27 08:25:09 10.0.0.99 GET /logo.png 200 8820
2026-07-27 08:25:44 10.0.0.52 GET /index.html 200 1240
2026-07-27 08:26:20 10.0.0.11 GET /report.pdf 200 44100
2026-07-27 08:27:03 10.0.0.88 GET /style.css 200 3180
2026-07-27 08:27:41 10.0.0.24 GET /api/items 200 2044
2026-07-27 08:28:18 10.0.0.37 GET /api/status 200 96
2026-07-27 08:28:52 10.0.0.75 GET /index.html 200 1240
2026-07-27 08:29:30 10.0.0.14 GET /help.html 200 1710
2026-07-27 08:30:11 10.0.0.63 GET /api/items 500 64
2026-07-27 08:30:48 10.0.0.99 POST /api/login 200 312
2026-07-27 08:31:25 10.0.0.52 GET /style.css 200 3180
2026-07-27 08:32:02 10.0.0.11 GET /api/status 200 96
2026-07-27 08:32:39 10.0.0.88 GET /missing.html 404 512
2026-07-27 08:33:16 10.0.0.24 GET /index.html 200 1240
2026-07-27 08:33:54 10.0.0.37 GET /api/status 200 96
2026-07-27 08:34:31 10.0.0.75 GET /report.pdf 200 44100
2026-07-27 08:35:08 10.0.0.14 GET /api/items 200 2044
2026-07-27 08:35:45 10.0.0.63 GET /style.css 200 3180
2026-07-27 08:36:22 10.0.0.99 GET /index.html 200 1240
2026-07-27 08:36:59 10.0.0.52 GET /help.html 200 1710
2026-07-27 08:37:36 10.0.0.11 GET /logo.png 200 8820
2026-07-27 08:38:13 10.0.0.88 GET /api/items 200 2044
2026-07-27 08:38:50 10.0.0.24 POST /api/items 201 128
2026-07-27 08:39:27 10.0.0.37 GET /api/status 200 96
2026-07-27 08:40:04 10.0.0.31 GET /admin/config ACCESS DENIED
2026-07-27 08:40:41 10.0.0.75 GET /index.html 200 1240
2026-07-27 08:41:18 10.0.0.14 GET /style.css 200 3180
2026-07-27 08:41:55 10.0.0.63 GET /api/status 200 96
2026-07-27 08:42:32 10.0.0.99 GET /report.pdf 200 44100
2026-07-27 08:43:09 10.0.0.52 GET /api/items 200 2044
2026-07-27 08:43:46 10.0.0.11 GET /index.html 200 1240
2026-07-27 08:44:23 10.0.0.88 GET /help.html 200 1710
2026-07-27 08:45:00 10.0.0.24 GET /logo.png 200 8820
2026-07-27 08:45:37 10.0.0.37 GET /api/status 200 96
2026-07-27 08:46:14 10.0.0.75 GET /missing.html 404 512
2026-07-27 08:46:51 10.0.0.14 GET /api/items 200 2044
2026-07-27 08:47:28 10.0.0.63 GET /index.html 200 1240
2026-07-27 08:48:05 10.0.0.99 GET /style.css 200 3180
2026-07-27 08:48:42 10.0.0.52 POST /api/login 200 312
2026-07-27 08:49:19 10.0.0.11 GET /api/status 200 96
2026-07-27 08:49:56 10.0.0.88 GET /index.html 200 1240
EOF
chown root:root "$DATA/access.log"
chmod 0444 "$DATA/access.log"

# --- 4. notlar.txt -------------------------------------------------------
# 25 satır. Satır başında TODO: 5 satır (silinecek). Satır ORTASINDA TODO:
# 1 satır (kalacak — `^` çapasının sınandığı yer). sunucu1: 4 satırda,
# toplam 5 geçiş (bir satırda iki kez → `:%s/.../.../g` yoksa biri kaçar).
cat > "$DATA/notlar.txt" <<'EOF'
Bakim notlari - hafta 30
Bu dosya elle tutuluyor, sonunda wiki'ye tasinacak.

TODO yedekleme cizelgesini gozden gecir
sunucu1 uzerinde disk kullanimi yuzde 82
Log rotasyonu her gece saat 03:00 civarinda calisiyor.
TODO monitoring alarm esiklerini dusur
Guvenlik duvari kurallari 2026-06 revizyonunda guncellendi.
sunucu1 ile sunucu1 arasindaki yedek link test edilmedi
Sertifika yenileme tarihi: 2026-09-14
TODO eski kullanici hesaplarini temizle
Not: asagidaki maddeler TODO listesinden cikarildi, silmeyin
Yedek diskler kasa icinde etiketli duruyor.
sunucu1 icin bakim penceresi cumartesi gecesi
NTP sunucusu ic aga tasindi.
TODO dokumantasyon linklerini duzelt
Yazici kuyrugu haftada bir temizleniyor.
Kullanici egitimi eylulde planlandi.
sunucu1 yedek konfigurasyonu /etc/backup altinda
Parola politikasi 12 karaktere cikarildi.
TODO ag semasini yeniden ciz
Kapasite raporu her ayin ilki gonderiliyor.
Eski kayitlar arsiv diskine tasindi.
Toplanti notlari ortak surucude.
Bu dosyanin sahibi operasyon ekibi.
EOF
chown student:student "$DATA/notlar.txt"
chmod 0644 "$DATA/notlar.txt"

# --- 5. Cevap dizini -----------------------------------------------------
mkdir -p "$ANS"
chown student:student "$ANS"
chmod 0755 "$ANS"

# --- 6. Stajyerin yanlis cevaplari (sifir bedava OK) ---------------------
# Beş dosya da VAR ama hepsi yanlış, hataların türü farklı:
#   01 → `wc -l DOSYA` çıktısı: başlık de sayılmış (61) ve dosya adı da
#        yazılmış, yani "yalnız sayı" biçim kriteri de düşer
#   02 → satır-temelli `grep open` çıktısı (5 tuzak satır fazla)
#   03 → bir öncelik (urgent) eksik, bir sayı (normal) yanlış
#   04 → 1 olmalıydı 0, 05 → 0 olmalıydı 1 (ikisi ters yazılmış)
wc -l "$DATA/tickets.csv" > "$ANS/01-adet.txt"
grep open "$DATA/tickets.csv" > "$ANS/02-acik.txt"
cat > "$ANS/03-oncelik.txt" <<'EOF'
12 low
23 normal
16 high
EOF
echo '1' > "$ANS/04-kod.txt"
echo '0' > "$ANS/05-kod.txt"
chown student:student "$ANS"/0*.txt
chmod 0644 "$ANS"/0*.txt

# --- 7. Orijinal kopyalar (check referansi) ------------------------------
# check.sh beklenen değerleri buradan türetir: notlar.txt'nin düzenlenmiş
# hâli bu kopyadan hesaplanır, "değişmedi" korkuluğu buna cmp'lenir.
# 0700/0400 root: student okuyamaz, kopyalayıp cevap üretemez.
mkdir -p "$ORIG"
cp "$DATA/tickets.csv" "$DATA/access.log" "$DATA/notlar.txt" "$ORIG/"
chown -R root:root "$ORIG"
chmod 0700 "$ORIG"
chmod 0400 "$ORIG"/*

# --- 8. Kendi kendini dogrulama ------------------------------------------
err=0

for f in "$DATA/tickets.csv" "$DATA/access.log" "$DATA/notlar.txt" \
         "$ANS/01-adet.txt" "$ANS/02-acik.txt" "$ANS/03-oncelik.txt" \
         "$ANS/04-kod.txt" "$ANS/05-kod.txt" \
         "$ORIG/tickets.csv" "$ORIG/access.log" "$ORIG/notlar.txt"; do
    [ -f "$f" ] || { echo "setup HATA: $f yok" >&2; err=1; }
done

# Tuzak gerçekten çalışıyor mu: grep open, alan-temelli cevaptan fazla
# satır vermeli. Vermezse lab kendi dersini öğretmiyor.
g=$(grep -c open "$DATA/tickets.csv")
a=$(awk -F';' '$4 == "open"' "$DATA/tickets.csv" | wc -l)
[ "$g" -gt "$a" ] || { echo "setup HATA: tuzak etkisiz ($g vs $a)" >&2; err=1; }

# DENIED geçmezse görev 4'ün ilk aramasi 1 döner ve kriter imkânsızlaşır.
grep -q DENIED "$DATA/access.log" ||
    { echo "setup HATA: access.log icinde DENIED yok" >&2; err=1; }

# `^TODO` ve satır ortasındaki TODO ayrı ayrı var olmalı.
[ "$(grep -c '^TODO' "$DATA/notlar.txt")" -ge 4 ] ||
    { echo "setup HATA: yeterli ^TODO satiri yok" >&2; err=1; }
grep -q 'TODO' <(grep -v '^TODO' "$DATA/notlar.txt") ||
    { echo "setup HATA: satir ortasinda TODO gecen satir yok" >&2; err=1; }

# sunucu1 en az bir satırda iki kez geçmeli (eksik `g` bayrağını yakalar).
[ "$(grep -o 'sunucu1' "$DATA/notlar.txt" | wc -l)" -gt \
  "$(grep -c 'sunucu1' "$DATA/notlar.txt")" ] ||
    { echo "setup HATA: satir ici cok gecisli sunucu1 satiri yok" >&2; err=1; }

[ "$err" -eq 0 ] || exit 1
echo "setup done: 007a-text-filters"
