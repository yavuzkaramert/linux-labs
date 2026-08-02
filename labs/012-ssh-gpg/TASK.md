Lab 012 — SSH Anahtarı, sshd Sertleştirme ve GPG
================================================

Hikâye
------

Sunucuya artık parolayla girilmesi istenmiyor; anahtarla girilecek.
Kurulum yarım bırakılmış: anahtar çifti üretilmiş ama gerisi
yapılmamış.

sshd yapılandırmasında root girişi ve parola girişi hâlâ açık.
Üstelik dosyayı biri düzenlemiş, kaydetmiş ve orada bırakmış:
çalışan servis hâlâ eski ayarlarla ayakta, diskteki dosya ise
başlatılamayacak durumda.

Son olarak dışarıdan iki paket sürümü gelmiş. İkisi de aynı
yayıncının imzasını taşıdığını iddia ediyor ama biri yolda
değiştirilmiş. Hangisi sağlam, imza söyleyecek.

Görevler
--------

1. student kullanıcısının anahtar çifti hazır:

       /home/student/.ssh/id_ed25519
       /home/student/.ssh/id_ed25519.pub

   Ama sunucu bu anahtarı tanımıyor. Açık anahtarı sunucunun
   tanıyacağı yere yerleştir.

   Yerleştirmek tek başına yetmeyecek. ssh sunucusu, kendisine
   güvenilmesi istenen dosyaların yalnız sahibi tarafından
   yazılabilir olmasını şart koşar; bu şart yalnız anahtar
   dosyasını değil, onun içinde bulunduğu dizini ve kullanıcının
   ev dizinini de kapsar. Şart sağlanmazsa giriş reddedilir ama
   istemci sana sebebini söylemez: sanki anahtar yanlışmış gibi
   parola sorar. Sebep yalnız sunucu tarafındaki günlükte durur.

   Sonunda student kullanıcısı, parola kullanmadan, yalnız
   anahtarla kendi sunucusuna girebilmeli.

2. Yapılandırma dosyası:

       /etc/ssh/sshd_config

   İçinde root girişi ve parola girişi hâlâ açık; ikisini de
   kapat.

   Dikkat: dosyada bir de sözdizimi hatası var. Servisi doğrudan
   yeniden başlatırsan ayağa kalkmaz ve o anda sunucuya bağlı
   olan tek yol da sensin. Yapılandırmayı uygulamadan ÖNCE
   sınayan bir yol var; önce onu kullan.

   Düzeltmeyi yazmak yetmez. Çalışan servis dosyayı yalnız
   başlarken okur; yeniden başlatmadığın sürece sunucu eski
   ayarlarla çalışmaya devam eder.

   Sonunda servis ayakta olmalı ve iki yönerge de kapalı
   olmalı.

3. student kullanıcısının GPG anahtarı yok. Bir anahtar çifti
   üret. Anahtarın kimliği şu e-posta adresini taşımalı:

       student@lab.local

   Anahtar parolasız olsun; bu bir laboratuvar anahtarı, ilerideki
   adımlar onu etkileşimsiz kullanacak.

   Sonra şu dosyayı kendi anahtarına şifrele:

       /home/student/gizli.txt

   Şifreli çıktının adı gizli.txt.gpg olacak ve student'ın kendi
   anahtarıyla çözülebilmeli. Çözüp içeriğin bozulmadığını kendin
   de doğrula.

4. Dışarıdan gelen paketler şurada:

       /opt/paket/surum-a.tar.gz
       /opt/paket/surum-b.tar.gz

   Her birinin yanında ayrık imza dosyası var (.sig uzantılı).
   Yayıncının açık anahtarı da aynı dizinde duruyor:

       /opt/paket/yayinci-acik.asc

   Ama bu anahtar senin anahtarlığında değil; o hâliyle imza
   doğrulaması "açık anahtar yok" diyerek düşer. Önce anahtarı
   kendi anahtarlığına aktar, sonra iki paketi de doğrula.

   Biri doğrulanacak, diğeri doğrulanmayacak. Kurcalanmış olanın
   dosya adını şuraya yaz:

       /home/student/cevap-paket.txt

   Aynı görevin ters yönü de isteniyor. Şu dosya senin:

       /home/student/duyuru.txt

   Onu kendi GPG anahtarınla ayrık imzayla imzala; imza dosyasının
   adı duyuru.txt.sig olacak ve doğrulanabilmeli.

Notlar
------

Anahtar çiftlerini yeniden üretmen gerekmiyor; SSH anahtarı zaten
var, GPG anahtarını sen üreteceksin.

Servis gövdelerine ve paket dosyalarının içeriğine dokunma;
kurcalanmış paketi düzeltmek istenmiyor, tespit edilmesi isteniyor.

Kabul kriterleri
----------------

[ ] .ssh dizini yalnız sahibine açık ve student'a ait

[ ] authorized_keys doğru izinde, student'a ait ve anahtarı içeriyor

[ ] ev dizini gruba ve diğerlerine yazılabilir değil

[ ] student parola kullanmadan yalnız anahtarla giriş yapabiliyor

[ ] sshd yapılandırması sözdizimi sınamasından temiz geçiyor

[ ] root girişi kapalı

[ ] parola ile giriş kapalı

[ ] sshd servisi ayakta ve yeni yapılandırmayla çalışıyor

[ ] student'ın gizli GPG anahtarı var ve doğru kimliği taşıyor

[ ] gizli.txt.gpg student'ın anahtarına şifrelenmiş

[ ] şifreli dosya çözüldüğünde içerik orijinaliyle aynı

[ ] yayıncının açık anahtarı student'ın anahtarlığında

[ ] sağlam paketin imzası student olarak doğrulanıyor

[ ] cevap dosyası kurcalanmış paketi doğru işaretliyor

[ ] duyuru.txt ayrık imzayla imzalanmış ve imza doğrulanıyor

Kontrol
-------

Host terminalinden:

    ./labctl check 012

Takıldın mı:

    ./labctl hint 012 1
