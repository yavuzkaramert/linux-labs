# Hints — Lab 900-vardiya-01b: Vardiya, Öğleden Sonra

Bu bir tekrar labı. Yalnızca **seviye 1** (kavramsal) ipucu var —
komut adı, bayrak, tam çözüm yok. Daha fazlasına ihtiyacın olursa
her ticket'ın kaynak lab'ına dön ve oradaki `solution.md`'yi aç.

## Seviye 1

### Ticket 7 — Destek bileti dökümü (kaynak: lab 007a)

Bir CSV satırı düz metin değil, ayraçla bölünmüş alanlar dizisidir.
"Durumu open olan" ile "içinde open geçen" farklı sorulardır;
birincisi belli bir alana bakmayı gerektirir.

Başlık satırı veri değildir. Saydığın şeyin ne olduğunu bir kez
daha düşün.

Bir aramanın iki ayrı çıktısı vardır: ekrana bastığı ve geriye
döndürdüğü. İkincisi "bulundu mu" sorusunun cevabıdır ve ekrana
hiçbir şey basmadan da alınabilir.

Satır başına çapa atmakla satırın herhangi bir yerini aramak
farklı şeylerdir. Bir de: değiştirme işlemi varsayılan olarak her
satırda yalnız İLK eşleşmeyi değiştirir.

> Bu konuyu lab 007a'da gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 8 — Karışık log ve otomatik rapor (kaynak: lab 007b)

Tarih çevirmek bir yakalama-grubu işidir: parçaları yakala, sırayı
değiştirerek geri yaz.

"Baştan sona tam olarak dört alan" cümlesi iki şey söylüyor: hem
başa hem sona çapa atacaksın, hem de son alan ayraç İÇEREMEZ.
Mesaj alanını "her şey" diye tanımlarsan beş alanlı satırlar da
geçerli sayılır.

Bir satırın geçersiz olması onu atmanı gerektirmez; iki kovaya
ayıracaksın ve iki kovanın toplamı kaynağa eşit kalacak.

Tekil sayım için ilişkisel bir dizi (anahtar → değer) düşün.
Anahtarın ne olduğu önemli: seviye mi, seviye+ip mi?

Rapor script'inin sözleşmesi 006'daki gibi: ilk satır durumu
söyler, çıkış kodu aynı durumu makineye söyler, dosya her koşuda
sıfırdan üretilir.

> Bu konuyu lab 007b'de gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 9 — Dosya yerleşimi ve arşivleme (kaynak: lab 008)

Taşımak kopyalamak değildir: eski konumda hiçbir şey kalmayacak.
Hedef dizin yoksa önce onu açacaksın.

İki dosyanın içeriği aynı olabilir ama kimlikleri farklıdır.
İçeriği karşılaştıran araçlar bu farkı göremez; dosya sisteminin
dosyaya verdiği numaraya bakman gerekir.

Sembolik bağlantı bir yol saklar, sabit bağlantı ise aynı dosyanın
ikinci bir adıdır. Birini silmek diğerini etkilemez ama ikisinin
davranışı aynı değildir.

"Diskte kapladığı yer" ile "boyutları toplamı" aynı sayı değildir:
aynı veriye iki ad veriyorsan disk onu bir kez sayar.

Arşivden bir şey dışarıda bırakmak, onu diskten silmek anlamına
gelmez. Arşivleme aracının bunun için bir seçeneği var.

Bir arşivin içeriğini görmek için onu açman gerekmez.

> Bu konuyu lab 008'de gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 10 — Paket durumu (kaynak: lab 009)

Paket yöneticisi iki ayrı soruya cevap verir: "bu dosya hangi
pakete ait?" ve "bu paket hangi dosyaları kurdu?" İkisi de tek bir
sorgu aracının farklı kipleridir.

Bir paketin kurduğu dosyaların bozulup bozulmadığını paket
yöneticisi kendi kayıtlarıyla karşılaştırabilir; çıktısındaki her
harf farklı bir özelliği (içerik, izin, sahip, zaman) temsil eder.

Kurulu olmayan bir komutun hangi paketten geldiğini depo
verisinden sorabilirsin; dosya adından tahmin etmen gerekmiyor.

Paket yöneticisi yaptığı her işlemi kaydeder ve bu kayıtlar geri
alınabilir. "En son işlem" ile "aradığın işlem" aynı olmayabilir;
önce listeye bak.

Bir paket DOSYASINI incelemek ile kurulu bir paketi sorgulamak
farklı kiplerdir. İncelemek kurmak değildir.

Bazı paketler varsayılan olarak kapalı depolardan gelir; bir
bağımlılık bulunamıyorsa eksik olan paket değil, depo olabilir.

> Bu konuyu lab 009'da gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 11 — systemd (kaynak: lab 010)

Servis tipini belirleyen şey programın davranışıdır: ön planda mı
kalıyor, fork mu ediyor, bir kez çalışıp çıkıyor mu?

Bir birim iki ayrı sebepten çökebilir ve birincisi ikincisini
gizleyebilir. Durum çıktısındaki çıkış kodu hangisinin devrede
olduğunu söyler; tahmin etme, oku.

Diskteki dosyayı düzeltmek yetmez: systemd tanımı bellekte tutar.
Ayrıca birim dosyasını okuyup okumadığını sana ayrıca söyleyebilir.

Sıralama ile gereklilik farklı şeylerdir. Biri "önce şu çalışsın"
der, diğeri "o olmadan ben başlamam" der. İkisi de gerekiyorsa
ikisini de yazacaksın.

Kalıcılık bir konum meselesidir: geçici dizinde duran birim
yeniden başlatmada kaybolur.

> Bu konuyu lab 010'da gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 12 — Log, cron ve saat (kaynak: lab 011)

Sistemin günlüğü varsayılan olarak bellekte tutulabilir; kalıcı
olması için gideceği yerin var olması gerekir.

Günlüğü birime göre, önceliğe göre, zamana göre ve süreç
numarasına göre süzebilirsin. Bir servis sürekli yeniden
başlıyorsa her denemenin ayrı bir kaydı vardır.

Zamanlanmış bir işin çalışmaması için üç şey birden bozuk olabilir:
servis çalışmıyordur, zamanı gelmemiştir, ya da komut zamanlayıcının
ortamında bulunamıyordur. Zamanlayıcının PATH'i senin kabuğununki
gibi değildir.

"İş tanımlandı" ile "iş çalıştı" farklı şeylerdir. Kanıt log
dosyasındaki gerçek satırdır.

Zamanlayıcı birimi, tetikleyeceği işi ad benzerliğiyle bulur; ama
tetiklenen tarafın da bir birim olarak tanımlı olması gerekir.

Saat dilimini değiştirmek yalnız görüntüyü değiştirir; senkron
ayrı bir servisin işidir ve o servisin nereye soracağını bilmesi
gerekir.

> Bu konuyu lab 011'de gördün, oradaki `solution.md`'ye bakabilirsin.

### Ticket 13 — SSH ve GPG (kaynak: lab 012)

Anahtarla giriş bir izin zinciridir: sunucu yalnız dosyaya değil,
o dosyanın durduğu dizine ve onun da üstündeki ev dizinine bakar.
Zincirin herhangi bir halkası başkasına yazılabilirse giriş
reddedilir ve istemci sana sebebini söylemez.

Sunucu yapılandırmasının iki hâli vardır: diskteki ve bellekteki.
Sözdizimini sınayan bir komut var, etkin değerleri döken de.
İkisini de kullan; dosyayı düzeltmek servisi güncellemez.

Şifreleme ile imzalama farklı işlerdir. Biri içeriği gizler,
diğeri kaynağını kanıtlar. İmza dosyanın içinde de olabilir,
ayrı bir dosyada da.

Bir imzayı doğrulayabilmen için imzalayanın açık anahtarının senin
anahtarlığında olması gerekir. Anahtar yoksa doğrulama "geçersiz"
demez, "bilmiyorum" der — ikisi aynı şey değildir.

> Bu konuyu lab 012'de gördün, oradaki `solution.md`'ye bakabilirsin.
