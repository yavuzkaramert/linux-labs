Lab 011 — Loglar, Zamanlanmış İşler ve Saat
===========================================

Hikâye
------

Sunucu ayakta ama kimse ona bakmıyor. Dört ayrı sorun birikmiş.

Bir servis dakikada bir çöküp yeniden başlıyor. Nedenini kimse
araştırmamış, çünkü sistemin kendi günlüğüne bakmak akıl etmemiş.
Üstelik o günlük kalıcı bile değil: sistem yeniden başladığında
bugüne kadar birikmiş her kayıt siliniyor.

Gecelik bir yedekleme işi zamanlayıcıya eklenmiş ama hiç
çalışmıyor. Aynı türden başka bir bakım işi ise hiç kurulmamış;
onu klasik zamanlayıcı yerine sistemin kendi zamanlayıcı
birimleriyle kurman isteniyor.

Son olarak sunucunun saat dilimi yanlış ve saat senkronu kapalı.
Loglardaki zaman damgaları bu hâliyle güvenilmez: bir olayın ne
zaman olduğunu söyleyemezsin.

Görevler
--------

1. bekci.service sürekli çöküp yeniden başlıyor. Servis gövdesi
   şurada:

       /opt/bekci/bekci

   Önce sistemin günlüğünü kalıcı hâle getir. Şu an günlük yalnız
   bellekte tutuluyor; kalıcı günlük dizini yok. Kalıcı hâle
   geldikten sonra kayıtlar yeniden başlatmalar arasında da durur.

   Sonra bu servisin günlüğüne bak ve çökme sebebini bul. Günlüğü
   birim adına göre süzebilir, yalnız hata seviyesindeki kayıtları
   isteyebilir, son birkaç dakikayla sınırlayabilirsin. Sürecin
   numarasını bulup günlüğü doğrudan o numaraya göre süzmek de bir
   yoldur.

   Bulduğun sebebi şu dosyaya yaz:

       /home/student/cevap-bekci.txt

   Dosyada iki bilgi geçmeli: servisin bulamadığı dosyanın tam yolu
   ve servisin hangi çıkış koduyla öldüğü.

   Sonra sorunu gider ve servisi ayağa kaldır. Dikkat: eksik olan
   şeyi tamamladığında servis yine çökebilir. İkinci sebebi de aynı
   yerden, günlükten okuyacaksın. Servis gövdesini değiştirmen
   gerekmiyor.

2. Gecelik yedekleme işi şu dosyada tanımlı:

       /etc/cron.d/yedek

   İş hiç çalışmıyor. Üç ayrı sebep var.

   Birincisi, zamanlanmış işleri çalıştıran servis şu an ayakta
   değil ve açılışta da başlamayacak.

   İkincisi, iş gece üçe kurulmuş. Sen laboratuvar süresince
   çalıştığını görmek istiyorsun: her dakika çalışacak biçimde
   değiştir.

   Üçüncüsü, komut yazıldığı hâliyle bulunamıyor. Zamanlayıcı bir
   giriş kabuğu değildir: senin kabuğunda çalışan bir komut,
   zamanlayıcının verdiği ortamda çalışmayabilir. Gerçek program
   şurada:

       /usr/local/bin/yedekle

   İş çalıştığında şu dosyaya satır ekler:

       /var/log/yedek/yedek.log

   O dosyada gerçek bir çalışma satırı görene kadar bitmiş sayma.
   Zamanlayıcı servisin günlüğü, işi çalıştırdığını da yazar;
   oradan da doğrulayabilirsin.

3. Aynı türden ikinci bir bakım işi var ama hiç kurulmamış. Program
   hazır:

       /usr/local/bin/temizlik

   Bu işi klasik zamanlayıcıyla değil, sistemin kendi zamanlayıcı
   birimiyle kur. İki dosya yazacaksın:

       /etc/systemd/system/temizlik.service
       /etc/systemd/system/temizlik.timer

   Servis bir kez çalışıp biten türden olmalı; sürekli ayakta kalan
   bir süreç değil. Zamanlayıcı birim en geç dakikada bir tetiklemeli
   ve açılışta kendiliğinden devreye girmeli.

   Zamanlayıcının varsayılan tetikleme toleransı bir dakikadır: bunu
   daraltmazsan kısa aralıklı bir zamanlayıcı bile geç ateşleyebilir.

   İş çalıştığında şu dosyaya satır ekler:

       /var/log/temizlik.log

   Kurduktan sonra sistemdeki zamanlayıcıları listeleyip seninkinin
   sırada göründüğünü doğrula.

4. Sunucunun saat dilimi yanlış ayarlanmış; olması gereken:

       Europe/Istanbul

   Saat senkronu da kapalı. Senkron istemcisinin yapılandırma dosyası
   şurada duruyor ve içindeki zaman sunucusu satırı silinmiş:

       /etc/chrony.conf

   Yapılandırmayı tamamla, senkron servisini çalışır ve açılışta
   başlar hâle getir, sistemin saat senkronunun açık olduğunu
   raporladığını gör.

Notlar
------

Zamanlayıcı birim dosyaları kalıcı konumda, /etc/systemd/system/
altında tutulur.

/opt ve /usr/local/bin altındaki program gövdelerini değiştirmen
gerekmiyor; sorunların hepsi yapılandırma tarafında.

Zamanlanmış işler gerçekten tetiklendiğinde doğrulanır. Kontrol
komutu, çıktı dosyaları henüz oluşmamışsa bir süre bekler.

Kabul kriterleri
----------------

[ ] kalıcı günlük dizini var ve günlük oraya yazılıyor

[ ] cevap dosyasında eksik dosyanın yolu ve çıkış kodu yazılı

[ ] bekci.service hatasız çalışıyor ve enabled

[ ] zamanlanmış iş servisi hem aktif hem enabled

[ ] yedek işi her dakika çalışacak biçimde tanımlı

[ ] yedek işinin komutu zamanlayıcının ortamında bulunabiliyor

[ ] yedek log dosyasında gerçek bir çalışma satırı var

[ ] zamanlayıcı servisin günlüğü işi çalıştırdığını gösteriyor

[ ] temizlik.service bir kez çalışan tipte ve doğru programı çağırıyor

[ ] temizlik.timer enabled

[ ] temizlik.timer aktif ve tetiklemeyi bekliyor

[ ] temizlik.timer temizlik.service birimini tetikliyor

[ ] temizlik.timer bir sonraki tetiklemeye en fazla bir dakika var

[ ] temizlik log dosyasında gerçek bir çalışma satırı var

[ ] sistem saat dilimi Europe/Istanbul

[ ] saat dilimi kalıcı biçimde ayarlanmış

[ ] chrony yapılandırmasında geçerli bir zaman sunucusu satırı var

[ ] senkron servisi hem aktif hem enabled

[ ] sistem saat senkronunu açık olarak raporluyor

Kontrol
-------

Host terminalinden:

    ./labctl check 011

Takıldın mı:

    ./labctl hint 011 1
