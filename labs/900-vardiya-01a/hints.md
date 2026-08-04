# Hints — Lab 900-vardiya-01a: Vardiya, Sabah

Bu bir tekrar labı. Yalnızca **seviye 1** (kavramsal) ipucu var —
komut adı, bayrak, tam çözüm yok. Daha fazlasına ihtiyacın olursa
her ticket'ın kaynak lab'ına dön ve oradaki `solution.md`'yi aç.

## Seviye 1

### Ticket 1 — Vardiya günlüğü (kaynak: lab 001)

Bir dosyaya erişimi olan üç taraf var: sahip, grup ve "diğer
herkes". Sen sahibi değilsin, grubunda da değilsin. Geriye tek bir
taraf kalıyor — istenen okuma iznini oraya vereceksin, yazma iznini
oraya vermeyeceksin.

Dosyaya ulaşmak yetmez: dosyanın durduğu dizinden geçebilmen de
gerekir. Dizinde "geçiş" izni okuma izninden ayrı bir bit.

> Bu konuyu lab 001'de gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 2 — İşe alımlar ve proje dizini (kaynak: lab 002)

Bir kullanıcının birincil grubu ile ikincil grupları farklı
şeylerdir; kullanıcı açarken birincil olan varsayılan olarak
üretilir, ikincil olanı ayrıca eklersin.

Servis hesabının insan gibi oturum açmasını istemiyorsan kabuğunu
buna göre seç; ev dizini istemiyorsan onu da açıkça belirt.

Bir dizinde açılan yeni dosyaların grubunun kendiliğinden dizinin
grubuna düşmesini istiyorsan, dizine standart üç haneye ek bir bit
gerekir. O bit `2770`'in başındaki `2`.

Grup üyeliği değişikliği, o kullanıcının **yeni** oturumunda
geçerli olur. Kendini bir gruba ekledikten sonra hâlâ eski
oturumdaysan değişikliği göremezsin.

> Bu konuyu lab 002'de gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 3 — Proje dizinini temizle (kaynak: lab 003)

Bütün maddeler tek bir arama aracının farklı ölçütleriyle çözülür:
değişiklik zamanı, boyut, tip, isim kalıbı, izin biti. Her madde
için "hangi ölçüt?" diye sor, sonra bulduklarını ne yapacağına
karar ver — taşımak, silmek, izin vermek.

Kopyalarken metadata korunması istiyorsa, düz kopyalama yetmez;
kopyalama aracının "her şeyi olduğu gibi al" kipini kullanacaksın.
`root:root` bir dosyanın sahipliğini koruyarak kopyalamak için
yetki de gerekir.

"En yeni dosya" ile "en yeni `.csv`" aynı şey değil. Önce filtrele,
sonra sırala.

> Bu konuyu lab 003'te gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 4 — Log analizi (kaynak: lab 004)

Satırı bir bütün metin olarak değil, **alanlara** bölünmüş bir kayıt
olarak düşün. Durum kodu belli bir alanda; aynı sayı başka alanlarda
da geçiyor. Alan farkındalığı olan bir araç kullanırsan tuzağa
düşmezsin.

"En çok" türü sorular hep aynı zincirdir: ilgili alanı çıkar,
sırala, tekrarları say, sayıya göre tersten sırala, baştan kes.

Yapılandırma dosyasında yalnız **etkin** satırlar değişecek, yorum
satırları değişmeyecek. Yani değiştirme işlemini satırın yorum olup
olmadığına bağlamalısın.

Değiştirmeden önce orijinali sakla — sonradan geri alamazsın.

> Bu konuyu lab 004'te gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 5 — Başıboş süreçler (kaynak: lab 005)

Süreçleri PID ile değil, komut satırlarındaki işaretle bul: PID her
koşuda değişir, işaret değişmez. Kendi arama komutun da bir süreçtir
ve kendi arama kalıbını komut satırında taşır — çıktına karışır.

Sinyal göndermek bir istektir, emir değil. Süreç isteği yakalayıp
görmezden gelebilir. Yakalanamayan tek bir sinyal vardır.

Önceliği düşürmek öldürmek değildir. Çalışan bir sürecin önceliğini
değiştiren ayrı bir komut var; normal kullanıcı önceliği yalnızca
düşürebilir (nice değerini artırabilir), yükseltemez.

> Bu konuyu lab 005'te gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 6 — Gün ortası özet raporu (kaynak: lab 006)

Bir script'in sözleşmesi üç parçadır: standart çıktı (sonuç),
standart hata (insana mesaj) ve çıkış kodu (makineye mesaj).
Üçünü karıştırmayacaksın: hata mesajı asla sonuç kanalına gitmez.

Kontrolleri işi yapmadan **önce** yap. "Dosya var mı" ile "dosyayı
okuyabiliyor muyum" iki ayrı sorudur; ikincisi cevabı olmayanı da
kapsar.

Listeyi satır satır okurken boş satırı ve yorum satırını atlamak
senin işin; atlamazsan onları da servis sanarsın.

Bir script içinden başka bir script'i çağırdığında, o çağrının
çıkış kodunu okumak zorundasın — yoksa toplam durumu (sağlıklı mı,
bozuk mu) hesaplayamazsın.

Rapor her çalıştırmada sıfırdan üretilmeli. Dosyaya eklemekle
dosyayı yeniden yazmak arasındaki fark tam olarak budur.

> Bu konuyu lab 006'da gördün, oradaki `solution.md`'ye bakabilirsin.
