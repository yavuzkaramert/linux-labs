# Solution — Lab 010: systemd Servisleri

Komutlar `student` olarak çalıştırılır. Sistem seviyesinde systemd'yi
değiştiren her işlem `sudo` ister; sorgular (`status`, `show`, `cat`,
`is-active`, `list-dependencies`) istemez.

## Görev 1 — Yeni unit yazma

`/opt/app/gorevci` ön planda kalıyor, fork etmiyor → `Type=simple`.

```bash
sudo tee /etc/systemd/system/gorevci.service >/dev/null <<'EOF'
[Unit]
Description=Gorevci servisi

[Service]
Type=simple
ExecStart=/opt/app/gorevci

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start  gorevci.service
sudo systemctl enable gorevci.service
systemctl is-active gorevci.service      # active
```

Dört adım da ayrı iş: `daemon-reload` tanımı belleğe alır, `start`
şimdi çalıştırır, `enable` açılış için `multi-user.target.wants/`
altına sembolik bağ kurar. `enable` başlatmaz, `start` kalıcı kılmaz.

`[Install]` bölümü olmadan `enable` çalışmaz — birimin hangi hedefe
bağlanacağı orada yazar.

## Görev 2 — Bozuk unit: iki katmanlı teşhis

```bash
systemctl status raporcu.service
#   Main PID: 166 (code=exited, status=217/USER)
```

`217/USER` = birimde yazan kullanıcı çözülemedi. Yol hatası bu
aşamada ÇIKMAZ; systemd süreci başlatırken önce kullanıcıya geçer,
oradan dönemeyince `ExecStart`'a hiç sıra gelmez. İkinci hata
gizlenmiş durumda.

```bash
getent passwd raporcu                    # bos: kullanici yok
sudo useradd -r -s /sbin/nologin raporcu
sudo systemctl restart raporcu.service
systemctl status raporcu.service
#    Process: 488 ExecStart=/usr/local/bin/raporcu (code=exited, status=203/EXEC)
```

Kod değişti: `203/EXEC` = çalıştırılacak dosya yok ya da
çalıştırılabilir değil. İkinci hata ancak şimdi görünür oldu.

```bash
sudo sed -i 's#^ExecStart=.*#ExecStart=/opt/raporcu/bin/raporcu#' \
    /etc/systemd/system/raporcu.service
sudo systemctl daemon-reload
sudo systemctl restart raporcu.service
```

**daemon-reload'u atlarsan ne olur (fiilen ölçüldü):**

```
Warning: The unit file ... changed on disk. Run 'systemctl daemon-reload'
is-active: failed
NeedDaemonReload: yes
```

Dosya doğru, sistem hâlâ eski tanımı çalıştırıyor. `NeedDaemonReload`
özelliği disk ile bellek arasındaki bu ayrışmanın adıdır.

`User=` için iki geçerli çözüm var: kullanıcıyı yaratmak (yukarıdaki)
ya da `User=` satırını var olan bir kullanıcıya çevirmek / tümden
silmek (silinirse servis root olarak çalışır). Sınanan şey systemd'nin
o kullanıcıyı çözebilmesi.

## Görev 3 — Bağımlılık sırası

`veritabani.service` bir kez çalışıp çıkar (`Type=oneshot`), ama
`RemainAfterExit=yes` sayesinde çıktıktan sonra da `active (exited)`
kalır. `api.service` başlarken `/var/lib/veritabani/.ready` arıyor.

```bash
sudo sed -i '/^Description=/a After=veritabani.service\nRequires=veritabani.service' \
    /etc/systemd/system/api.service
sudo systemctl daemon-reload
sudo systemctl enable veritabani.service
sudo systemctl restart api.service
```

İki direktif AYRI işler ve biri diğerinin yerini tutmaz:

| Direktif | Ne yapar | Tek başına neden yetmez |
|---|---|---|
| `After=` | sırayı belirler | veritabani hiç başlatılmazsa sıralanacak bir şey yok |
| `Requires=` | birimi çeker | çekilen birim api ile aynı anda başlayabilir, yarış olur |

Doğrulama (çözüm değil, kontrol aracı):

```bash
systemctl list-dependencies api.service
# api.service
# ● ├─system.slice
# ● ├─veritabani.service
# ● └─sysinit.target

systemctl is-active veritabani.service   # active
systemctl show veritabani.service -p SubState --value   # exited
systemctl is-active api.service          # active
```

`Requires=` ile çekilen birim `enable` edilmemiş olsa da başlatılır;
buradaki `enable` açılış kalıcılığı için.

## Görev 4 — Varsayılan target

```bash
systemctl get-default                    # rescue.target
sudo systemctl set-default multi-user.target
systemctl get-default                    # multi-user.target
```

`set-default` yalnız `/etc/systemd/system/default.target` sembolik
bağını değiştirir; çalışan sistemi o hedefe GEÇİRMEZ. Geçirmek
isteseydin `isolate` gerekirdi — bu görevde istenmiyor.

## Alternatif düzenleme yöntemi

Birincil yöntem yukarıdaki: dosyayı doğrudan `/etc/systemd/system/`
altına yazıp `daemon-reload`. Alternatif:

```bash
sudo systemctl edit --full raporcu.service
```

Editörden çıkınca `systemctl` tanımları kendisi tazeler,
`daemon-reload` gerekmez. `--full` bayrağı ŞART: bayraksız `edit` tam
dosyayı değil, üstüne yazan bir drop-in parçası
(`raporcu.service.d/override.conf`) oluşturur.

`--runtime` bayrağından kaçın: değişikliği `/run/systemd/system`
altına yazar, yeniden başlatmada kaybolur. Bu labda kalıcılık kriteri
onu eler (`FragmentPath` ile doğrulanır — fiilen sınandı: birim
yalnız /run altındayken kriter FAIL veriyor).

## Tuzaklar

- `daemon-reload` unutmak: dosya doğru, davranış yanlış. Belirti
  `NeedDaemonReload=yes` ve restart sırasındaki uyarı satırı.
- `enable` ≠ `start`. Biri açılış için, diğeri şimdi için.
- Yalnız `After=` yazmak: api sıraya girer ama veritabani hiç
  başlamaz, `.ready` oluşmaz, api yine çöker.
- Ön planda kalan bir script'e `Type=forking` vermek: systemd ana
  sürecin çıkmasını bekler, çıkmayınca zaman aşımına düşer.
- Çıkıp biten bir script'e `RemainAfterExit` vermemek: birim çalışır
  ama `inactive (dead)` görünür, ona bağlı servisler bunu "hazır
  değil" sayar.
- İki hatalı unit'te ilk hatayı düzeltmeden ikincisini aramak:
  `217/USER` çıktığı sürece `203/EXEC` hiç basılmaz.
- `/etc/systemd/system/` `/run/systemd/system/`'den önceliklidir:
  birimi /run'a KOPYALAMAK hiçbir şey değiştirmez, /etc'deki dosya
  kazanır.
