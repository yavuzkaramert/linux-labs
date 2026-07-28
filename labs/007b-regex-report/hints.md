# Hints — Lab 007b: Regex, Normalleştirme ve Rapor

## Seviye 1

Kavramsal. Komut adı yok.

- Bir metni **değiştirmek** ile bir metni **seçmek** farklı işlerdir,
  araçları da farklıdır. Birinci görev değiştirme, ikinci görev seçmedir.
  Aynı aleti ikisine de zorlamaya çalışırsan biri kötü olur.
- Değiştirme yaparken "bulduğum parçayı geri yazmam gerekiyor" durumu var:
  tarihin gün, ay ve yıl parçaları kayboluyor değil, yer değiştiriyor.
  Kalıp dilinde bulunan bir parçayı hatırlayıp yeniden kullanmanın bir yolu
  vardır.
- "Bu satır biçime uyuyor mu" sorusu, "bu satırda şu geçiyor mu" sorusundan
  farklıdır. İkincisi satırın tamamını taahhüt etmez: satırın ortasında
  doğru görünen bir parça bulunca "uyuyor" der. Bu dosyada tam olarak öyle
  satırlar var.
- "Dört alan" demek "en az dört alan" demek değildir. Beşinci alanı olan
  bir satır dört alanlı değildir; kalıbın bunu reddetmesi gerekir.
- Bir şeyin kaç kez geçtiğini saymakla kaç **farklı** değerinin olduğunu
  saymak farklı sorulardır. İkincisi hafıza ister: gördüğün değerleri bir
  yerde tutup tekrarları atman gerekir.
- Bir değeri satırın tamamından toplamakla belirli bir alandan toplamak
  farklı sonuç verir. Bu dosyada bazı mesajların içinde de IP ve seviye adı
  geçiyor.
- Zincirin son halkası, önceki halkaların başarısını nasıl öğrenir? Rapor
  metnini okuyan kimse yok; okuyan şey bir sayıya bakıyor. O sayı ile
  raporun ilk satırı **aynı gerçeği** söylemek zorunda.

## Seviye 2

Araç adları. Bayrak yok.

- İlgili araçlar: `sed`, `grep`, `awk`, `sort`, `uniq`, `wc`, `cut`, `tr`.
- Görev 1 `sed` işi, görev 2 `grep` işi, görev 3 `awk` işi. Üçü de tek
  satırlık.
- awk tarafında **ilişkisel dizi** var: anahtarı sayı olmak zorunda olmayan
  bir dizi. Bir de `END` bloğu var: girdi bittikten sonra bir kez çalışır,
  biriktirdiğini orada basarsın.
- Dizinin kaç anahtarı olduğunu söyleyen bir awk fonksiyonu var.
- vi'da toplu düzenleme `:%s` ve `:g` ile yapılır. `sed` ile de yapılır;
  kalıp dili ortak.
- Okunacak man bölümleri: `man grep` → "EXTENDED REGULAR EXPRESSIONS",
  `man sed` → "Regular expressions", `man awk` → "Arrays". Kalıp dilinin
  iki lehçesi olduğunu ve hangi bayrakla hangisine geçildiğini orada
  yazıyor.
- mkreport'un çıkış kodu için 006'daki `report` script'ine geri bak:
  sözleşme aynı, kaynağı tek.

## Seviye 3

Bayrak ve parametre düzeyi. Tam komut yok.

- `sed`'in yakalama grupları BRE'de `\(...\)` ile açılır ve değiştirme
  tarafında `\1 \2 \3` ile geri çağrılır. `-E` verirsen parantezler ters
  bölüsüz yazılır ve arama tarafı `grep -E` ile aynı ağzı konuşur — iki
  aracın kalıbını tek lehçede tutmak hata payını düşürür.
- `{n}` tekrar sayısı belirtir: "tam n kez". BRE'de ters bölü ister
  (`\{n\}`), ERE'de istemez. 004 debrief'inde düştüğün yer buydu.
- `^` ve `$` çapaları olmadan bir kalıp satırın herhangi bir yerinde
  eşleşir. "Biçime uyuyor mu" sorusunu yanlış cevaplayan tek eksik budur.
- `|` bu dosyada hem alan ayırıcın hem de regex'te alternatif operatörü.
  Birini kastederken diğeri anlaşılmasın diye kaçırılması gerekebilir;
  hangi bağlamda ne anlama geldiğini karıştırırsan kalıp sessizce başka
  bir şey arar.
- Bir karakter sınıfının içine `^` koyarsan anlamı tersine döner: "bunlar
  hariç". Mesaj alanının ayırıcı içermemesi gerektiğini böyle söylersin.
- `grep`'in eşleşmeyenleri basan bir bayrağı var; ikinci dosyayı ayrı bir
  kalıp yazmadan üretmenin yolu bu. Aynı kalıp, ters yön.
- awk'ta `dizi[$3]++` yapıp `END` içinde `length(dizi)` almak tekil sayımın
  deyimsel yoludur. İki boyut gerekiyorsa anahtarı birleştirebilirsin;
  awk'ın bunun için ayırdığı bir ayırıcı değişkeni var.
- awk'ta birleştirme yan yana yazmaktır; ayırıcı string literal olur
  (006 debrief'inde `$2:$1` yazıp takıldığın yer).
- vi'da `:%s/eski/yeni/g` — `%` tüm dosya, sondaki `g` satır içindeki tüm
  eşleşmeler. `:g/kalıp/d` kalıba uyan satırları siler; kalıba `^` koymazsan
  satır ortasındaki eşleşmeyi de siler.
- Script'te durum satırı ile çıkış kodu **aynı kaynaktan** türetilir. İki
  yerde ayrı ayrı hesaplarsan bir gün ikisi ayrışır ve alarm sistemi yanlış
  şeye bakar.
