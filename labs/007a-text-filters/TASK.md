Lab 007a — Metin Filtreleri: Okuma ve Süzme
===========================================

Hikâye
------

Destek ekibi bilet dökümünü ve web sunucusunun erişim kaydını sana
bıraktı. Senden istenen basit sorulara cevap üretmek. Senden önceki
stajyer cevapların bir kısmını çoktan yazmış — ama kimse kontrol
etmemiş. Dosyalar duruyor, içindeki sayılar tutmuyor.

Hiçbir cevabı elle sayarak bulma. Her cevap bir komutun çıktısı
olmalı; veri yarın değişirse aynı komut yeni doğru cevabı vermeli.

Veri dosyaları salt okunurdur, değiştirilmez:

    /srv/data/tickets.csv
    /srv/data/access.log

Cevaplar şu dizine yazılır:

    /home/student/cevaplar/

Görevler
--------

1. tickets.csv dosyasındaki veri satırı sayısını bul. Başlık satırı
   sayılmaz. Yalnız sayıyı, tek satır olarak 01-adet.txt içine yaz.

2. Durum alanı open olan biletlerin tam satırlarını 02-acik.txt
   içine yaz. Satırların sırası bozulmaz.

   Dikkat: open kelimesi bazı biletlerin konu alanında da geçiyor.
   Yalnız durum alanı sayılır.

3. Her önceliğin kaç bilet aldığını say. Her öncelik için tek satır,
   biçim: sayı ve öncelik adı, aralarında boşluk. Sonucu
   03-oncelik.txt içine yaz. Sıralama önemsiz.

4. access.log içinde DENIED kelimesinin geçip geçmediğine bak. Arama
   ekrana hiçbir şey basmamalı; yalnız aramanın çıkış kodunu tek
   satır olarak 04-kod.txt içine yaz.

   Aynı şeyi hiç geçmeyen bir kelime için tekrarla ve çıkış kodunu
   05-kod.txt içine yaz.

5. /srv/data/notlar.txt dosyasını düzenle:

   - TODO ile başlayan satırların hepsi silinecek
   - sunucu1 geçen her yer web01 olacak
   - dosyanın geri kalanı ve satır sırası değişmeyecek

Kabul kriterleri
----------------

[ ] 01-adet.txt tek satır ve yalnız sayı içerir

[ ] 01-adet.txt'deki sayı başlık hariç veri satırı sayısına eşittir

[ ] 02-acik.txt yalnız durumu open olan satırları içerir

[ ] 02-acik.txt konu alanında open geçen kapalı bileti içermez

[ ] 02-acik.txt satır sırası kaynak dosyadaki sırayla aynıdır

[ ] 03-oncelik.txt her öncelik için tek satır içerir

[ ] 03-oncelik.txt sayıları gerçek dağılıma eşittir

[ ] 04-kod.txt tek satır ve yalnız çıkış kodu içerir, değeri 0'dır

[ ] 05-kod.txt tek satır ve yalnız çıkış kodu içerir, değeri 1'dir

[ ] notlar.txt içinde TODO ile başlayan satır kalmamıştır

[ ] notlar.txt içinde sunucu1 geçmez, karşılıkları web01 olmuştur

[ ] notlar.txt'nin diğer satırları ve sırası değişmemiştir

[ ] /srv/data altındaki tickets.csv ve access.log değiştirilmemiştir

Kontrol
-------

Host terminalinden:

    ./labctl check 007a

Takıldın mı:

    ./labctl hint 007a 1

Uzun dosyaları okurken cat yerine less kullan, sayfalanır:

    less /lab/TASK.md
