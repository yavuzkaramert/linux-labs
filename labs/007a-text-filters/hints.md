# Hints — Lab 007a: Metin Filtreleri

## Seviye 1

Kavramsal. Komut adı yok.

- Bir dosyanın "kaç satırı var" ile "kaç satırı şu koşula uyuyor" farklı
  sorulardır. İkincisini sormak için önce süzmek, sonra saymak gerekir.
  Başlık satırı veri değildir; sayarken bunu kim halledecek?
- Bir kelimenin satırda geçmesi ile o kelimenin belirli bir sütunda olması
  aynı şey değildir. Sütunu görmeden sütunu süzemezsin. Bu senin 004 ve
  005'te iki kez düştüğün yer: seçmediğin sütunu grepleyemezsin.
- Her komut geride bir sayı bırakır. Bu sayı komutun ne bulduğunu söyler;
  ekrana bakmana gerek yoktur. Bir aramanın "buldu mu" cevabı ekranda değil
  o sayıda durur.
- Aynı şeyi saymak ile tekilleştirip saymak arasında bir sıralama adımı
  vardır. Ardışık olmayan tekrarları sayan araç yoktur; onları önce yan yana
  getirmek gerekir.
- Bir metin düzenleyicide "her yerde değiştir" ve "şu kalıba uyan satırları
  sil" tek tek elle yapılmaz. İkisinin de komutu vardır ve dosya 25 satır da
  olsa 25.000 satır da olsa aynı komut çalışır.
- Bir kalıbın "satırın başında" mı yoksa "satırın herhangi bir yerinde" mi
  arandığını sen söylemezsen araç ikincisini varsayar.

## Seviye 2

Araç adları. Bayrak yok.

- İlgili araçlar: `wc`, `grep`, `cut`, `sort`, `uniq`, `awk`, `head`, `tail`,
  `diff`.
- Süzme ile sayma ayrı iki araç işi olabilir; boru hattı bu yüzden var.
- Özel değişken: `$?`. Bir önceki komutun geride bıraktığı sayıyı taşır.
  `echo` ile ekrana basılır, yönlendirme ile dosyaya yazılır.
- `man grep` içinde "EXIT STATUS" bölümü var. Üç değeri ve anlamlarını orada
  yazıyor; hangi değerin ne demek olduğunu tahmin etmeye çalışma, oku.
- vi tarafında iki komut ailesi işini bitirir: `:s` (substitute) ve `:g`
  (global). Kaydedip çıkmak için `:w` ve `:q`.
- Uzun dosyayı `cat` ile değil `less` ile aç; içinde `/` ile arama yapılır,
  `q` ile çıkılır.

## Seviye 3

Bayrak ve parametre düzeyi. Tam komut yok.

- `grep`'in sessiz çalışan bir bayrağı var: hiçbir şey basmaz, yalnız çıkış
  kodu döner. Görev 4 tam olarak bunu istiyor.
- `uniq`'in saydıran bayrağı, çalışmadan önce girdinin sıralı olmasını
  bekler. Sırasız girdide sessizce yanlış sayar; hata vermez.
- `cut`'ın ayırıcı seçen ve alan seçen iki ayrı bayrağı var. Varsayılan
  ayırıcı sekmedir, bu dosyada işe yaramaz.
- `awk -F` ile ayırıcı verilir, alanlara `$1 $2 $3` diye erişilir. Bir alanı
  başka bir değerle karşılaştırmak awk'ın kendi işidir, ayrı bir grep
  gerekmez.
- `tail`'in `-n +N` biçimi baştan N-1 satırı atlar. `-n N` ile karıştırma:
  o sondan sayar.
- vi'da `:%s/eski/yeni/g` biçimindeki `%` tüm dosyayı kapsar, sondaki `g`
  satır içindeki tüm eşleşmeleri kapsar. `g` olmadan her satırda yalnız
  ilk eşleşme değişir.
- `:g/kalıp/d` kalıba uyan satırların hepsini siler.
- `^` satır başı çapasıdır. Çapasız yazılan kalıp satırın ortasındaki
  eşleşmeyi de yakalar ve silmemen gereken satırı siler.
