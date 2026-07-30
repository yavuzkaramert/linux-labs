# Solution — Lab 011: Loglar, Zamanlanmış İşler ve Saat

Komutlar `student` olarak çalıştırılır. Sistemi değiştiren her işlem
`sudo` ister. Günlük okuma da burada `sudo` ister: `student` kullanıcısı
`systemd-journal` grubunda değildir, `sudo`suz `journalctl` çıkış kodu 0
döner ama "No journal files were opened due to insufficient permissions"
diyip boş çıktı verir — sessiz bir tuzak.

## Görev 1 — Kalıcı günlük ve bekci.service teşhisi

Önce günlüğü kalıcı hâle getir. Varsayılan `Storage=auto` şu demektir:
`/var/log/journal` varsa diske yaz, yoksa yalnız `/run/log/journal`
altında bellekte tut. Yani ayar değil, dizin gerekiyor.

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo journalctl --flush
```

`systemd-tmpfiles` dizine doğru sahiplik ve izinleri (root:systemd-journal,
setgid) verir. `--flush`, `/run` altında birikmiş kayıtları diske aktarır
ve journald'ı kalıcı dosyaya geçirir. Doğrulama:

```bash
sudo journalctl --header | head -3          # File path artık /var/log/journal/...
ls -ld /var/log/journal/*/
```

`sudo systemctl restart systemd-journald` tek başına YETMEZ: ölçülmüş
davranış, dizin açıldıktan sonra yalnız restart atıldığında journald'ın
hâlâ `/run/log/journal` altına yazmaya devam ettiğidir. Aktarmayı tetikleyen
şey `--flush`'tır.

Şimdi çökme sebebini bul:

```bash
sudo journalctl -u bekci.service -p err -n 20 --no-pager
```

Çıktı:

```
bekci[551]: FATAL: /etc/bekci/lisans.key bulunamadi
systemd[1]: bekci.service: Main process exited, code=exited, status=3/NOTIMPLEMENTED
```

Çıkış kodu ham hâliyle de sorulabilir:

```bash
systemctl show bekci.service -p ExecMainStatus --value
```

Alternatif süzme yolları (aynı sonuca çıkar):

```bash
sudo journalctl -u bekci.service --since "5 min ago" --no-pager
pgrep -f /opt/bekci/bekci                    # süreç numarası
sudo journalctl _PID=<pid> --no-pager
```

`pgrep` burada tek başına yeterli değildir çünkü servis her 5 saniyede
yeniden doğar ve PID değişir; ama canlı bir sürecin kayıtlarını izlerken
doğal yoldur.

Cevabı yaz:

```bash
printf '/etc/bekci/lisans.key bulunamadi, cikis kodu 3\n' > /home/student/cevap-bekci.txt
```

Eksik dosyayı oluştur:

```bash
sudo mkdir -p /etc/bekci
sudo touch /etc/bekci/lisans.key
```

Servis yine çöker — ikinci hata ancak şimdi görünür:

```
bekci[425]: FATAL: lisans anahtari gecersiz (/etc/bekci/lisans.key icinde KEY= satiri yok)
```

Bu ikinci katman kasıtlıdır: program ilk eksiklikte durduğu için ikinci
kontrolü hiç çalıştıramıyordu. Düzelt:

```bash
echo 'KEY=A1B2-C3D4' | sudo tee /etc/bekci/lisans.key
sudo systemctl restart bekci.service
sudo systemctl enable bekci.service
systemctl status bekci.service
```

`Restart=always` olduğu için servis dosya düzeltilince kendiliğinden de
ayağa kalkar; `restart` sadece beklemeyi kısaltır. `enable` ayrı iştir:
setup servisi başlatır ama enable ETMEZ, kalıcılık senin işin.

## Görev 2 — cron: üç bağımsız hata

```bash
sudo systemctl enable --now crond.service
```

Sonra tanımı düzelt:

```bash
sudo vim /etc/cron.d/yedek
```

Bozuk hâli:

```
0 3 * * * root yedekle
```

Doğrusu:

```
* * * * * root /usr/local/bin/yedekle
```

Üç hata da burada kapanır: crond ayağa kalktı, zamanlama her dakikaya
çekildi, komut mutlak yolla yazıldı.

Mutlak yol yerine arama yolunu bildirmek de geçerli bir çözümdür:

```
PATH=/usr/local/bin:/usr/bin:/bin
* * * * * root yedekle
```

cron işlere varsayılan olarak `/usr/bin:/bin` verir. `/usr/local/bin`
bunun içinde yoktur — senin kabuğunda çalışan komutun cron'da
"command not found" almasının sebebi budur. cron bir giriş kabuğu
değildir: `.bash_profile`, `.bashrc` ya da `/etc/profile.d` hiç okunmaz.

Doğrulama (iş dakikada bir çalıştığı için en fazla bir dakika bekle):

```bash
cat /var/log/yedek/yedek.log
sudo journalctl -u crond.service -n 10 --no-pager | grep CMD
```

crond çıktısı:

```
CROND[...]: (root) CMD (/usr/local/bin/yedekle)
```

Not: `/etc/cron.d/` altındaki satırlarda kullanıcı crontab'ından farklı
olarak altıncı alan vardır — işin hangi kullanıcı olarak çalışacağı. Bu
alanı unutmak klasik hatadır; cron satırı sessizce çalışmaz.

## Görev 3 — systemd timer

İki dosya yazılır. Önce iş:

```bash
sudo vim /etc/systemd/system/temizlik.service
```

```
[Unit]
Description=Bakim isi

[Service]
Type=oneshot
ExecStart=/usr/local/bin/temizlik
```

`Type=oneshot`: iş çalışır ve biter, ayakta kalan bir süreç değil. Bu
birimin `[Install]` bölümü YOKTUR ve enable EDİLMEZ — onu tetikleyecek
olan zamanlayıcıdır.

Sonra zamanlayıcı:

```bash
sudo vim /etc/systemd/system/temizlik.timer
```

```
[Unit]
Description=Bakim isini periyodik calistirir

[Timer]
OnBootSec=15s
OnUnitActiveSec=30s
AccuracySec=1s

[Install]
WantedBy=timers.target
```

`AccuracySec=1s` kritik: varsayılan tolerans `1min`'dir ve sistem
zamanlayıcıları enerji tasarrufu için gruplayıp geciktirir. 30 saniyelik
bir aralık, tolerans daraltılmazsa bir dakikaya kadar kayabilir.

`.timer` ile `.service` aynı adı taşıdığı için `Unit=` yazmaya gerek
yoktur; systemd `temizlik.timer` için `temizlik.service`'i tetikler.
Farklı bir ad kullanacaksan `[Timer]` bölümüne `Unit=` eklenir.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now temizlik.timer
systemctl list-timers --no-pager | head -3
cat /var/log/temizlik.log
```

Etkinleştirilen `.timer`'dır, `.service` değil. `.service`'i enable etmek
onu açılışta bir kez çalıştırır ve zamanlayıcıyla ilgisi olmaz.

## Görev 4 — Saat dilimi ve senkron

```bash
sudo timedatectl set-timezone Europe/Istanbul
timedatectl show -p Timezone --value
ls -l /etc/localtime
```

`set-timezone`, `/etc/localtime` sembolik bağını
`/usr/share/zoneinfo/Europe/Istanbul` dosyasına yönlendirir — kalıcı olan
budur. `export TZ=Europe/Istanbul` yalnız o kabuğu etkiler, oturum
kapanınca biter ve sistemin saat dilimini değiştirmez.

Zaman kaynağını geri koy:

```bash
echo 'pool 2.rocky.pool.ntp.org iburst' | sudo tee -a /etc/chrony.conf
sudo systemctl enable --now chronyd.service
sudo timedatectl set-ntp true
timedatectl show -p NTP --value
timedatectl status
```

`set-ntp true`, systemd-timedated üzerinden sistemin NTP istemcisini
(burada chronyd) etkinleştirir. `enable --now chronyd` tek başına da
`NTP=yes` raporlar; ikisi aynı anahtarı çevirir.

Kaynak durumu:

```bash
chronyc sources
chronyc tracking
```

## Tuzaklar

- Kalıcı günlük için `Storage=` ayarı aramak: varsayılan `auto` zaten
  dizin varsa diske yazar. Eksik olan ayar değil, dizindir.
- Dizini açıp `--flush` atmamak: dizin var ama içi boş kalır, günlük
  hâlâ bellekte tutulur.
- `journalctl`'i `sudo`suz çalıştırmak: hata vermez, çıkış kodu 0'dır,
  sadece boş çıktı verir. Sessizce yanlış sonuca götürür.
- İlk hatayı düzeltip servisi kontrol etmemek: ikinci hata yalnız
  birinci giderildikten sonra görünür.
- cron'da komutu mutlak yolsuz bırakmak. Senin kabuğunda çalışması
  hiçbir şey kanıtlamaz; ölçüt cron'un verdiği `/usr/bin:/bin`.
- `/etc/cron.d/` satırında kullanıcı alanını unutmak.
- crond'u enable etmeden yalnız start etmek (ya da tersi): biri şimdiyi,
  diğeri açılışı ayarlar.
- `.timer` yerine `.service`'i enable etmek.
- `AccuracySec=` daraltmadan kısa aralıklı timer beklemek: 30s'lik timer
  varsayılan 1min toleransla geç ateşler.
- Yeni birim dosyalarını yazıp `daemon-reload` atmamak.
- Saat dilimini `TZ` ortam değişkeniyle "düzeltmek": geçicidir,
  `/etc/localtime` değişmez, sistem raporu eski değeri verir.
- Birim dosyalarını `/run/systemd/system/` altına yazmak: sistem
  yeniden başladığında kaybolur, kalıcı konum `/etc/systemd/system/`.
