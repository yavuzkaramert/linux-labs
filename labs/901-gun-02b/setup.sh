#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Lab 901-gun-02b'nin bozuk durumunu kurar. Idempotent.
#
# Bu bir TEKRAR labıdır: yedi ayrı ticket, yedi ayrı kaynak lab (007a-012).
# 901-gun-02a'nın devamı gibi anlatılır ama KENDİ container'ından sıfırdan
# kurulur — 02a'nın çözülmüş olması gerekmez.
#
# Senaryo: PatiVet Klinikleri, yedek/DR sunucusunu üretime alma gününün ikinci
# yarısı. Destek verisi işlenecek, servisler ayağa kaldırılacak, zamanlanmış
# işler kurulacak, sonunda uzaktan erişim sertleştirilecek.
#
# ORTAM GEREKSİNİMLERİ:
#  * container-systemd zorunlu: Ticket 11, 12 ve 13'ün kriterleri systemd'nin
#    PID 1 olmasını ister (birim başlatma/enable, timer, crond, chronyd, sshd).
#    Salt --privileged yetmez.
#  * AĞ GEREKİYOR: Ticket 10 gerçek dnf işlemleri yapar (EPEL/CRB, bc, lsof,
#    dpkg). Ağsız ortamda setup kurulur ama ticket çözülemez.
#
# DİKKAT:
#  * Ticket 11'in birim adları (veritabani-hazirla, randevu-api, hatirlatici,
#    stok-raporu) ile Ticket 12'nin adları (gozcu, temizlik, yedek) BİLEREK
#    ayrık tutulmuştur; "temizlik" yalnız Ticket 12'de geçer.
#  * Ticket 13'ün GPG ve paket varlıkları image'daki /opt/lab-assets/paket
#    altından kopyalanır; setup ağa çıkıp anahtar üretmez. Yayıncının GİZLİ
#    anahtarı image'da yoktur — imza yeniden üretilemez.
#  * Tüm beklenen değerler check.sh'ta /srv/.orig'ten HESAPLANIR.
set -euo pipefail

KLINIK=/srv/klinik
TALEP="$KLINIK/talepler"
LOGLAR="$KLINIK/loglar"
IS="$KLINIK/is"
PKGDIR="$KLINIK/paketler"
CONF=/etc/klinik
ORIG=/srv/.orig
ANS=/home/student/cevaplar
BINDIR=/usr/local/bin
UNITS=/etc/systemd/system
ASSETS_ROOT=/opt/lab-assets
ASSETS="$ASSETS_ROOT/paket"
PAKET=/opt/paket
STUDENT=student
HOME_STUDENT=/home/student
SSH_DIR="$HOME_STUDENT/.ssh"
SSHD_CONF=/etc/ssh/sshd_config
LAB_DATA="$(cd "$(dirname "$0")" && pwd)/data"

# =============================================================================
# 0. Önceki koşudan kalanları temizle
# =============================================================================
for u in gozcu temizlik veritabani-hazirla randevu-api hatirlatici stok-raporu; do
    systemctl stop "$u.service"    >/dev/null 2>&1 || true
    systemctl disable "$u.service" >/dev/null 2>&1 || true
    rm -f "$UNITS/$u.service"
    rm -rf "$UNITS/$u.service.d"
done
systemctl stop temizlik.timer    >/dev/null 2>&1 || true
systemctl disable temizlik.timer >/dev/null 2>&1 || true
rm -f  "$UNITS/temizlik.timer"
rm -rf "$UNITS/temizlik.timer.d"
rm -f  /run/systemd/system/temizlik.service /run/systemd/system/temizlik.timer
crontab -r -u "$STUDENT" >/dev/null 2>&1 || true
crontab -r -u root       >/dev/null 2>&1 || true
rm -f /etc/cron.d/yedek
systemctl daemon-reload
systemctl reset-failed >/dev/null 2>&1 || true

rm -rf "$KLINIK" "$ORIG" "$CONF" "$ANS" "$PAKET" \
       /srv/klinik-arsiv /srv/klinik-yedek-kaynagi \
       /etc/randevu /var/log/randevu /var/lib/klinik
rm -f "$BINDIR/rapor-uret" "$BINDIR/yedek-yardimcisi" "$BINDIR/dozhesapla.sh" \
      "$BINDIR/yedekle" "$BINDIR/temizle" "$BINDIR/stok-raporu" \
      "$BINDIR/hatirlatici" "$BINDIR/randevu-api" "$BINDIR/veritabani-hazirla"

install -d -o root -g root -m 0700 "$ORIG"
install -d -o root -g root -m 0755 "$KLINIK" "$CONF"
install -d -o "$STUDENT" -g "$STUDENT" -m 0755 "$ANS"

# =============================================================================
# TICKET 7 — Destek talepleri dökümü (kaynak: lab 007a, text filters)
# =============================================================================
install -d -o root -g root -m 0755 "$TALEP"

# talepler.csv — ';' ayraçlı, başlık satırı var.
# TUZAK: KAPALI bazı taleplerin konu alanında da "open" geçiyor. Satır-temelli
# `grep open` bunları da yakalar; alan-temelli süzme yakalamaz.
{
  echo 'id;tarih;oncelik;durum;atanan;konu'
  echo 'T2001;2026-07-01;yuksek;open;derya;randevu ekrani acilmiyor'
  echo 'T2002;2026-07-01;orta;closed;kaan;yazici kagit sikistirdi'
  echo 'T2003;2026-07-02;dusuk;pending;derya;stok raporu yavas'
  echo 'T2004;2026-07-02;yuksek;open;kaan;asi takvimi guncellenmiyor'
  echo 'T2005;2026-07-03;orta;closed;derya;open office dosyasi bozuk'
  echo 'T2006;2026-07-03;yuksek;open;kaan;rontgen cihazi baglanmiyor'
  echo 'T2007;2026-07-04;dusuk;closed;derya;etiket yazicisi degisti'
  echo 'T2008;2026-07-04;orta;pending;kaan;tahlil sonucu gec geliyor'
  echo 'T2009;2026-07-05;yuksek;open;derya;kasa ekrani donuyor'
  echo 'T2010;2026-07-05;orta;closed;kaan;open source surucu denendi'
  echo 'T2011;2026-07-06;dusuk;open;derya;yeni personel hesabi'
  echo 'T2012;2026-07-06;yuksek;pending;kaan;yedek alinmiyor'
  echo 'T2013;2026-07-07;orta;open;derya;randevu sms gitmiyor'
  echo 'T2014;2026-07-07;dusuk;closed;kaan;monitor kablosu'
  echo 'T2015;2026-07-08;yuksek;open;derya;hasta kaydi kayboldu'
  echo 'T2016;2026-07-08;orta;pending;kaan;laboratuvar entegrasyonu'
  echo 'T2017;2026-07-09;dusuk;closed;derya;open beta surumu istendi'
  echo 'T2018;2026-07-09;yuksek;open;kaan;odeme modulu hata veriyor'
  echo 'T2019;2026-07-10;orta;closed;derya;klavye degisimi'
  echo 'T2020;2026-07-10;dusuk;pending;kaan;arsiv dosyasi buyuk'
  echo 'T2021;2026-07-11;yuksek;open;derya;sunucu yavas'
  echo 'T2022;2026-07-11;orta;closed;kaan;yazilim guncellemesi'
  echo 'T2023;2026-07-12;dusuk;open;derya;raf etiketi basilmiyor'
  echo 'T2024;2026-07-12;yuksek;pending;kaan;veritabani baglantisi kopuyor'
  echo 'T2025;2026-07-13;orta;closed;derya;open kaynak lisans sorusu'
  echo 'T2026;2026-07-13;dusuk;open;kaan;fatura sablonu'
  echo 'T2027;2026-07-14;yuksek;open;derya;asi stogu gorunmuyor'
  echo 'T2028;2026-07-14;orta;pending;kaan;kamera kaydi'
  echo 'T2029;2026-07-15;dusuk;closed;derya;fare pili'
  echo 'T2030;2026-07-15;yuksek;open;kaan;randevu cakismasi'
  echo 'T2031;2026-07-16;orta;closed;derya;telefon santrali'
  echo 'T2032;2026-07-16;dusuk;pending;kaan;etiket sablonu'
  echo 'T2033;2026-07-17;yuksek;open;derya;kayit ekrani hata veriyor'
  echo 'T2034;2026-07-17;orta;closed;kaan;yedek disk degisimi'
  echo 'T2035;2026-07-18;dusuk;open;derya;yazici surucusu'
  echo 'T2036;2026-07-18;yuksek;pending;kaan;rontgen arsivi dolu'
  echo 'T2037;2026-07-19;orta;closed;derya;open tab sorunu'
  echo 'T2038;2026-07-19;dusuk;open;kaan;masaustu kisayolu'
  echo 'T2039;2026-07-20;yuksek;open;derya;odeme terminali'
  echo 'T2040;2026-07-20;orta;pending;kaan;stok sayimi'
  echo 'T2041;2026-07-21;dusuk;closed;derya;kablosuz ag sifresi'
  echo 'T2042;2026-07-21;yuksek;open;kaan;lab cihazi kalibrasyon'
  echo 'T2043;2026-07-22;orta;closed;derya;ekran karti'
  echo 'T2044;2026-07-22;dusuk;pending;kaan;dosya paylasimi'
  echo 'T2045;2026-07-23;yuksek;open;derya;sunucu diski dolu'
  echo 'T2046;2026-07-23;orta;closed;kaan;yazici toner'
  echo 'T2047;2026-07-24;dusuk;open;derya;randevu notu eklenmiyor'
  echo 'T2048;2026-07-24;yuksek;pending;kaan;yedekleme zamanlamasi'
  echo 'T2049;2026-07-25;orta;closed;derya;klima arizasi'
  echo 'T2050;2026-07-25;dusuk;open;kaan;etiket boyutu'
} > "$TALEP/talepler.csv"

# erisim.log — "ENGELLENDI" ifadesi GEÇİYOR (3 kez) → arama çıkış kodu 0.
{
  i=0
  while [ "$i" -lt 40 ]; do
      i=$((i + 1))
      printf '2026-07-%02d 09:%02d:00 10.30.0.%d ERISIM randevu-modulu OK\n' \
          $(( (i % 25) + 1 )) $(( i % 60 )) $(( (i % 8) + 10 ))
  done
  printf '2026-07-26 10:00:00 10.30.0.14 ERISIM rontgen-arsivi ENGELLENDI\n'
  printf '2026-07-26 10:05:00 10.30.0.15 ERISIM stok-modulu OK\n'
  printf '2026-07-26 10:10:00 10.30.0.16 ERISIM hasta-kayit ENGELLENDI\n'
  printf '2026-07-26 10:15:00 10.30.0.17 ERISIM odeme-modulu OK\n'
  printf '2026-07-26 10:20:00 10.30.0.18 ERISIM yedek-alani ENGELLENDI\n'
} > "$TALEP/erisim.log"

# notlar.txt — TUZAKLAR:
#  (a) 5 satır ^TODO ile başlar (silinecek), 1 satırda TODO satır İÇİNDE geçer
#      (korunacak) → `^` çıpası şart.
#  (b) sube1 toplam 6 kez geçiyor ve BİR satırda İKİ kez → `s///g` şart.
cat > "$TALEP/notlar.txt" <<'EOF'
PatiVet destek notlari - kurtarma oncesi son surum
TODO randevu modulunun logu buyuyor, rotasyon kurulacak
sube1 sunucusu artik yok, kayitlar merkeze tasindi
Asi hatirlatma sms'leri sube1 numarasindan gidiyordu
TODO stok raporu icin yeni sablon hazirlanacak
Laboratuvar entegrasyonu test asamasinda
Yedekleme her gece 02:00'de calisiyordu
TODO eski yazici surucusu kaldirilacak
Kasa ekrani icin dokunmatik kalibrasyon yapildi
sube1 ve sube1 kayitlari ayni veritabanindaydi
Rontgen arsivi haftalik temizleniyor
TODO hasta kayit formuna alan eklenecek
Odeme terminali yeni firmware bekliyor
Bu satirda TODO kelimesi ortada geciyor, silinmemeli
sube1 yedegi harici diskte duruyor
Personel egitimi eylulde planlandi
TODO devir notu yazilacak
Klima bakimi yapildi
Kamera kayitlari 30 gun tutuluyor
Etiket yazicisi surucusu guncellendi
Randevu cakismalari icin uyari eklendi
Telefon santrali yeni numaraya tasindi
Ag sifresi degistirildi
Dosya paylasimi kapatildi
Arsiv diski yuzde 80 dolu
EOF

chown root:root "$TALEP"/*
chmod 0644 "$TALEP"/*

# Önceki danışmandan kalma YANLIŞ cevap dosyaları. Hepsi ayrı bir hata tipi.
printf 'toplam 51 kayit\n'                > "$ANS/01-adet.txt"
grep 'open' "$TALEP/talepler.csv"          > "$ANS/02-acik.txt" || true
printf 'yuksek 18\norta 16\ndusuk 16\n'   > "$ANS/03-oncelik.txt"
printf '1\n'                              > "$ANS/04-kod.txt"
printf '0\n'                              > "$ANS/05-kod.txt"
chown "$STUDENT:$STUDENT" "$ANS"/*.txt
chmod 0644 "$ANS"/*.txt

cp -p "$TALEP/talepler.csv" "$TALEP/erisim.log" "$TALEP/notlar.txt" "$ORIG/"

# =============================================================================
# TICKET 8 — Karışık log'u temizle ve otomatik rapor kur (kaynak: lab 007b)
# =============================================================================
install -d -o root -g root -m 0755 "$LOGLAR"
install -d -o "$STUDENT" -g "$STUDENT" -m 0755 "$IS"

# karisik.log — aşı/randevu kayıtları, iki tarih biçimi karışık, ayraç
# çevresinde 1-3 boşluk var. Geçersiz satırlar dört ayrı tuzak sınıfı:
#  (A) geçerli kaydın ÖNÜNDE serbest metin  -> `^` çıpası olmadan yakalanır
#  (B) fazladan alan (5 alan)               -> `.+$` fazla cömert
#  (C) bozuk/eksik IP
#  (D) tanınmayan seviye
# Ayrıca MESAJ alanında seviye adı ve IP geçen GEÇERLİ satırlar var: satır
# temelli sayım hem seviyeyi hem tekil IP'yi fazla sayar.
cat > "$LOGLAR/karisik.log" <<'EOF'
2026-07-01|INFO|10.40.0.11|kuduz asisi uygulandi
02/07/2026 | INFO | 10.40.0.12 | karma asi randevusu olusturuldu
2026-07-03|WARN|10.40.0.13|asi stogu azaldi
04/07/2026|ERROR|10.40.0.14|randevu kaydi yazilamadi
2026-07-05 | INFO | 10.40.0.11 | hatirlatma sms gonderildi
uyari: asagidaki kayit gec islendi 2026-07-06|INFO|10.40.0.15|kuduz asisi uygulandi
07/07/2026|WARN|10.40.0.16|randevu cakismasi tespit edildi
2026-07-08|INFO|10.40.0.12|karma asi uygulandi
09/07/2026 | ERROR | 10.40.0.13 | asi partisi dogrulanamadi
2026-07-10|INFO|10.40.0.17|randevu iptal edildi
11/07/2026|INFO|10.40.0.11|ERROR mesaji kullaniciya gosterildi
2026-07-12|WARN|10.40.0.18|sogutucu sicakligi yuksek
13/07/2026 | INFO | 10.40.0.14 | kuduz asisi uygulandi
2026-07-14|ERROR|10.40.0.19|stok dusumu basarisiz|ek-alan
15/07/2026|INFO|10.40.0.12|randevu onaylandi
2026-07-16|WARN|10.40.0.15|asi son kullanma tarihi yaklasti
17/07/2026 | ERROR | 10.40.0.11 | randevu servisi yanit vermedi
2026-07-18|INFO|10.40.0.16|karma asi randevusu olusturuldu
19/07/2026|TRACE|10.40.0.13|izleme kaydi
2026-07-20|INFO|10.40.0.17|hatirlatma sms gonderildi
21/07/2026 | WARN | 10.40.0.14 | asi stogu azaldi
2026-07-22|INFO|10.40.0.18|kuduz asisi uygulandi
23/07/2026|ERROR|10.40.0.12|asi kaydi cift girildi
2026-07-24|INFO|10.40.0.11|randevu notu eklendi
not: bu satir once serbest metin 25/07/2026|WARN|10.40.0.19|stok esigi asildi
2026-07-26|INFO|10.40.0.15|karma asi uygulandi
27/07/2026 | INFO | 10.40.0.13 | 10.40.0.99 adresinden istek geldi
2026-07-28|WARN|10.40.0.16|randevu yogunlugu yuksek
29/07/2026|ERROR|10.40.0.17|sms saglayicisi hata dondu
2026-07-30|INFO|10.40.0.14|kuduz asisi uygulandi
31/07/2026 | INFO | 10.40.0.12 | randevu tamamlandi
2026-08-01|WARN|10.40.0.11|asi buzdolabi kapisi acik kaldi
02/08/2026|ERROR|10.40.0.18|randevu servisi yeniden baslatildi
2026-08-03|INFO|10.40.0.19|karma asi randevusu olusturuldu
04/08/2026|INFO|10.40.0|adres alani eksik oktetli
2026-08-05|INFO||adres alani bos geldi
06/08/2026 | WARN | 10.40.0.15 | asi stogu kritik
2026-08-07|DEBUG|10.40.0.16|ayiklama kaydi
08/08/2026|INFO|10.40.0.13|randevu hatirlatmasi gonderildi
2026-08-09|ERROR|10.40.0.14|WARN esigi asildi ve islem durdu
10/08/2026 | INFO | 10.40.0.17 | kuduz asisi uygulandi
2026-08-11|WARN|10.40.0.18|sogutucu bakimi gerekiyor
12/08/2026|INFO|10.40.0.11|karma asi uygulandi
2026-08-13|INFO|10.40.0.12|randevu kaydi olusturuldu
EOF
chown root:root "$LOGLAR/karisik.log"
chmod 0644 "$LOGLAR/karisik.log"

# Önceki koşudan kalma YARIM iş: duzenli.log var ama tarihleri çevrilmemiş,
# gecerli.log eksik satırlı, gecersiz.log ve asi-ozet.txt hiç yok.
head -20 "$LOGLAR/karisik.log" > "$IS/duzenli.log"
head -6  "$LOGLAR/karisik.log" > "$IS/gecerli.log"
rm -f "$IS/gecersiz.log" "$IS/asi-ozet.txt" "$IS/metin-rapor.txt"
chown "$STUDENT:$STUDENT" "$IS"/*.log
chmod 0644 "$IS"/*.log

# klinik-ayarlar.conf — ^# yorumlar silinecek, satır içi # korunacak,
# /opt/eskisistem -> /srv/klinik/veri (bir satırda İKİ kez → g bayrağı şart),
# retention 45 olacak.
cat > "$CONF/klinik-ayarlar.conf" <<'EOF'
# PatiVet klinik yazilimi - ana ayar dosyasi
# kurtarma sonrasi elle duzenlendi
veri_yolu = /opt/eskisistem/veri
arsiv_yolu = /opt/eskisistem/arsiv
# eski kurulum notu: /opt/eskisistem kokunu degistirmeyi unutma
yedek_yolu = /opt/eskisistem/yedek ve /opt/eskisistem/gecici
retention = 15
# asagidaki satir gecici olarak kapatildi
sms_saglayici = yerel   # merkez sube uzerinden
log_seviyesi = INFO
# bakim penceresi cumartesi
bakim_penceresi = 02:00-04:00   # yerel saat
maksimum_baglanti = 64
EOF
chown root:root "$CONF/klinik-ayarlar.conf"
chmod 0644 "$CONF/klinik-ayarlar.conf"

cp -p "$LOGLAR/karisik.log" "$ORIG/"
cp -p "$CONF/klinik-ayarlar.conf" "$ORIG/"

# =============================================================================
# TICKET 9 — Dosya yerleşimi, bağlantılar, arşiv (kaynak: lab 008)
# =============================================================================
install -d -o root -g root -m 0755 /srv/klinik-arsiv
install -d -o root -g root -m 0755 /srv/klinik-yedek-kaynagi

# kayit1 + sert bağlantısı AYNI inode'u paylaşır → du iki kez saymaz.
# kayit2-kopya BAĞIMSIZ bir kopyadır → ayrı inode, ayrı blok.
dd if=/dev/urandom of=/srv/klinik-yedek-kaynagi/kayit1.txt bs=1K count=100 \
    status=none
ln /srv/klinik-yedek-kaynagi/kayit1.txt \
   /srv/klinik-yedek-kaynagi/kayit1-yedek.txt
dd if=/dev/urandom of=/srv/klinik-yedek-kaynagi/kayit2.txt bs=1K count=60 \
    status=none
cp /srv/klinik-yedek-kaynagi/kayit2.txt \
   /srv/klinik-yedek-kaynagi/kayit2-kopya.txt
dd if=/dev/urandom of=/srv/klinik-yedek-kaynagi/kayit3.txt bs=1K count=40 \
    status=none

install -d -o root -g root -m 0755 /srv/klinik-arsiv/kalici
install -d -o root -g root -m 0755 /srv/klinik-arsiv/gecici
printf 'kalici klinik kaydi - arsive girecek\n' \
    > /srv/klinik-arsiv/kalici/onemli.txt
printf 'arsiv kok dosyasi\n' > /srv/klinik-arsiv/dosya.txt
printf 'gecici is dosyasi - arsive GIRMEYECEK\n' \
    > /srv/klinik-arsiv/gecici/silinecek.txt
chmod 0644 /srv/klinik-yedek-kaynagi/* /srv/klinik-arsiv/dosya.txt \
           /srv/klinik-arsiv/kalici/onemli.txt \
           /srv/klinik-arsiv/gecici/silinecek.txt

# Yanlış yerde duran üç dosya. Hepsi student'ın ev dizininde.
cat > "$HOME_STUDENT/klinik-uygulama.log" <<'EOF'
2026-08-05T13:00:00 randevu servisi yeniden baslatildi
2026-08-05T13:05:00 asi modulu yuklendi
EOF
cat > "$HOME_STUDENT/randevu.conf" <<'EOF'
slot_dakika = 20
gunluk_kapasite = 48
hatirlatma = acik
EOF
cat > "$HOME_STUDENT/yedek-yardimcisi" <<'EOF'
#!/usr/bin/env bash
echo "yedek-yardimcisi: klinik verisi arsivleniyor"
EOF
chown "$STUDENT:$STUDENT" "$HOME_STUDENT/klinik-uygulama.log" \
      "$HOME_STUDENT/randevu.conf" "$HOME_STUDENT/yedek-yardimcisi"
chmod 0644 "$HOME_STUDENT/klinik-uygulama.log" "$HOME_STUDENT/randevu.conf"
chmod 0644 "$HOME_STUDENT/yedek-yardimcisi"

cp -a /srv/klinik-arsiv          "$ORIG/klinik-arsiv"
cp -a /srv/klinik-yedek-kaynagi  "$ORIG/klinik-yedek-kaynagi"

# =============================================================================
# TICKET 10 — Paket durumu (kaynak: lab 009, package management)
# =============================================================================
install -d -o root -g root -m 0755 "$PKGDIR"

# EPEL depo tanımı lab'ın data/ dizininden gelir, KAPALI olarak kurulur.
install -o root -g root -m 0644 "$LAB_DATA/epel.repo" /etc/yum.repos.d/epel.repo
dnf config-manager --set-disabled epel >/dev/null 2>&1 || true
dnf config-manager --set-disabled crb  >/dev/null 2>&1 || true

# Paketleri kaldır: lsof (EPEL değil ama kurulu olmayacak), bc, dpkg, ed.
dnf -y remove lsof bc dpkg ed epel-release >/dev/null 2>&1 || true
dnf -y remove zlib-ng libmd >/dev/null 2>&1 || true
rm -rf /var/lib/dpkg /var/lib/dpkg-* /etc/dpkg

# Kurulmadan incelenecek paket dosyaları image'dan gelir (.rpm ve .deb
# image kökündeki /opt/lab-assets altında, imzalı tarball'lar ise paket/ altında).
cp "$ASSETS_ROOT"/*.rpm "$ASSETS_ROOT"/*.deb "$PKGDIR/"
chown root:root "$PKGDIR"/*
chmod 0644 "$PKGDIR"/*

# /etc/vimrc: hem İÇERİK hem İZİN bozulur → rpm -V çıktısında 5 (md5) ve M.
# `dnf reinstall` bunu düzeltmez: /etc/vimrc paket içinde config (c) işaretli,
# rpm değiştirilmiş config'in üzerine yazmaz, .rpmnew bırakır.
cp -p "$ASSETS_ROOT/vimrc.pristine" /etc/vimrc
chown root:root /etc/vimrc
rm -f /etc/vimrc.rpmnew /etc/vimrc.rpmsave
printf '%s\n' '" PatiVet kurtarma sirasinda elle eklendi - paket disi degisiklik' \
    >> /etc/vimrc
chmod 0666 /etc/vimrc

# İlaç dozu hesaplayan script: hesabı kendisi yapmaz, bc'ye devreder.
cat > "$BINDIR/dozhesapla.sh" <<'EOF'
#!/usr/bin/env bash
# Kilo basina doz hesabi. Hesabi bc yapar.
# Kullanim: echo "12.5 * 2" | dozhesapla.sh
exec bc -l
EOF
chown root:root "$BINDIR/dozhesapla.sh"
chmod 0755 "$BINDIR/dozhesapla.sh"

cp -a "$PKGDIR" "$ORIG/paketler"

# =============================================================================
# TICKET 11 — Dört systemd işi (kaynak: lab 010, systemd)
# =============================================================================
install -d -o root -g root -m 0755 /opt/klinik/bin /var/lib/klinik

cat > /opt/klinik/bin/veritabani-hazirla <<'EOF'
#!/usr/bin/env bash
# Randevu veritabanini hazirlar ve biter (tek seferlik is).
mkdir -p /var/lib/klinik
sleep 1
touch /var/lib/klinik/.hazir
echo "veritabani hazir"
EOF

cat > /opt/klinik/bin/randevu-api <<'EOF'
#!/usr/bin/env bash
# Veritabani hazir degilse baslamaz.
if [ ! -e /var/lib/klinik/.hazir ]; then
    echo "randevu-api: veritabani hazir degil" >&2
    exit 1
fi
while :; do sleep 5; done
EOF

cat > /opt/klinik/bin/hatirlatici <<'EOF'
#!/usr/bin/env bash
# Randevu hatirlatmalarini gonderen surekli servis.
while :; do sleep 5; done
EOF

cat > /opt/klinik/bin/stok-raporu <<'EOF'
#!/usr/bin/env bash
# Stok durumunu periyodik raporlar.
while :; do sleep 5; done
EOF
chmod 0755 /opt/klinik/bin/*
chown root:root /opt/klinik/bin/*
rm -f /var/lib/klinik/.hazir

# veritabani-hazirla: Type YANLIŞ (simple), RemainAfterExit YOK.
cat > "$UNITS/veritabani-hazirla.service" <<'EOF'
[Unit]
Description=PatiVet randevu veritabani hazirlama

[Service]
Type=simple
ExecStart=/opt/klinik/bin/veritabani-hazirla

[Install]
WantedBy=multi-user.target
EOF

# randevu-api: veritabanina hicbir bagi yok (After/Requires eksik).
cat > "$UNITS/randevu-api.service" <<'EOF'
[Unit]
Description=PatiVet randevu API

[Service]
Type=simple
ExecStart=/opt/klinik/bin/randevu-api

[Install]
WantedBy=multi-user.target
EOF

# hatirlatici: ExecStart var olmayan yolu gosteriyor; Type de yanlis.
cat > "$UNITS/hatirlatici.service" <<'EOF'
[Unit]
Description=PatiVet randevu hatirlatici

[Service]
Type=oneshot
ExecStart=/opt/klinik/sbin/hatirlatici

[Install]
WantedBy=multi-user.target
EOF

# stok-raporu: ExecStart yanlis yol, User var olmayan kullanici.
cat > "$UNITS/stok-raporu.service" <<'EOF'
[Unit]
Description=PatiVet stok raporlayici

[Service]
Type=simple
ExecStart=/opt/klinik/bin/stokraporu
User=stokbot

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 "$UNITS"/veritabani-hazirla.service "$UNITS"/randevu-api.service \
           "$UNITS"/hatirlatici.service "$UNITS"/stok-raporu.service

systemctl daemon-reload
systemctl set-default rescue.target >/dev/null 2>&1 || true

# =============================================================================
# TICKET 12 — Log, cron ve saat (kaynak: lab 011)
# =============================================================================
# Kalıcı journal yok: /var/log/journal silindi, Storage= satırı yok.
rm -rf /etc/systemd/journald.conf.d
if [ -f /etc/systemd/journald.conf ]; then
    sed -i '/^[[:space:]]*Storage=/d' /etc/systemd/journald.conf
fi
rm -rf /var/log/journal
systemctl restart systemd-journald.service >/dev/null 2>&1 || true

# gozcu: lisans anahtarini arar, bulamazsa hata verir. Dosya BILEREK yok.
rm -f "$CONF/lisans.anahtar"
cat > /opt/klinik/bin/gozcu <<'EOF'
#!/usr/bin/env bash
# Klinik yazilimi lisansini dogrular.
LIS=/etc/klinik/lisans.anahtar
if [ ! -r "$LIS" ]; then
    echo "gozcu: lisans anahtari okunamiyor: $LIS" >&2
    exit 3
fi
echo "gozcu: lisans dogrulandi"
EOF
chmod 0755 /opt/klinik/bin/gozcu
chown root:root /opt/klinik/bin/gozcu

cat > "$UNITS/gozcu.service" <<'EOF'
[Unit]
Description=PatiVet lisans gozcusu

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/opt/klinik/bin/gozcu

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 "$UNITS/gozcu.service"
systemctl daemon-reload
systemctl disable gozcu.service >/dev/null 2>&1 || true
systemctl start gozcu.service >/dev/null 2>&1 || true

# cron: crond durdurulmuş+disabled, zamanlama yanlış (03:00), komut MUTLAK
# YOLSUZ. cron'un işlere verdiği PATH /usr/bin:/bin'dir; /usr/local/bin orada
# YOKTUR → komut bulunamaz ve iş sessizce hiç çalışmaz.
cat > "$BINDIR/yedekle" <<'EOF'
#!/usr/bin/env bash
printf '%s yedek alindi\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
    >> /var/log/klinik-yedek.log
EOF
chmod 0755 "$BINDIR/yedekle"
chown root:root "$BINDIR/yedekle"
rm -f /var/log/klinik-yedek.log

cat > /etc/cron.d/yedek <<'EOF'
# PatiVet gece yedegi - kurtarma sirasinda elle yazildi
0 3 * * * root yedekle
EOF
chmod 0644 /etc/cron.d/yedek
systemctl stop crond.service    >/dev/null 2>&1 || true
systemctl disable crond.service >/dev/null 2>&1 || true

# temizlik.service ve temizlik.timer HİÇ YOK. Program hazır.
cat > "$BINDIR/temizle" <<'EOF'
#!/usr/bin/env bash
printf '%s gecici dosyalar temizlendi\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
    >> /var/log/klinik-temizlik.log
EOF
chmod 0755 "$BINDIR/temizle"
chown root:root "$BINDIR/temizle"
rm -f /var/log/klinik-temizlik.log

# Saat dilimi yanlış, chrony sunucusuz ve kapalı.
timedatectl set-timezone America/New_York >/dev/null 2>&1 || \
    ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
if [ -f /etc/chrony.conf ]; then
    sed -i -E '/^[[:space:]]*(server|pool|peer)[[:space:]]/d' /etc/chrony.conf
fi
systemctl stop chronyd.service    >/dev/null 2>&1 || true
systemctl disable chronyd.service >/dev/null 2>&1 || true
timedatectl set-ntp false >/dev/null 2>&1 || true

# =============================================================================
# TICKET 13 — Erişim sertleştirme: SSH + GPG (kaynak: lab 012)
# =============================================================================
# Host anahtarları image'da üretilmiyor (reset tertemiz sunucu versin diye).
ssh-keygen -A >/dev/null

# sshd_config: ÖNCE sağlam sürüm, servis onunla başlatılır.
cat > "$SSHD_CONF" <<'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
StrictModes yes
UsePAM yes
Subsystem sftp /usr/libexec/openssh/sftp-server
EOF
chown root:root "$SSHD_CONF"
chmod 0600 "$SSHD_CONF"
sshd -t
systemctl enable sshd.service >/dev/null 2>&1 || true
systemctl restart sshd.service

# Servis ayağa kalktıktan SONRA config bozulur ve RESTART EDİLMEZ:
# sshd -t düşer, iki yönerge hâlâ yes, config mtime servis başlangıcından yeni.
# sleep: mtime ile servis başlangıcı AYNI saniyeye düşerse "yeniden başlatılmış"
# sınaması toleransa takılıp bedava geçer. Saniye çözünürlüğü + yuvarlama payı
# için 4 saniye bırakılır.
sleep 4
cat > "$SSHD_CONF" <<'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
StrictModes yes
UsePAM yes
MaxAuthTrys 4
Subsystem sftp /usr/libexec/openssh/sftp-server
EOF
chown root:root "$SSHD_CONF"
chmod 0600 "$SSHD_CONF"

# student'ın anahtar çifti var, authorized_keys BİLEREK yok.
rm -rf "$SSH_DIR"
install -d -o "$STUDENT" -g "$STUDENT" -m 0755 "$SSH_DIR"
su - "$STUDENT" -c "ssh-keygen -t ed25519 -N '' -q -f $SSH_DIR/id_ed25519"
chmod 0600 "$SSH_DIR/id_ed25519"
chmod 0644 "$SSH_DIR/id_ed25519.pub"
chown -R "$STUDENT:$STUDENT" "$SSH_DIR"
# Ev dizini gruba yazılabilir: StrictModes tuzağı. authorized_keys doğru
# izinde olsa bile giriş reddedilir, üstelik istemci sebebini söylemez.
chmod 0775 "$HOME_STUDENT"
chown "$STUDENT:$STUDENT" "$HOME_STUDENT"

# GPG tarafı: student'ın anahtarlığı hiç yok.
rm -rf "$HOME_STUDENT/.gnupg"
cat > "$HOME_STUDENT/gizli-hasta-notu.txt" <<'EOF'
Hasta sahibi iletisim listesi ozeti.
Kasa parolasi oda 3'teki zarfta.
Bu dosya sifrelenmeden diskte durmamali.
EOF
cat > "$HOME_STUDENT/devir-notu.txt" <<'EOF'
Yedek sunucu devir notu: kurtarma tamamlandi, uzaktan erisim sertlestirildi.
Sonraki hafta gelen danisman bu notu imzali olarak dogrulayabilir.
EOF
chown "$STUDENT:$STUDENT" "$HOME_STUDENT/gizli-hasta-notu.txt" \
      "$HOME_STUDENT/devir-notu.txt"
chmod 0644 "$HOME_STUDENT/gizli-hasta-notu.txt" "$HOME_STUDENT/devir-notu.txt"
rm -f "$HOME_STUDENT/gizli-hasta-notu.txt.gpg" \
      "$HOME_STUDENT/devir-notu.txt.sig" "$HOME_STUDENT/devir-notu.txt.asc" \
      "$ANS/06-paket.txt"

# Tedarikçi paketleri image'dan kopyalanır; setup ağa çıkıp anahtar üretmez.
# surum-b BİLEREK kurcalanmış: imzası artık tutmuyor.
install -d -o root -g root -m 0755 "$PAKET"
install -o root -g root -m 0644 "$ASSETS"/surum-a.tar.gz     "$PAKET/"
install -o root -g root -m 0644 "$ASSETS"/surum-a.tar.gz.sig "$PAKET/"
install -o root -g root -m 0644 "$ASSETS"/surum-b.tar.gz     "$PAKET/"
install -o root -g root -m 0644 "$ASSETS"/surum-b.tar.gz.sig "$PAKET/"
install -o root -g root -m 0644 "$ASSETS"/yayinci-acik.asc   "$PAKET/"

chmod 0400 "$ORIG"/*.csv "$ORIG"/*.log "$ORIG"/*.txt "$ORIG"/*.conf 2>/dev/null || true

# =============================================================================
# Kurulum doğrulaması — sıfır bedava OK
# =============================================================================
err=0
say() { echo "setup HATA: $*" >&2; err=1; }
st() { su - "$STUDENT" -c "$1" >/dev/null 2>&1; }

# Ticket 7
[ -s "$TALEP/talepler.csv" ] || say "talepler.csv bos"
grep -q 'ENGELLENDI' "$TALEP/erisim.log" || say "erisim.log ENGELLENDI icermiyor"
[ "$(grep -c '^TODO' "$TALEP/notlar.txt")" -eq 5 ] || \
    say "notlar.txt icinde 5 adet ^TODO bekleniyordu"
[ "$(grep -o 'sube1' "$TALEP/notlar.txt" | wc -l)" -eq 5 ] || \
    say "notlar.txt icinde 5 adet sube1 bekleniyordu"
[ "$(grep -c 'sube1.*sube1' "$TALEP/notlar.txt")" -ge 1 ] || \
    say "notlar.txt icinde bir satirda IKI sube1 gecen satir yok (g bayragi tuzagi)"

# Ticket 8
[ -s "$LOGLAR/karisik.log" ] || say "karisik.log bos"
[ -e "$IS/gecersiz.log" ] && say "gecersiz.log var olmamali"
[ -e "$IS/asi-ozet.txt" ] && say "asi-ozet.txt var olmamali"
[ -e "$BINDIR/rapor-uret" ] && say "rapor-uret var olmamali"

# Ticket 9
[ -e /etc/randevu/randevu.conf ] && say "randevu.conf zaten dogru yerde"
[ -e /var/log/randevu/klinik-uygulama.log ] && say "uygulama logu zaten dogru yerde"
[ -e "$BINDIR/yedek-yardimcisi" ] && say "yedek-yardimcisi zaten dogru yerde"

# Ticket 10
command -v lsof >/dev/null 2>&1 && say "lsof kurulu olmamali"
rpm -q bc   >/dev/null 2>&1 && say "bc kurulu olmamali"
rpm -q dpkg >/dev/null 2>&1 && say "dpkg kurulu olmamali"
dnf repolist --enabled 2>/dev/null | grep -qi '^epel' && say "epel etkin olmamali"
dnf repolist --enabled 2>/dev/null | grep -qi '^crb'  && say "crb etkin olmamali"
vimrc_v="$(rpm -V vim-common 2>/dev/null || true)"
[ -n "$vimrc_v" ] || say "rpm -V vim-common temiz dondu, /etc/vimrc bozulmamis"
case "$vimrc_v" in *5*) ;; *) say "rpm -V icerik (5) degisikligini gostermiyor: $vimrc_v" ;; esac
case "$vimrc_v" in *M*) ;; *) say "rpm -V izin (M) degisikligini gostermiyor: $vimrc_v" ;; esac
ls "$PKGDIR"/*.rpm >/dev/null 2>&1 || say "$PKGDIR icinde .rpm yok"
ls "$PKGDIR"/*.deb >/dev/null 2>&1 || say "$PKGDIR icinde .deb yok"

# Ticket 11
[ -e /var/lib/klinik/.hazir ] && say "veritabani hazir isareti var olmamali"
[ "$(systemctl get-default 2>/dev/null)" = "multi-user.target" ] && \
    say "varsayilan target zaten multi-user.target"

# Ticket 12
[ -d /var/log/journal ] && say "/var/log/journal var olmamali"
systemctl is-active crond.service   >/dev/null 2>&1 && say "crond aktif olmamali"
systemctl is-active chronyd.service >/dev/null 2>&1 && say "chronyd aktif olmamali"
systemctl is-enabled gozcu.service  >/dev/null 2>&1 && say "gozcu enabled olmamali"
[ -e "$UNITS/temizlik.timer" ] && say "temizlik.timer var olmamali"
[ -e /var/log/klinik-yedek.log ] && say "yedek logu var olmamali"
grep -q '^0 3 ' /etc/cron.d/yedek || say "cron isi 03:00 zamanlamasiyla kurulmadi"

# Ticket 13
[ "$(systemctl is-active sshd.service 2>/dev/null || true)" = "active" ] ||
    say "sshd.service aktif degil"
sshd -t >/dev/null 2>&1 && say "sshd -t temiz cikti, sozdizimi hatasi kurulmamis"
[ -e "$SSH_DIR/authorized_keys" ] && say "authorized_keys var olmamali"
[ -f "$SSH_DIR/id_ed25519.pub" ] || say "student anahtar cifti uretilemedi"
# NOT: `gpg --list-secret-keys` argümansız çağrıldığında BOŞ anahtarlıkta da 0
# döner. Kimlik verilmeden yapılan sınama sessizce hep "var" der.
st "gpg --batch --list-secret-keys bt@pativet.local" && \
    say "student'in gpg anahtari zaten var"
[ -e "$HOME_STUDENT/gizli-hasta-notu.txt.gpg" ] && say "sifreli dosya var olmamali"
[ -f "$PAKET/surum-a.tar.gz.sig" ] || say "$PAKET/surum-a.tar.gz.sig yok"
[ -f "$PAKET/yayinci-acik.asc" ] || say "$PAKET/yayinci-acik.asc yok"

[ "$err" -eq 0 ] || exit 1
echo "setup tamam: lab 901-gun-02b hazir (PatiVet Klinikleri / Yedek Sunucu Gunu)"
