#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Lab 900-vardiya-01b'nin bozuk durumunu kurar. Idempotent.
#
# Bu bir TEKRAR labıdır: yedi ticket, yedi kaynak lab (007a-012).
# 01a'nın devamı gibi anlatılır ama KENDİ container'ında sıfırdan kurulur;
# 01a'nın çözülmüş olması gerekmez.
#
# NEDEN container-systemd:
#   Ticket 11 systemd birimleri, Ticket 12 journald/cron/timer/chrony,
#   Ticket 13 ise sshd'nin yeniden başlatılması üzerine kurulu. Bunların
#   hiçbiri "sleep infinity" PID 1 altında öğretilemez. Brief bu labı da
#   düz `container` diye işaretlemişti; teknik olarak mümkün değil.
set -euo pipefail

PROJE=/srv/proje
DESTEK="$PROJE/destek"
GUNLUKLER="$PROJE/gunlukler"
WORK="$PROJE/work"
ORIG=/srv/.orig
ANS=/home/student/cevaplar
BINDIR=/usr/local/bin
STUDENT=student

# --- 0. Temizlik (idempotens) -----------------------------------------------
rm -rf "$PROJE" "$ORIG" "$ANS" /etc/proje /srv/reports \
       /srv/backup-kaynagi /srv/backup /srv/data /srv/paketler \
       /opt/app /opt/raporcu /opt/bekci /opt/paket \
       /var/log/myapp /etc/myapp /var/log/yedek /var/log/temizlik.log
rm -f "$BINDIR/mkreport" "$BINDIR/backup-helper" "$BINDIR/hesapla" \
      /home/"$STUDENT"/uygulama.log /home/"$STUDENT"/myapp.conf \
      /home/"$STUDENT"/backup-helper

mkdir -p "$ANS" /srv/reports
chown "$STUDENT:$STUDENT" "$ANS" /srv/reports
chmod 0755 "$ANS" /srv/reports

# Veri dizini student'a yazılabilir: vim writebackup dosyayı yazmadan önce
# aynı dizinde yedek açar, dizin yazılamazsa `:w` E509 ile ölür.
mkdir -p "$PROJE"
chown root:"$STUDENT" "$PROJE"
chmod 0775 "$PROJE"

# =============================================================================
# TICKET 7 — Destek bileti dökümü (kaynak: lab 007a, text filters)
# =============================================================================
mkdir -p "$DESTEK"
chown root:"$STUDENT" "$DESTEK"
chmod 0775 "$DESTEK"

# biletler.csv — 60 veri satırı. durum: open=19 pending=12 closed=29.
# oncelik: low=12 normal=24 high=16 urgent=8 (adetler bilerek farklı).
# TUZAK: beş KAPALI biletin KONU alanında "open" geçiyor (T1006, T1010,
# T1017, T1025, T1037). Satır-temelli `grep open` 24 satır verir; doğrusu 19.
cat > "$DESTEK/biletler.csv" <<'EOF'
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
chown root:root "$DESTEK/biletler.csv"
chmod 0444 "$DESTEK/biletler.csv"

# erisim.log — DENIED üç kez geçiyor → görev 4'ün ilk araması 0 döner.
cat > "$DESTEK/erisim.log" <<'EOF'
2026-07-27 13:01:12 10.0.0.11 GET /index.html 200 1240
2026-07-27 13:01:44 10.0.0.11 GET /style.css 200 3180
2026-07-27 13:02:03 10.0.0.24 GET /index.html 200 1240
2026-07-27 13:02:31 10.0.0.24 GET /logo.png 200 8820
2026-07-27 13:03:09 10.0.0.37 GET /api/status 200 96
2026-07-27 13:03:55 10.0.0.11 POST /api/login 200 312
2026-07-27 13:04:20 10.0.0.52 GET /index.html 200 1240
2026-07-27 13:05:01 10.0.0.52 GET /missing.html 404 512
2026-07-27 13:05:47 10.0.0.37 GET /api/status 200 96
2026-07-27 13:06:12 10.0.0.63 GET /admin ACCESS DENIED
2026-07-27 13:06:40 10.0.0.24 GET /report.pdf 200 44100
2026-07-27 13:07:15 10.0.0.11 GET /api/items 200 2044
2026-07-27 13:08:02 10.0.0.75 GET /index.html 200 1240
2026-07-27 13:08:33 10.0.0.75 GET /style.css 200 3180
2026-07-27 13:09:10 10.0.0.37 GET /api/status 200 96
2026-07-27 13:09:58 10.0.0.52 POST /api/items 201 128
2026-07-27 13:10:26 10.0.0.63 GET /index.html 200 1240
2026-07-27 13:11:04 10.0.0.24 GET /api/items 200 2044
2026-07-27 13:11:49 10.0.0.11 GET /help.html 200 1710
2026-07-27 13:12:22 10.0.0.88 GET /index.html 200 1240
2026-07-27 13:13:07 10.0.0.88 GET /api/status 500 64
2026-07-27 13:13:41 10.0.0.37 GET /api/status 200 96
2026-07-27 13:14:19 10.0.0.52 GET /logo.png 200 8820
2026-07-27 13:15:02 10.0.0.75 POST /api/login 401 88
2026-07-27 13:15:36 10.0.0.75 POST /api/login 200 312
2026-07-27 13:16:11 10.0.0.24 GET /help.html 200 1710
2026-07-27 13:16:55 10.0.0.11 GET /api/items 200 2044
2026-07-27 13:17:30 10.0.0.63 GET /report.pdf 200 44100
2026-07-27 13:18:08 10.0.0.37 GET /api/status 200 96
2026-07-27 13:18:44 10.0.0.99 GET /index.html 200 1240
2026-07-27 13:19:21 10.0.0.99 GET /style.css 200 3180
2026-07-27 13:20:03 10.0.0.52 GET /missing.html 404 512
2026-07-27 13:20:47 10.0.0.88 GET /api/items 200 2044
2026-07-27 13:21:12 10.0.0.11 GET /index.html 200 1240
2026-07-27 13:21:59 10.0.0.24 GET /api/status 200 96
2026-07-27 13:22:35 10.0.0.75 GET /help.html 200 1710
2026-07-27 13:23:14 10.0.0.14 GET /etc/passwd ACCESS DENIED
2026-07-27 13:23:50 10.0.0.37 GET /api/status 200 96
2026-07-27 13:24:26 10.0.0.63 POST /api/items 201 128
2026-07-27 13:25:09 10.0.0.99 GET /logo.png 200 8820
2026-07-27 13:25:44 10.0.0.52 GET /index.html 200 1240
2026-07-27 13:26:20 10.0.0.11 GET /report.pdf 200 44100
2026-07-27 13:27:03 10.0.0.88 GET /style.css 200 3180
2026-07-27 13:27:41 10.0.0.24 GET /api/items 200 2044
2026-07-27 13:28:18 10.0.0.37 GET /api/status 200 96
2026-07-27 13:28:52 10.0.0.75 GET /index.html 200 1240
2026-07-27 13:29:30 10.0.0.14 GET /help.html 200 1710
2026-07-27 13:30:11 10.0.0.63 GET /api/items 500 64
2026-07-27 13:30:48 10.0.0.99 POST /api/login 200 312
2026-07-27 13:31:25 10.0.0.52 GET /style.css 200 3180
2026-07-27 13:32:02 10.0.0.11 GET /api/status 200 96
2026-07-27 13:32:39 10.0.0.88 GET /missing.html 404 512
2026-07-27 13:33:16 10.0.0.24 GET /index.html 200 1240
2026-07-27 13:33:54 10.0.0.37 GET /api/status 200 96
2026-07-27 13:34:31 10.0.0.75 GET /report.pdf 200 44100
2026-07-27 13:35:08 10.0.0.14 GET /api/items 200 2044
2026-07-27 13:35:45 10.0.0.63 GET /style.css 200 3180
2026-07-27 13:36:22 10.0.0.99 GET /index.html 200 1240
2026-07-27 13:36:59 10.0.0.52 GET /help.html 200 1710
2026-07-27 13:37:36 10.0.0.11 GET /logo.png 200 8820
2026-07-27 13:38:13 10.0.0.88 GET /api/items 200 2044
2026-07-27 13:38:50 10.0.0.24 POST /api/items 201 128
2026-07-27 13:39:27 10.0.0.37 GET /api/status 200 96
2026-07-27 13:40:04 10.0.0.31 GET /admin/config ACCESS DENIED
2026-07-27 13:40:41 10.0.0.75 GET /index.html 200 1240
2026-07-27 13:41:18 10.0.0.14 GET /style.css 200 3180
2026-07-27 13:41:55 10.0.0.63 GET /api/status 200 96
2026-07-27 13:42:32 10.0.0.99 GET /report.pdf 200 44100
2026-07-27 13:43:09 10.0.0.52 GET /api/items 200 2044
2026-07-27 13:43:46 10.0.0.11 GET /index.html 200 1240
2026-07-27 13:44:23 10.0.0.88 GET /help.html 200 1710
2026-07-27 13:45:00 10.0.0.24 GET /logo.png 200 8820
2026-07-27 13:45:37 10.0.0.37 GET /api/status 200 96
2026-07-27 13:46:14 10.0.0.75 GET /missing.html 404 512
2026-07-27 13:46:51 10.0.0.14 GET /api/items 200 2044
2026-07-27 13:47:28 10.0.0.63 GET /index.html 200 1240
2026-07-27 13:48:05 10.0.0.99 GET /style.css 200 3180
2026-07-27 13:48:42 10.0.0.52 POST /api/login 200 312
2026-07-27 13:49:19 10.0.0.11 GET /api/status 200 96
2026-07-27 13:49:56 10.0.0.88 GET /index.html 200 1240
EOF
chown root:root "$DESTEK/erisim.log"
chmod 0444 "$DESTEK/erisim.log"

# notlar.txt — satır BAŞINDA TODO: 5 satır (silinecek). Satır ORTASINDA TODO:
# 1 satır (kalacak — `^` çapasının sınandığı yer). sunucu1: 4 satırda, toplam
# 5 geçiş (bir satırda iki kez → `s///g` yoksa biri kaçar).
cat > "$DESTEK/notlar.txt" <<'EOF'
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
chown "$STUDENT:$STUDENT" "$DESTEK/notlar.txt"
chmod 0644 "$DESTEK/notlar.txt"

# Stajyerin yanlış cevapları (sıfır bedava OK). Beş dosya da VAR ama hepsi
# yanlış: 01 → `wc -l DOSYA` çıktısı (başlık sayılmış + dosya adı yazılmış),
# 02 → satır-temelli `grep open` (5 tuzak satır fazla), 03 → bir öncelik
# eksik + bir sayı yanlış, 04/05 → ikisi ters yazılmış.
wc -l "$DESTEK/biletler.csv" > "$ANS/01-adet.txt"
grep open "$DESTEK/biletler.csv" > "$ANS/02-acik.txt"
cat > "$ANS/03-oncelik.txt" <<'EOF'
12 low
23 normal
16 high
EOF
echo '1' > "$ANS/04-kod.txt"
echo '0' > "$ANS/05-kod.txt"

# Orijinal kopyalar: check.sh beklenen değerleri buradan türetir.
# 0700/0400 root → student okuyup cevabı kopyalayamaz.
mkdir -p "$ORIG/destek"
cp "$DESTEK/biletler.csv" "$DESTEK/erisim.log" "$DESTEK/notlar.txt" "$ORIG/destek/"
chown -R root:root "$ORIG"
chmod 0700 "$ORIG" "$ORIG/destek"
chmod 0400 "$ORIG"/destek/*

# =============================================================================
# TICKET 8 — Karışık log'u temizle, otomatik rapor kur (kaynak: lab 007b)
# =============================================================================
mkdir -p "$GUNLUKLER" "$WORK" /etc/proje
chown root:root "$GUNLUKLER"
chmod 0755 "$GUNLUKLER"
chown "$STUDENT:$STUDENT" "$WORK"
chmod 0755 "$WORK"
# /etc/proje student'a yazılabilir: vim writebackup aynı dizinde yedek açar,
# dizin yazılamazsa `:w` E509 ile ölür.
chown root:"$STUDENT" /etc/proje
chmod 0775 /etc/proje

# merged.log — 70 satır. Tarihlerin yarısı GG/AA/YYYY, yarısı YYYY-AA-GG.
# Dört satırda ayırıcı çevresinde 1-3 boşluk. 12 satır geçersiz.
# TUZAKLAR:
#  A) İki satır geçerli görünen kaydın ÖNÜNE serbest metin taşıyor →
#     `^` çapası olmayan regex bunları geçerli sayar.
#  B) İki satır beş alanlı, ilk dört alanı kusursuz → mesaj alanı `.+$`
#     ile yazılırsa geçerli sayılır. Doğrusu `[^|]+$`.
#  C) Üç GEÇERLİ satırın mesajında bir seviye adı VE bir IP geçiyor →
#     satır-temelli sayım yanlış sonuç verir, alan farkındalığı şart.
# Geçersiz IP'ler bilinçli olarak 4 HANELİ oktet ve EKSİK oktet.
cat > "$GUNLUKLER/merged.log" <<'EOF'
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
chown root:root "$GUNLUKLER/merged.log"
chmod 0444 "$GUNLUKLER/merged.log"

# report.conf — satır başında `#`: 6 satır (silinecek). Satır ORTASINDA `#`:
# 1 satır (kalacak). /opt/eski: 4 satırda, toplam 5 geçiş (bir satırda iki
# kez → eksik `g` bayrağı buradan çıkar). retention bilerek 90.
cat > /etc/proje/report.conf <<'EOF'
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
chown root:"$STUDENT" /etc/proje/report.conf
chmod 0664 /etc/proje/report.conf

# Önceki gecenin yarım kalmış koşusu (sıfır bedava OK):
# normal.log yalnız ilk 20 satır, tarihler ÇEVRİLMEMİŞ, boşluklar duruyor.
# valid.log o yarım dosya üzerinde ÇAPASIZ regex ile üretilmiş.
# invalid.log ve ozet.txt hiç yok.
head -20 "$GUNLUKLER/merged.log" > "$WORK/normal.log"
grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}\|(INFO|WARN|ERROR)\|' "$WORK/normal.log" \
    > "$WORK/valid.log" || true
chown "$STUDENT:$STUDENT" "$WORK/normal.log" "$WORK/valid.log"
chmod 0644 "$WORK/normal.log" "$WORK/valid.log"

mkdir -p "$ORIG/gunlukler"
cp "$GUNLUKLER/merged.log" /etc/proje/report.conf "$ORIG/gunlukler/"
chown -R root:root "$ORIG"
chmod 0700 "$ORIG" "$ORIG/gunlukler"
chmod 0400 "$ORIG"/gunlukler/*

chown -R "$STUDENT:$STUDENT" "$ANS"
chmod 0644 "$ANS"/0*.txt

# =============================================================================
# TICKET 9 — Aceleyle atılmış dosyalar ve arşivleme (kaynak: lab 008)
# =============================================================================
HOME_DIR="/home/$STUDENT"
SRC=/srv/backup-kaynagi
DATA=/srv/data
BACKUP=/srv/backup

rm -f "$HOME_DIR/kaynak3-hardlink.txt" "$HOME_DIR/kaynak3-symlink.txt"

# Üç dosya da ev dizininde duruyor. Doğru yerleri sırasıyla /var/log/myapp,
# /etc/myapp ve /usr/local/bin. İlk iki hedef dizin YOK.
cat > "$HOME_DIR/uygulama.log" <<'EOF'
2026-07-20 09:14:02 INFO  servis basladi
2026-07-20 09:14:07 INFO  yapilandirma okundu
2026-07-20 10:02:41 WARN  onbellek isabet orani dusuk
2026-07-20 11:37:19 ERROR yedek birimine yazilamadi
2026-07-20 11:37:25 INFO  yeniden deneme kuyruga alindi
2026-07-21 08:00:03 INFO  gece isi tamamlandi
EOF

cat > "$HOME_DIR/myapp.conf" <<'EOF'
listen_port = 8080
data_dir = /srv/data
backup_dir = /srv/backup
log_level = info
retention_days = 14
EOF

# İçerik bilinçli olarak arşivleme görevinin cevabını VERMEZ.
# Çalıştırma izni yok — kriter 9.3'ün bozuk hâli.
cat > "$HOME_DIR/backup-helper" <<'EOF'
#!/usr/bin/env bash
# Yedek dizinindeki arsivleri listeler.
set -eu
ls -lh /srv/backup
EOF

chown "$STUDENT:$STUDENT" "$HOME_DIR/uygulama.log" "$HOME_DIR/myapp.conf" \
                          "$HOME_DIR/backup-helper"
chmod 0644 "$HOME_DIR/uygulama.log" "$HOME_DIR/myapp.conf" \
           "$HOME_DIR/backup-helper"

# Bağlantı kaynakları. Dizin root:root 0755 → öğrenci burada dosya
# yaratamaz, bağlantılarını ev dizinine kurar. Dosyaların SAHİBİ student:
# fs.protected_hardlinks=1 altında kendine ait olmayan bir dosyaya hard
# link kurmak EPERM verir, root sahipli bırakılsaydı görev imkânsız olurdu.
#
# Boyutlar bilinçli:  kaynak1 100000 B (+hard link, diskte bir kez sayılır)
#                     kaynak2  60000 B (+bağımsız kopya, iki kez sayılır)
#                     kaynak3  40000 B
# du -s → 260 KB. Görünen boyutları toplayan çözüm 360 KB der: tuzak bu.
mkdir -p "$SRC"
chown root:root "$SRC"
chmod 0755 "$SRC"

# Boru hattı KULLANILMIYOR: `yes | head -c N` head çıkınca SIGPIPE yollar,
# `set -o pipefail` altında pipeline 141 döner ve setup ölür.
gen() {  # gen <dosya> <bayt> <satir metni>
    local f="$1" n="$2" s="$3" i
    : > "$f"
    for ((i = 0; i < n / 20 + 1; i++)); do printf '%s\n' "$s"; done > "$f"
    truncate -s "$n" "$f"
}
gen "$SRC/kaynak1.txt" 100000 'kaynak1 - birincil yedek kaynagi'
gen "$SRC/kaynak2.txt" 60000  'kaynak2 - ikincil yedek kaynagi'
gen "$SRC/kaynak3.txt" 40000  'kaynak3 - arsiv disi kaynak'

# kaynak1-yedek.txt: AYNI inode (hard link).
ln "$SRC/kaynak1.txt" "$SRC/kaynak1-yedek.txt"
# kaynak2-kopya.txt: birebir aynı içerik, FARKLI inode. Tuzak: diff ve cmp
# sessiz kalır, ayırt eden tek şey inode karşılaştırmasıdır.
cp "$SRC/kaynak2.txt" "$SRC/kaynak2-kopya.txt"

chown "$STUDENT:$STUDENT" "$SRC"/*
chmod 0644 "$SRC"/*

# Arşivlenecek ağaç. gecici/ arşive girmeyecek ama diskten de silinmeyecek:
# --exclude yerine dizini SİLEN çözüm 9.11'den düşer.
mkdir -p "$DATA/kalici" "$DATA/gecici"
printf '%s\n' 'kalici veri govdesi' 'ikinci satir' > "$DATA/dosya.txt"
printf '%s\n' 'bu dosya yedege girmeli' > "$DATA/kalici/onemli.txt"
printf '%s\n' 'bu dosya yedege girmemeli' > "$DATA/gecici/silinecek.txt"
chown -R "$STUDENT:$STUDENT" "$DATA"
chmod 0755 "$DATA" "$DATA/kalici" "$DATA/gecici"
chmod 0644 "$DATA/dosya.txt" "$DATA/kalici/onemli.txt" "$DATA/gecici/silinecek.txt"

mkdir -p "$BACKUP"
chown "$STUDENT:$STUDENT" "$BACKUP"
chmod 0755 "$BACKUP"

mkdir -p "$ORIG/links/data"
cp "$HOME_DIR/uygulama.log" "$HOME_DIR/myapp.conf" "$HOME_DIR/backup-helper" \
   "$ORIG/links/"
cp "$SRC/kaynak1.txt" "$SRC/kaynak2.txt" "$SRC/kaynak3.txt" "$ORIG/links/"
cp -a "$DATA/." "$ORIG/links/data/"

# =============================================================================
# TICKET 10 — Paket durumu (kaynak: lab 009, package management)
# =============================================================================
# NETWORK GEREKİYOR: bc'nin install/remove işlemleri GERÇEK dnf işlemleridir,
# taklit edilmez — öğrenci gerçek bir history kaydı üzerinde çalışır.
ASSETS=/opt/lab-assets
PKGDIR=/srv/paketler

# Öğrencinin kurmuş olabileceği her şey geri alınır.
dnf -y remove lsof bc dpkg ed epel-release >/dev/null 2>&1 || true
# dpkg ile gelen bağımlılıklar da gitmeli: zlib-ng crb'den gelir, bırakılırsa
# .deb görevinin bağımlılık hatası hiç ortaya çıkmaz.
dnf -y remove zlib-ng libmd >/dev/null 2>&1 || true
dnf config-manager --set-disabled crb >/dev/null 2>&1 || true
rm -rf /var/lib/dpkg /var/lib/dpkg-* /etc/dpkg

# /etc/vimrc'yi önce KURULUM hâline döndür, sonra bilinçli boz. Aksi hâlde
# ikinci koşuda bozma satırı iki kez eklenirdi.
# `dnf reinstall vim-common` BU İŞİ YAPMAZ: /etc/vimrc paket içinde config (c)
# işaretli, rpm değiştirilmiş bir config dosyasının üzerine yazmaz.
cp -p "$ASSETS/vimrc.pristine" /etc/vimrc
chown root:root /etc/vimrc
rm -f /etc/vimrc.rpmnew /etc/vimrc.rpmsave

# Paket dosyaları image'daki varlıklardan KOPYALANIR: öğrenci bozsa bile
# reset gerçekten eski hâle döndürür ve setup network'ten dosya indirmez.
mkdir -p "$PKGDIR"
cp "$ASSETS"/*.rpm "$ASSETS"/*.deb "$PKGDIR/"
chown -R root:root "$PKGDIR"
chmod 0755 "$PKGDIR"
chmod 0644 "$PKGDIR"/*

# İçerik + izin birlikte bozulur: `rpm -V` çıktısı 5 (md5) ve M (mode)
# bayraklarını birlikte göstersin, cevabın iki bileşeni de gerçek olsun.
printf '%s\n' '" elle eklenmis satir - paket disi degisiklik' >> /etc/vimrc
chmod 0666 /etc/vimrc

# hesapla: bc'ye dayanır, bc kaldırılmış olduğu için şu an sıfırdan farklı
# kod döner.
cat > "$BINDIR/hesapla" <<'EOF'
#!/usr/bin/env bash
# Standart girdiden okudugu aritmetik ifadeyi hesaplar.
# Hesaplamayi kendisi yapmaz, bc'ye devreder.
set -eu
exec bc -l
EOF
chmod 0755 "$BINDIR/hesapla"
chown root:root "$BINDIR/hesapla"

# İki AYRI gerçek dnf işlemi: önce kurulum, sonra kaldırma. Öğrenci
# `dnf history undo` ile kaldırma işlemini geri alacak.
dnf -y install bc >/dev/null
dnf -y remove  bc >/dev/null
# Kaldırma işlemi listenin en üstünde kalmasın: "en son işlemi geri al"
# refleksi doğru cevabı kazara vermesin, geçmişi okuma gereği kalksın.
dnf -y reinstall tree >/dev/null

mkdir -p "$ORIG/paketler"
cp "$PKGDIR"/* "$ORIG/paketler/"

# =============================================================================
# TICKET 11 — Dört systemd işi (kaynak: lab 010, systemd)
# =============================================================================
UNITS=/etc/systemd/system
READY=/var/lib/veritabani/.ready

# Öğrencinin yapmış olabileceği her şey geri alınır.
for u in gorevci raporcu api veritabani; do
    systemctl stop "$u.service"    >/dev/null 2>&1 || true
    systemctl disable "$u.service" >/dev/null 2>&1 || true
    rm -f "/run/systemd/system/$u.service"
    rm -rf "/run/systemd/system/$u.service.d" "$UNITS/$u.service.d"
done
rm -f "$UNITS/gorevci.service"
userdel -r raporcu >/dev/null 2>&1 || true
rm -rf /var/lib/veritabani /opt/db /opt/api
systemctl daemon-reload
systemctl reset-failed >/dev/null 2>&1 || true

# Servis gövdeleri. Hepsi ÖN PLANDA kalır (oneshot hariç): fork etmez,
# & kullanmaz. Type=simple'ın doğru seçim olmasının sebebi bu.
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

# raporcu.service — İKİ bağımsız hata:
# (a) ExecStart yanlış yola bakıyor; gerçek binary /opt/raporcu/bin/raporcu.
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

# api.service — After/Requires bulunmadığı için veritabani'ndan bağımsız
# başlar ve .ready dosyasını bulamayıp güvenilir biçimde başarısız olur.
cat > "$UNITS/api.service" <<'EOF'
[Unit]
Description=API servisi

[Service]
Type=simple
ExecStart=/opt/api/api

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 "$UNITS"/raporcu.service "$UNITS"/veritabani.service "$UNITS"/api.service
systemctl daemon-reload

# Unit dosyasını yazmak yetmez: servisler başlatılıp gerçekten failed
# duruma düşürülür ki öğrenci `systemctl status` ile canlı bir hata görsün.
rm -f "$READY"
systemctl start raporcu.service >/dev/null 2>&1 || true
systemctl start api.service     >/dev/null 2>&1 || true
# Type=simple'da `start` fork eder etmez 0 döner; başarısızlık asenkron gelir.
sleep 2

# set-default yalnız default.target bağını değiştirir; çalışan sistemi
# rescue'ya DÜŞÜRMEZ, o yüzden container ayakta kalır.
systemctl set-default rescue.target >/dev/null 2>&1

# =============================================================================
# TICKET 12 — Log, cron ve saat (kaynak: lab 011, journalctl/cron/zaman)
# =============================================================================
LISANS=/etc/bekci/lisans.key
CEVAP="/home/$STUDENT/cevap-bekci.txt"
YEDEK_LOG=/var/log/yedek/yedek.log
TEMIZLIK_LOG=/var/log/temizlik.log

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
rm -f  "$CEVAP" /etc/cron.d/yedek
rm -rf /var/log/yedek "$TEMIZLIK_LOG"
crontab -r -u "$STUDENT" >/dev/null 2>&1 || true
crontab -r -u root       >/dev/null 2>&1 || true
systemctl daemon-reload
# reset-failed BİRİM BAZLI: çıplak çağrı Ticket 11'in bilerek failed
# bırakılmış raporcu/api servislerini de temizler ve o ticket'ın bozuk
# durumu kurulamaz.
systemctl reset-failed bekci.service temizlik.service temizlik.timer \
    >/dev/null 2>&1 || true

# journald yalnız bellekte tutsun: kalıcı dizin ve Storage= ayarı silinir.
rm -rf /etc/systemd/journald.conf.d
if [ -f /etc/systemd/journald.conf ]; then
    sed -i '/^[[:space:]]*Storage=/d' /etc/systemd/journald.conf
fi
rm -rf /var/log/journal
systemctl restart systemd-journald.service >/dev/null 2>&1 || true

# bekci: İKİ KADEMELİ hata. Önce lisans dosyası hiç yok (exit 3). Öğrenci
# dosyayı açınca ikinci sebep ortaya çıkar: KEY= satırı yok (exit 4).
# İkincisi ilki çözülmeden GÖRÜNMEZ — katmanlı teşhis.
mkdir -p /opt/bekci
cat > /opt/bekci/bekci <<'EOF'
#!/usr/bin/env bash
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

cat > "$BINDIR/yedekle" <<'EOF'
#!/usr/bin/env bash
set -u
LOG=/var/log/yedek/yedek.log
mkdir -p "$(dirname "$LOG")"
printf '%s yedek alindi\n' "$(date '+%F %T')" >> "$LOG"
EOF

cat > "$BINDIR/temizlik" <<'EOF'
#!/usr/bin/env bash
set -u
LOG=/var/log/temizlik.log
printf '%s temizlik yapildi\n' "$(date '+%F %T')" >> "$LOG"
EOF

chmod 0755 /opt/bekci/bekci "$BINDIR/yedekle" "$BINDIR/temizlik"
chown root:root /opt/bekci/bekci "$BINDIR/yedekle" "$BINDIR/temizlik"

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

# /etc/cron.d/yedek ÜÇ ayrı sebepten çalışmıyor: (a) cron servisi kapalı ve
# disabled, (b) saat gece 3'e kurulu, (c) komut mutlak yol değil ve
# zamanlayıcı ortamının PATH'inde /usr/local/bin yok.
cat > /etc/cron.d/yedek <<'EOF'
0 3 * * * root yedekle
EOF
chmod 0644 /etc/cron.d/yedek
chown root:root /etc/cron.d/yedek
systemctl disable crond.service >/dev/null 2>&1 || true
systemctl stop    crond.service >/dev/null 2>&1 || true

# Saat dilimi yanlış, chrony'de zaman sunucusu satırı silinmiş, senkron kapalı.
timedatectl set-timezone America/New_York >/dev/null 2>&1 ||
    ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
cat > /etc/chrony.conf <<'EOF'
driftfile /var/lib/chrony/drift
makestep 1.0 3
logdir /var/log/chrony
EOF
chmod 0644 /etc/chrony.conf
systemctl disable chronyd.service >/dev/null 2>&1 || true
systemctl stop    chronyd.service >/dev/null 2>&1 || true
timedatectl set-ntp false >/dev/null 2>&1 || true
sleep 3

# =============================================================================
# TICKET 13 — Nöbet devri: SSH sertleştirme ve GPG (kaynak: lab 012)
# =============================================================================
SSH_DIR="$HOME_DIR/.ssh"
SSHD_CONF=/etc/ssh/sshd_config
PAKET=/opt/paket
PAKET_ASSETS=/opt/lab-assets/paket
GIZLI="$HOME_DIR/gizli.txt"
DUYURU="$HOME_DIR/duyuru.txt"
CEVAP_PAKET="$HOME_DIR/cevap-paket.txt"

rm -rf "$SSH_DIR" "$HOME_DIR/.gnupg" "$PAKET"
rm -f  "$CEVAP_PAKET" "$GIZLI.gpg" "$DUYURU.sig" "$DUYURU.asc" "$GIZLI.asc"
systemctl stop sshd.service >/dev/null 2>&1 || true
ssh-keygen -A >/dev/null

# Önce GEÇERLİ bir yapılandırma ile servisi başlat: root ve parola girişi
# açık. Sözdizimi hatası ancak servis ayaktayken dosyaya eklenir; böylece
# çalışan yapılandırma temiz, diskteki dosya bozuk olur — `sshd -t`
# öğretisinin tam olarak istediği durum.
cat > "$SSHD_CONF" <<'EOF'
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
for _ in $(seq 1 20); do
    ss -ltn 2>/dev/null | grep -q ':22 ' && break
    sleep 1
done
sleep 3

# Sözdizimi hatası: doğrusu MaxAuthTries.
cat >> "$SSHD_CONF" <<'EOF'
MaxAuthTrys 6
EOF
chmod 0600 "$SSHD_CONF"

# Anahtar çifti hazır ama sunucu tanımıyor: authorized_keys yok, ev dizini
# ve .ssh izinleri sshd'nin StrictModes şartını sağlamıyor.
install -d -o "$STUDENT" -g "$STUDENT" -m 0755 "$SSH_DIR"
su - "$STUDENT" -c "ssh-keygen -t ed25519 -N '' -q -f $SSH_DIR/id_ed25519"
chmod 0600 "$SSH_DIR/id_ed25519"
chmod 0644 "$SSH_DIR/id_ed25519.pub"
chown -R "$STUDENT:$STUDENT" "$SSH_DIR"
chmod 0775 "$HOME_DIR"
chown "$STUDENT:$STUDENT" "$HOME_DIR"

cat > "$GIZLI" <<'EOF'
Sunucu devir teslim notu.
Yedek parolasi kasada, oda 3.
Bu dosya sifrelenmeden diskte durmamali.
EOF

cat > "$DUYURU" <<'EOF'
Bakim duyurusu: cumartesi 02:00-04:00 arasi kesinti olacak.
EOF

chown "$STUDENT:$STUDENT" "$GIZLI" "$DUYURU"
chmod 0644 "$GIZLI" "$DUYURU"

# İki paket sürümü + ayrık imzaları. Yayıncının açık anahtarı anahtarlıkta
# DEĞİL; sürümlerden biri yolda değiştirilmiş.
install -d -o root -g root -m 0755 "$PAKET"
install -o root -g root -m 0644 "$PAKET_ASSETS"/surum-a.tar.gz     "$PAKET/"
install -o root -g root -m 0644 "$PAKET_ASSETS"/surum-a.tar.gz.sig "$PAKET/"
install -o root -g root -m 0644 "$PAKET_ASSETS"/surum-b.tar.gz     "$PAKET/"
install -o root -g root -m 0644 "$PAKET_ASSETS"/surum-b.tar.gz.sig "$PAKET/"
install -o root -g root -m 0644 "$PAKET_ASSETS"/yayinci-acik.asc   "$PAKET/"

# =============================================================================
# Kurulum doğrulaması
# =============================================================================
chown -R root:root "$ORIG"
chmod -R go-rwx "$ORIG"
find "$ORIG" -type d -exec chmod 0700 {} +
find "$ORIG" -type f -exec chmod 0400 {} +

err=0
say() { echo "setup HATA: $*" >&2; err=1; }

for f in "$DESTEK/biletler.csv" "$DESTEK/erisim.log" "$DESTEK/notlar.txt" \
         "$ANS/01-adet.txt" "$ANS/02-acik.txt" "$ANS/03-oncelik.txt" \
         "$ANS/04-kod.txt" "$ANS/05-kod.txt" \
         "$GUNLUKLER/merged.log" /etc/proje/report.conf \
         "$WORK/normal.log" "$WORK/valid.log" \
         "$ORIG/destek/biletler.csv" "$ORIG/gunlukler/merged.log"; do
    [ -f "$f" ] || say "$f yok"
done
[ ! -e "$WORK/invalid.log" ]        || say "invalid.log var olmamali"
[ ! -e "$WORK/ozet.txt" ]           || say "ozet.txt var olmamali"
[ ! -e /srv/reports/text-report.txt ] || say "text-report.txt var olmamali"
[ ! -e "$BINDIR/mkreport" ]         || say "mkreport var olmamali"

# Ticket 7 tuzağı: satır-temelli `grep open`, alan-temelli cevaptan fazla
# satır vermeli. Vermezse lab kendi dersini öğretmiyor.
g=$(grep -c open "$DESTEK/biletler.csv")
a=$(awk -F';' '$4 == "open"' "$DESTEK/biletler.csv" | wc -l)
[ "$g" -gt "$a" ] || say "bilet tuzagi etkisiz ($g vs $a)"
grep -q DENIED "$DESTEK/erisim.log" || say "erisim.log icinde DENIED yok"
[ "$(grep -c '^TODO' "$DESTEK/notlar.txt")" -ge 4 ] || say "yeterli ^TODO satiri yok"
grep -q 'TODO' <(grep -v '^TODO' "$DESTEK/notlar.txt") ||
    say "satir ortasinda TODO gecen satir yok"
[ "$(grep -o 'sunucu1' "$DESTEK/notlar.txt" | wc -l)" -gt \
  "$(grep -c 'sunucu1' "$DESTEK/notlar.txt")" ] ||
    say "satir ici cok gecisli sunucu1 satiri yok"

# Ticket 8 tuzakları
BODY='[0-9]{4}-[0-9]{2}-[0-9]{2}\|(INFO|WARN|ERROR)\|([0-9]{1,3}\.){3}[0-9]{1,3}\|'
REF_ERE="^${BODY}[^|]+\$"
LOOSE_A="${BODY}[^|]+"
LOOSE_B="^${BODY}.+\$"
norm="$(mktemp)"
sed -E -e 's#([0-9]{2})/([0-9]{2})/([0-9]{4})#\3-\2-\1#g' \
       -e 's#[[:space:]]*\|[[:space:]]*#|#g' "$GUNLUKLER/merged.log" > "$norm"
total=$(wc -l < "$norm")
valid=$(grep -Ec "$REF_ERE" "$norm" || true)
[ "$total" -eq 70 ] || say "merged.log $total satir, 70 bekleniyordu"
[ $((total - valid)) -ge 10 ] || say "gecersiz satir sayisi yetersiz"
loose_a=$(grep -Ec "$LOOSE_A" "$norm" || true)
[ "$loose_a" -gt "$valid" ] || say "capasiz regex tuzagi etkisiz"
loose_b=$(grep -Ec "$LOOSE_B" "$norm" || true)
[ "$loose_b" -gt "$valid" ] || say "bes alanli satir tuzagi etkisiz"
grep -E "$REF_ERE" "$norm" > "$norm.v"
[ "$(grep -c 'ERROR' "$norm.v" || true)" -gt \
  "$(awk -F'|' '$2 == "ERROR"' "$norm.v" | wc -l)" ] ||
    say "mesaj icindeki seviye adi tuzagi etkisiz"
[ "$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$norm.v" | sort -u | wc -l)" -gt \
  "$(awk -F'|' '{print $3}' "$norm.v" | sort -u | wc -l)" ] ||
    say "mesaj icindeki IP tuzagi etkisiz"
[ "$(grep -c '^#' /etc/proje/report.conf)" -ge 5 ] || say "yeterli ^# satiri yok"
grep -q '#' <(grep -v '^#' /etc/proje/report.conf) ||
    say "satir ortasinda # gecen satir yok"
[ "$(grep -o '/opt/eski' /etc/proje/report.conf | wc -l)" -gt \
  "$(grep -c '/opt/eski' /etc/proje/report.conf)" ] ||
    say "satir ici cok gecisli /opt/eski satiri yok"
grep -Eq '^retention[[:space:]]*=[[:space:]]*90$' /etc/proje/report.conf ||
    say "retention = 90 satiri yok"
rm -f "$norm" "$norm.v"

# Ticket 9: bozuk başlangıç gerçekten bozuk mu?
ino() { stat -c '%i' "$1"; }
[ ! -e /var/log/myapp ] || say "/var/log/myapp var olmamali"
[ ! -e /etc/myapp ]     || say "/etc/myapp var olmamali"
[ ! -e "$BINDIR/backup-helper" ]     || say "backup-helper /usr/local/bin'de olmamali"
[ ! -e "$BACKUP/data-yedek.tar.gz" ] || say "arsiv var olmamali"
[ ! -x "$HOME_DIR/backup-helper" ]   || say "backup-helper x biti tasimamali"
for f in "$HOME_DIR/uygulama.log" "$HOME_DIR/myapp.conf" \
         "$HOME_DIR/backup-helper" "$SRC/kaynak1.txt" "$SRC/kaynak1-yedek.txt" \
         "$SRC/kaynak2.txt" "$SRC/kaynak2-kopya.txt" "$SRC/kaynak3.txt" \
         "$DATA/dosya.txt" "$DATA/kalici/onemli.txt" \
         "$DATA/gecici/silinecek.txt"; do
    [ -f "$f" ] || say "$f yok"
done
[ "$(ino "$SRC/kaynak1.txt")" = "$(ino "$SRC/kaynak1-yedek.txt")" ] ||
    say "kaynak1-yedek.txt hard link degil"
[ "$(stat -c '%h' "$SRC/kaynak1.txt")" -ge 2 ] || say "kaynak1.txt link sayisi < 2"
[ "$(ino "$SRC/kaynak2.txt")" != "$(ino "$SRC/kaynak2-kopya.txt")" ] ||
    say "kaynak2-kopya.txt bagimsiz kopya degil"
cmp -s "$SRC/kaynak2.txt" "$SRC/kaynak2-kopya.txt" ||
    say "kaynak2-kopya.txt icerigi kaynak2.txt ile ayni degil (tuzak etkisiz)"
real_kb=$(du -s "$SRC" | cut -f1)
apparent_kb=$(stat -c '%s' "$SRC"/* | awk '{t += $1} END {print int((t + 1023) / 1024)}')
[ "$real_kb" -lt "$apparent_kb" ] ||
    say "du tuzagi etkisiz (gercek $real_kb KB, gorunen $apparent_kb KB)"
if ! su - "$STUDENT" -c "ln $SRC/kaynak3.txt /tmp/.hl-probe.\$\$ \
                         && rm -f /tmp/.hl-probe.\$\$" >/dev/null 2>&1; then
    say "student kaynak3.txt'ye hard link kuramiyor (protected_hardlinks?)"
fi
if su - "$STUDENT" -c "touch $SRC/.probe" >/dev/null 2>&1; then
    rm -f "$SRC/.probe"
    say "student $SRC icine yazabiliyor, dizin root:root 0755 olmali"
fi

# Ticket 10 doğrulaması
ls "$PKGDIR"/*.rpm >/dev/null 2>&1 || say "$PKGDIR icinde .rpm yok"
ls "$PKGDIR"/*.deb >/dev/null 2>&1 || say "$PKGDIR icinde .deb yok"
rpm_pkg="$(rpm -qp --qf '%{NAME}' "$PKGDIR"/*.rpm 2>/dev/null || true)"
[ -n "$rpm_pkg" ] || say ".rpm dosyasi okunamiyor (rpm -qp bos dondu)"
[ -n "$rpm_pkg" ] && rpm -q "$rpm_pkg" >/dev/null 2>&1 &&
    say "$rpm_pkg zaten kurulu, inceleme gorevi anlamsiz"

# NOT: `rpm -V ... | grep` YAZILMAZ. rpm fark bulunca 1 döner ve
# `set -o pipefail` altında grep eşleşse bile pipeline 1 verir.
vimrc_v="$(rpm -V vim-common 2>/dev/null || true)"
[ -n "$vimrc_v" ] || say "rpm -V vim-common temiz dondu, /etc/vimrc bozulmamis"
case "$vimrc_v" in
    ??5*) ;;
    *) say "rpm -V icerik (5) degisikligini gostermiyor: $vimrc_v" ;;
esac
case "$vimrc_v" in
    ?M*) ;;
    *) say "rpm -V izin (M) degisikligini gostermiyor: $vimrc_v" ;;
esac

command -v lsof >/dev/null 2>&1 && say "lsof kurulu olmamali"
rpm -q bc   >/dev/null 2>&1 && say "bc kurulu olmamali"
rpm -q dpkg >/dev/null 2>&1 && say "dpkg kurulu olmamali"
rpm -q epel-release >/dev/null 2>&1 && say "epel-release kurulu olmamali"
dnf repolist --enabled 2>/dev/null | grep -qi '^epel' && say "epel etkin olmamali"
dnf repolist --enabled 2>/dev/null | grep -qi '^crb'  && say "crb etkin olmamali"
[ -x "$BINDIR/hesapla" ] || say "hesapla kurulu degil"
if su - "$STUDENT" -c 'echo "2+2" | hesapla' >/dev/null 2>&1; then
    say "hesapla calisiyor, bc kaldirilmis olmali"
fi
dnf history list 2>/dev/null | grep -q 'remove bc' ||
    say "history icinde 'remove bc' islemi yok"
for f in paket-sorgu.txt butunluk-raporu.txt eksik-komut.txt \
         rpm-inceleme.txt deb-inceleme.txt baglanti-raporu.txt \
         disk-kullanimi.txt arsiv-dogrulama.txt; do
    [ ! -e "$ANS/$f" ] || say "$ANS/$f var olmamali"
done
if su - "$STUDENT" -c "touch $PKGDIR/.probe" >/dev/null 2>&1; then
    rm -f "$PKGDIR/.probe"
    say "student $PKGDIR icine yazabiliyor, dizin root:root 0755 olmali"
fi

# Ticket 11 doğrulaması
is_active()  { systemctl is-active  "$1" 2>/dev/null || true; }
is_enabled() { systemctl is-enabled "$1" 2>/dev/null || true; }

[ -x /opt/app/gorevci ]         || say "/opt/app/gorevci yok"
[ -x /opt/raporcu/bin/raporcu ] || say "/opt/raporcu/bin/raporcu yok"
[ -x /opt/db/veritabani-init ]  || say "/opt/db/veritabani-init yok"
[ -x /opt/api/api ]             || say "/opt/api/api yok"
[ -e "$UNITS/gorevci.service" ] && say "gorevci.service var olmamali"
systemctl cat gorevci.service >/dev/null 2>&1 &&
    say "gorevci.service systemd tarafindan taniniyor, tanimamali"
[ "$(is_active raporcu.service)" = "failed" ] ||
    say "raporcu.service failed degil: $(is_active raporcu.service)"
rap_status="$(systemctl show raporcu.service -p ExecMainStatus --value 2>/dev/null || true)"
[ "$rap_status" = "217" ] ||
    say "raporcu.service 217/USER ile degil '$rap_status' ile coktu"
getent passwd raporcu >/dev/null 2>&1 && say "raporcu kullanicisi var olmamali"
[ "$(is_active api.service)" = "failed" ] ||
    say "api.service failed degil: $(is_active api.service)"
api_req="$(systemctl show api.service -p Requires --value 2>/dev/null || true)"
case "$api_req" in *veritabani.service*) say "api.service'te Requires zaten var" ;; esac
api_aft="$(systemctl show api.service -p After --value 2>/dev/null || true)"
case "$api_aft" in *veritabani.service*) say "api.service'te After zaten var" ;; esac
[ "$(is_active veritabani.service)" = "inactive" ] ||
    say "veritabani.service inactive degil: $(is_active veritabani.service)"
[ ! -e "$READY" ] || say "$READY var olmamali"
for u in raporcu api veritabani; do
    [ "$(is_enabled "$u.service")" = "enabled" ] && say "$u.service enabled olmamali"
done
[ "$(systemctl get-default 2>/dev/null || true)" = "rescue.target" ] ||
    say "varsayilan target rescue.target degil"
su - "$STUDENT" -c 'systemctl show api.service -p Id --value' >/dev/null 2>&1 ||
    say "student systemctl sorgusu yapamiyor"

# Ticket 12 doğrulaması
[ -x /opt/bekci/bekci ]    || say "/opt/bekci/bekci yok"
[ -x "$BINDIR/yedekle" ]   || say "$BINDIR/yedekle yok"
[ -x "$BINDIR/temizlik" ]  || say "$BINDIR/temizlik yok"
[ -e /var/log/journal ] && say "/var/log/journal var olmamali"
[ -f /etc/systemd/journald.conf ] &&
    grep -q '^[[:space:]]*Storage=' /etc/systemd/journald.conf &&
    say "journald.conf'ta Storage satiri kalmis"
[ -e "$CEVAP" ]  && say "$CEVAP var olmamali"
[ -e "$LISANS" ] && say "$LISANS var olmamali"
bekci_res="$(systemctl show bekci.service -p Result --value 2>/dev/null || true)"
[ "$bekci_res" = "exit-code" ] ||
    say "bekci.service Result='$bekci_res', beklenen 'exit-code'"
bekci_st="$(systemctl show bekci.service -p ExecMainStatus --value 2>/dev/null || true)"
[ "$bekci_st" = "3" ] || say "bekci.service '$bekci_st' ile degil 3 ile cokmeli"
[ "$(is_enabled bekci.service)" = "enabled" ] && say "bekci.service enabled olmamali"
journalctl -u bekci.service -n 50 --no-pager 2>/dev/null |
    grep -q "FATAL: $LISANS bulunamadi" ||
    say "bekci'nin hata satiri journal'da gorunmuyor"
[ "$(is_active  crond.service)" = "active"  ] && say "crond.service aktif olmamali"
[ "$(is_enabled crond.service)" = "enabled" ] && say "crond.service enabled olmamali"
grep -q '^0 3 \* \* \* root yedekle$' /etc/cron.d/yedek ||
    say "/etc/cron.d/yedek beklenen bozuk satiri tasimiyor"
[ -e "$YEDEK_LOG" ] && say "$YEDEK_LOG var olmamali"
systemctl cat temizlik.service >/dev/null 2>&1 &&
    say "temizlik.service systemd tarafindan taniniyor, tanimamali"
systemctl cat temizlik.timer >/dev/null 2>&1 &&
    say "temizlik.timer systemd tarafindan taniniyor, tanimamali"
[ -e "$TEMIZLIK_LOG" ] && say "$TEMIZLIK_LOG var olmamali"
tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
[ "$tz" = "Europe/Istanbul" ] && say "saat dilimi hala Europe/Istanbul"
case "$(readlink -f /etc/localtime 2>/dev/null || true)" in
    */Europe/Istanbul) say "/etc/localtime hala Istanbul'a bakiyor" ;;
esac
grep -Eq '^[[:space:]]*(pool|server)[[:space:]]+[^[:space:]]+' /etc/chrony.conf &&
    say "chrony.conf'ta zaman sunucusu satiri kalmis"
[ "$(is_active  chronyd.service)" = "active"  ] && say "chronyd.service aktif olmamali"
[ "$(is_enabled chronyd.service)" = "enabled" ] && say "chronyd.service enabled olmamali"
[ "$(timedatectl show -p NTP --value 2>/dev/null || true)" = "yes" ] &&
    say "timedated NTP acik kalmis"
su - "$STUDENT" -c 'sudo -n journalctl -u bekci.service -n 5 --no-pager' 2>/dev/null |
    grep -q 'FATAL' || say "student sudo ile bekci gunlugunu okuyamiyor"
su - "$STUDENT" -c 'systemctl list-timers --all' >/dev/null 2>&1 ||
    say "student systemctl list-timers calistiramiyor"

# Ticket 13 doğrulaması
st() { su - "$STUDENT" -c "$1" >/dev/null 2>&1; }
[ -s /etc/ssh/ssh_host_ed25519_key ] || say "host anahtari uretilmemis"
[ "$(is_active sshd.service)" = "active" ] || say "sshd.service aktif degil"
ss -ltn 2>/dev/null | grep -q ':22 ' || say "sshd 22 portunu dinlemiyor"
sshd -t >/dev/null 2>&1 && say "sshd -t temiz cikti, sozdizimi hatasi kurulmamis"
grep -q '^PermitRootLogin yes'        "$SSHD_CONF" || say "PermitRootLogin yes yok"
grep -q '^PasswordAuthentication yes' "$SSHD_CONF" || say "PasswordAuthentication yes yok"
conf_m="$(stat -c %Y "$SSHD_CONF")"
svc_us="$(systemctl show sshd.service -p ExecMainStartTimestampMonotonic --value)"
boot_us="$(awk '{printf "%.0f", $1 * 1000000}' /proc/uptime)"
svc_epoch=$(( $(date +%s) - (boot_us - svc_us) / 1000000 ))
[ "$conf_m" -gt "$svc_epoch" ] ||
    say "config mtime servis baslangicindan yeni degil (uygulanmamis durumu kurulamadi)"
[ -e "$SSH_DIR/authorized_keys" ] && say "authorized_keys var olmamali"
[ -s "$SSH_DIR/id_ed25519" ]      || say "student ssh anahtari uretilmemis"
[ "$(stat -c %a "$SSH_DIR")" = "755" ]  || say ".ssh izni 755 degil"
[ "$(stat -c %a "$HOME_DIR")" = "775" ] || say "ev dizini izni 775 degil"
st "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o PasswordAuthentication=no student@localhost true" &&
    say "anahtarla giris zaten calisiyor, bozuk durum kurulmamis"
[ -e "$HOME_DIR/.gnupg" ] && say "student .gnupg dizini var olmamali"
st "gpg --list-secret-keys student@lab.local" &&
    say "student'in gizli gpg anahtari zaten var"
[ -e "$GIZLI.gpg" ]  && say "$GIZLI.gpg var olmamali"
[ -e "$DUYURU.sig" ] && say "$DUYURU.sig var olmamali"
[ -e "$CEVAP_PAKET" ] && say "$CEVAP_PAKET var olmamali"
st "gpg --verify $PAKET/surum-a.tar.gz.sig $PAKET/surum-a.tar.gz" &&
    say "yayinci anahtari ice aktarilmadan imza dogrulanabiliyor"
for f in surum-a.tar.gz surum-a.tar.gz.sig surum-b.tar.gz surum-b.tar.gz.sig \
         yayinci-acik.asc; do
    [ -s "$PAKET/$f" ] || say "$PAKET/$f yok"
done
st "cat $PAKET/yayinci-acik.asc" || say "student yayinci-acik.asc okuyamiyor"

[ "$err" -eq 0 ] || exit 1
echo "setup done: 900-vardiya-01b"
