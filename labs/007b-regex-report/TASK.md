Lab 007b — Regex, Normalleştirme ve Rapor
==========================================

Hikâye
------

İki ayrı sistemin log çıktısı tek dosyada birleştirilmiş, ama
birleştiren kişi biçimleri hizalamamış. Tarihler iki farklı biçimde,
ayırıcıların çevresinde rastgele boşluklar var, ve bir kısım satır
hiçbir biçime uymuyor — hatalı üretilmiş, atılacak.

Senden bu dosyayı temizleyip bir rapor üretmen isteniyor. Rapor gece
otomatik çalışacak; okuyan bir insan değil, çıkış koduna bakan bir
alarm sistemi olacak.

Kaynak dosya salt okunurdur, üzerine yazma:

    /srv/raw/merged.log

Ara çıktılar buraya:

    /srv/work/

Görevler
--------

1. merged.log dosyasını normalleştir ve sonucu /srv/work/normal.log
   içine yaz:

   - GG/AA/YYYY biçimindeki tarihler YYYY-AA-GG biçimine çevrilir
   - ayırıcı karakterin solundaki ve sağındaki boşluklar silinir
   - satır sırası ve satır sayısı değişmez

2. normal.log satırlarını ikiye ayır:

   - biçime uyanlar /srv/work/valid.log
   - uymayanlar /srv/work/invalid.log

   Biçime uyan satır, baştan sona tam olarak dört alandan oluşur:

       tarih|seviye|ip|mesaj

   tarih YYYY-AA-GG biçiminde, seviye INFO WARN ERROR
   değerlerinden biri, ip dört sayıdan oluşan bir IPv4 adresi,
   mesaj boş olmayan serbest metin.

   İki dosyadaki satır sayısının toplamı normal.log ile aynı olmalı.

3. valid.log dosyasından özet üret ve /srv/work/ozet.txt içine yaz.
   Her seviye için tek satır, üç alan, aralarında tek boşluk:

       seviye toplam_satir tekil_ip_sayisi

   Yalnız valid.log içinde gerçekten geçen seviyeler yazılır.

4. /etc/labs/report.conf dosyasını düzenle:

   - # ile başlayan satırların hepsi silinecek
   - /opt/eski geçen her yol /srv/work olacak
   - retention satırındaki değer 30 yapılacak
   - diğer satırlar ve sıraları değişmeyecek

5. /usr/local/bin/mkreport script'ini yaz. Sırayla 1, 2 ve 3 numaralı
   adımları çalıştırır, sonra raporu /srv/reports/text-report.txt
   içine yazar.

   Raporun ilk satırı durum özetidir: invalid.log boş değilse DIRTY,
   boşsa CLEAN. Script'in çıkış kodu bu özeti yansıtır: DIRTY ise 1,
   CLEAN ise 0.

   Raporun devamında ozet.txt içeriği ve atılan satır sayısı yer alır.

   Rapor her çalıştırmada sıfırdan üretilir, üstüne eklenmez.
   Script student tarafından sudo'suz çalıştırılabilmelidir.

Kabul kriterleri
----------------

[ ] normal.log satır sayısı merged.log ile aynıdır

[ ] normal.log içinde GG/AA/YYYY biçiminde tarih kalmamıştır

[ ] normal.log içinde ayırıcı çevresinde boşluk kalmamıştır

[ ] normal.log satır sırası merged.log ile aynıdır

[ ] valid.log yalnız dört alanlı, tam eşleşen satırları içerir

[ ] valid.log içinde geçersiz seviye veya geçersiz ip yoktur

[ ] invalid.log geri kalan satırların hepsini içerir

[ ] valid.log ve invalid.log satır toplamı normal.log'a eşittir

[ ] ozet.txt her seviye için tek satır ve üç alan içerir

[ ] ozet.txt toplam sayıları valid.log ile uyuşur

[ ] ozet.txt tekil ip sayıları doğrudur

[ ] report.conf içinde # ile başlayan satır kalmamıştır

[ ] report.conf içinde /opt/eski geçmez, karşılıkları /srv/work olmuştur

[ ] report.conf retention değeri 30'dur

[ ] mkreport student tarafından sudo'suz çalıştırılır

[ ] text-report.txt ilk satırı DIRTY veya CLEAN'dir ve doğrudur

[ ] mkreport çıkış kodu raporun ilk satırıyla tutarlıdır

[ ] mkreport iki kez çalıştırıldığında rapor büyümez

[ ] merged.log değiştirilmemiştir

Kontrol
-------

Host terminalinden:

    ./labctl check 007b

Takıldın mı:

    ./labctl hint 007b 1
