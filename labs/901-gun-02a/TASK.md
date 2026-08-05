Lab 901-gun-02a — Yedek Sunucu Gunu: Bolum A
============================================

Hikâye
------

PatiVet Klinikleri kucuk bir veteriner klinik zinciri. Merkez subenin
sunucu odasinda UPS arizasi cikti, ana sunucu gitti. Elindeki makine
yedek/DR sunucusu: ayakta ama yarim yapilandirilmis, veriler kismen
kurtarilmis. Bugun bu makineyi uretime alinabilir hale getiriyorsun.

Bu bir tekrar labi. Buradaki alti ticket'in hepsini daha once gordun,
001'den 006'ya kadar. Yeni bir konu yok, yeni bir komut yok. Yalnizca
hepsi ayni kurtarma operasyonunun icinde, arka arkaya geliyor.

Onerilen sira ticket numarasi sirasidir (1'den 6'ya). Zorunlu degil,
her ticket kendi basina degerlendirilir; ama hikâye bu sirada en
tutarli ve bazi ticketlar bir oncekinin kurdugu ortami kullanir.

Sureyi kendin tut: baslangic ve bitis saatini JOURNAL.md'ye elle yaz.
Script senin yerine saat tutmuyor.

Ortam
-----

Ana veri dizini: /srv/klinik
Cikti dizini:    /srv/rapor      (Ticket 4, 5 ve 6 buraya yazar)
Ayar dizini:     /etc/klinik     (Ticket 4)
Klinik grubu:    vetekip
Toplam kriter:   47

Ticket haritasi
---------------

    Ticket 1   Kurtarilan dosyalarda karisik izin   kaynak 001    7
    Ticket 2   Personel hesaplarini kur             kaynak 002   10
    Ticket 3   Kurtarilan klinik verisini duzenle   kaynak 003    6
    Ticket 4   Log ve ayar analizi                  kaynak 004    7
    Ticket 5   Basibos surecler                     kaynak 005    5
    Ticket 6   Gun sonu ozet scriptleri             kaynak 006   12

Ticket 1 — Kurtarilan dosyalarda karisik izin
---------------------------------------------

Kaynak: lab 001, 7 kriter

Yedekten geri yuklenen dosyalarin izni tutarsiz cikmis: biri olmasi
gerekenden fazla acik, digeri olmasi gerekenden fazla kapali.
Yedekleme sistemi izinleri guvenilir sekilde tasimamis.

1. /srv/klinik/gizli/hastasahibi-iletisim.csv hasta sahiplerinin
   telefon ve adres bilgisini tutuyor. Su an dunyaya okunabilir ve
   grup sahipligi eski teknisyenin uzerinde kalmis. Kilitle:
   sahiplik root:root OLACAK, mod 600 olacak, student dosyayi
   okuyamayacak. Cozum dosyayi KENDINE chown etmek degil.

2. /srv/klinik/ortak/haftalik-notlar.txt root'a ait oldugu icin
   student duzenleyemiyor. student sahip olacak, mod 644 olacak.

3. /srv/klinik/scriptler/yedek-al.sh calistirma bitini kaybetmis.
   student bu scripti calistirabilecek.

4. Bir dizinden gecebilmek ile icindeki dosyayi okumak ayri iki
   izindir. /srv/klinik/scriptler dizinine student giremiyor bile.
   Dosya iznini duzeltmek tek basina yetmez.

Ticket 2 — Personel hesaplarini yedek sunucuda kur
---------------------------------------------------

Kaynak: lab 002, 10 kriter

Personel listesi eski sunucudan kurtarildi ama hesaplar bu makinede
henuz yok. Eski yedekte ayrilmis bir calisanin hesabi da hâlâ
geliyor. Klinik ortak veri dizini de yanlis izinle geldi.

1. vetekip grubunu ac, GID'i tam 4600 olsun.

2. derya ve kaan kullanicilarini ac: ev dizinleri /home/<isim>,
   sahibi kendileri, kabuklari /bin/bash.

3. Ikisinin de birincil grubu kendi adiyla ayni olsun; vetekip
   ikincil (supplementary) grup olarak eklensin.

4. randevubot servis hesabini ac: kabugu nologin, vetekip uyesi.

5. randevubot'un ev dizini OLUSMASIN.

6. /srv/klinik dizini var ama yanlis sahiplik ve izinle. Sahibi
   root:vetekip, modu tam 2770 olmali.

7. derya /srv/klinik icinde dosya acabilmeli; actigi dosya otomatik
   olarak vetekip grubuna dusmeli; kaan da o dosyaya yazabilmeli.

8. oguz gecen ay ayrildi. Hesabini ve /home/oguz dizinini kaldir.

9. derya wheel grubunda OLMAMALI.

10. Kendini (student) de vetekip grubuna ekle. 2770 bir dizinde
    "other" hicbir sey goremez; sen de bu grupta olmazsan Ticket 1,
    3 ve 4'te kendi yetkinle calisamazsin.

Ticket 3 — Kurtarilan klinik verisini duzenle
----------------------------------------------

Kaynak: lab 003, 6 kriter

/srv/klinik yedekten dagink geri geldi: kismi kopyalar, sifir
byte'lik bozuk dosyalar, yanlis yerlesmis buyuk dosyalar var.
Hepsi bu dizinin altinda.

1. 30 gunden eski .log dosyalarini (muayene kayitlari)
   /srv/klinik/arsiv/ altina tasi. Yeniler yerinde kalsin. Hicbiri
   silinmesin.

2. 0 byte'lik artik dosyalari sil. Dolu dosyalara ve bos dizinlere
   dokunma.

3. /srv/klinik/ayarlar-yedek/ dizini /srv/klinik/ayarlar/ ile
   metadata ve icerik olarak birebir ayni olmali. Su an degil.

4. Buyuk rontgen goruntulerini (1 MB'den buyuk)
   /srv/klinik/buyuk-dosyalar/ altinda topla; kucuk onizleme
   dosyalarini /srv/klinik/gecici/ altinda topla.

5. /srv/klinik/raporlar/guncel adinda sembolik link uret; raporlar
   icindeki en guncel .csv dosyasini gostersin. En yeni dosya ile en
   yeni csv ayni sey degil, dikkat.

6. /srv/klinik/scriptler/ altindaki (alt dizinler dâhil) tum .sh
   dosyalari student tarafindan calistirilabilir olsun. .sh olmayan
   dosyalarda calistirma biti OLMASIN.

Ticket 4 — Log ve ayar analizi
-------------------------------

Kaynak: lab 004, 7 kriter

Klinik yazilaminin erisim ve uygulama loglari ile ayar dosyasi
karisik; birkac analiz isteniyor.

Veri:

    /srv/klinik/loglar/erisim.log
    /srv/klinik/loglar/uygulama.log
    /etc/klinik/sistem.conf
    /etc/klinik/cihazlar.list

1. Loglari su an sudo'suz okuyamiyorsun. Izin duzeltmesiyle
   sudo'suz okunabilir hale getir.

2. /srv/rapor/hatalar.log uret: erisim.log icinde durum kodu tam 500
   olan satirlar, orijinal siralari korunarak. Boyut alani 500 olan
   ve yolunda /500 gecen satirlar tuzaktir.

3. /srv/rapor/en-cok-istek.txt uret: en cok istek yapan 5 IP, azalan
   sirada, her satir "sayi IP" biciminde.

4. /srv/rapor/tekil-kullanici.txt uret: tek satir, yalniz sayi,
   dogru tekil kullanici sayisi. "-" bir kullanici degildir.

5. /srv/rapor/uyarilar.tsv uret: uygulama.log icindeki yalniz WARN
   seviyeli satirlar, TAB ayrali iki alan (zaman damgasi ve mesaj),
   orijinal sirada. Mesaj govdesinde gecen seviye adlari tuzaktir.

6. /etc/klinik/sistem.conf dosyasini yerinde duzenle: debug kapali
   olacak, aktif satirlarda eskisunucu referansi kalmayacak, yorum
   satirlari aynen KORUNACAK.

7. /srv/rapor/cihazlar-temiz.txt uret: cihazlar.list icinden yorum
   satirlari ve bos satirlar cikarilmis hali. Satir ici yorumlara
   dokunma.

Ticket 5 — Basibos surecler
----------------------------

Kaynak: lab 005, 5 kriter

Kurtarma sirasinda baslatilan test surecleri hâlâ ayakta, biri de
askida kalmis. Ucu de KLINIKPROC ile isaretli. Isaretsiz benzer
isimli surecler tuzaktir, onlara dokunma.

1. /srv/rapor/surecler.txt uret: KLINIKPROC ile baslayan surecleri
   PID ve komut satiriyla listele. Kendi arama komutunun satiri
   listeye karismasin.

2. KLINIKPROC-asili oldurulecek, surec tablosunda kalmayacak. Bu
   surec kibar sinyali yok sayiyor.

3. KLINIKPROC-sahte oldurulecek, surec tablosunda kalmayacak. Surec
   adi alaninda kendini baska bir sey gibi gosteriyor.

4. KLINIKPROC-toplu calismaya devam edecek; nice degeri 10 veya
   daha buyuk olacak sekilde ayarlanacak. Bu surec oldurulmeyecek.

5. /srv/rapor/toplu-nice.txt uret: tek satir, KLINIKPROC-toplu'nun
   gercek nice degeriyle ayni sayi.

Ticket 6 — Gun sonu ozet scriptleri
------------------------------------

Kaynak: lab 006, 12 kriter

Kurtarma gununu uc kucuk scriptle kapatiyorsun. Ucu de
/usr/local/bin altinda duracak, student tarafindan tam yol
yazmadan ve sudo'suz calistirilabilecek, "other" icin yazma biti
kapali olacak.

Veri:

    /var/log/klinik/gunsonu.log
    /var/log/klinik/denetim.log     (var ama okunamiyor)
    /etc/klinik-servis/servisler.list

1. logozet.sh — bir log dosyasi yolu alir ve seviye sayimlarini
   SEVIYE:sayi biciminde basar, cikis kodu 0. Argumansiz cagrilirsa
   stdout bos, stderr dolu, cikis kodu 2. Dosya yoksa veya
   okunamiyorsa cikis kodu 3 ve stdout bos. Mesaj govdesinde gecen
   seviye adlari tuzaktir.

2. durumkontrol.sh — argument olarak verilen klinik servislerinin
   durumunu kontrol eder. Ayakta olan icin "[OK] ad PID", olmayan
   icin "[FAIL] ad" basar; sira argument sirasidir. Hepsi ayaktaysa
   cikis 0, eksik varsa 1, argumansiz cagrilirsa 2. Kendi arama
   sureci ciktiya karismamali, yazilan PID'ler gercek olmali.

3. gunsonu-rapor.sh — argumansiz calisir, servisler.list icindeki
   servisleri ve gunsonu.log seviye sayimlarini kullanarak
   /srv/rapor/gunsonu.txt uretir. Ilk satir HEALTHY veya DEGRADED
   olur, cikis kodu buna gore 0 veya 1'dir. Iki kez calistirildiginda
   dosya buyumez veya tekrarlamaz.

Not: servisler.list icindeki randevu-kuyruk BILEREK ayakta degil.
Bu bir tuzak, hata degil. Yorum satirlari ve bos satirlar
atlanmalidir.

Kabul kriterleri
----------------

[ ] hastasahibi-iletisim.csv sahipligi root:root
[ ] hastasahibi-iletisim.csv modu 600
[ ] student hastasahibi-iletisim.csv'yi okuyamiyor
[ ] haftalik-notlar.txt student'a ait ve modu 644
[ ] student haftalik-notlar.txt'yi duzenleyebiliyor
[ ] student yedek-al.sh'i calistirabiliyor
[ ] scriptler/ dizini student icin gecilebilir
[ ] vetekip grubu var, GID 4600
[ ] derya ve kaan var, ev dizini ve kabuk dogru
[ ] derya/kaan birincil grubu kendi adi, vetekip ikincil
[ ] randevubot nologin kabuklu ve vetekip uyesi
[ ] randevubot'un ev dizini yok
[ ] /srv/klinik root:vetekip ve modu 2770
[ ] setgid davranisi calisiyor: derya acar, kaan yazar
[ ] oguz hesabi ve /home/oguz kaldirilmis
[ ] derya wheel grubunda degil
[ ] student vetekip grubuna eklenmis
[ ] eski .log dosyalari arsiv/ altinda, yeniler yerinde
[ ] 0 byte artiklar silindi, dolu dosya ve bos dizin duruyor
[ ] ayarlar-yedek/ metadata ve icerik olarak birebir kopya
[ ] buyuk ve kucuk rontgen dosyalari dogru dizinde
[ ] raporlar/guncel en yeni csv'ye isaret ediyor
[ ] tum .sh calistirilabiliyor, digerlerinde x biti yok
[ ] student iki logu da sudo'suz okuyabiliyor
[ ] hatalar.log yalniz durum 500 satirlarini iceriyor
[ ] en-cok-istek.txt 5 IP'yi azalan sirada veriyor
[ ] tekil-kullanici.txt dogru tekil kullanici sayisini veriyor
[ ] uyarilar.tsv yalniz WARN satirlarini TAB ayrali veriyor
[ ] sistem.conf: debug kapali, eski sunucu temiz, yorum korunmus
[ ] cihazlar-temiz.txt yorum ve bos satirdan arindirilmis
[ ] surecler.txt KLINIKPROC sureclerini PID ve komutla listeliyor
[ ] KLINIKPROC-asili surec tablosunda yok
[ ] KLINIKPROC-sahte surec tablosunda yok
[ ] KLINIKPROC-toplu calisiyor ve nice >= 10
[ ] toplu-nice.txt gercek nice degeriyle ayni
[ ] logozet.sh seviye sayimlarini dogru basiyor, cikis 0
[ ] logozet.sh argumansiz: stdout bos, stderr dolu, cikis 2
[ ] logozet.sh olmayan dosyada cikis 3
[ ] logozet.sh okunamayan dosyada cikis 3
[ ] durumkontrol.sh dogru bicim ve sirada cikti veriyor
[ ] durumkontrol.sh cikis kodlari 0/1/2 dogru
[ ] durumkontrol.sh gercek PID'leri basiyor
[ ] gunsonu-rapor.sh DEGRADED durumunu dogru raporluyor
[ ] gunsonu.txt servis durumlari ve seviye sayimlarini iceriyor
[ ] gunsonu-rapor.sh idempotent
[ ] gunsonu-rapor.sh HEALTHY durumunu dogru raporluyor
[ ] uc script pathless calisiyor, other-yazma biti kapali

Kontrol
-------

Ciktinin varsayilan kipi grupludur: her ticket icin bir baslik,
altinda yalniz dusen kriterler, sonda ozet tablosu.

    ./labctl check 901-gun-02a

Tum [OK] satirlarini gormek icin:

    docker exec -e CHECK_VERBOSE=1 -u root lab-901-gun-02a \
        bash /lab/check.sh
