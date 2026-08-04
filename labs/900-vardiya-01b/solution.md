# Kaynak Haritası — Lab 900-vardiya-01b

Bu bir **tekrar labı**. Burada tam komut çözümü YOK ve bilerek yok:
her ticket daha önce çözdüğün bir lab'ın birebir uyarlaması. Takıldığın
yerde ilgili lab'ın kendi `solution.md`'sini aç.

    ./labctl solution 007a-text-filters
    ./labctl solution 007b-regex-report
    ./labctl solution 008-links-fhs-archiving
    ./labctl solution 009-package-management
    ./labctl solution 010-systemd
    ./labctl solution 011-journalctl-cron-zaman
    ./labctl solution 012-ssh-gpg

## Ticket → kaynak lab özeti

| Ticket | Kaynak lab | Kriter | Bu labda ne değişti |
|---|---|---|---|
| 7  | `007a-text-filters` | 13 | `/srv/data` → `/srv/proje/destek`, `tickets.csv` → `biletler.csv`, `access.log` → `erisim.log` |
| 8  | `007b-regex-report` | 19 | `/srv/raw` → `/srv/proje/gunlukler`, `/srv/work` → `/srv/proje/work`, `/etc/labs` → `/etc/proje` |
| 9  | `008-links-fhs-archiving` | 11 | birebir, yollar aynı |
| 10 | `009-package-management` | 16 | birebir, yollar aynı (ağ gerekli) |
| 11 | `010-systemd` | 11 | birebir |
| 12 | `011-journalctl-cron-zaman` | 19 | birebir |
| 13 | `012-ssh-gpg` | 15 | birebir |

## Kriter kırılımı

### Ticket 7 — lab 007a (13 kriter)

| Kriter | Orijinal karşılığı |
|---|---|
| 7.1–7.2 | kriter 1-2: `01-adet.txt` biçim + değer |
| 7.3–7.5 | kriter 3-5: `02-acik.txt` küme, tuzak bilet, sıra |
| 7.6–7.7 | kriter 6-7: `03-oncelik.txt` biçim + dağılım |
| 7.8–7.9 | kriter 8-9: çıkış kodu 0 / 1 |
| 7.10–7.12 | kriter 10-12: `^TODO`, `sunucu1`→`web01` (geçiş sayısı), gerisi aynı |
| 7.13 | kriter 13: kaynak dosyalar değişmemiş (korkuluk) |

Tuzaklar birebir korundu: konu alanında `open` geçen kapalı biletler,
satır ortasındaki `TODO`, bir satırda iki kez geçen `sunucu1`.

### Ticket 8 — lab 007b (19 kriter)

| Kriter | Orijinal karşılığı |
|---|---|
| 8.1–8.4 | kriter 1-4: normalleştirme (satır sayısı, tarih, boşluk, sıra) |
| 8.5–8.8 | kriter 5-8: `valid`/`invalid` ayrımı ve toplam korunumu |
| 8.9–8.11 | kriter 9-11: `ozet.txt` biçim, toplam, tekil ip |
| 8.12–8.14 | kriter 12-14: `report.conf` yorum, yol, retention |
| 8.15–8.18 | kriter 15-18: `mkreport` çalışması, DIRTY/CLEAN, çıkış kodu, idempotens |
| 8.19 | kriter 19: `merged.log` değişmemiş (korkuluk) |

Not: brief bu ticket için "15 kriter" diyordu; lab 007b'nin gerçek
check'inde 19 kriter var ve orijinale sadık kalındı.

Tuzaklar birebir: çapasız regex'in yakaladığı önek metinli satırlar,
`.+$` ile geçerli sayılan beş alanlı satırlar, mesaj içinde geçen
seviye adı ve IP.

### Ticket 9 — lab 008 (11 kriter)

| Kriter | Orijinal karşılığı |
|---|---|
| 9.1–9.3 | kriter 1-3: FHS yerleşimi, taşıma (kopyalama değil), `+x` ve PATH |
| 9.4 | kriter 4: `baglanti-raporu.txt` |
| 9.5–9.6 | kriter 5-6: hard link inode kimliği, symlink hedefi |
| 9.7 | kriter 7: `du` ile gerçek disk kullanımı (hard link tuzağı) |
| 9.8–9.10 | kriter 8-10: arşiv içeriği, `--exclude`, açmadan doğrulama |
| 9.11 | kriter 11: kaynaklar değişmemiş (`gecici/` silinmemiş) |

### Ticket 10 — lab 009 (16 kriter)

| Kriter | Orijinal karşılığı |
|---|---|
| 10.1–10.2 | kriter 1-2: `rpm -qf` + `rpm -ql` |
| 10.3–10.4 | kriter 3-4: `rpm -V`, değişen alanlar `icerik,izin` |
| 10.5–10.6 | kriter 5-6: `dnf provides` ile eksik komut, kurulum |
| 10.7–10.8 | kriter 7-8: `dnf history undo`, `hesapla` çalışıyor |
| 10.9–10.10 | kriter 9-10: `.rpm`'i kurmadan inceleme |
| 10.11–10.13 | kriter 11-13: EPEL, CRB, `dpkg` |
| 10.14–10.15 | kriter 14-15: `.deb`'i kurmadan inceleme |
| 10.16 | kriter 16: paket dosyaları değişmemiş (korkuluk) |

Kaldırma işlemi geçmişte en üstteki kayıt DEĞİL — `dnf history` okumadan
"son işlemi geri al" refleksi doğru cevabı vermez.

### Ticket 11 — lab 010 (11 kriter)

| Kriter | Orijinal karşılığı |
|---|---|
| 11.1–11.3 | kriter 1-3: `gorevci.service` tip/ExecStart, aktif+enabled, canlı süreç |
| 11.4–11.6 | kriter 4-6: `raporcu` iki hatası, `NeedDaemonReload=no` |
| 11.7–11.9 | kriter 7-9: `After`+`Requires`, oneshot tamamlanma, `api` ayakta |
| 11.10 | kriter 10: varsayılan target |
| 11.11 | kriter 11: `FragmentPath` kalıcı konumda |

`raporcu`'nun iki hatası katmanlı: systemd önce 217/USER verir ve
203/EXEC'i maskeler. Kullanıcı düzeltilmeden yol hatası görünmez.

### Ticket 12 — lab 011 (19 kriter)

| Kriter | Orijinal karşılığı |
|---|---|
| 12.1–12.3 | kriter 1-3: kalıcı journal, cevap dosyası, `bekci` iki kademeli hata |
| 12.4–12.8 | kriter 4-8: cron servisi, zamanlama, PATH, gerçek log, crond günlüğü |
| 12.9–12.14 | kriter 9-14: `temizlik.service`+`.timer`, tetikleme aralığı, gerçek log |
| 12.15–12.19 | kriter 15-19: saat dilimi, kalıcılık, chrony sunucusu, servis, NTP |

`bekci` önce eksik dosyadan (exit 3), dosya açılınca `KEY=` satırı
olmadığından (exit 4) çöker. İkincisi ilki çözülmeden görünmez.

### Ticket 13 — lab 012 (15 kriter)

| Kriter | Orijinal karşılığı |
|---|---|
| 13.1–13.4 | kriter 1-4: izin zinciri ve gerçek anahtarla giriş denemesi |
| 13.5–13.8 | kriter 5-8: `sshd -t`, `sshd -T` etkin değerler, servis tazeliği |
| 13.9–13.11 | kriter 9-11: GPG anahtarı, şifreleme, çözülen içerik |
| 13.12–13.15 | kriter 12-15: yayıncı anahtarı, imza doğrulama, cevap, ayrık imza |

Servis tazeliği `ExecMainStartTimestampMonotonic` ile `sshd_config`
mtime'ının karşılaştırılmasıyla ölçülür: dosyayı düzeltip servisi
yeniden başlatmamak kriteri geçirmez.

Tek fark: burada 1 saniyelik tolerans var. Monotonic saat → epoch
çevirimi saniyeye yuvarladığı için düzenleme ile restart aynı saniyeye
düştüğünde orijinal kriter haksız yere düşüyordu. Yakalanmak istenen
hata ("restart unutuldu") dakikalar mertebesinde olduğundan bu pencere
onu kaçırmaz.

## Bu labın kendine ait tek yeniliği

Yok — hepsi tekrar. Tek fark, yedi konunun tek bir gün içinde arka arkaya
gelmesi ve `/home/student/cevaplar/` dizininin üç ticket tarafından
paylaşılması. Ticket'lar birbirinden teknik olarak bağımsız; biri
çözülmeden diğerinin kriterleri yanlış yöne etkilenmez.
