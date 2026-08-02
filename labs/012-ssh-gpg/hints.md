# Hints — Lab 012: SSH Anahtarı, sshd Sertleştirme ve GPG

## Seviye 1

Kavramsal. Komut adı yok.

- Anahtarla kimlik doğrulama iki parçalıdır: sende kalan ve kimseye
  verilmeyen bir yarım, sunucuya bırakılan ve herkese gösterilebilen
  bir yarım. Sunucu, senin kim olduğunu ikinci yarıma bakıp birinci
  yarıma sahip olduğunu kanıtlamanı isteyerek anlar. Yani sunucuya
  kopyalanacak olan açık olandır; gizli olan makineden çıkmaz.
- Sunucunun bir kullanıcı için tanıdığı açık anahtarlar, o
  kullanıcının kendi ev dizini içindeki bir dosyada tutulur. Dosya
  yoksa sunucu o kullanıcı için hiçbir anahtar tanımıyor demektir.
- Sunucu bu dosyaya güvenmeden önce dosyanın gerçekten yalnız
  kullanıcının denetiminde olduğuna bakar. Ölçüt yalnız dosyanın
  kendisi değildir: dosyayı içeren dizin ve kullanıcının ev dizini de
  ölçülür. Bir başkası bu dizinlerden birine yazabiliyorsa, anahtar
  dosyasını değiştirip yerine kendi anahtarını koyabilirdi; sunucu bu
  ihtimali kapatmak için girişi tümden reddeder.
- Bu reddin en can sıkıcı yanı sessiz olmasıdır. İstemciye "izinler
  yanlış" denmez; giriş reddedilir ve istemci sıradaki yönteme, yani
  parolaya geçer. Sanki anahtar tanınmamış gibi görünür. Gerçek sebep
  yalnız sunucunun kendi günlüğünde durur — 011'de öğrendiğin araç
  tam olarak burada işe yarar.
- Bir sunucu servisinin yapılandırması metin dosyasıdır ama servis o
  dosyayı yalnız başlarken okur. Dosyayı düzenleyip kaydetmek çalışan
  servisi değiştirmez; değişikliğin geçerli olması için servisin
  yapılandırmayı yeniden okuması gerekir.
- Uzaktan yönetilen bir sunucuda yapılandırmayı sınamadan uygulamak
  tehlikelidir: bozuk bir yapılandırmayla servis ayağa kalkmazsa, o
  servis üzerinden bağlanan sen de dışarıda kalırsın. Bu yüzden
  servisin, yapılandırmayı uygulamadan önce yalnız sözdizimi
  bakımından sınayan bir kipi vardır. Sıra: önce sına, sonra uygula.
- Şifreleme ile imzalama farklı işlerdir ve anahtar çiftinin farklı
  yarımlarını kullanır. Bir dosyayı BİRİNE şifrelersin: onun açık
  anahtarıyla kilitlenir, yalnız onun gizli anahtarı açar. Bir dosyayı
  ise KENDİ gizli anahtarınla imzalarsın: herkes senin açık anahtarınla
  imzanın sana ait olduğunu ve dosyanın değişmediğini doğrulayabilir.
- İmza dosyanın içine gömülebileceği gibi ayrı bir dosyada da
  durabilir. İkincisi, asıl dosyayı hiç değiştirmeden yanında taşınan
  küçük bir kanıttır; paket dağıtımında yaygın olan budur.
- Bir imzayı doğrulayabilmek için imzalayanın açık anahtarının senin
  anahtar deposunda bulunması gerekir. Anahtar diskte bir dosya olarak
  duruyor olabilir; bu yetmez, deponun içine alınması gerekir. Aksi
  hâlde araç "bu imzayı kontrol edemiyorum, anahtar yok" der — bu
  "imza bozuk" demek DEĞİLDİR, ikisini karıştırma.
- İmza doğrulaması bir bütünlük kanıtıdır: dosyanın tek baytı bile
  değiştiyse imza tutmaz. Aynı yayıncının iki paketinden biri yolda
  değiştirildiyse, hangisinin sağlam olduğunu sana ancak bu söyler.

## Seviye 2

Araç, dosya ve kavram adları. Bayrak yok.

- İstemci tarafı ssh, anahtar üretimi ssh-keygen, açık anahtarı
  sunucuya taşımanın hazır yolu ssh-copy-id. Sunucu tarafı sshd,
  yapılandırması /etc/ssh/sshd_config, servis adı sshd.service.
- Kullanıcının tanınan açık anahtarları ~/.ssh/authorized_keys
  dosyasında tutulur. Bu dosyayı elle kurarken açık anahtar dosyasının
  (.pub uzantılı) içeriği olduğu gibi eklenir.
- İzin denetiminin adı StrictModes'tur ve sshd_config'te açıp
  kapatılabilen bir yönergedir. Kapatmak çözüm değil, tuzağı örtmektir;
  doğru çözüm izinleri düzeltmektir. Reddin sebebi sunucu günlüğünde
  görünür: journalctl ile sshd birimine bak.
- Dizin ve dosya izinleri chmod, sahiplik chown ile ayarlanır; mevcut
  durumu ls ve stat gösterir.
- Sertleştirmede geçen iki yönerge PermitRootLogin ve
  PasswordAuthentication'dır. sshd'nin yapılandırmayı uygulamadan
  sınayan bir kipi ve etkin değerlerin tam listesini basan bir kipi
  vardır; ikisi de aynı komutun bayraklarıdır. Servisi yeniden
  başlatmak systemctl'in işi.
- GPG tarafında araç gpg. İhtiyacın olan alt işlevler: anahtar çifti
  üretme, anahtarları listeleme, bir anahtar dosyasını depoya alma
  (import), şifreleme, şifre çözme, imzalama ve doğrulama. Anahtar
  deposu kullanıcının ev dizininde ~/.gnupg altında oturur.
- Şifrelerken alıcıyı belirtmen gerekir; alıcı bir e-posta adresiyle
  ya da anahtar kimliğiyle gösterilir. Bu labda alıcı sensin.
- Etkileşimsiz (script'ten çağrılabilen) çalışma için gpg'nin toplu
  kip bayrakları vardır; parolasız anahtar üretimi bunlarla yapılır.
- Kullanılacak man sayfaları: ssh, ssh-keygen, sshd, sshd_config,
  ssh-copy-id, gpg.

## Seviye 3

Yönerge, alt işlev ve bayrak adları. Tam komut satırı yok.

- İzin hedefleri: ~/.ssh için 700, ~/.ssh/authorized_keys için 600.
  Ev dizini için ölçüt gruba ve diğerlerine YAZMA hakkı olmamasıdır:
  755 ya da 750 olur, 775 olmaz. sshd kaynak kodundaki denetim
  "sahibi kullanıcı mı ve mod & 022 sıfır mı" biçimindedir.
- sshd'nin sınama kipi -t, etkin yapılandırmayı dökme kipi -T'dir.
  -T çıktısı tüm yönergeleri küçük harfle ve varsayılanlarıyla
  birlikte basar; dosyada satır olmasa bile etkin değeri gösterir.
  Yazım hatası olan bir yönerge adı "Bad configuration option" diye
  raporlanır ve satır numarası verilir.
- PermitRootLogin ve PasswordAuthentication'ın kapalı değeri no'dur.
  Değişiklikten sonra servisin yeniden başlatılması gerekir; reload
  sshd için de tanımlıdır ama bu labda restart bekleniyor.
- ssh istemcisinde işine yarayacak seçenekler: -i ile kullanılacak
  gizli anahtarı seçmek, -o ile tek seferlik yapılandırma vermek,
  -v ile istemci tarafındaki karar zincirini görmek. Sunucunun
  gerçek reddi -v ile de görünmez; sunucu günlüğüne bakman gerekir.
- gpg anahtar üretimi: --full-generate-key etkileşimli, --gen-key
  yönlendirmeli, --quick-generate-key ise tek satırda kimlik alıp
  üretir. Toplu kullanım için --batch, parolayı komut satırından
  vermek için --passphrase, parola isteğini terminal yerine sürece
  yönlendirmek için --pinentry-mode gerekir. Parolasız anahtar boş
  parola demektir.
- Şifreleme --encrypt, alıcı --recipient ile verilir, çıktı dosyası
  --output ile adlandırılır. Şifre çözme --decrypt. Ayrık imza
  --detach-sign, doğrulama --verify; --verify önce imza dosyasını
  sonra asıl dosyayı bekler. Anahtar alma --import, listeleme
  --list-keys ve --list-secret-keys.
- --verify çıktısında "Good signature" ile "BAD signature" farklı
  şeylerdir; "Can't check signature: No public key" ise üçüncü ve
  bambaşka bir durumdur. Çıkış kodu da bu üç durumu ayırır.
- Anahtar deposundaki güven düzeyi (unknown/ultimate) imzanın geçerli
  olup olmadığını değiştirmez; "This key is not certified with a
  trusted signature" uyarısı doğrulamanın başarısız olduğu anlamına
  gelmez.
