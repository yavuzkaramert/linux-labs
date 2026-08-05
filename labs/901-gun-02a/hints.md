## Seviye 1

Bu bir tekrar labı. Seviye 2 ve 3 bilerek yok: komut adı ve bayrak
verilmiyor. Takıldığın yerde kaynak lab'ın kendi hints ve solution
dosyasını aç — asıl amaç orayı hatırlaman.

### Ticket 1 — Kurtarılan dosyalarda karışık izin

Bir dosyaya erişmek için iki ayrı kapıdan geçersin: dosyanın kendi
izin bitleri ve o dosyaya giden dizinlerin geçiş (execute) biti.
Dosyayı 0644 yapmak, dizin kapalıysa hiçbir işe yaramaz.

Sahiplik değiştirmek her izin probleminin çözümü değildir. Sistem
dosyaları sistemin kalır; senin değiştireceğin şey izin bitleridir.
Ayrı bir soru: "student okuyabiliyor mu?" ile "dosyanın modu doğru
mu?" farklı iki kriterdir, ikisini de ayrı ayrı sına.

Bu konuyu lab 001'de gördün.

### Ticket 2 — Personel hesaplarını yedek sunucuda kur

Bir kullanıcının bir birincil grubu, sıfır veya daha fazla ikincil
grubu vardır. İkisi farklı yerlerde saklanır ve farklı bayraklarla
ayarlanır; birini ayarlarken diğerini ezmek klasik hatadır.

Servis hesapları insan hesabı değildir: giriş kabuğu yoktur ve ev
dizini istemezler. Ev dizininin otomatik açılması varsayılan
davranıştır — kapatmak ayrı bir tercihtir.

Paylaşılan bir dizinde "kim açarsa açsın dosya aynı gruba düşsün"
davranışı normal izin bitlerinden gelmez; dizin üstünde ayrı bir bit
vardır. O bit olmadan ekip birbirinin dosyasına yazamaz.

Ve kritik olan: 2770 bir dizinde "other" hiçbir şey göremez. Sen o
grupta değilsen sonraki ticketlarda kendi yetkinle çalışamazsın.

Bu konuyu lab 002'de gördün.

### Ticket 3 — Kurtarılan klinik verisini düzenle

Dosya arama aracın hem yaşa, hem boyuta, hem türe, hem de isme göre
süzebilir; bunları birleştirebilirsin. Bulduğun şeyi tek tek elle
taşımak yerine aynı komuta iş yaptırabilirsin.

"Boş dosya" ile "boş dizin" aynı şey değildir; süzgecin hangisini
seçtiğine dikkat et.

Kopyalama varsayılan olarak metadata taşımaz. İzin, sahiplik ve
değişiklik zamanının korunması ayrıca istenir. Birebir kopya
denildiğinde kastedilen budur.

Sembolik link kurarken "en yeni dosya" ile "en yeni belirli türde
dosya" farklı sorulardır. Sıralamayı neye göre yaptığını düşün.

Bu konuyu lab 003'te gördün.

### Ticket 4 — Log ve ayar analizi

Satır bazlı arama ile alan bazlı arama farklı sonuç verir. Bir sayı
log satırının birden çok yerinde geçebilir: durum kodu, boyut,
hatta yolun içinde. Doğru cevap "hangi alanda?" sorusunu sorar.

Aynı şey seviye adları için de geçerli: bir kayıt satırının mesaj
gövdesinde başka bir seviyenin adı geçebilir. Alan farkındalığı
olmayan sayım her seferinde fazla sayar.

Sıralama ve tekilleştirme birlikte çalışır; hangisinin önce
geldiği sonucu değiştirir. "En çok" sorusu sayma, sıralama ve
kesme adımlarının zinciridir.

Yerinde düzenleme yaparken yorum satırlarını korumak, süzgecin
neyi hedeflediğini daraltmakla olur — tüm eşleşmeleri değil,
yalnız aktif satırdakileri.

Bu konuyu lab 004'te gördün.

### Ticket 5 — Başıboş süreçler

Süreçleri ararken iki farklı alana bakabilirsin: sürecin adı
(comm) ve tam komut satırı. Bir süreç kendini comm alanında başka
bir şey gibi gösterebilir; işaret komut satırında durur.

Kendi arama komutun da bir süreçtir ve kendi aradığı metni
içerir. Çıktına karışması bir hata değil, beklenen davranıştır —
önlemek senin işin.

Sinyaller kibar ve kibar olmayan diye ikiye ayrılır. Kibar olanı
süreç yakalayıp yok sayabilir; diğeri yakalanamaz.

Öncelik değeri sıradan bir kullanıcı için tek yönlüdür: yalnız
düşürebilirsin, yükseltemezsin. Hangi yönün hangisi olduğuna
dikkat et.

Bu konuyu lab 005'te gördün.

### Ticket 6 — Gün sonu özet scriptleri

Bir script'in sözleşmesi üç parçadır: standart çıktı, standart
hata ve çıkış kodu. Hata mesajı standart çıktıya giderse
sözleşme bozulur — çağıran taraf onu veri sanır.

Argüman kontrolü işi yapmadan ÖNCE gelir. Dosyanın var olması ile
okunabilir olması ayrı iki kontroldür; biri diğerini kapsamaz.

Bir raporun idempotent olması, ikinci çalıştırmanın birincisiyle
bayt bayt aynı sonucu vermesi demektir. Ekleme yapan bir yazma
kipi bunu bozar.

Listelerde yorum ve boş satır olur. Onları atlamak scriptin
işidir; atlamazsan var olmayan bir servisi arar ve raporu yanlış
çıkarırsın.

Bu konuyu lab 006'da gördün.
