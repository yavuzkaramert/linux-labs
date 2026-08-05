#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Lab 901-gun-02a'nın bozuk durumunu kurar. Idempotent.
#
# Bu bir TEKRAR labıdır: altı ayrı ticket, altı ayrı kaynak lab (001-006).
# Her ticket'ın kurulumu kendi bölümünde; hepsi TEK setup.sh çağrısında olur.
#
# Senaryo: PatiVet Klinikleri'nin yedek/DR sunucusu. Ana sunucu UPS arızasıyla
# gitti, bu makine yarım yapılandırılmış ve veriler kısmen kurtarılmış durumda.
# HER kriterin bozuk başlaması bu çerçevenin doğal sonucudur.
#
# DİKKAT:
#  * Ticket 1, 3 ve 4 aynı ağacı (/srv/klinik) paylaşır. /srv/klinik BAŞLANGIÇTA
#    0755 root:root'tur — Ticket 2 onu 2770 root:vetekip yapacak. Bu sayede
#    Ticket 1'in student-perspektifli kriterleri ilk saniyeden itibaren
#    ölçülebilir; Ticket 2 doğru çözülünce (student de vetekip üyesi) ölçülebilir
#    kalır.
#  * Ticket 4'ün ayar dosyaları /etc/klinik altındadır, /srv/klinik/ayarlar
#    DEĞİL. Sebep: Ticket 3 "ayarlar/ ile ayarlar-yedek/ birebir aynı olmalı"
#    diyor; Ticket 4 yerinde düzenleme istiyor. Aynı dosyada ikisi çakışırdı.
#  * Ticket 5 canlı süreçler başlatır (KLINIKPROC-* işaretli), Ticket 6 ayrı bir
#    servis süreci seti başlatır (randevu-* comm işaretli). İkisi teknik olarak
#    birbirine bağlı DEĞİL — biri argümanda, diğeri comm alanında taşınır.
#  * Ticket 4, 5 ve 6'nın çıktıları /srv/rapor altındadır, /srv/klinik'in
#    DIŞINDA. Ticket 2'nin 2770 sahiplik zinciri bu üç ticket'ı kilitlemesin.
#  * Setup başında eski süreçler öldürülür → `labctl reset` kalıntı bırakmaz.
set -euo pipefail

KLINIK=/srv/klinik
RAPOR=/srv/rapor
ORIG=/srv/.orig
CONFDIR=/etc/klinik
PROCDIR=/opt/klinik-procs
SVCDIR=/usr/local/lib/klinikprocs
LOGDIR=/var/log/klinik
LISTDIR=/etc/klinik-servis
BINDIR=/usr/local/bin
STUDENT=student

# comm alanı 15 karaktere kırpılır; en uzun ad randevu-kuyruk (14) — sığıyor.
SERVICES="randevu-web randevu-islem randevu-sms"

# --- 0. Önceki koşudan kalanları temizle ------------------------------------
pkill -9 -f 'KLINIKPROC'       2>/dev/null || true
pkill -9 -f "$PROCDIR"         2>/dev/null || true
pkill -9 -f 'gece-tarama-isi'  2>/dev/null || true
for svc in $SERVICES randevu-kuyruk; do
    pkill -9 -x "$svc" 2>/dev/null || true
done
sleep 1

rm -rf "$KLINIK" "$RAPOR" "$ORIG" "$CONFDIR" "$PROCDIR" "$SVCDIR" \
       "$LOGDIR" "$LISTDIR"
rm -f "$BINDIR/logozet.sh" "$BINDIR/durumkontrol.sh" "$BINDIR/gunsonu-rapor.sh"

# Ticket 2: derya/kaan/randevubot hiç yok, vetekip grubu hiç yok.
for u in derya kaan randevubot; do
    userdel -r "$u" >/dev/null 2>&1 || true
done
rm -rf /home/derya /home/kaan /home/randevubot
groupdel vetekip >/dev/null 2>&1 || true
gpasswd -d "$STUDENT" vetekip >/dev/null 2>&1 || true

# Çıktı dizini: Ticket 4, 5 ve 6 buraya yazar.
mkdir -p "$RAPOR"
chown "$STUDENT:$STUDENT" "$RAPOR"
chmod 0755 "$RAPOR"

# Değişmez referans kopyaları. check.sh beklenen değerleri BURADAN hesaplar.
mkdir -p "$ORIG"
chown root:root "$ORIG"
chmod 0700 "$ORIG"

# /srv/klinik: Ticket 2 bunu root:vetekip 2770 yapacak. Şimdilik yanlış.
mkdir -p "$KLINIK"
chown root:root "$KLINIK"
chmod 0755 "$KLINIK"

# oguz hesabı Ticket 2'nin verisi ama BURADA açılır: Ticket 1'in gizli dosyası
# "oguz döneminden gelen yedekten" geri yüklendiği için grup sahipliği oguz'da
# kalmış olacak. Sıralama zorunlu, mantık Ticket 2'ye ait.
userdel -r oguz >/dev/null 2>&1 || true
useradd -m -s /bin/bash oguz
cat > /home/oguz/devir-notlari.txt <<'EOF'
Ayrilmadan once devrettiklerim:
- rontgen arsivi /srv/klinik/buyuk-dosyalar altina tasinacak
- eski sube1 referanslari temizlenecek
EOF
chown oguz:oguz /home/oguz/devir-notlari.txt

# =============================================================================
# TICKET 1 — Kurtarılan dosyalarda karışık izin (kaynak: lab 001, permissions)
# =============================================================================
# Yedekleme sistemi izinleri taşımamış: biri fazla açık, biri fazla kapalı.
mkdir -p "$KLINIK/gizli" "$KLINIK/ortak" "$KLINIK/scriptler"

# 1.1-1.3: hasta sahibi iletişim bilgisi. Şu an dünyaya okunabilir (0644) VE
# grup sahipliği eski teknisyen oguz'da kalmış (yedek oguz dönemine ait).
# Kilitlenecek: sahiplik root:root, mod 0600. Çözüm dosyayı KENDİNE chown
# etmek değil — sistem verisi sistemde kalır.
cat > "$KLINIK/gizli/hastasahibi-iletisim.csv" <<'EOF'
sahip;telefon;adres;hasta
Nurten Aksoy;0532 000 1122;Bahcelievler Mah. 14/3;Pamuk (kedi)
Kerem Dogan;0505 000 3344;Yesilyurt Cad. 8;Roka (kopek)
Sibel Ertan;0542 000 5566;Camlik Sok. 21/7;Limon (muhabbet kusu)
Onur Balci;0533 000 7788;Ihlamur Mah. 3;Zeytin (kedi)
Hale Yavas;0555 000 9900;Denizkoy Cad. 45/2;Findik (tavsan)
EOF
chown root:oguz "$KLINIK/gizli/hastasahibi-iletisim.csv"
chmod 0644 "$KLINIK/gizli/hastasahibi-iletisim.csv"
chown root:root "$KLINIK/gizli"
chmod 0755 "$KLINIK/gizli"

# 1.4-1.5: haftalık notlar. root'a ait olduğu için student düzenleyemiyor.
# student SAHİP olacak, mod 644.
cat > "$KLINIK/ortak/haftalik-notlar.txt" <<'EOF'
PatiVet merkez sube - haftalik notlar
-------------------------------------
Pzt: asi stogu sayimi yapilacak
Sal: rontgen cihazi kalibrasyonu
Car: yedek sunucu devreye alma (bugun)
Per: tedarikci siparisi
Cum: haftalik rapor
EOF
chown root:root "$KLINIK/ortak/haftalik-notlar.txt"
chmod 0644 "$KLINIK/ortak/haftalik-notlar.txt"
chown root:root "$KLINIK/ortak"
chmod 0755 "$KLINIK/ortak"

# 1.6: yedek alma scripti — çalıştırma biti yok.
cat > "$KLINIK/scriptler/yedek-al.sh" <<'EOF'
#!/usr/bin/env bash
# Klinik verisinin gunluk yedegini alir (kurtarma sonrasi basit surum).
echo "yedek-al: /srv/klinik icerigi yedekleniyor"
EOF
chown root:root "$KLINIK/scriptler/yedek-al.sh"
chmod 0644 "$KLINIK/scriptler/yedek-al.sh"

# 1.7: dizinden GEÇEBİLME ayrı bir bit. scriptler/ 0750 root:root → student
# dosyayı çalıştırmak bir yana dizine giremiyor bile. Dosya izni ile dizin
# geçiş izni ayrı iki şey; ikisi de düzelmeden 1.6 da geçmez.
chown root:root "$KLINIK/scriptler"
chmod 0750 "$KLINIK/scriptler"

# =============================================================================
# TICKET 2 — Personel hesaplarını yedek sunucuda kur (kaynak: lab 002)
# =============================================================================
# vetekip grubu yok, derya/kaan/randevubot yok, /srv/klinik yanlış sahiplikte
# (yukarıda 0755 root:root olarak kuruldu).
#
# oguz (2 ay önce ayrılmış teknisyen, hesabı eski yedekten geri gelmiş) bu
# dosyanın başında açıldı — Ticket 1'in grup sahipliği ona bağlı.

# =============================================================================
# TICKET 3 — Kurtarılan klinik verisini düzenle (kaynak: lab 003, finding files)
# =============================================================================
mkdir -p "$KLINIK/muayene/kayitlar" "$KLINIK/rontgen" "$KLINIK/laboratuvar" \
         "$KLINIK/ayarlar/conf.d" "$KLINIK/ayarlar-yedek" \
         "$KLINIK/raporlar" "$KLINIK/gecici" "$KLINIK/bos-klasor"

# --- Kriter 1: 30 günden eski/yeni .log karışımı. Eskiler arsiv/'e taşınacak.
printf 'muayene kaydi - nisan doneme ait toplu kayit\n' \
    > "$KLINIK/muayene/nisan-muayene.log"
printf 'muayene kaydi - mayis doneme ait toplu kayit\n' \
    > "$KLINIK/muayene/kayitlar/mayis-muayene.log"
printf 'asi kaydi - eski donem\n' \
    > "$KLINIK/laboratuvar/asi-eski.log"
touch -d '85 days ago' "$KLINIK/muayene/nisan-muayene.log"
touch -d '60 days ago' "$KLINIK/muayene/kayitlar/mayis-muayene.log"
touch -d '45 days ago' "$KLINIK/laboratuvar/asi-eski.log"

printf 'muayene kaydi - bu hafta\n'  > "$KLINIK/muayene/guncel-muayene.log"
printf 'laboratuvar sonuclari - dun\n' > "$KLINIK/laboratuvar/tahlil.log"
touch -d '3 days ago'  "$KLINIK/muayene/guncel-muayene.log"
touch -d '1 day ago'   "$KLINIK/laboratuvar/tahlil.log"

# --- Kriter 2: sıfır byte artıklar + benzer isimli DOLU yemler ---
: > "$KLINIK/gecici/aktarim.tmp"
: > "$KLINIK/gecici/kilit.lock"
: > "$KLINIK/muayene/kayitlar/yarim-kayit.old"
: > "$KLINIK/laboratuvar/bozuk-tahlil.sql"
printf 'gecerli onbellek verisi\n'   > "$KLINIK/gecici/onbellek.dat"
printf 'INSERT INTO asi VALUES (1);\n' > "$KLINIK/laboratuvar/tahlil-saglam.sql"
# bos-klasor/ bilerek boş: "boş dizinlere dokunma" kriterinin kanıtı.

# --- Kriter 3: ayarlar/ ile ayarlar-yedek/ metadata+içerik birebir olmalı.
# Yedek `cp -r` ile alınmış: içerik aynı ama izin/sahiplik/mtime KAYIP.
cat > "$KLINIK/ayarlar/randevu.ayar" <<'EOF'
slot_dakika = 20
gunluk_kapasite = 48
EOF
cat > "$KLINIK/ayarlar/stok.ayar" <<'EOF'
kritik_esik = 5
sayim_gunu = pazartesi
EOF
cat > "$KLINIK/ayarlar/conf.d/asi-takvimi.ayar" <<'EOF'
kuduz = 12 ay
karma = 12 ay
EOF
chmod 0640 "$KLINIK/ayarlar/randevu.ayar"
chmod 0600 "$KLINIK/ayarlar/stok.ayar"
chmod 0644 "$KLINIK/ayarlar/conf.d/asi-takvimi.ayar"
chown root:root "$KLINIK/ayarlar/randevu.ayar" "$KLINIK/ayarlar/conf.d/asi-takvimi.ayar"
chown "$STUDENT:$STUDENT" "$KLINIK/ayarlar/stok.ayar"
touch -d '80 days ago' "$KLINIK/ayarlar/randevu.ayar"
touch -d '75 days ago' "$KLINIK/ayarlar/stok.ayar"
touch -d '70 days ago' "$KLINIK/ayarlar/conf.d/asi-takvimi.ayar"

cp -r "$KLINIK/ayarlar/." "$KLINIK/ayarlar-yedek/"
chown -R root:root "$KLINIK/ayarlar-yedek"
chmod -R u=rwX,go=rX "$KLINIK/ayarlar-yedek"
find "$KLINIK/ayarlar-yedek" -exec touch {} +

# --- Kriter 4: büyük röntgen dosyaları yanlış yerde, küçük geçiciler dağınık.
dd if=/dev/zero of="$KLINIK/rontgen/rontgen-ham-01.img" bs=1M count=3 \
    status=none
dd if=/dev/zero of="$KLINIK/rontgen/rontgen-ham-02.img" bs=1M count=2 \
    status=none
dd if=/dev/zero of="$KLINIK/rontgen/onizleme-01.dat"    bs=1K count=20 \
    status=none
dd if=/dev/zero of="$KLINIK/rontgen/onizleme-02.dat"    bs=1K count=100 \
    status=none

# --- Kriter 5: aylık csv raporlar. ozet.txt hepsinden YENİ → "en yeni dosya"
# ile "en yeni csv" aynı şey değil.
printf 'ay;muayene;asi\n2026-05;180;64\n'  > "$KLINIK/raporlar/2026-05.csv"
printf 'ay;muayene;asi\n2026-06;205;71\n'  > "$KLINIK/raporlar/2026-06.csv"
printf 'ay;muayene;asi\n2026-07;198;69\n'  > "$KLINIK/raporlar/2026-07.csv"
printf 'aylik ozet notu - en son bu dosyaya dokunuldu\n' \
    > "$KLINIK/raporlar/ozet.txt"
touch -d '50 days ago' "$KLINIK/raporlar/2026-05.csv"
touch -d '20 days ago' "$KLINIK/raporlar/2026-06.csv"
touch -d '2 days ago'  "$KLINIK/raporlar/2026-07.csv"
touch                  "$KLINIK/raporlar/ozet.txt"

# --- Kriter 6: scriptler 0644; biri alt dizinde saklı, notlar.txt yem ---
mkdir -p "$KLINIK/scriptler/bakim"
cat > "$KLINIK/scriptler/stok-uyari.sh" <<'EOF'
#!/usr/bin/env bash
echo "stok esigi altindaki kalemler listeleniyor"
EOF
cat > "$KLINIK/scriptler/bakim/arsivle.sh" <<'EOF'
#!/usr/bin/env bash
echo "eski kayitlar arsivleniyor"
EOF
cat > "$KLINIK/scriptler/notlar.txt" <<'EOF'
Bu bir script degil. Calistirma izni ALMAMALI.
EOF
chown -R root:root "$KLINIK/scriptler"
chmod 0644 "$KLINIK/scriptler/stok-uyari.sh" \
           "$KLINIK/scriptler/bakim/arsivle.sh" \
           "$KLINIK/scriptler/notlar.txt"
chmod 0750 "$KLINIK/scriptler/bakim"
# scriptler/ dizininin kendi modu Ticket 1.7'de 0750 olarak bırakıldı.
chmod 0750 "$KLINIK/scriptler"

# =============================================================================
# TICKET 4 — Log ve ayar analizi (kaynak: lab 004, text processing)
# =============================================================================
mkdir -p "$KLINIK/loglar" "$CONFDIR"

# erisim.log — üretimsel. İki TUZAK bilerek var:
#   (a) boyut alanı 500 olan 200'lük satırlar,
#   (b) yolunda /500 geçen satırlar.
# Naif `grep 500` ikisini de yakalar; doğru çözüm durum alanına bakar.
{
  # Toplam sayımlar bilerek BİRBİRİNDEN FARKLI: 11→9, 12→7, 13→5, 14→4,
  # 15→3, 16→2. Beraberlik olsaydı `sort -rn | head -5` sıralaması son-çare
  # satır karşılaştırmasına düşerdi; kriter kırılgan olurdu.
  ips="10.20.0.11 10.20.0.11 10.20.0.11 10.20.0.11 10.20.0.11
10.20.0.12 10.20.0.12 10.20.0.12 10.20.0.12
10.20.0.13 10.20.0.13 10.20.0.13 10.20.0.13
10.20.0.14 10.20.0.14 10.20.0.14
10.20.0.15 10.20.0.15
10.20.0.16"
  i=0
  for ip in $ips; do
    i=$((i + 1))
    printf '%s - derya [05/Aug/2026:09:%02d:00] "GET /randevu/liste" 200 1024\n' \
        "$ip" "$((i % 60))"
  done
  # tekil kullanıcı tuzağı: "-" kullanıcı sayılmaz.
  printf '10.20.0.11 - kaan [05/Aug/2026:09:31:00] "POST /randevu/olustur" 201 512\n'
  printf '10.20.0.12 - derya [05/Aug/2026:09:32:00] "GET /hasta/ara" 200 500\n'
  printf '10.20.0.13 - - [05/Aug/2026:09:33:00] "GET /saglik" 200 96\n'
  printf '10.20.0.14 - - [05/Aug/2026:09:34:00] "GET /saglik" 200 96\n'
  printf '10.20.0.11 - randevubot [05/Aug/2026:09:35:00] "GET /randevu/500" 200 800\n'
  printf '10.20.0.12 - kaan [05/Aug/2026:09:36:00] "GET /rapor/aylik" 200 500\n'
  # gerçek 500'ler
  printf '10.20.0.15 - derya [05/Aug/2026:09:37:00] "GET /rapor/uret" 500 210\n'
  printf '10.20.0.11 - kaan [05/Aug/2026:09:38:00] "POST /asi/kaydet" 500 187\n'
  printf '10.20.0.16 - randevubot [05/Aug/2026:09:39:00] "GET /stok/durum" 503 140\n'
  printf '10.20.0.12 - derya [05/Aug/2026:09:40:00] "GET /randevu/500" 500 305\n'
  printf '10.20.0.11 - oguz [05/Aug/2026:09:41:00] "GET /eski/panel" 404 88\n'
} > "$KLINIK/loglar/erisim.log"

# uygulama.log — TS|SEVIYE|mesaj. TUZAK: bazı satırların MESAJ gövdesinde
# seviye adı geçiyor; alan-farkındalığı olmayan `grep -c WARN` fazla sayar.
cat > "$KLINIK/loglar/uygulama.log" <<'EOF'
2026-08-05T09:00:01|INFO|randevu servisi basladi
2026-08-05T09:00:04|DEBUG|WARN esigi 90 olarak ayarlandi
2026-08-05T09:00:08|WARN|asi stogu kritik esigin altinda
2026-08-05T09:00:12|INFO|kurtarma sonrasi ilk senkron tamam
2026-08-05T09:00:15|ERROR|rontgen arsivine erisilemiyor
2026-08-05T09:00:19|WARN|yedek sunucu saat kaymasi 40ms
2026-08-05T09:00:23|INFO|gunluk ERROR butcesi 25
2026-08-05T09:00:27|DEBUG|onbellek anahtari hasta:4471
2026-08-05T09:00:31|WARN|randevu kuyrugu yuzde 80
2026-08-05T09:00:36|INFO|hasta kayit modulu yuklendi
2026-08-05T09:00:40|ERROR|tedarikci servisi zaman asimi
2026-08-05T09:00:44|WARN|disk kullanimi yuzde 78
2026-08-05T09:00:48|INFO|WARN kanali sessize alindi
2026-08-05T09:00:52|DEBUG|thread 7 bosta
2026-08-05T09:00:56|WARN|tahlil sonucu gecikti
2026-08-05T09:01:02|ERROR|asi kaydi yazilamadi
2026-08-05T09:01:06|INFO|saglik kontrolu gecti
2026-08-05T09:01:10|DEBUG|ERROR handler kaydedildi
2026-08-05T09:01:14|WARN|randevubot yanit vermiyor
2026-08-05T09:01:18|INFO|metrikler bosaltildi
EOF

# Loglar 0600 root:root → student sudo'suz okuyamıyor. Düzeltilecek.
chown root:root "$KLINIK/loglar/erisim.log" "$KLINIK/loglar/uygulama.log"
chmod 0600 "$KLINIK/loglar/erisim.log" "$KLINIK/loglar/uygulama.log"
chown root:root "$KLINIK/loglar"
chmod 0755 "$KLINIK/loglar"

# sistem.conf — debug açık, ESKİ SUNUCU referansları canlı. Yorum satırlarında
# da geçiyorlar: yorumlar KORUNACAK, yalnız canlı satırlar düzelecek.
cat > "$CONFDIR/sistem.conf" <<'EOF'
# PatiVet merkez sube - sistem ayarlari
# kurtarma notu: asagidaki debug satiri gecici olarak acilmisti
debug = true
# eski kurulumda su satir vardi: sunucu = eskisunucu.pativet.local
sunucu = eskisunucu.pativet.local
yedek_sunucu = eskisunucu.pativet.local
port = 8443
# debug = false   <- kurtarmadan onceki hali
zaman_asimi = 30
EOF
chown root:root "$CONFDIR/sistem.conf"
chmod 0644 "$CONFDIR/sistem.conf"

# cihazlar.list — boş satır, yorum satırı, satır içi yorum karışık.
cat > "$CONFDIR/cihazlar.list" <<'EOF'
# klinik cihaz envanteri

rontgen-01
ultrason-02   # muayene odasi 2
# devre disi: otoklav-eski

santrifuj-03
biyokimya-04    # laboratuvar
mikroskop-05
EOF
chown root:root "$CONFDIR/cihazlar.list"
chmod 0644 "$CONFDIR/cihazlar.list"
chmod 0755 "$CONFDIR"

# Referans kopyaları: check.sh yorum bloklarını ve sayımları buradan çıkarır.
cp -p "$CONFDIR/sistem.conf"   "$ORIG/sistem.conf"
cp -p "$CONFDIR/cihazlar.list" "$ORIG/cihazlar.list"
cp -p "$KLINIK/loglar/erisim.log"   "$ORIG/erisim.log"
cp -p "$KLINIK/loglar/uygulama.log" "$ORIG/uygulama.log"
chmod 0400 "$ORIG"/*

# =============================================================================
# TICKET 5 — Başıboş süreçler (kaynak: lab 005, processes)
# =============================================================================
mkdir -p "$PROCDIR"

# toplu: gece toplu işi. Çok düşük nice ile başlar, ÖLDÜRÜLMEMELİ, yavaşlatılmalı.
cat > "$PROCDIR/toplu.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = KLINIKPROC isareti
while :; do
    sleep 5
done
EOF

# asili: TERM'i trap ile YOK SAYAR. Kibar sinyal yetmez, KILL şart.
cat > "$PROCDIR/asili.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = KLINIKPROC isareti. TERM yok sayilir; sadece KILL bu sureci bitirir.
trap '' TERM
trap '' INT
trap '' HUP
while :; do
    sleep 5
done
EOF

# sahte: CPU'yu boşuna meşgul eder, comm alanında sahte bir çekirdek-thread
# ismiyle görünür. TERM ile ölür.
cat > "$PROCDIR/sahte.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = KLINIKPROC isareti
while :; do
    i=0
    while [ "$i" -lt 40000 ]; do i=$((i + 1)); done
    sleep 0.2
done
EOF

# gürültü: KLINIKPROC işareti YOK. Adı "toplu"ya benziyor → yanlış hedef tuzağı.
cat > "$PROCDIR/gurultu.sh" <<'EOF'
#!/usr/bin/env bash
while :; do
    sleep 7
done
EOF

chmod 0755 "$PROCDIR"/*.sh
chown root:root "$PROCDIR"/*.sh

# nice -n -15 root tarafından uygulanır, yetki student'a düşer. Nice değeri
# fork/exec üzerinden miras kalır → süreç student'a ait ve nice -15.
nice -n -15 su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash $PROCDIR/toplu.sh KLINIKPROC-toplu >/dev/null 2>&1 </dev/null &"

# setsid → yeni oturum, denetim terminali yok → setup bitince SIGHUP gelmez.
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash $PROCDIR/asili.sh KLINIKPROC-asili >/dev/null 2>&1 </dev/null &"

# exec -a ile sahte bir çekirdek-thread ismi takar; işaret argümanda kalır.
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash -c 'exec -a kworker/u8:5-events nice -n 19 bash $PROCDIR/sahte.sh KLINIKPROC-sahte' >/dev/null 2>&1 </dev/null &"

# gürültü: KLINIKPROC içermeyen sahte süreçler (yanlış süreci öldürme tuzağı).
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash $PROCDIR/gurultu.sh gece-tarama-isi >/dev/null 2>&1 </dev/null &"
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup sleep 5151 >/dev/null 2>&1 </dev/null &"
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup sleep 5152 >/dev/null 2>&1 </dev/null &"

# =============================================================================
# TICKET 6 — Gün sonu özet scriptleri (kaynak: lab 006, shell scripting)
# =============================================================================
# Bu ticket'ın servis işaretleri Ticket 5'in KLINIKPROC-* süreçleriyle teknik
# olarak BAĞLI DEĞİL — ayrı bir set, comm (süreç adı) üzerinden taşınır.
mkdir -p "$LOGDIR" "$LISTDIR"
chown root:root "$LOGDIR" "$LISTDIR"
chmod 0755 "$LOGDIR" "$LISTDIR"

# Sayımlar bilerek FARKLI: INFO 16, WARN 10, ERROR 7, DEBUG 9.
# TUZAK: 5 satırın MESAJ GÖVDESİNDE bir seviye adı geçiyor. Alan-farkındalığı
# olmayan `grep -c ERROR` fazla sayar → kriter düşer.
cat > "$LOGDIR/gunsonu.log" <<'EOF'
2026-08-05T17:00:01|INFO|randevu-web gun sonu moduna gecti
2026-08-05T17:00:03|DEBUG|WARN esigi 90 olarak ayarlandi
2026-08-05T17:00:05|INFO|islem havuzu boyutu 8
2026-08-05T17:00:08|WARN|yanit suresi 200ms uzerinde
2026-08-05T17:00:11|INFO|ust servisten ERROR sonrasi yeniden deneniyor
2026-08-05T17:00:14|ERROR|rontgen diski neredeyse dolu
2026-08-05T17:00:17|INFO|onbellek isinma tamamlandi
2026-08-05T17:00:20|WARN|sms modulu icin DEBUG gunlugu acildi
2026-08-05T17:00:24|INFO|randevu 8812 41ms icinde islendi
2026-08-05T17:00:27|DEBUG|dispatch icine giriliyor
2026-08-05T17:00:30|WARN|baglanti havuzu yuzde 80
2026-08-05T17:00:33|INFO|gunluk ERROR butcesi 25
2026-08-05T17:00:36|ERROR|tedarikci servisi 5s sonra zaman asimi
2026-08-05T17:00:39|DEBUG|onbellek anahtari hasta:4471
2026-08-05T17:00:42|INFO|oturum deposuna baglanildi
2026-08-05T17:00:45|WARN|randevu 8813 icin yeniden deneme sayisi 2
2026-08-05T17:00:48|INFO|randevu 8813 37ms icinde islendi
2026-08-05T17:00:51|ERROR|INFO kanali birikimi asildi
2026-08-05T17:00:54|INFO|yapilandirma diskten yeniden yuklendi
2026-08-05T17:00:57|DEBUG|gc duraklamasi 12ms
2026-08-05T17:01:00|WARN|disk kullanimi yuzde 78
2026-08-05T17:01:04|INFO|randevu 8814 52ms icinde islendi
2026-08-05T17:01:08|ERROR|hasta oturumu 4471 yazilamadi
2026-08-05T17:01:12|INFO|kuyruk derinligi 3
2026-08-05T17:01:16|WARN|asi tablosunda 1.4s yavas sorgu
2026-08-05T17:01:20|INFO|randevu 8815 44ms icinde islendi
2026-08-05T17:01:23|DEBUG|soket tamponu 64k
2026-08-05T17:01:26|INFO|saglik kontrolu gecti
2026-08-05T17:01:29|WARN|onbellek isabetsizlik orani 0.42
2026-08-05T17:01:33|INFO|randevu 8816 39ms icinde islendi
2026-08-05T17:01:36|DEBUG|ERROR handler kaydedildi
2026-08-05T17:01:39|ERROR|randevu-kuyruk yanit vermiyor
2026-08-05T17:01:42|INFO|metrikler bosaltildi
2026-08-05T17:01:45|WARN|islem birimi yeniden baslatma talebi
2026-08-05T17:01:49|INFO|randevu 8817 48ms icinde islendi
2026-08-05T17:01:52|DEBUG|thread 7 bosta
2026-08-05T17:01:56|INFO|gecelik rotasyon planlandi
2026-08-05T17:02:00|WARN|saat kaymasi 40ms
2026-08-05T17:02:04|ERROR|gun sonu raporu uretilemedi
2026-08-05T17:02:08|DEBUG|bosaltma araligi 30s
2026-08-05T17:02:12|DEBUG|kapanis kancasi kaydedildi
2026-08-05T17:02:16|INFO|gun sonu kapanisi tamam
EOF
chown root:root "$LOGDIR/gunsonu.log"
chmod 0644 "$LOGDIR/gunsonu.log"

# Okunamayan log: `[ -f ]` ile `[ -r ]` farkını zorlayan TEK nokta. Silme.
cat > "$LOGDIR/denetim.log" <<'EOF'
2026-08-05T16:59:00|INFO|denetim kanali acildi
2026-08-05T16:59:30|WARN|konsoldan root girisi
EOF
chown root:root "$LOGDIR/denetim.log"
chmod 0600 "$LOGDIR/denetim.log"

# Bozuk logozet.sh. Kusurları (her biri ayrı kriter kırar): shebang yok ·
# çalıştırma izni yok · $1 yok sayılıyor · varsayılan alan ayırıcısı · çıktı
# biçimi SEVIYE:sayı değil · hata mesajı stdout'a gidiyor · kontrol iş bittikten
# SONRA yapılıyor · -r kontrolü hiç yok · her yolda exit 0 · other-yazma açık.
cat > "$BINDIR/logozet.sh" <<'EOF'
# gun sonu raporu icin log ozeti - devam edilecek
LOG=/var/log/klinik/gunsonu.log
awk '{print $2}' $LOG | sort | uniq -c
if [ ! -f "$LOG" ]; then
  echo "logozet: dosya yok"
fi
exit 0
EOF
chown root:root "$BINDIR/logozet.sh"
chmod 0666 "$BINDIR/logozet.sh"

# Servis süreçleri. randevu-kuyruk BİLEREK yok: listede var, süreci yok →
# [FAIL] → DEGRADED. Bu bir TUZAK, hata değil. Gerçek `sleep` binary'si servis
# adıyla kopyalanır → comm = servis adı, `pgrep -x randevu-web` bulur.
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
# bilerek var. randevu-eski süreci YOK; yorum atlanmazsa fazladan [FAIL].
cat > "$LISTDIR/servisler.list" <<'EOF'
# gun sonu raporunda izlenen klinik servisleri
randevu-web
randevu-islem

randevu-kuyruk
#randevu-eski
randevu-sms
EOF
chown root:root "$LISTDIR/servisler.list"
chmod 0644 "$LISTDIR/servisler.list"

sleep 1

# =============================================================================
# Kurulum doğrulaması — sıfır bedava OK, her süreç gerçekten ayakta
# =============================================================================
for mark in KLINIKPROC-toplu KLINIKPROC-asili KLINIKPROC-sahte; do
    if ! pgrep -f "$mark" >/dev/null 2>&1; then
        echo "setup HATA: $mark sureci baslatilamadi" >&2
        exit 1
    fi
done

TPID="$(pgrep -f 'KLINIKPROC-toplu' | head -1)"
TNICE="$(ps -o ni= -p "$TPID" | tr -d '[:space:]')"
if [ "$TNICE" -ge 10 ]; then
    echo "setup HATA: KLINIKPROC-toplu nice $TNICE — 10'un altinda olmaliydi" >&2
    exit 1
fi

for svc in $SERVICES; do
    if ! pgrep -x "$svc" >/dev/null 2>&1; then
        echo "setup HATA: $svc sureci baslatilamadi (comm eslesmesi yok)" >&2
        exit 1
    fi
done
if pgrep -x randevu-kuyruk >/dev/null 2>&1; then
    echo "setup HATA: randevu-kuyruk calisiyor — calismamaliydi" >&2
    exit 1
fi
N="$(ps -eo comm | grep -c '^randevu-' || true)"
if [ "$N" -ne 3 ]; then
    echo "setup HATA: comm alaninda 3 randevu-* sureci bekleniyordu, $N bulundu" >&2
    exit 1
fi

if id derya >/dev/null 2>&1 || id kaan >/dev/null 2>&1; then
    echo "setup HATA: derya/kaan silinmeliydi, duruyor" >&2
    exit 1
fi
if ! id oguz >/dev/null 2>&1; then
    echo "setup HATA: oguz hesabi kurulamadi" >&2
    exit 1
fi
if getent group vetekip >/dev/null 2>&1; then
    echo "setup HATA: vetekip grubu silinmeliydi, duruyor" >&2
    exit 1
fi

echo "setup tamam: lab 901-gun-02a hazir (PatiVet Klinikleri / Yedek Sunucu Gunu)"
