# Hints — Lab 010: systemd Servisleri

## Seviye 1

Kavramsal. Komut adı yok.

- Bir servis, işletim sisteminin senin adına başlattığı ve hayatta
  tuttuğu bir süreçtir. Sistemin bunu yapabilmesi için süreci nasıl
  başlatacağını, hangi kullanıcı olarak çalıştıracağını ve ne zaman
  "çalışıyor" sayacağını bilmesi gerekir. Bu bilgi bir metin
  dosyasında, birim tanımında durur.
- Birim tanımı diskte bir dosyadır, ama sistemin çalışırken kullandığı
  şey o dosyanın BELLEĞE ALINMIŞ kopyasıdır. Dosyayı değiştirmek
  belleği değiştirmez. İkisi ayrıştığında sistem sana eski tanımla
  cevap verir; çıktı doğru görünür, davranış yanlış olur. Bu yüzden
  değişiklikten sonra sisteme "tanımları yeniden oku" demek gerekir.
- Başlatmak ile açılışta başlamasını sağlamak AYRI iki iştir. Biri
  şimdiki durumu değiştirir, diğeri gelecekteki açılışlar için bir
  kayıt bırakır. Birini yapıp diğerini yapmamak mümkündür.
- Servislerin tipi vardır. Bazıları başlar ve süresiz ön planda
  kalır. Bazıları bir iş yapıp çıkar; bunlar için "çıktı ama işi
  başarıyla bitti, o yüzden hâlâ tamamlanmış say" diyebilen ayrı bir
  davranış vardır. Yanlış tip seçmek, düzgün çalışan bir programı
  bile çökmüş göstertir.
- Bir servis çöktüğünde sistem sana sebebini bir kod ile söyler.
  Kodlar birbirinden farklıdır: "böyle bir kullanıcı yok" ile
  "böyle bir program yok" ayrı hatalardır. Sistem süreci başlatmaya
  sırayla girişir, bu yüzden ilk adımda takılırsa sonraki adımın
  hatasını hiç görmez. İlk hatayı düzeltmeden ikincisi görünmez —
  bir servis birden çok hata taşıyabilir.
- İki servis arasında iki farklı ilişki kurulabilir ve bunlar
  birbirinin yerine geçmez. Biri ZAMAN ilişkisidir: hangisi önce
  çalışacak. Diğeri GEREKLİLİK ilişkisidir: biri olmadan diğeri
  anlamsız, o yüzden biri istendiğinde diğeri de çekilsin. Yalnız
  zaman ilişkisi kurarsan, diğeri hiç başlatılmamışsa sıra kavramının
  bir anlamı kalmaz.
- Sistemin bir varsayılan hedefi vardır: açılışta hangi servis
  kümesine ulaşmaya çalışacağı. Kurtarma hedefi kasten dardır, normal
  çok kullanıcılı hizmet vermek için değil, arıza gidermek içindir.
- Birim dosyaları farklı dizinlerde durabilir ve bu dizinlerin
  öncelikleri vardır. Bir kısmı kalıcıdır, bir kısmı yalnız sistem
  ayaktayken vardır ve yeniden başlatınca kaybolur. Kalıcı olması
  isteniyorsa doğru dizine yazılmalıdır.

## Seviye 2

Araç ve alt komut adları. Bayrak yok.

- Neredeyse her şey tek bir araçla yapılır: systemctl. Alt komutları
  iş bazlı ayrılır — durum sorma, tanımları yeniden okuma, başlatma,
  durdurma, açılışa ekleme, açılıştan çıkarma, birim dosyasını
  gösterme, birimin tüm özelliklerini dökme.
- Görev 1: dosyayı yaz, tanımları yeniden okut, başlat, açılışa ekle.
  Dört ayrı alt komut, dördü de gerekli.
- Görev 2: teşhis için status alt komutu ve journalctl -u kullanılır.
  status çıktısındaki Process ve Main PID satırlarında parantez içinde
  bir çıkış kodu vardır; asıl bilgi orada. Bir hatayı düzeltip tekrar
  başlattığında o kodun DEĞİŞTİĞİNİ göreceksin — ikinci hata ancak o
  zaman görünür hâle gelir. Dosyayı düzelttikten sonra tanımları
  yeniden okutmayı unutma.
- Görev 2'nin kullanıcı tarafı için: sistemde bir kullanıcının var
  olup olmadığını getent ya da id ile sorabilirsin. Kullanıcıyı
  yaratmak da (useradd), unit'i var olan bir kullanıcıya yöneltmek de
  geçerli çözümdür.
- Görev 3: ilişkiler [Unit] bölümündeki iki ayrı direktifle kurulur —
  biri sıralama, diğeri gereklilik. İkisi de gerekli.
  Kurduğun ilişkiyi doğrulamak için systemctl list-dependencies
  kullanılabilir; bu bir DOĞRULAMA aracıdır, çözümün kendisi değil.
  Bağımlılığı hangi direktiflerin kurduğunu man sayfasından bul.
- Görev 4: varsayılan hedefi okuyan ve ayarlayan iki alt komut var,
  isimleri birbirinin simetriği.
- Bir birimin sistemin gözündeki halini (dosya yolu, tip, kullanıcı,
  durum, bağımlılıklar) show alt komutu döker; cat ise diskteki
  dosyayı gösterir. İkisinin farkı bu labın merkezindeki farktır.
- Okunacak man sayfaları: man systemd.service (Type, ExecStart, User,
  RemainAfterExit), man systemd.unit (After, Requires, birim dizinleri
  ve öncelikleri), man systemctl (alt komutlar).

## Seviye 3

Direktif ve bayrak düzeyi. Tam komut yok.

- Bir servis birimi en az iki bölüm ister: [Service] ve genelde
  [Install]. [Unit] bölümü açıklama ve ilişkiler içindir.
- [Service] altındaki direktifler:

      Type=simple      surec on planda kalir (varsayilan)
      Type=oneshot     bir is yapar ve cikar
      Type=forking     surec kendini arka plana atar
      ExecStart=       calistirilacak TAM yol (PATH aranmaz)
      User=            hangi kullanici olarak calisacagi
      WorkingDirectory=  calisma dizini
      RemainAfterExit=yes   cikan oneshot birimi "aktif" saydirir

  Ön planda kalan bir script'e forking vermek onu çökmüş gösterir;
  çıkıp biten bir script'e simple vermek onu "başarısız" değil ama
  "inactive" bırakır — RemainAfterExit onu tamamlanmış tutar.
- [Install] altında WantedBy= bulunur. Açılışa ekleme işlemi tam
  olarak bunu okur ve hedefin .wants dizinine bir sembolik bağ kurar.
  [Install] yoksa birim açılışa eklenemez.
- [Unit] altında After= sırayı belirler ama birimi ÇEKMEZ. Requires=
  birimi çeker ama sırayı garanti ETMEZ. İkisi birlikte yazılır;
  bu ikilinin ayrı olması systemd'nin en sık yanlış anlaşılan yeridir.
- Çıkış kodları: 203 çalıştırılacak dosya bulunamadı ya da
  çalıştırılabilir değil demektir; 217 birimde yazan kullanıcı
  çözülemedi demektir. Sistem önce kullanıcıya geçer, sonra programı
  çalıştırır — bu yüzden kullanıcı hatası program hatasını maskeler.
- Bellekteki tanımın tazeliği bir özellik olarak sorgulanabilir:
  NeedDaemonReload. Değeri yes ise disk ile bellek ayrışmıştır.
- Birim dosyasını düzenlemenin iki yolu var. Dosyayı doğrudan
  /etc/systemd/system/ altına yazmak; ya da systemctl edit alt
  komutunun --full bayrağı (bayraksız hâli yalnızca üstüne yazan bir
  parça oluşturur, tam dosyayı değil). Editörden çıkınca ikincisi
  tanımları kendisi tazeler. --runtime bayrağı ise değişikliği /run
  altına yazar ve yeniden başlatmada kaybolur; bu labda kabul edilmez.
- Birimin gerçekten hangi dosyadan okunduğu FragmentPath özelliğinde
  yazar. Kalıcılığı buradan doğrulayabilirsin.
