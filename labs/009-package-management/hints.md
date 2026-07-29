# Hints — Lab 009: Paket Yönetimi

## Seviye 1

Kavramsal. Komut adı yok.

- Paket yöneticisi yalnız dosya kopyalayan bir araç değildir; kurduğu
  her dosyanın kaydını tutan bir veritabanı işletir. O veritabanı
  "hangi dosya kimin", "kurulduğunda hangi boyutta, hangi izinle,
  hangi özetle geldi" bilgisini taşır.
- Bu yüzden ilişki iki yönlü sorulabilir: bir paketten yola çıkıp
  dosyalarına, ya da bir dosyadan yola çıkıp paketine gidebilirsin.
- Kurulum anındaki kayıt saklandığı için, dosyanın bugünkü hâli ile
  kayıtlı hâli karşılaştırılabilir. Bu karşılaştırma "değişti mi"
  sorusuna değil, "NESİ değişti" sorusuna cevap verir: boyutu mu,
  özeti mi, izni mi, sahibi mi, zaman damgası mı. Yapılandırma
  dosyalarının değişmesi normaldir ve ayrıca işaretlenir.
- Bir komut sistemde yoksa, onu hangi paketin sağladığını tahmin
  etmen gerekmez: paket yöneticisi depolardaki paketlerin içerdiği
  dosyaları da bilir, "şu yolu kim sağlıyor" diye sorulabilir.
- Paket yöneticisi yaptığı her işlemi (kurulum, kaldırma, güncelleme)
  numaralı bir kayıt olarak tutar. Bu kayıt yalnız okunmak için değil,
  geri alınmak için de vardır: bir işlemi geri almak, o işlemin
  etkisini tersine çevirir. Paketi elle yeniden kurmak aynı şey
  değildir — biri geçmişe dayanır, diğeri senin tahminine.
- Bir paket dosyasının içinde ne olduğunu öğrenmek için onu kurmak
  gerekmez. Paket dosyası kendi dosya listesini ve metaverisini
  kendi içinde taşır; kurulu paketi sorgulayan araç, kurulmamış bir
  dosyayı da sorgulayabilir — ama bunu ayrı bir kipte yapar.
- Dağıtımın kendi depoları her şeyi taşımaz. Topluluk tarafından
  bakılan ek depolar vardır; onları etkinleştirmek de bir kurulum
  işidir. Ek depodaki paketler bazen dağıtımın "geliştirme/yardımcı"
  deposundaki kütüphanelere dayanır; o depo kapalıyken bağımlılık
  çözülemez ve hata paketi değil eksik depoyu işaret eder.
- İki büyük paket biçimi ailesi vardır. Bir ailenin aracı diğerinin
  paket dosyasını okuyabilir, ama bu okumak demektir — o paketi bu
  sisteme kurmak demek değildir.

## Seviye 2

Araç adları. Bayrak yok.

- İlgili araçlar: rpm, dnf, dpkg-deb, dpkg-query, crb.
- Görev 1 ve 2 rpm işi. rpm'in sorgu kipi kurulu paketlerin
  veritabanına bakar; hangi soruyu sorduğunu bir bayrak belirler.
- Görev 2'de rpm'in doğrulama kipi kullanılır. Çıktısı boş ise
  değişiklik yok demektir; boş değilse her satır bir dosyayı ve
  yanında hangi özelliklerin değiştiğini gösteren bir harf dizisini
  taşır. Önce dosyanın paketini bulman, sonra o paketi doğrulaman
  daha kısa yoldur.
- Görev 3'te dnf'in "bu dosyayı/komutu kim sağlıyor" sorgusu var.
  Sonra normal kurulum.
- Görev 4 dnf'in işlem geçmişi alt komutudur. Listeleme, tek bir
  işlemin ayrıntısını gösterme ve geri alma aynı alt komudun
  farklı kullanımlarıdır.
- Görev 5 yine rpm; ama bu kez sorgu veritabanına değil DOSYAYA
  yapılır. Bunu ayrı bir bayrak açar.
- Görev 6'da önce epel-release paketi kurulur, sonra dağıtımın
  yardımcı deposu crb açılır (epel-release ile birlikte gelen crb
  komutu ya da dnf'in depo yapılandırma alt komutu bunu yapar),
  sonra dpkg kurulur. .deb dosyasını okuyan araç dpkg-deb'dir;
  dosya listesi ve metaveri için iki ayrı bayrağı vardır.
- Kurulu OLMADIĞINI doğrulamak için rpm'in ve dpkg'nin sorgu
  kipleri kullanılır.
- Okunacak man sayfaları: man rpm, man dnf, man dnf.plugin.download,
  man dpkg-deb, man dpkg-query. dnf history için: man dnf, "history"
  bölümü.

## Seviye 3

Bayrak ve parametre düzeyi. Tam komut yok.

- rpm sorgu kipi -q ile açılır ve tek başına anlamsızdır; ne
  sorduğunu ikinci harf söyler: -qf bir DOSYANIN paketini, -ql bir
  PAKETİN dosyalarını, -qi paket bilgilerini verir.
- Aynı sorgular kurulmamış bir paket DOSYASINA da yapılabilir: -qlp
  ve -qip. Buradaki p "package file" demektir, veritabanına değil
  dosyaya bakılır. Yol vermeyi unutma.
- rpm --qf ile çıktının biçimini sen seçersin: %{NAME}, %{VERSION},
  %{RELEASE} gibi alanlar tek satırda alınabilir.
- rpm -V bir paketi doğrular, -Va tüm sistemi doğrular (yavaş ve
  gürültülü; hangi paketi soracağını biliyorsan -V daha temiz).
  Çıktıdaki dokuz karakter sırayla şunlardır:

      S  boyut (size) farklı
      M  izin/mod (mode) farklı
      5  içerik özeti (MD5/SHA) farklı
      D  aygıt numarası farklı
      L  sembolik bağlantı hedefi farklı
      U  sahip (user) farklı
      G  grup farklı
      T  değiştirilme zamanı (mtime) farklı
      P  capabilities farklı

  Değişmemiş özellik nokta ile gösterilir. Satırdaki harflerden
  sonra gelen tek harf dosyanın türüdür: c yapılandırma dosyası,
  d belge, g "ghost". Yani SM5....T. bir dosyanın boyutunun,
  izninin, içeriğinin ve zaman damgasının değiştiğini söyler.
- dnf provides bir komut adı ya da tam yol alır; joker de kabul
  eder. Depo metaverisi üzerinden çalışır, kurulu olmayan paketleri
  de bulur.
- dnf history list işlemleri numaralarıyla listeler, en yeni üstte.
  dnf history info <id> tek işlemin ayrıntısını verir. Geri alma
  dnf history undo <id> biçimindedir ve normal bir işlem gibi onay
  ister; -y ile onaysız koşar. Geri alınan şey işlemdir: kaldırma
  işlemini geri almak paketi geri kurar.
- crb deposunu açmanın iki yolu var: epel-release ile gelen crb
  komutunun enable alt komutu, ya da dnf config-manager'ın
  --set-enabled bayrağı. Etkin depoları dnf repolist listeler,
  --all bayrağı kapalıları da gösterir.
- dpkg-deb -c arşivdeki dosyaları tar listesi biçiminde basar
  (yollar ./ ile başlar), dpkg-deb -I control dosyasını ve paket
  bilgilerini basar. Tek bir alanı almak için -f <dosya> <Alan>
  kullanılır: Package, Version.
- Kurulu olmama doğrulaması: rpm -q <ad> kurulu değilse sıfırdan
  farklı kod döner; dpkg tarafında dpkg -l ya da dpkg-query -W
  aynı işi görür.
