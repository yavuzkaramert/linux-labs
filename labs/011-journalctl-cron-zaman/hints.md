# Hints — Lab 011: Loglar, Zamanlanmış İşler ve Saat

## Seviye 1

Kavramsal. Komut adı yok.

- Sistemin merkezî bir günlüğü vardır. Servislerin ekrana yazdığı her
  satır, servisin kendisi bir dosyaya log yazmasa bile oraya düşer.
  Bir servis neden çöküyor sorusunun cevabı neredeyse her zaman
  oradadır: aramaya oradan başlanır.
- O günlüğün nereye yazıldığı bir tercihtir. Varsayılan davranış
  şudur: kalıcı günlük dizini VARSA diske yazılır, YOKSA yalnız
  bellekte tutulan geçici alana yazılır. Dizin yoksa sistem yeniden
  başladığında geçmiş kaybolur. Yani kalıcılığı açmak için bir ayar
  değil, bir dizin gerekir.
- Kalıcı dizin açıldığında geçmiş kayıtlar kendiliğinden oraya
  taşınmaz; günlük servisine "biriken kayıtları kalıcı depoya aktar"
  demek gerekir.
- Günlük büyüktür. Onu birime göre, önceliğe göre ve zaman
  aralığına göre daraltabilirsin. Bir sürecin numarasını biliyorsan
  doğrudan o sürecin bıraktığı kayıtları da isteyebilirsin.
- Bir süreç öldüğünde geriye bir çıkış kodu bırakır. Sıfır başarı
  demektir; sıfırdan farklı her değer programın kendi tanımladığı bir
  hata anlamına gelir. Servis yöneticisi bu kodu saklar ve gösterir.
- Bir sorunun ardında ikinci bir sorun durabilir. Program ilk
  eksikliği görüp durduğu için ikinciyi hiç kontrol edemez. İlkini
  giderdiğinde program bir adım ilerler ve yeni hata görünür. Bu
  yüzden düzelt-bak-düzelt döngüsü bir gecikme değil, yöntemdir.
- Periyodik işleri çalıştıran servis, senin kabuğun değildir.
  Senin kabuğun giriş sırasında bir sürü ortam değişkeni kurar;
  periyodik iş çalıştırıcısı bunların hemen hiçbirini kurmaz. En sık
  ısırdığı yer arama yolu: senin yazınca çalışan komut, orada
  bulunamaz. İki çözüm vardır: komutu tam yeriyle yazmak, ya da o
  ortama arama yolunu açıkça bildirmek.
- Periyodik işi tanımlamak yetmez; o işleri çalıştıran servisin
  ayakta olması ve açılışta da başlaması gerekir. Tanım doğru olsa
  bile servis kapalıysa hiçbir şey çalışmaz.
- Aynı iş, servis yöneticisinin kendi zamanlayıcı birimleriyle de
  kurulabilir. Bu yaklaşımda iki dosya olur: ne yapılacağını anlatan
  birim ve ne zaman yapılacağını anlatan birim. İkincisi birincisini
  tetikler. Tetiklenen birim sürekli ayakta kalan bir süreç değil,
  çalışıp biten bir iştir.
- Zamanlayıcı birimlerin bir tetikleme toleransı vardır: sistem,
  birçok zamanlayıcıyı aynı ana toplayıp enerji tasarrufu yapmak için
  ateşlemeyi geciktirebilir. Varsayılan tolerans bir dakikadır. Kısa
  aralıklı bir zamanlayıcı istiyorsan bu toleransı daraltman gerekir.
- Saatle ilgili üç ayrı şey vardır ve karıştırılır: sistemin saati,
  saat dilimi, ve saatin bir dış kaynakla senkron tutulması. Saat
  dilimi yalnız gösterimi etkiler ama loglardaki damgalar da gösterim
  olduğu için teşhiste doğrudan işine karışır.
- Saat dilimini yalnız kendi kabuğun için ayarlayabilirsin; bu
  geçicidir, oturumla birlikte biter. Kalıcı ayar sistem genelindedir
  ve /etc altında bir dosyayla temsil edilir.

## Seviye 2

Araç ve alt komut adları. Bayrak yok.

- Günlüğü okuyan araç journalctl. Günlüğü tutan servis
  systemd-journald. Kalıcı günlük dizini /var/log/journal'dır; dizin
  açıldıktan sonra dosya sahipliğini/izinlerini doğru kurmak için
  systemd-tmpfiles kullanılır, biriken kayıtları diske aktarmak için
  journalctl'in aktarma alt işlevi vardır.
- Günlük varsayılan olarak yalnız root ve journal grubundaki
  kullanıcılara açıktır. student bu grupta değil: sorguları sudo ile
  çalıştıracaksın.
- Bir servisin durumu ve son satırları için systemctl status; daha
  fazlası için journalctl. Servisin sakladığı ham değerler (çıkış
  kodu, sonuç, alt durum) systemctl show ile alınır.
- Sürecin numarasını bulmak için pgrep. Sürecin adını da komut
  satırını da eşleştirebilir.
- Klasik zamanlayıcı: servis adı crond, tanım dosyaları
  /etc/cron.d/ altında ve kullanıcı tabloları crontab aracıyla
  yönetilir. /etc/cron.d altındaki satırlarda, kullanıcı crontab'ından
  farklı olarak ek bir alan vardır: işin hangi kullanıcı olarak
  çalışacağı.
- Bir komutun sistemde nerede olduğunu which ya da command
  söyler. Sen bulabiliyorsan da zamanlayıcı bulamayabilir; ölçüt senin
  kabuğun değil, işin ortamıdır.
- crond çalıştırdığı her işi günlüğe yazar; işin gerçekten
  tetiklenip tetiklenmediğini journalctl ile crond birimine bakarak
  görürsün.
- Zamanlayıcı birimler .timer uzantılı, tetikledikleri iş .service
  uzantılıdır. İkisi de /etc/systemd/system/ altına yazılır. Yeni
  birim dosyalarını systemd'ye okutmak, etkinleştirmek ve başlatmak
  systemctl'in işi. Sistemdeki zamanlayıcıları ve sıradaki tetikleme
  zamanlarını systemctl'in list-timers alt komutu listeler.
- Saatle ilgili her şey timedatectl ile yönetilir: saat dilimini
  listeleme, saat dilimini ayarlama, senkronu açıp kapama ve genel
  durum raporu. Senkron istemcisinin kendisi chronyd servisi,
  yapılandırması /etc/chrony.conf, sunucu durumunu sorgulayan araç
  chronyc.
- Kullanılacak man sayfaları: journalctl, journald.conf,
  systemd.timer, systemd.time, crontab (5. bölüm biçim için),
  timedatectl, chrony.conf.

## Seviye 3

Direktif, alan ve bayrak adları. Tam komut satırı yok.

- journalctl süzme: -u birim adına göre, -p öncelik seviyesine göre
  (err seviyesi hata satırlarını verir), --since ve --until zaman
  aralığı, -n son N satır, -f canlı takip. Alan eşleşmesi de
  yapılabilir: _PID=, _SYSTEMD_UNIT=, _COMM= gibi. --no-pager
  çıktının sayfalayıcıya girmesini engeller.
- Günlüğü kalıcı depoya aktarma: journalctl --flush. Alternatif yol
  journald.conf içindeki Storage= anahtarını persistent yapmaktır ama
  varsayılan auto zaten dizin varsa kalıcı yazar; dizini açmak yeter.
- systemctl show özellikleri: ExecMainStatus (son çıkış kodu),
  Result, SubState, ActiveState, FragmentPath, NextElapseUSecMonotonic.
  Birden çok özelliği tek çağrıda sormak çıktı sırasını garanti
  ETMEZ; her özelliği ayrı sor.
- cron alan düzeni beş alandır: dakika, saat, ayın günü, ay,
  haftanın günü. Yıldız "her" demektir; her dakika çalışmak için beş
  alanın da yıldız olması gerekir. /etc/cron.d dosyalarında altıncı
  alan kullanıcı, yedinci ve sonrası komuttur. Dosyaya PATH=... satırı
  eklenebilir; bu satır o dosyadaki işler için arama yolunu belirler.
  cron işlere varsayılan olarak /usr/bin:/bin verir — /usr/local/bin
  bunun içinde YOKTUR.
- Zamanlayıcı birim [Timer] bölümünde tanımlanır. Aralık
  direktifleri: OnBootSec= (açılıştan sonra), OnUnitActiveSec=
  (tetiklenen birim en son etkinleştikten sonra), OnCalendar= (takvim
  ifadesi). Tolerans AccuracySec= ile daraltılır; varsayılanı 1min'dir
  ve 30s'lik bir aralığı bile geciktirir. Zamanlayıcının açılışta
  devreye girmesi için [Install] bölümünde WantedBy=timers.target
  gerekir. Tetiklenen birim, .timer ile aynı adı taşıyan .service
  dosyasıdır; farklı bir ad kullanılacaksa Unit= ile belirtilir.
- Tetiklenen birim çalışıp biten bir iş olduğu için [Service]
  bölümünde Type=oneshot uygundur; sürekli ayakta kalan bir süreç
  olmadığı için burada RemainAfterExit gerekmez.
- Etkinleştirme ve başlatmayı tek adımda yapmak için systemctl'in
  --now bayrağı vardır. Zamanlayıcı için etkinleştirilmesi gereken
  .timer birimidir, .service değil.
- timedatectl alt komutları: list-timezones, set-timezone, set-ntp,
  status, show. show çıktısında Timezone ve NTP anahtarları vardır ve
  --value ile yalnız değer alınır. Kalıcı saat dilimi ayarı
  /etc/localtime sembolik bağını /usr/share/zoneinfo/ altındaki
  dosyaya yönlendirir; TZ ortam değişkeni yalnız o kabuğu etkiler.
- chrony.conf içinde zaman kaynağı pool ya da server anahtar
  kelimesiyle tanımlanır, genelde iburst seçeneğiyle. Sunucu
  durumunu chronyc'nin sources ve tracking alt komutları gösterir.
