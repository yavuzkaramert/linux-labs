Lab 009 — Paket Yönetimi
========================

Hikâye
------

Devraldığın sunucuda paket durumu belirsiz. Kimse hangi dosyanın
hangi paketten geldiğini bilmiyor, vim açılışta tuhaf davranıyor,
günlük işte kullanılan bir komut sistemde yok, bir hesap script'i
dün çalışırken bugün çalışmıyor. Ayrıca bir dizine iki paket dosyası
bırakılmış; kurulmadan önce içlerinde ne olduğu öğrenilmek isteniyor.

Paket yöneticisinin veritabanı bu soruların hepsini cevaplar: hangi
dosya kimin, dosya kurulduğu günden beri değişmiş mi, eksik bir
komutu kim sağlıyor, sisteme en son ne yapıldı.

Cevap dosyaları buraya yazılır:

    /home/student/cevaplar/

Paket dosyalarının bulunduğu dizin değiştirilmez, silinmez:

    /srv/paketler/

Görevler
--------

1. Sistemde kurulu tree komutu /usr/bin/tree yolunda duruyor. Bu
   dosyanın hangi paketten geldiğini bul, sonra o paketin sisteme
   kurduğu tüm dosyaları listele.

   Sonucu /home/student/cevaplar/paket-sorgu.txt içine yaz:

       ilk satır: yalnız paket adı
       sonraki satırlar: paketin dosya listesi, birebir

2. vim'in yapılandırma dosyası /etc/vimrc kurulduğu hâlinde değil;
   biri hem içeriğine dokunmuş hem iznini değiştirmiş. Paket
   yöneticisi kurulum anındaki hâli sakladığı için bu farkı sana
   söyleyebilir.

   Dosyanın hangi pakete ait olduğunu bul, o paketi doğrula ve
   çıktının hangi özelliklerin değiştiğini söylediğini oku.

   Sonucu /home/student/cevaplar/butunluk-raporu.txt içine üç satır
   olarak yaz. Türkçe karakter yok, degisen alanı virgülle ayrılır,
   sırası önemsizdir:

       paket <paket-adi>
       dosya /etc/vimrc
       degisen icerik,izin

3. lsof komutu sistemde yok; önce bunu kendin doğrula. Paket
   yöneticisine bu komutu hangi paketin sağladığını sor, o paketi
   kur ve lsof çalışır hâle gelsin.

   Sağlayan paketin adını /home/student/cevaplar/eksik-komut.txt
   içine tek satır olarak yaz.

4. /usr/local/bin/hesapla script'i kurulu ama çalışmıyor: dayandığı
   paket bir işlemle sistemden kaldırılmış. Paket yöneticisinin
   işlem geçmişine bak, o işlemi bul ve geri al.

   Bir işlemi geri almak, paketi elle yeniden kurmaktan farklı bir
   iştir; görev geri almanı istiyor.

   Sonunda hesapla çalışmalı:

       echo "2+2" | hesapla    ->    4

5. /srv/paketler/ altındaki .rpm dosyasını KURMADAN içeriğini ve
   metaverisini incele. Dosya listesini ve paket bilgilerini
   kurulum yapmadan okumak mümkündür.

   Sonucu /home/student/cevaplar/rpm-inceleme.txt içine şu düzende
   yaz:

       paket-adi: <ad>
       surum: <surum>
       dosyalar:
       <dosya listesi>

   Paket kurulmayacak. Kurarsan bu görev geçersiz sayılır.

6. Aynı dizindeki .deb dosyası Debian ailesinden geliyor; onu
   okuyacak araç bu sistemde yok. Araç temel depolarda da yok, ek
   bir depo etkinleştirmen gerekiyor. Ek deponun bazı paketleri
   dağıtımın yardımcı deposundaki kütüphanelere dayanır; bağımlılık
   hatası alırsan eksik olan depodur, paket değil.

   Gerekli depoları etkinleştir, aracı kur ve .deb dosyasını
   KURMADAN içeriğini ve metaverisini incele.

   Sonucu /home/student/cevaplar/deb-inceleme.txt içine şu düzende
   yaz:

       paket-adi: <ad>
       surum: <surum>
       dosyalar:
       <dosya listesi>

   Bu paket de kurulmayacak.

Kabul kriterleri
----------------

[ ] paket-sorgu.txt ilk satırında doğru paket adı var

[ ] paket-sorgu.txt dosya listesi paketin gerçek listesiyle eşleşiyor

[ ] butunluk-raporu.txt doğru paket ve dosya yolunu içeriyor

[ ] butunluk-raporu.txt hem icerik hem izin değişikliğini işaretlemiş

[ ] eksik-komut.txt doğru paket adını içeriyor

[ ] lsof komutu artık çalışıyor

[ ] bc paketi kurulu

[ ] hesapla scripti doğru sonucu üretiyor

[ ] rpm-inceleme.txt doğru paket adı, sürüm ve dosya listesi içeriyor

[ ] rpm-inceleme.txt'deki paket sistemde kurulu değil

[ ] EPEL deposu etkin

[ ] crb deposu etkin

[ ] dpkg kurulu ve çalışıyor

[ ] deb-inceleme.txt doğru paket adı, sürüm ve dosya listesi içeriyor

[ ] deb-inceleme.txt'deki paket sistemde kurulu değil

[ ] /srv/paketler altındaki dosyalar değiştirilmemiş

Kontrol
-------

Host terminalinden:

    ./labctl check 009

Takıldın mı:

    ./labctl hint 009 1
