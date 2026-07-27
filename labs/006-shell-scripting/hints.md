# İpuçları — Lab 006: Shell Scripting Temeli

## Seviye 1

- Bir script'in "başarısı" ekrana bastığı şey değil, geride bıraktığı
  sayıdır. Bu sayıyı kim okur, bir sonraki komut ona nasıl bakar? Gece
  çalışan zincirde ekranı kimse görmüyor — karar bu sayıyla veriliyor.
- Metni sütunlara bölen araç, bir sütunun nerede bittiğini nereden bilir?
  Varsayılan kabulü nedir, senin dosyan o kabule uyuyor mu? Uymuyorsa
  aracın ayırıcıyı sana sorması gerekir.
- Bir satırın *ikinci alanı* ile *satırın içinde geçen bir kelime* aynı şey
  değildir. Log mesajlarının gövdesinde de seviye adları geçiyor; sayarken
  neye baktığın belirleyici.
- Hata mesajı ile veri aynı akıştan gitmemeli. Neden? Çünkü bu script'in
  çıktısı başka bir dosyanın içine yazılıyor — hata mesajı veriyle aynı
  yerden çıkarsa raporun ortasına sızar.
- Bir dosyanın "var olması" ile "senin onu okuyabilmen" aynı şey mi? İkisini
  ayrı ayrı sınayabilen araçlar var; hangisini sorduğun sonucu değiştirir.
- Bir script başka bir script'in sonucunu nasıl öğrenir? O sonucu bir
  döngü boyunca nasıl biriktirip, sonunda kendi kararına nasıl çevirir?
  Tek bir başarısızlık tüm raporun durumunu belirliyor.
- Bir dosyayı satır satır işleyeceksen, satırın kendisiyle ne yapacağına
  karar vermeden önce onu *atlamaya* karar verebilmen gerekir.
- Süreç ararken kendi arama işlemin de bir süreçtir ve senin verdiğin
  metni komut satırında taşır. Sonuçlarda kendini görebilirsin.

## Seviye 2

- İlgili araçlar: `awk`, `pgrep`, `printf` / `echo`, `exit`, `test` / `[ ]`,
  `read`, `sort`, `uniq`.
- Özel değişkenler: `$1` (ilk argüman), `$#` (argüman sayısı), `$@` (tüm
  argümanlar), `$?` (son komutun çıkış kodu). Kendi süreç kimliğini taşıyan
  bir değişken de vardır, ebeveyninkini taşıyan da.
- Döngüler: `for` ve `while`. Bir komutun çıktısını değişkene almak için
  komut ikamesi vardır.
- Bir seviyeden kaç tane olduğunu saymanın iki yolu var: `awk` içinde
  ilişkisel dizi ile saymak, ya da alanı ayıklayıp `sort` + `uniq`'e
  vermek. İkincisinde çıktının biçimini sonradan düzeltmen gerekir.
- `man bash` içinde "Special Parameters" ve "Compound Commands" bölümlerine
  bak; `man test` çıkış kodlarıyla dosya sınamalarını listeler.
- Görev eşleşmesi: logsum → alan ayırıcısı + sayma + çıkış kodu sözleşmesi;
  svccheck → argüman döngüsü + süreç arama + biriktirilen çıkış kodu;
  report → satır satır okuma + süzme + diğer iki script'i çağırma.

## Seviye 3

- `awk`'ın alan ayırıcısını değiştiren bir bayrağı var. Alanlara `$1`, `$2`
  ile erişilir — ve bu `$1` script'in `$1`'i **değildir**; awk programını tek
  tırnak içine almazsan shell onu senden önce yorumlar.
- `pgrep` varsayılan olarak süreç *adına* bakar; tam komut satırına baktıran
  bayrak, işareti argüman olarak taşıyan kendi süreç satırını da kapsama
  alır — kendi aramanı bulman burada başlar. `pgrep`'in bir de "tam eşleşme"
  bayrağı vardır, alt dizge eşleşmesini kapatır.
- `>&2` çıktıyı hata akışına yönlendirir. `exit` argüman almazsa son komutun
  çıkış kodunu taşır — bu bazen tam istediğin şeydir, bazen felakettir.
- `test`'in `-f` ve `-r` bayrakları farklı soruları yanıtlar; `-z` boş
  dizgiyi sınar. Bir sınamayı `!` ile tersine çevirebilirsin.
- Satır satır okumanın deyimsel hâli `while IFS= read -r ...` biçimindedir;
  döngüye dosyayı `< dosya` ile beslersin. Son satırın sonunda yeni satır
  yoksa `read` o satırı okur ama başarısız döner — döngü koşulunu buna göre
  kurmalısın.
- Yorum ve boş satırları elemek için `case` deseni ya da `[ -z ]` +
  desen eşleştirme kullanabilirsin; `continue` döngünün kalanını atlar.
- Çıkış kodunu biriktirmek: bir değişkeni 0 ile başlat, her başarısızlıkta
  1 yap, döngü bitince o değişkenle çık. Bir komutun başarısızlığını
  yakalamak için `||` yeterlidir.
- Dosyayı sıfırdan üretmek `>`, üstüne eklemek `>>`. Rapor her koşuda
  sıfırdan üretilmeli; ilk satırın en sona hesaplandığı durumda gövdeyi
  geçici bir yerde biriktirip sonunda tek seferde yazmak işini kolaylaştırır.
- Hiçbir seviyede tam komut verilmez — zinciri sen kur.
