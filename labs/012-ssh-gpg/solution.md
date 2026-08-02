# Solution — Lab 012: SSH Anahtarı, sshd Sertleştirme ve GPG

Komutlar `student` olarak çalıştırılır. `/etc/ssh` altını değiştiren ve
servisi yeniden başlatan her işlem `sudo` ister; kendi ev dizinindeki
dosyalar (`~/.ssh`, `~/.gnupg`) için `sudo` GEREKMEZ — 001/006/008/009'da
tekrarlayan "gereksiz sudo" refleksinin tam da kırılması gereken yer.

## Görev 1 — Anahtarla giriş ve StrictModes tuzağı

Açık anahtarı sunucunun tanıyacağı yere koy:

```bash
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

`ssh-copy-id student@localhost` de aynı işi yapar ve izinleri kendisi
kurar, ama bu labda parola girişi henüz açıkken çalışır; görev 2'den
sonra bu yol kapanır.

Şimdi dene:

```bash
ssh -o BatchMode=yes student@localhost
```

Hâlâ reddediliyor:

```
student@localhost: Permission denied (publickey,password).
```

İstemci sebebini söylemez. Sunucuya sor:

```bash
sudo journalctl -u sshd -n 20 --no-pager
```

```
sshd-session[534]: Authentication refused: bad ownership or modes for directory /home/student
```

Sebep budur: ev dizini 0775, yani gruba yazılabilir. sshd'nin StrictModes
denetimi "sahibi bu kullanıcı mı ve mod & 022 sıfır mı" diye bakar ve
grup yazma hakkını gördüğü anda anahtarı hiç okumadan reddeder — çünkü
gruptaki bir başkası `authorized_keys`'i değiştirip yerine kendi
anahtarını koyabilirdi.

```bash
chmod 750 ~
ssh -o BatchMode=yes student@localhost 'echo GIRIS_OK'
```

`chmod 755 ~` de geçerlidir; ölçüt grup/diğerleri için YAZMA hakkının
olmamasıdır. `StrictModes no` yazmak da girişi açar ama bu çözüm değil,
denetimi kapatmaktır — kabul edilmez.

## Görev 2 — sshd_config sertleştirme

Önce sınamadan HİÇBİR ŞEY yapma:

```bash
sudo sshd -t
```

```
/etc/ssh/sshd_config: line 22: Bad configuration option: MaxAuthTrys
/etc/ssh/sshd_config: terminating, 1 bad configuration options
```

Doğrudan `systemctl restart sshd` deseydin servis ayağa kalkmayacaktı ve
gerçek bir sunucuda bağlantın da kopmuş olacaktı. Sıra her zaman şudur:
düzenle → `sshd -t` → yeniden başlat.

```bash
sudo vim /etc/ssh/sshd_config
```

Üç düzeltme:

```
MaxAuthTrys 6          ->  MaxAuthTries 6
PermitRootLogin yes    ->  PermitRootLogin no
PasswordAuthentication yes  ->  PasswordAuthentication no
```

`sed` ile:

```bash
sudo sed -i 's/^MaxAuthTrys /MaxAuthTries /' /etc/ssh/sshd_config
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
```

Sına, sonra uygula:

```bash
sudo sshd -t && sudo systemctl restart sshd
systemctl is-active sshd
```

Etkin değerleri dosyadan değil sshd'nin kendisinden doğrula — `-T`
varsayılanları ve Match bloklarını da hesaba katar, dosyayı grep'lemek
katmaz:

```bash
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication) '
```

Dosyayı düzeltip yeniden başlatmamak bu labın sessiz hatasıdır: `sshd -T`
diskteki dosyayı okur ve doğru değeri gösterir, ama çalışan servis hâlâ
eski tanımı taşır. check.sh bu farkı servisin başlama anıyla dosyanın
değişme anını karşılaştırarak yakalar.

## Görev 3 — GPG anahtarı ve şifreleme

Parolasız anahtar, etkileşimsiz üretim:

```bash
gpg --batch --pinentry-mode loopback --passphrase '' \
    --quick-generate-key 'Student <student@lab.local>' default default never
```

`default default never` sırasıyla algoritma, kullanım ve son kullanma
tarihidir. Etkileşimli yol `gpg --full-generate-key`'dir ve aynı sonucu
verir; toplu kip yalnız script'ten çağrılabilir olmasını sağlar.

```bash
gpg --list-secret-keys
gpg --batch --yes --encrypt --recipient student@lab.local \
    --output ~/gizli.txt.gpg ~/gizli.txt
gpg --batch --yes --decrypt ~/gizli.txt.gpg
```

Çıktının `gizli.txt` ile birebir aynı olduğunu kendin doğrula:

```bash
gpg --batch --decrypt ~/gizli.txt.gpg 2>/dev/null | diff - ~/gizli.txt && echo AYNI
```

Şifreleme ALICININ açık anahtarıyla yapılır. Burada alıcı sensin, o
yüzden kendi anahtarın hem kilitliyor hem açıyor; gerçek kullanımda
`--recipient` karşı tarafın kimliği olurdu.

## Görev 4 — İmza doğrulama ve imzalama

Önce anahtar olmadan dene, farkı gör:

```bash
gpg --verify /opt/paket/surum-a.tar.gz.sig /opt/paket/surum-a.tar.gz
```

```
gpg: Can't check signature: No public key
```

Bu "imza bozuk" DEĞİLDİR: doğrulayacak anahtar yok demektir. Anahtar
diskte duruyor ama anahtarlığında değil:

```bash
gpg --import /opt/paket/yayinci-acik.asc
gpg --list-keys yayinci@lab.local
```

Şimdi ikisini de doğrula:

```bash
gpg --verify /opt/paket/surum-a.tar.gz.sig /opt/paket/surum-a.tar.gz
gpg --verify /opt/paket/surum-b.tar.gz.sig /opt/paket/surum-b.tar.gz
```

```
gpg: Good signature from "Lab Yayinci <yayinci@lab.local>"
gpg: BAD signature from "Lab Yayinci <yayinci@lab.local>"
```

Üç farklı durum var ve üçü de ayrı anlama gelir: Good (dosya imzalandığı
andaki hâlinde), BAD (dosya değişmiş), No public key (kontrol edilemedi).
Çıkış kodu da bunları ayırır.

"This key is not certified with a trusted signature" uyarısı normaldir:
anahtarı henüz kendi anahtarınla onaylamadın. Uyarı güven düzeyi
hakkındadır, imzanın geçerliliği hakkında değil.

```bash
echo 'surum-b.tar.gz' > ~/cevap-paket.txt
```

Ters yön — kendi dosyanı ayrık imzayla imzala:

```bash
gpg --batch --yes --detach-sign --output ~/duyuru.txt.sig ~/duyuru.txt
gpg --verify ~/duyuru.txt.sig ~/duyuru.txt
```

Ayrık imza asıl dosyayı hiç değiştirmez; yanında taşınan ayrı bir
kanıttır. `--sign` gömülü imza üretir ve dosyayı sarmalar, `--clearsign`
ise metnin okunabilirliğini koruyup imzayı metne ekler. Paket dağıtımında
kullanılan ayrık olandır.

## Tuzaklar

- İzinleri düzeltmeden `authorized_keys` kurmak: dosya doğru yerde ve
  doğru izinde olsa bile ev dizini gruba yazılabilirse giriş reddedilir.
- Reddin sebebini istemcide aramak: `ssh -v` bile göstermez, sebep yalnız
  sunucunun günlüğünde durur.
- `StrictModes no` ile sorunu "çözmek": denetimi kapatmak, sebebi
  gidermek değil.
- `sshd -t` atlayıp doğrudan restart: bozuk yapılandırmada servis ayağa
  kalkmaz; gerçek sunucuda bağlantını da kaybedersin.
- Dosyayı düzeltip servisi yeniden başlatmamak: `sshd -T` doğru değeri
  gösterir ama çalışan servis eski tanımla koşmaya devam eder.
- Yönergeleri dosyadan grep'leyip "tamam" demek: etkin değer
  varsayılanlardan ve Match bloklarından da etkilenir, ölçüt `sshd -T`.
- `~/.ssh` ya da `~/.gnupg` altındaki kendi dosyalarını `sudo` ile
  oluşturmak: dosya root'un olur, sonra hem sshd hem gpg reddeder.
- "No public key" ile "BAD signature"ı aynı şey sanmak: biri
  doğrulayamadım, diğeri doğruladım ve tutmadı demektir.
- Şifrelerken `--recipient` vermeyi unutmak ya da alıcıyı kendi yerine
  başkası sanmak.
- Parolasız anahtar üretiminde `--batch` olmadan `--passphrase`
  kullanmak: gpg parolayı yine terminalden ister, `--pinentry-mode
  loopback` gerekir.
