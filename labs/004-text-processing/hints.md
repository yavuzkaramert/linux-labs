# İpuçları — Lab 004: Metin İşleme

## Seviye 1

- Bir dosyayı satır satır süzmek (belirli satırları seçmek), bir satırın
  belirli bir alanını almak, tekrar eden değerleri saymak, sayıya göre
  sıralamak, listenin ilk N tanesini almak ve metin içinde toplu değiştirme
  yapmak — bunların her biri **ayrı** bir iştir. Her biri için ayrı, küçük
  bir araç vardır; işi bu araçları bir zincir gibi birbirine bağlayarak
  çözersin.
- Bir alanı seçebilmek için satırın hangi karakterle bölündüğünü bilmen
  gerekir: boşluk, `|` veya `:` gibi. Aracına "ayraç bu" demen gerekir.
- Aynı değeri kaç kez gördüğünü saymak, önce onları yan yana getirmeyi
  (sıralamayı) ister.
- Bir dosyayı okuyabilmek bir izin/sahiplik meselesidir; içeriğini işlemekle
  karıştırma — önce erişimi açman gerekir.
- "Sadece 500 durum kodu" derken dikkat: aradığın sayı satırın belli bir
  alanında olmalı. Ham metinde aynı sayı başka yerde de geçebilir; alanı
  hedeflemeyen bir arama seni yanıltır.

## Seviye 2

- Satır süzme / kalıp arama: `grep` (ters çevirmek de mümkün)
- Alanlara bölüp belirli alanı almak veya alan bazlı koşul: `awk`
- Sabit sütun/alan kesmek: `cut`
- Sıralama: `sort` — Tekilleştirme ve sayma: `uniq`
- Satır/kelime saymak: `wc`
- Baştan N satır: `head`
- Metin içinde arama-değiştirme ve satır seçerek düzenleme: `sed`
- İzin/sahiplik: `chmod`, `chown`
- Dosya kopyalama (orijinali saklamak için): `cp`
- Görev eşleşmesi: hata satırları → alan koşulu; en çok IP → say + sırala +
  ilk 5; farklı kullanıcı → tekilleştir + say; WARN tablosu → ayraçlı alan
  seçimi; ayar düzeltme → satır-seçici değiştirme.

## Seviye 3

- `grep`: `-v` eşleşmeyenleri verir, `-E` genişletilmiş regex, `-c` sayar,
  `-i` büyük/küçük harf duyarsız.
- `awk -F` ayraç belirler (`-F'|'` gibi). Alanlara `$1`, `$3` ... ile,
  son alana `$NF`, sondan bir öncekine `$(NF-1)` ile erişirsin. Koşul:
  `awk '$(NF-1)==500'`. TAB üretmek için çıktıda `\t` kullan
  (`printf "%s\t%s\n", $1, $3`).
- `sort -rn` sayısal ve tersten (büyükten küçüğe) sıralar; `sort -u`
  sıralayıp tekilleştirir.
- `uniq -c` her satırın kaç kez tekrarlandığını başına yazar (önce `sort`
  gerekir).
- `wc -l` satır sayar. `head -n 5` ilk 5 satır.
- `sed` yerine koyma genel biçimi `s/desen/yeni/` ve `g` bayrağı satırdaki
  tüm eşleşmeler için. Belirli satırları hedeflemek/dışlamak için satır
  seçici kullanılır (bir desenle başlayan satırları hariç tutmak gibi);
  yerinde düzenleme için `-i`.
- Tam komutlar hiçbir seviyede verilmez — zinciri sen kur.
