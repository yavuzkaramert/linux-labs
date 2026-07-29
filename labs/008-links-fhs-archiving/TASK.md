Lab 008 — Bağlantılar, FHS ve Arşivleme
========================================

Hikâye
------

Bir uygulamanın dosyaları aceleyle kurulmuş: log, yapılandırma ve
yardımcı script ev dizinine atılmış. Ayrıca yedek kaynağı dizininde
kimin kimin kopyası olduğu belli değil; bir dosya çifti aynı içeriği
taşıyor ama bunlardan yalnız biri gerçekten ikinci bir isim.

Senden dosyaları doğru yerlerine taşımanı, bağlantı durumunu tespit
etmeni, diskte gerçekten ne kadar yer kullanıldığını ölçmeni ve veri
dizininin arşivini üretmeni istiyorlar.

Cevap dosyaları buraya yazılır:

    /home/student/cevaplar/

Kaynak dizinler değiştirilmez, silinmez:

    /srv/backup-kaynagi/
    /srv/data/

Görevler
--------

1. Ev dizinindeki üç dosyayı FHS'e uygun yerlerine taşı:

   - uygulama.log dosyası /var/log/myapp/uygulama.log olacak
   - myapp.conf dosyası /etc/myapp/myapp.conf olacak
   - backup-helper dosyası /usr/local/bin/backup-helper olacak ve
     çalıştırılabilir olacak

   İki hedef dizin henüz yok, önce onları açman gerekir. Taşıma
   işleminden sonra dosyaların eski konumunda kopyası kalmamalı.

2. /srv/backup-kaynagi/ altında kaynak1-yedek.txt ve kaynak2-kopya.txt
   dosyaları var. Bunlardan biri kendi kaynağının ikinci ismi, diğeri
   bağımsız bir kopya. İçerik karşılaştırması ikisini de aynı gösterir;
   ayırt eden şey içerik değildir.

   Hangisinin ne olduğunu belirle ve sonucu
   /home/student/cevaplar/baglanti-raporu.txt içine iki satır olarak
   yaz. Satırların biçimi tam olarak şöyle, Türkçe karakter yok:

       kaynak1-yedek.txt hardlink
       kaynak2-kopya.txt bagimsiz

3. /srv/backup-kaynagi/kaynak3.txt dosyası için iki bağlantı üret:

   - /home/student/kaynak3-hardlink.txt aynı dosyanın ikinci ismi
     olacak
   - /home/student/kaynak3-symlink.txt ise
     /srv/backup-kaynagi/kaynak3.txt yolunu gösteren sembolik bağlantı
     olacak

4. /srv/backup-kaynagi/ dizininin diskte gerçekten kapladığı yeri ölç.
   Dosyaların görünen boyutlarının toplamı ile diskteki gerçek kullanım
   aynı değil; sebebini de anlamış olman gerekiyor.

   Sonucu /home/student/cevaplar/disk-kullanimi.txt içine tek satır
   olarak yaz: yalnız sayı, KB cinsinden, birim harfi yok.

5. /srv/data dizinini arşivle ve sıkıştır. Arşiv
   /srv/backup/data-yedek.tar.gz olacak. gecici alt dizini arşive
   girmeyecek; ama diskteki hâli de silinmeyecek, olduğu gibi kalacak.

6. Ürettiğin arşivi AÇMADAN içeriğini listele. kalici/onemli.txt
   dosyasının arşivde olduğunu, gecici/silinecek.txt dosyasının
   olmadığını doğrula ve sonucu
   /home/student/cevaplar/arsiv-dogrulama.txt içine iki satır olarak
   yaz:

       kalici/onemli.txt var
       gecici/silinecek.txt yok

Kabul kriterleri
----------------

[ ] uygulama.log /var/log/myapp/ altında, eski konumda yok

[ ] myapp.conf /etc/myapp/ altında, eski konumda yok

[ ] backup-helper /usr/local/bin/ altında ve çalıştırılabilir

[ ] baglanti-raporu.txt iki satır, etiketler doğru

[ ] kaynak3-hardlink.txt kaynak3.txt ile aynı inode

[ ] kaynak3-symlink.txt doğru hedefe işaret ediyor

[ ] disk-kullanimi.txt tek satır, yalnız sayı ve doğru

[ ] data-yedek.tar.gz var, gecici içeriği arşivde yok

[ ] data-yedek.tar.gz içinde dosya.txt ve kalici/onemli.txt var

[ ] arsiv-dogrulama.txt iki satır, doğru var/yok

[ ] /srv/data ve /srv/backup-kaynagi kaynakları değişmemiş

Kontrol
-------

Host terminalinden:

    ./labctl check 008

Takıldın mı:

    ./labctl hint 008 1
