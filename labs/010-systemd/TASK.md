Lab 010 — systemd Servisleri
============================

Hikâye
------

Devraldığın sunucuda dört iş var, hiçbiri yolunda gitmiyor.

Bir script sürekli çalışması gerekirken hiç çalışmıyor: kimse onu
sisteme bir servis olarak tanıtmamış. Bir raporlama servisi kurulu
ama ayağa kalkmıyor. Bir API servisi başlıyor ve hemen ölüyor.
Sunucunun varsayılan açılış hedefi de yanlış ayarlanmış.

systemd bu soruların hepsini cevaplar: bir servisin neden çöktüğünü,
neyin neden önce çalışması gerektiğini, sistemin açılışta hangi
hedefe gideceğini. Servis dosyaları burada durur:

    /etc/systemd/system/

Bir unit dosyasını değiştirmek yetmez; systemd o dosyayı okuyup
belleğine almadan hiçbir şey değişmez.

Görevler
--------

1. /opt/app/gorevci script'i sürekli çalışması gereken bir iş
   yapıyor: ön planda kalır, kendi kendine arka plana geçmez. Şu an
   sistemde bu script'i tanıyan hiçbir servis yok.

   Bu script için bir servis dosyası yaz:

       /etc/systemd/system/gorevci.service

   Servis ön planda kalan bir süreci yönetecek biçimde tanımlanmalı.
   Yazdıktan sonra systemd'ye okut, başlat ve açılışta kendiliğinden
   başlayacak hâle getir.

2. raporcu.service zaten kurulu ama ayağa kalkmıyor. İçinde İKİ
   bağımsız hata var ve bunlardan biri diğerini gizliyor: ilkini
   düzeltmeden ikincisi çıktıda hiç görünmez.

   Servisin durumuna bak, çıktının söylediği hata koduna güven,
   düzelt, tekrar dene. İkinci hata ancak o zaman ortaya çıkacak.

   Gerçek program şurada duruyor:

       /opt/raporcu/bin/raporcu

   Servis çalışır hâle gelmeli. Unit dosyasını değiştirdikten sonra
   systemd'nin bellekteki kopyasını tazelemeyi unutma; tazelemezsen
   servis çalışıyor görünse bile sistem eski tanımı taşır.

3. Üç numaralı sorun bir sıralama sorunu.

   veritabani.service bir kez çalışıp iş yapan ve çıkan bir birimdir:
   /var/lib/veritabani/.ready dosyasını oluşturur ve biter. Sürekli
   çalışmaz, ama işi bittikten sonra da "tamamlandı" olarak durur.

   api.service ise başlarken o .ready dosyasını arar. Bulamazsa
   başlamayı reddedip hata ile çıkar.

   Şu anda ikisi arasında hiçbir ilişki tanımlı değil, bu yüzden
   api.service her defasında başarısız oluyor.

   api.service'e veritabani.service ile arasındaki ilişkiyi tanımla.
   İki ayrı şey gerekiyor: birincisi sıralama (hangisi önce
   çalışacak), ikincisi gereklilik (biri olmadan diğeri anlamsız).
   Yalnız sıralama yeterli değildir.

   veritabani.service'i de gerektiği gibi çalıştır. Sonunda
   api.service başarıyla başlamalı ve ayakta kalmalı.

4. Sunucunun varsayılan açılış hedefi yanlış ayarlanmış; şu an
   kurtarma hedefine bakıyor. Normal çok kullanıcılı hedefe düzelt.

Notlar
------

Tüm servis dosyaları kalıcı konumda, /etc/systemd/system/ altında
tutulur. Geçici birim dizinleri (çalışma anında oluşan kopyalar)
kabul edilmez.

Servis gövdelerini (/opt altındaki script'ler) değiştirmen
gerekmiyor; sorunların hepsi systemd tarafında.

Kabul kriterleri
----------------

[ ] gorevci.service dosyası doğru tip ve doğru ExecStart ile yazılmış

[ ] gorevci.service hem aktif hem enabled

[ ] gorevci süreci systemd'ye göre gerçekten koşuyor

[ ] raporcu.service ExecStart gerçek program yoluna işaret ediyor

[ ] raporcu.service User var olan bir kullanıcıya işaret ediyor

[ ] raporcu.service aktif ve systemd bellekteki tanımı tazelenmiş

[ ] api.service veritabani.service'e sıralama ve gereklilik ile bağlı

[ ] veritabani.service tamamlanmış durumda duruyor

[ ] api.service başarıyla başlıyor ve aktif kalıyor

[ ] varsayılan target multi-user.target

[ ] dört servis dosyası da /etc/systemd/system/ altında kalıcı

Kontrol
-------

Host terminalinden:

    ./labctl check 010

Takıldın mı:

    ./labctl hint 010 1
