# Kaynak Haritası — Lab 901-gun-02b

Bu bir **tekrar labı**. Burada tam komut çözümü YOK ve bilerek yok:
her ticket daha önce çözdüğün bir lab'ın aynı beceriyi sınayan yeni
bir senaryosudur. Takıldığın yerde ilgili lab'ın kendi `solution.md`
dosyasını aç.

    ./labctl solution 007a-text-filters
    ./labctl solution 007b-regex-report
    ./labctl solution 008-links-fhs-archiving
    ./labctl solution 009-package-management
    ./labctl solution 010-systemd
    ./labctl solution 011-journalctl-cron-zaman
    ./labctl solution 012-ssh-gpg

Gün 1'den (900-vardiya-01b) farkı: senaryo, veri, dosya adları,
kullanıcılar ve birim adları tamamen yenidir. Komut yüzeyi aynı,
metin değil.

## Ticket → kaynak lab tablosu

| Ticket | Kaynak lab | Orijinal karşılığı | Bu labda ne değişti |
|---|---|---|---|
| 7.1–7.2 | `007a` | kriter 1-2 (adet) | veri `talepler.csv`, `;` ayraçlı, başlık satırı var |
| 7.3–7.5 | `007a` | kriter 3-5 (açık kayıtlar) | tuzak korundu: KAPALI taleplerin `konu` alanında `open` geçiyor |
| 7.6–7.7 | `007a` | kriter 6-7 (öncelik dağılımı) | üç öncelik: `yuksek`/`orta`/`dusuk` |
| 7.8–7.9 | `007a` | kriter 8-9 (arama çıkış kodları) | aranan kelime `ENGELLENDI`, `erisim.log` içinde 3 kez geçiyor |
| 7.10–7.12 | `007a` | kriter 10-12 (yerinde düzenleme) | `^TODO` silinir, `sube1` → `merkez-sube`; bir satırda İKİ `sube1` |
| 7.13 | `007a` | kriter 13 (kaynak korunumu) | `talepler.csv` ve `erisim.log` |
| 8.1–8.4 | `007b` | kriter 1-4 (normalizasyon) | `karisik.log`, aşı/randevu kayıtları |
| 8.5–8.8 | `007b` | kriter 5-8 (ERE ile ayırma) | dört tuzak sınıfı korundu: baştaki serbest metin, fazla alan, bozuk IP, tanınmayan seviye |
| 8.9–8.12 | `007b` | kriter 9-11 (özet) | `asi-ozet.txt`; mesaj alanında geçen seviye adı ve IP tuzağı |
| 8.13–8.15 | `007b` | kriter 12-14 (conf düzenleme) | `/opt/eskisistem` → `/srv/klinik/veri`, `retention` 45 |
| 8.16–8.19 | `007b` | kriter 15-19 (`mkreport`) | script adı `rapor-uret`; CLEAN yolu için ortam geçici olarak temiz veriyle değiştirilir |
| 9.1 | `008` | disk kullanımı | sert bağlantı çifti `kayit1` + `kayit1-yedek`; bağımsız kopya `kayit2-kopya` çeldirici |
| 9.2–9.3 | `008` | hard link / symlink | `kayit3.txt` üzerinden, inode ve link sayısı ayrı ayrı sınanır |
| 9.4–9.6 | `008` | FHS yerleşimi | `randevu.conf` → `/etc/randevu`, `klinik-uygulama.log` → `/var/log/randevu`, `yedek-yardimcisi` → `/usr/local/bin` |
| 9.7–9.9 | `008` | arşiv + doğrulama | `gecici/` dışlanacak ama kaynaktan SİLİNMEYECEK |
| 9.10 | `008` | bağlantı raporu | `kayit1` sert bağlantı, `kayit2` bağımsız kopya |
| 9.11 | `008` | kaynak korunumu | iki kaynak dizin `diff -r` ile bütün olarak sınanır |
| 10.1–10.2 | `009` | EPEL + CRB | EPEL tanımı `data/epel.repo` ile diskte hazır ama KAPALI; CRB adı hata mesajından çıkarılır |
| 10.3–10.4 | `009` | `bc` + `hesapla` | script `dozhesapla.sh`, ilaç dozu hesabı |
| 10.5–10.6 | `009` | eksik komut | `lsof` |
| 10.7–10.8 | `009` | `rpm -qf` + `rpm -ql` | `/usr/bin/tree` sahibi paket; ad sabit yazılmaz, sorgulanır |
| 10.9–10.11 | `009` | `.rpm`'i kurmadan inceleme | paket kurulmuşsa kriter DÜŞER — yan hasar yakalanır |
| 10.12–10.14 | `009` | `dpkg` + `.deb` inceleme | `dpkg` CRB bağımlılığı üzerinden gelir |
| 10.15 | `009` | `rpm -V` vs `-Vf` | `/etc/vimrc` hem içerik hem izin olarak bozuk; rapor paket ADI ister |
| 10.16 | `009` | referans korunumu | `/srv/klinik/paketler` |
| 11.1–11.2 | `010` | oneshot + RemainAfterExit | `veritabani-hazirla.service` |
| 11.3–11.5 | `010` | After + Requires | `randevu-api.service`; `BindsTo` bu iş için doğru tercih değil |
| 11.6–11.8 | `010` | gerçekten koşuyor mu | `hatirlatici.service`; `MainPID` + `SubState` ayrı ayrı sorgulanır |
| 11.9–11.10 | `010` | ExecStart + User + daemon-reload | `stok-raporu.service` |
| 11.11 | `010` | varsayılan target | `rescue.target` → `multi-user.target`, birim dosyaları kalıcı konumda |
| 12.1–12.2 | `011` | kalıcı journal | `Storage=`, dizin ve `--flush` zinciri |
| 12.3–12.6 | `011` | `bekci` → `gozcu` | eksik dosya `/etc/klinik/lisans.anahtar`, çıkış kodu 3 |
| 12.7–12.11 | `011` | cron | PATH tuzağı korundu: cron'un PATH'i `/usr/bin:/bin` |
| 12.12–12.17 | `011` | timer | `temizlik.service` + `temizlik.timer`; `NextElapseUSec*` insan-okur biçimde döner |
| 12.18–12.19 | `011` | saat dilimi + chrony | `Europe/Istanbul` |
| 13.1–13.4 | `012` | izinler + StrictModes | ev dizini `0775` tuzağı korundu |
| 13.5–13.8 | `012` | sshd sertleştirme | config bozuk ve servis yeniden başlatılmamış olarak kurulur |
| 13.9 | `012` | gerçek giriş | `ssh -o BatchMode=yes` ile canlı bağlantı denemesi |
| 13.10–13.11 | `012` | GPG anahtarlığı | kimlik `PatiVet BT <bt@pativet.local>` |
| 13.12–13.13 | `012` | imza doğrulama | `surum-a` sağlam, `surum-b` kurcalanmış (image'da böyle üretiliyor) |
| 13.14 | `012` | şifreleme roundtrip | `gizli-hasta-notu.txt` |
| 13.15 | `012` | ayrık imza | `devir-notu.txt` |

## Uygulama notları

`check.sh` Ticket 8'de **değerlendirme sırasına** bağlıdır: öğrencinin
kendi ürettiği dosyalar (8.1–8.15) ÖNCE ölçülür, `rapor-uret` SONRA
koşturulur. Ters sıra öğrencinin işini ölçülemez hâle getirirdi.

Ticket 8.19 ve 12.x bazı kriterler ortamı geçici olarak değiştirir
(`karisik.log` takası, servis listesi vb.) ve her seferinde eski hâline
geri döner. Hiçbir kriter süreç öldürmez veya servis durdurmaz.

Beklenen değerlerin hiçbiri sabit yazılmamıştır: hepsi `/srv/.orig`
altındaki değişmez kopyalardan ya da canlı sistemden hesaplanır.

### Baştan geçen üç kriter

Sıfır bedava OK kuralının tek istisnası **korkuluk kriterleridir**:
7.13, 9.11 ve 10.16. Üçü de "bu dosyalara dokunulmadı" der, yani
doğru başlangıç durumu zaten geçer durumdur — tanımı gereği bozulamaz.
Amaçları ödül değil **yan hasarı yakalamak**: örneğin `gecici/`
içeriğini `tar --exclude` ile dışarıda bırakmak yerine kaynaktan
`rm -rf` etmek 9.11'i düşürür. Aynı kalıp Gün 1'de de vardı (orada
altı korkuluk kriteri sayılmıştı). Geri kalan **101 kriterin hepsi**
sıfırdan başlar.

## Ortam gereksinimleri

Bu lab `container-systemd` ister — Ticket 11, 12 ve 13'ün kriterleri
systemd'nin PID 1 olmasını gerektirir. Ticket 10 ayrıca **gerçek ağ
erişimi** ister (EPEL/CRB metadata, `bc`, `lsof`, `dpkg` indirmeleri).

GPG ve paket varlıkları image'daki `/opt/lab-assets/paket` altından
gelir; `setup.sh` onları `/opt/paket` altına kopyalar. Yayıncının gizli
anahtarı image'da yoktur, dolayısıyla `surum-b`'nin imzası yeniden
üretilemez — kurcalanmış paket kalıcı olarak kurcalanmış kalır.
