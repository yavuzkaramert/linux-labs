## Seviye 1

Bu bir tekrar labı. Seviye 2 ve 3 bilerek yok: komut adı ve bayrak
verilmiyor. Takıldığın yerde kaynak lab'ın kendi hints ve solution
dosyasını aç — asıl amaç orayı hatırlaman.

### Ticket 7 — Destek talepleri dökümü

Satır bazlı arama ile alan bazlı arama farklı sorulardır. Ayraçlı
bir dosyada "durumu open olan" ile "içinde open geçen" aynı şey
değildir; ikincisi konu alanındaki kelimeyi de yakalar.

Bir aramanın çıkış kodu, bulup bulmadığını söyler. Bu kod çıktının
kendisi değildir; ayrı bir kanaldır ve komut bittikten hemen sonra
okunur.

Yerinde düzenlemede çıpa önemlidir: "satırın başında" ile "satırın
herhangi bir yerinde" ayrı desenlerdir. Değiştirme işleminin
varsayılanı satır başına bir kez çalışır; bir satırda iki eşleşme
varsa ikincisi sessizce kalır.

Bu konuyu lab 007a'da gördün.

### Ticket 8 — Karışık log'u temizle ve otomatik rapor kur

Bir kalıbın başına ve sonuna çıpa koymazsan, kalıbı içeren her satır
eşleşir — kaydın önünde serbest metin olsa bile. "Mesaj alanında
ayraç yok" şartı da tam olarak bunun için vardır: aksi hâlde fazladan
alan taşıyan bozuk satırlar geçerli sayılır.

Normalizasyon iki ayrı iştir: tarih biçimi ve boşluk temizliği.
İkisini tek geçişte yapabilirsin ama satır sayısı değişmemeli —
hiçbir satır silinmiyor, yalnız yeniden yazılıyor.

Tekil sayım yaparken neyin tekilliğini saydığına dikkat et: alanın
kendisi mi, yoksa satırın tamamı mı? Mesaj gövdesinde geçen bir
adres, adres alanı değildir.

Bir raporlayıcının çıkış kodu ile raporun ilk satırı aynı bilgiyi
iki farklı kanaldan söyler; ikisi çelişirse çağıran taraf yanılır.
İdempotentlik, ikinci çalıştırmanın birincisiyle bayt bayt aynı
sonucu vermesidir.

Bu konuyu lab 007b'de gördün.

### Ticket 9 — Dosya yerleşimi, bağlantılar, arşiv

Sert bağlantı ile sembolik bağlantı farklı şeylerdir: biri aynı
inode'a ikinci bir isimdir, diğeri bir yola işaret eden ayrı bir
dosyadır. Disk kullanımını sayan araç aynı inode'u iki kez saymaz;
dosya boyutlarını tek tek toplayan bir hesap sayar.

"Taşımak" ile "kopyalamak" farklıdır. Eski konumda bir şey kalıyorsa
taşıma yapılmamıştır.

Arşive bir şeyi dâhil etmemenin yolu onu kaynaktan silmek değildir;
arşivleme aracının kendi dışlama mekanizması vardır. Kaynak dizinler
bu ticket'ta salt okunur kabul edilir.

Standart dizin düzeni rastgele değildir: yapılandırma, günlük ve
yerel olarak kurulmuş çalıştırılabilir dosyalar için ayrı ayrı
kararlaştırılmış yerler vardır.

Bu konuyu lab 008'de gördün.

### Ticket 10 — Paket durumu

Bir deponun tanımının diskte olması onun etkin olduğu anlamına
gelmez. Etkinleştirme ayrı bir işlemdir ve kalıcıdır.

Bir bağımlılık çözülemediğinde paket yöneticisi hangi paketin
eksik olduğunu söyler; aradığın depo adı çoğu zaman o hata
mesajının içindedir.

Paketleri kurmadan inceleyebilirsin: hem rpm hem deb tarafında,
dosyanın kendisini sorgulayan ayrı bayraklar vardır. Bir soruyu
"kurulu paket" olarak mı yoksa "paket dosyası" olarak mı sorduğuna
dikkat et; ikisi farklı bayraklardır.

Bütünlük doğrulama aracı varsayılan olarak bir paket ADI bekler.
Elinde yalnız dosya yolu varsa, ya önce o dosyanın hangi pakete ait
olduğunu sorarsın ya da aracın dosya-yolu alan biçimini kullanırsın.
Çıktıdaki her harf ayrı bir değişikliği gösterir; içerik ile izin
ayrı sütunlardır.

Bu konuyu lab 009'da gördün.

### Ticket 11 — Dört systemd işi

Bir birimin tipi, systemd'nin "bu iş bitti mi?" sorusunu nasıl
cevaplayacağını belirler. Tek seferlik çalışıp biten bir iş, varsayılan
tipte "öldü" sayılır; tamamlandıktan sonra ayakta görünmesini
istiyorsan bunu ayrıca söylemen gerekir.

Sıralama bağı ile gereklilik bağı ayrı şeylerdir. Biri "önce şu
başlasın" der, diğeri "o olmadan ben olmam" der. İkisini birden
istiyorsan ikisini de yazarsın.

Bir birim dosyasını diskte değiştirmek yetmez; systemd kendi
belleğindeki tanımı kullanmaya devam eder. Tazeleme ayrı bir adımdır
ve unutulduğunda birim "değişti ama uygulanmadı" durumunda kalır.

"Aktif görünüyor" ile "gerçekten bir süreci var" farklı sorulardır;
sorgulayacağın alanlar da farklıdır.

Bu konuyu lab 010'da gördün.

### Ticket 12 — Log, cron ve saat

Günlüklerin yeniden başlatmadan sonra da durması varsayılan değildir.
Hem yapılandırmada bir tercih, hem diskte bir dizin, hem de bellekteki
kayıtların diske aktarılması gerekir; üçü ayrı adımdır.

Zamanlanmış işler senin kabuk ortamınla çalışmaz. Onlara verilen
arama yolu çok dardır ve yerel olarak kurduğun dizinleri içermez.
Elle çalıştırdığında çalışıp zamanlandığında sessizce çalışmayan bir
komutun ilk şüphelisi budur.

Zamanlayıcı birimi ile onun tetiklediği iş birimi iki ayrı dosyadır
ve aralarındaki eşleşme isim üzerinden kurulur. Zamanlayıcının
"bir sonraki ne zaman" bilgisi süre olarak da zaman damgası olarak da
sorulabilir; hangisini okuduğuna dikkat et.

Saat dilimi ve saat senkronu ayrı ayarlardır. Birini düzeltmek
diğerini düzeltmez.

Bu konuyu lab 011'de gördün.

### Ticket 13 — Erişim sertleştirme: SSH + GPG

Anahtarla giriş üç ayrı iznin aynı anda doğru olmasını ister:
anahtar dosyasının, onu tutan dizinin ve ev dizininin. Sunucu bu
kontrolü sessizce yapar; istemciye "izinler yanlış" demez, yalnız
reddeder.

Yapılandırmayı değiştirmek ile onu uygulamak farklıdır. Servis
yeniden okumadıkça diskteki dosya sadece bir dosyadır. Değiştirmeden
önce sözdizimini sınamak, kendini dışarıda bırakmanı önler.

İmza doğrulama ile şifreleme farklı sorulara cevap verir: biri "bunu
kim yazdı ve değişti mi?", diğeri "bunu kim okuyabilir?". Ayrık imza,
imzayı dosyanın içine gömmeden ayrı bir dosyada tutar — orijinal dosya
olduğu gibi kalır.

Bir imzanın doğrulanabilmesi için imzalayanın açık anahtarının senin
anahtarlığında olması gerekir. Doğrulama başarısız olması bir hata
değil, bir sonuçtur: dosyanın değiştiğini söyler.

Bu konuyu lab 012'de gördün.
