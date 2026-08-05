Lab 901-gun-02b — Yedek Sunucu Gunu: Bolum B
============================================

Hikâye
------

Kurtarma operasyonunun ikinci yarisi. Sabah (02a) veriyi ve temel
hesaplari ayaga kaldirdin. Simdi sira destek/talep verisini
islemekte, servisleri saglikli sekilde ayakta tutmakta, zamanlanmis
isleri kurmakta ve son olarak sunucunun uzaktan erisimini
sertlestirip kurtarma operasyonunu guvenli sekilde kapatmakta.

Bu lab 02a'nin devami gibi anlatilir ama KENDI container'inda
sifirdan kurulur. 02a'yi cozmus olman gerekmez.

Yeni konu yok: yedi ticket, yedi kaynak lab. Onerilen sira ticket
numarasi sirasidir (7'den 13'e). Zorunlu degil, her ticket kendi
basina degerlendirilir.

Sureyi kendin tut: baslangic ve bitis saatini JOURNAL.md'ye elle yaz.

Ortam
-----

PID 1:           systemd
Ag:              Ticket 10 icin gerekli (gercek dnf islemleri)
Cevap dizini:    /home/student/cevaplar
Is dizini:       /srv/klinik/is       (Ticket 8)
Toplam kriter:   104

Ticket haritasi
---------------

    Ticket 7    Destek talepleri dokumu          kaynak 007a   13
    Ticket 8    Karisik log + otomatik rapor     kaynak 007b   19
    Ticket 9    Dosya yerlesimi, baglanti, arsiv kaynak 008    11
    Ticket 10   Paket durumu                     kaynak 009    16
    Ticket 11   Dort systemd isi                 kaynak 010    11
    Ticket 12   Log, cron ve saat                kaynak 011    19
    Ticket 13   Erisim sertlestirme: SSH + GPG   kaynak 012    15

Ticket 7 — Destek talepleri dokumu
-----------------------------------

Kaynak: lab 007a, 13 kriter

Veri:

    /srv/klinik/talepler/talepler.csv    ayracli, baslik satiri var
    /srv/klinik/talepler/erisim.log
    /srv/klinik/talepler/notlar.txt

Cikti dosyalari /home/student/cevaplar altinda. Bes dosya ZATEN VAR
ama onceki danismandan kalma ve hepsi yanlis:

    01-adet.txt    Veri satiri sayisi (baslik haric). Tek satir,
                   yalniz sayi.

    02-acik.txt    Durumu open olan taleplerin TAM satirlari,
                   orijinal sira korunur.

    03-oncelik.txt Her oncelik icin bir satir, "sayi oncelik"
                   biciminde. Sira onemsiz.

    04-kod.txt     erisim.log icinde ENGELLENDI aramasinin CIKIS
                   KODU. Tek satir.

    05-kod.txt     Hic gecmeyen bir kelime icin ayni aramanin cikis
                   kodu. Tek satir.

Ayrica notlar.txt yerinde duzenlenecek: TODO ile BASLAYAN satirlar
silinecek, sube1 gecen her yer merkez-sube olacak. Satir icinde
TODO gecen satira dokunulmayacak.

talepler.csv ve erisim.log dosyalarina DOKUNMA.

Tuzak: bazi KAPALI taleplerin konu alaninda da open kelimesi
geciyor. 02-acik.txt bu satirlari icermemeli.

Ticket 8 — Karisik log'u temizle ve otomatik rapor kur
-------------------------------------------------------

Kaynak: lab 007b, 19 kriter

Veri: /srv/klinik/loglar/karisik.log — farkli bicimlerde karismis
asi ve randevu kayitlari. Bu dosyaya DOKUNULMAZ.

Kayit bicimi dort alandir: tarih, seviye, ip, mesaj. Gecerli bir
kayit YYYY-AA-GG tarihli, seviyesi INFO/WARN/ERROR olan, gecerli
bir IP tasiyan ve mesaj alaninda ayrac bulunmayan satirdir.

Cikti dosyalari /srv/klinik/is altinda:

    duzenli.log    GG/AA/YYYY bicimli tarihler YYYY-AA-GG'ye
                   cevrilmis, ayrac cevresindeki bosluklar
                   kaldirilmis. Satir sayisi ve sirasi karisik.log
                   ile ayni; hicbir satir silinmez.

    gecerli.log    duzenli.log icinden gecerli kayitlar.

    gecersiz.log   geri kalan her sey. Ikisinin toplami
                   duzenli.log'a esit olmali.

    asi-ozet.txt   Her seviye icin tek satir, uc alan:
                   seviye, toplam, tekil ip sayisi. Sayimlar
                   gecerli.log ile uyusmali.

/etc/klinik/klinik-ayarlar.conf yerinde duzenlenecek: # ile
BASLAYAN yorum satirlari silinecek, /opt/eskisistem gecen her yer
/srv/klinik/veri olacak, retention degeri 45 olacak. Satir icinde
gecen # isaretine dokunulmayacak.

/usr/local/bin/rapor-uret adinda bir script yazilacak. Argumansiz
calisir, karisik.log'tan yukaridaki dort dosyayi bastan uretir ve
/srv/klinik/is/metin-rapor.txt dosyasini yazar. Raporun ilk satiri
gecersiz kayit varsa DIRTY, yoksa CLEAN olur; cikis kodu buna gore
1 veya 0'dir. Iki kez calistirildiginda rapor buyumez.

student bu scripti sudo'suz calistirabilmeli.

Tuzaklar: bazi satirlarda gecerli kaydin ONUNDE serbest metin var;
bazilarinda fazladan alan var; bazi gecerli kayitlarin MESAJ
alaninda seviye adi veya IP adresi geciyor.

Ticket 9 — Dosya yerlesimi, baglantilar, arsiv
-----------------------------------------------

Kaynak: lab 008, 11 kriter

Kaynak dizinler DEGISMEDEN kalmali; yalniz okunacak ve
kopyalanacak:

    /srv/klinik-arsiv
    /srv/klinik-yedek-kaynagi

1. /home/student/cevaplar/disk-kullanimi.txt: tek satir, yalniz
   sayi, /srv/klinik-yedek-kaynagi dizininin gercek disk
   kullanimi (KB). Dizinde ayni inode'u paylasan bir dosya cifti
   var; iki kez sayilmamali.

2. /home/student/kayit3-hardlink.txt:
   /srv/klinik-yedek-kaynagi/kayit3.txt ile AYNI inode'u paylasan
   sert baglanti.

3. /home/student/kayit3-symlink.txt: ayni dosyaya isaret eden
   sembolik link.

4. randevu.conf /etc/randevu/ altina tasinacak, eski konumda
   KALMAYACAK.

5. klinik-uygulama.log /var/log/randevu/ altina tasinacak, eski
   konumda kalmayacak.

6. yedek-yardimcisi /usr/local/bin/ altina tasinacak ve
   calistirilabilir olacak.

7. /home/student/klinik-yedek.tar.gz uretilecek: /srv/klinik-arsiv
   icerigi arsivlenecek ama gecici/ altindaki icerik arsive
   GIRMEYECEK. Kaynak dizinden gecici/ SILINMEZ.

8. /home/student/cevaplar/arsiv-dogrulama.txt: iki satir. Birinci
   satir kalici/onemli.txt icin var, ikinci satir
   gecici/silinecek.txt icin yok bilgisini tasir.

9. /home/student/cevaplar/baglanti-raporu.txt: iki satir. Bir satir
   kayit1 ciftini sert baglanti olarak, digeri kayit2 ciftini
   bagimsiz kopya olarak etiketler.

Ticket 10 — Paket durumu
-------------------------

Kaynak: lab 009, 16 kriter

Klinik randevu yaziliminin birkac bagimligi eksik veya bozuk.

1. EPEL deposu etkinlestirilecek. Depo tanimi diskte var ama kapali.

2. CRB deposu etkinlestirilecek. Depo adini hata mesajindan
   cikaracaksin.

3. bc paketi kurulacak. /usr/local/bin/dozhesapla.sh ilac dozu
   hesabini bc'ye devrediyor; bc kurulunca dogru sonucu uretmeli.

4. lsof komutu calisir hale gelecek.
   /home/student/cevaplar/eksik-komut.txt tek satir, lsof komutunu
   saglayan paketin adi.

5. dpkg kurulacak ve calisir durumda olacak.

Cevap dosyalari /home/student/cevaplar altinda:

    paket-sorgu.txt      1. satir: /usr/bin/tree dosyasinin sahibi
                         olan paketin adi. Sonraki satirlar: o
                         paketin dosya listesi.

    rpm-inceleme.txt     /srv/klinik/paketler altindaki .rpm icin.
                         1. satir ad, 2. satir surum, sonraki
                         satirlar dosya listesi. Paket KURULMAYACAK.

    deb-inceleme.txt     Ayni bilgiler, .deb dosyasi icin.
                         1. satir ad, 2. satir surum, sonraki
                         satirlar dosya listesi.

    butunluk-raporu.txt  Uc satir. 1. satir: bozulmus dosyanin ait
                         oldugu paket adi. 2. satir: dosya yolu.
                         3. satir: nelerin degistigi (icerik ve
                         izin). Dogrulama araci paket ADI bekler,
                         dosya yolu degil; dosya yolu ayri bir
                         bayrakla verilir.

/srv/klinik/paketler altindaki referans dosyalar DEGISMEYECEK.

Ticket 11 — Dort systemd isi
-----------------------------

Kaynak: lab 010, 11 kriter

Dort birim, klinik sisteminin parcalari. Hepsinin dosyasi var ama
her biri baska bir sekilde bozuk.

1. veritabani-hazirla.service tek seferlik bir is olmali ve
   tamamlandiktan sonra tamamlanmis durumda kalmali. Kostugunda
   /var/lib/klinik/.hazir dosyasini olusturur.

2. randevu-api.service veritabani-hazirla.service'e hem siralama
   hem gereklilik baglariyla bagli olmali; basariyla baslamali ve
   aktif kalmali.

3. hatirlatici.service dogru tip ve dogru program yoluyla
   yazilmali; hem aktif hem enabled olmali ve systemd'ye gore
   gercekten kosuyor olmali.

4. stok-raporu.service ExecStart'i var olan bir programa, User'i
   var olan bir kullaniciya isaret etmeli; aktif olmali ve dosya
   duzenlendikten sonra systemd tanimi tazelenmis olmali.

5. Varsayilan target multi-user.target olmali.

6. Dort servis dosyasi da kalici bir birim dizininde durmali.

Not: tek seferlik ve tamamlandiktan sonra ayakta sayilan bir servis
icin gereklilik bagi olarak Requires dogru tercihtir.

Ticket 12 — Log, cron ve saat
------------------------------

Kaynak: lab 011, 19 kriter

1. gozcu.service eksik bir lisans dosyasi yuzunden hata veriyor.
   Servis hatasiz calisir hale gelecek ve enabled olacak.
   /home/student/cevaplar/cevap.txt eksik dosyanin TAM YOLUNU ve
   servisin dondugu CIKIS KODUNU icerecek.

2. Kalici journal dizini kurulacak ve gunlukler oraya yazilacak.

3. yedek isi: her dakika calisacak bicimde tanimli olacak.
   Calistirdigi komut cron'un minimal ortaminda bulunabilmeli.
   /var/log/klinik-yedek.log icinde gercek bir calisma satiri
   olacak. Cron bir dakika beklemeyi gerektirir.

4. temizlik.service ve temizlik.timer kurulacak. Servis bir kez
   calisan tipte olacak ve /usr/local/bin/temizle programini
   cagiracak. Timer aktif olacak, tetiklemeyi bekleyecek, enabled
   olacak, bir sonraki tetiklemeye en fazla bir dakika kalacak ve
   dogru service birimini tetikleyecek.
   /var/log/klinik-temizlik.log isin calistigini gosterecek.

5. Sistem saat dilimi Europe/Istanbul olacak, kalici bicimde.

6. chrony yapilandirmasinda gecerli bir zaman sunucusu satiri
   olacak, senkron servisi hem aktif hem enabled olacak ve sistem
   saat senkronunu acik olarak raporlayacak.

Ticket 13 — Erisim sertlestirme: SSH + GPG
-------------------------------------------

Kaynak: lab 012, 15 kriter

Kurtarmayi kapatirken sunucunun uzaktan erisimini sertlestiriyor,
tedarikciden gelen paketleri dogruluyor ve devir notunu
imzaliyorsun.

1. .ssh dizini yalniz sahibine acik ve student'a ait olacak.

2. authorized_keys dogru izinde, student'a ait ve student'in acik
   anahtarini iceriyor olacak.

3. Ev dizini gruba ve digerlerine yazilabilir OLMAYACAK. sshd bunu
   sessizce reddeder, istemci sebebini soylemez.

4. Parola ile giris kapali, root girisi kapali olacak.

5. sshd yapilandirmasi sozdizimi sinamasindan temiz gececek ve
   servis yeni yapilandirmayla calisiyor olacak.

6. student parola kullanmadan yalniz anahtarla giris yapabilecek.

7. student'in gizli GPG anahtari olacak, kimligi su olacak:

    PatiVet BT <bt@pativet.local>

8. Tedarikcinin acik anahtari student'in anahtarliginda olacak.
   Anahtar dosyasi /opt/paket altinda.

9. /opt/paket altindaki saglam paketin imzasi student olarak
   dogrulanabilecek. /home/student/cevaplar/06-paket.txt iki satir
   tasiyacak: her paket adi ve imza sonucu. Bir paket bilerek
   kurcalanmistir.

10. /home/student/gizli-hasta-notu.txt.gpg uretilecek: student'in
    anahtarina sifrelenmis olacak, cozuldugunde icerik orijinaliyle
    ayni cikacak.

11. /home/student/devir-notu.txt AYRIK imzayla imzalanacak ve imza
    dogrulanacak. Bu, sonraki haftaki danismana birakilan devir
    notudur.

Not: SSH sertlestirmesi tamamlanmadan, yani parola girisi
kapatilmadan sonraki hafta kimse bu makineye guvenli sekilde
disaridan baglanamaz. Bu gercekcilik notudur, ayri bir kabul
kriteri degildir.

Kabul kriterleri
----------------

[ ] 01-adet.txt tek satir ve yalniz sayi
[ ] 01-adet.txt dogru veri satiri sayisini veriyor
[ ] 02-acik.txt yalniz durumu open olan talepleri iceriyor
[ ] 02-acik.txt konu alani tuzagina dusmemis
[ ] 02-acik.txt orijinal sirayi koruyor
[ ] 03-oncelik.txt her oncelik icin tek satir, iki alan
[ ] 03-oncelik.txt oncelik dagilimini dogru veriyor
[ ] 04-kod.txt gecen kelimenin cikis kodunu veriyor
[ ] 05-kod.txt gecmeyen kelimenin cikis kodunu veriyor
[ ] notlar.txt bastaki TODO satirlari silindi, satir ici korundu
[ ] notlar.txt tum sube1 gecisleri merkez-sube oldu
[ ] notlar.txt yalnizca istenen iki degisikligi tasiyor
[ ] talepler.csv ve erisim.log degistirilmemis
[ ] duzenli.log satir sayisi karisik.log ile ayni
[ ] duzenli.log'da eski tarih bicimi kalmamis
[ ] duzenli.log'da ayrac cevresi temiz
[ ] duzenli.log icerigi ve sirasi dogru
[ ] gecerli.log dogru satirlari iceriyor
[ ] gecerli.log'da kaliba uymayan satir yok
[ ] gecersiz.log geri kalan satirlari iceriyor
[ ] gecerli ve gecersiz toplami duzenli.log'a esit
[ ] asi-ozet.txt her satiri uc alanli
[ ] asi-ozet.txt seviye adlari gecerli.log ile ayni
[ ] asi-ozet.txt toplamlari gecerli.log ile uyusuyor
[ ] asi-ozet.txt tekil IP sayilari dogru
[ ] klinik-ayarlar.conf yorum satirlarindan arindirilmis
[ ] tum /opt/eskisistem gecisleri degistirilmis
[ ] klinik-ayarlar.conf retention degeri 45
[ ] rapor-uret student tarafindan calistirilabiliyor
[ ] metin-rapor.txt ilk satiri dogru durumu gosteriyor
[ ] rapor-uret idempotent
[ ] rapor-uret cikis kodu raporun ilk satiriyla tutarli
[ ] disk-kullanimi.txt dogru KB degerini veriyor
[ ] kayit3-hardlink.txt kaynakla ayni inode'u paylasiyor
[ ] kayit3-symlink.txt dogru hedefe isaret ediyor
[ ] randevu.conf /etc/randevu/ altina tasinmis
[ ] klinik-uygulama.log /var/log/randevu/ altina tasinmis
[ ] yedek-yardimcisi /usr/local/bin altinda ve calistirilabilir
[ ] klinik-yedek.tar.gz gecici icerik barindirmiyor
[ ] klinik-yedek.tar.gz kalici dosyalari iceriyor
[ ] arsiv-dogrulama.txt dogru var/yok bilgisini veriyor
[ ] baglanti-raporu.txt sert baglanti/kopya ayrimini dogru yapiyor
[ ] kaynak dizinler degistirilmemis
[ ] EPEL deposu etkinlestirilmis
[ ] CRB deposu etkinlestirilmis
[ ] bc paketi kurulu
[ ] dozhesapla.sh dogru sonucu uretiyor
[ ] lsof komutu calisir durumda
[ ] eksik-komut.txt dogru paket adini iceriyor
[ ] paket-sorgu.txt ilk satirinda dogru paket adi var
[ ] paket-sorgu.txt dosya listesi dogru
[ ] rpm-inceleme.txt dogru paket adini veriyor, paket kurulmamis
[ ] rpm-inceleme.txt dogru surumu veriyor
[ ] rpm-inceleme.txt dosya listesi dogru
[ ] dpkg kurulu ve calisir durumda
[ ] deb-inceleme.txt dogru ad ve surumu veriyor
[ ] deb-inceleme.txt dosya listesi dogru
[ ] butunluk-raporu.txt icerik ve izin degisikligini isaretliyor
[ ] paketler dizinindeki referans dosyalar degismemis
[ ] veritabani-hazirla oneshot ve RemainAfterExit ile yazilmis
[ ] veritabani-hazirla tamamlanmis durumda kaliyor
[ ] randevu-api siralama bagiyla bagli
[ ] randevu-api gereklilik bagiyla bagli
[ ] randevu-api aktif ve gercekten kosuyor
[ ] hatirlatici dogru Type ve ExecStart ile yazilmis
[ ] hatirlatici hem aktif hem enabled
[ ] hatirlatici PID 1 altinda gercekten kosuyor
[ ] stok-raporu ExecStart ve User degerleri gecerli
[ ] stok-raporu aktif ve systemd tanimi tazelenmis
[ ] varsayilan target multi-user, dort birim kalici konumda
[ ] kalici journal dizini kurulmus ve kullaniliyor
[ ] journald kalici depolamayi kullaniyor
[ ] gozcu.service enabled
[ ] gozcu.service hatasiz calisiyor
[ ] cevap.txt eksik dosyanin yolunu iceriyor
[ ] cevap.txt cikis kodunu iceriyor
[ ] crond servisi aktif
[ ] crond servisi enabled
[ ] yedek cron isi her dakika calisacak sekilde tanimli
[ ] cron komutu mutlak yolla yazilmis
[ ] yedek isi gercekten calismis, log satiri var
[ ] temizlik.service tek seferlik ve dogru programi cagiriyor
[ ] temizlik.timer aktif ve tetiklemeyi bekliyor
[ ] temizlik.timer enabled
[ ] temizlik.timer dogru service birimini tetikliyor
[ ] bir sonraki tetiklemeye en fazla bir dakika var
[ ] temizlik isi calismis, log satiri var
[ ] sistem saat dilimi Europe/Istanbul ve kalici
[ ] chrony yapilandirilmis, servis aktif ve senkron acik
[ ] .ssh dizini 0700 ve student'a ait
[ ] authorized_keys dogru izinde ve student'a ait
[ ] authorized_keys student'in acik anahtarini iceriyor
[ ] ev dizini gruba/digerlerine yazilabilir degil
[ ] parola ile giris kapali
[ ] root girisi kapali
[ ] sshd yapilandirmasi sozdizimi sinamasindan temiz geciyor
[ ] sshd ayakta ve yeni yapilandirmayla calisiyor
[ ] student parolasiz, anahtarla giris yapabiliyor
[ ] student'in gizli GPG anahtari var, kimligi dogru
[ ] tedarikcinin acik anahtari anahtarlikta
[ ] saglam paketin imzasi dogrulaniyor
[ ] kurcalanmis paket cevap dosyasinda dogru isaretlenmis
[ ] sifreli hasta notu cozuluyor ve icerik ayni
[ ] devir-notu.txt ayrik imzayla imzalanmis ve dogrulaniyor

Not: yukaridaki kriterlerden ucu KORKULUK kriteridir ve daha ilk
kosuda gecer. Ucu de "su dosyalara dokunma" der: talepler.csv ve
erisim.log, iki kaynak dizin, ve paketler dizini. Bozulacak bir
sey yok; bunlar yan hasari yakalamak icin var. Ornegin arsivden
gecici/ icerigini disarida birakmak yerine onu kaynaktan silersen
bu kriterlerden biri duser.

Kontrol
-------

Ciktinin varsayilan kipi grupludur: her ticket icin bir baslik,
altinda yalniz dusen kriterler, sonda ozet tablosu.

    ./labctl check 901-gun-02b

Tum [OK] satirlarini gormek icin:

    docker exec -e CHECK_VERBOSE=1 -u root lab-901-gun-02b \
        bash /lab/check.sh
