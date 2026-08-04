Lab 900-vardiya-01a — Vardiya: Sabah (08:00–12:00)
==================================================

Hikâye
------

Bugün yeni işe başlıyorsun. Küçük bir firmada tek kişilik sistem
sorumlususun. Gece nöbetçisi bir vardiya günlüğü bırakmış ama sen
onu bile okuyamıyorsun.

Bu bir tekrar labı. Buradaki altı ticket'ın hepsini daha önce
gördün — 001'den 006'ya kadar. Yeni bir konu yok, yeni bir komut
yok. Yalnızca hepsi aynı sabahın içinde, arka arkaya geliyor.

Süreyi kendin tut: başlangıç ve bitiş saatini JOURNAL.md'ye elle
yaz. Script senin yerine saat tutmuyor.

Görevler
--------

**Ticket 1 — Vardiya günlüğü** (kaynak: lab 001)

Gece nöbetçisinin bıraktığı günlük şurada:

    /vardiya/gunluk.md

Okuyamıyorsun. Sudo'suz okuyabilir hâle getir ama değiştiremiyor
ol. Dosya ve dizin sisteme ait: sahiplik `root:root` olarak
KALMALI. Çözüm dosyayı kendine chown etmek değil.

**Ticket 2 — İşe alımlar ve proje dizini** (kaynak: lab 002)

İki yeni işe alım var: `ayse` ve `mehmet`. Ayrıca `tolga` geçen ay
ayrıldı ama hesabı hâlâ duruyor.

1. `developers` grubunu aç, GID'i tam `4000` olsun.
2. `ayse` ve `mehmet` kullanıcılarını aç: ev dizinleri
   `/home/<isim>`, sahibi kendileri, kabukları `/bin/bash`.
3. İkisinin de birincil grubu kendi adıyla aynı olsun; `developers`
   ikincil (supplementary) grup olarak eklensin.
4. `deploybot` servis hesabını aç: kabuk nologin, `developers`
   üyesi, ev dizini `/home/deploybot` OLUŞMASIN.
5. `/srv/proje` dizini var ama yanlış sahiplik ve izinle. Sahibi
   `root:developers`, modu tam `2770` olmalı.
6. `ayse` `/srv/proje` içinde dosya açabilmeli; açtığı dosya
   otomatik olarak `developers` grubuna düşmeli; `mehmet` de o
   dosyaya yazabilmeli.
7. `tolga` hesabını ve `/home/tolga` dizinini kaldır.
8. `ayse` `wheel` grubunda OLMAMALI.
9. Kendini (`student`) de `developers` grubuna ekle. `2770` bir
   dizinde "other" hiçbir şey göremez — sen de bu grupta olmazsan
   Ticket 3 ve 4'te kendi yetkinle çalışamazsın.

**Ticket 3 — Proje dizinini temizle** (kaynak: lab 003)

`/srv/proje` dağınık. Hepsi bu dizinin altında:

1. 30 günden eski `.log` dosyalarını `/srv/proje/archive/` altına
   taşı. Yeniler yerinde kalsın. Hiçbiri silinmesin.
2. 0 byte'lık artık dosyaları sil. Dolu dosyalara ve boş dizinlere
   dokunma.
3. `/srv/proje/tmp/` içindeki 1 MB'den büyük dosyaları
   `/srv/proje/big/` altına taşı. Küçükler tmp'de kalsın.
4. `/srv/proje/config/` dizinini `/srv/proje/backup/config` altına
   kopyala. İzin, sahiplik ve değişiklik zamanı birebir korunmalı.
5. `/srv/proje/reports/latest` adında sembolik link üret; `reports/`
   içindeki en güncel `.csv` dosyasını göstersin. En yeni dosya ile
   en yeni csv aynı şey değil, dikkat.
6. `/srv/proje/scripts/` altındaki (alt dizinler dâhil) tüm `.sh`
   dosyaları `student` tarafından çalıştırılabilir olsun. `.sh`
   olmayan dosyalarda çalıştırma izni olmasın.

**Ticket 4 — Log analizi** (kaynak: lab 004)

Gece boyunca log birikti:

    /srv/proje/logs/access.log
    /srv/proje/logs/app.log

1. İkisini de `student` olarak, sudo'suz okuyabilir hâle getir.
2. `/srv/reports/errors.log` — `access.log`'daki yalnızca HTTP 500
   durum kodlu satırlar, orijinal sırayla. Satırın başka
   alanlarında da 500 geçiyor, ona kanma.
3. `/srv/reports/top-ips.txt` — en çok istek yapan 5 IP, azalan
   sırada, "sayı IP" biçiminde, tam 5 satır.
4. `/srv/reports/unique-users.txt` — tek satır, tek sayı: kaç farklı
   kullanıcı istek yapmış (`-` sayılmaz).
5. `/srv/reports/warnings.tsv` — `app.log`'daki yalnızca WARN
   satırları, zaman ve mesaj TAB ile ayrılmış, orijinal sırada.
6. `/srv/proje/etc/settings.conf` — etkin `debug` kapatılsın, etkin
   satırlardaki `old-server.local` yerine `web01.local` yazılsın.
   Yorum satırları birebir korunmalı. Düzeltmeden önceki orijinali
   `/srv/reports/settings.conf.orig` olarak sakla.
7. `/srv/reports/hosts-clean.txt` — `/srv/proje/etc/hosts.list`'ten
   boş satırlar ve `#` ile BAŞLAYAN satırlar çıkarılmış hâli. Kalan
   satırların içeriği ve sırası değişmeyecek.

**Ticket 5 — Başıboş süreçler** (kaynak: lab 005)

Üç süreç başıboş kalmış. Komut satırlarında `LABPROC-hog`,
`LABPROC-rogue` ve `LABPROC-batch` işaretleri geçiyor.

1. `/srv/reports/procs.txt` — `LABPROC` işareti taşıyan süreçlerin
   PID ve tam komut satırı dökümü. Kendi arama komutun (grep)
   listede olmayacak.
2. `LABPROC-hog` CPU yiyor: kibar sinyalle (SIGTERM) durdur.
3. `LABPROC-rogue` kibar sinyali yok sayıyor. Onu durdurmanın tek
   yolu var, bul.
4. `LABPROC-batch` gece batch işi — ÖLDÜRME. Önceliğini düşür:
   nice değeri 10 veya üzeri olsun.
5. `/srv/reports/batch-nice.txt` — tek satır, `LABPROC-batch`'in
   güncel nice değeri.

**Ticket 6 — Gün ortası özet raporu** (kaynak: lab 006)

Öğlen arasından önce özet rapor zincirini ayağa kaldır. Log:
`/var/log/vardiya/gunluk.log` (`|` ayraçlı, seviye ikinci alan).
Servis listesi: `/etc/vardiya/servisler.list`.

1. `/usr/local/bin/logsum` bozuk. Onar: argüman olarak verilen log
   dosyasındaki seviyeleri saysın, `SEVIYE:sayı` biçiminde bassın.
   Seviye adı mesajın içinde de geçiyor — alanı doğru seç.
2. `logsum` hata davranışı: argümansız çağrılırsa stderr'e kullanım
   mesajı + çıkış kodu 2. Okunamayan/olmayan dosya için stderr +
   çıkış kodu 3. Başarıda stdout temiz, çıkış kodu 0.
3. `/usr/local/bin/svccheck` yaz. Argüman olarak servis adları alır,
   her biri için `[OK] <ad> <pid>` ya da `[FAIL] <ad>` basar. En az
   bir FAIL varsa çıkış kodu 1, hepsi ayaktaysa 0, argümansız 2.
   Kendi arama sürecin çıktıya karışmayacak.
4. `/usr/local/bin/report` yaz. `servisler.list`'i satır satır okur
   (boş ve `#` satırları atlanır), her servis için `svccheck`
   çağırır, sonunda `logsum`'ı çalıştırır, hepsini
   `/srv/reports/daily.txt`'e yazar. İlk satır `HEALTHY` ya da
   `DEGRADED`, çıkış kodu bunu yansıtır. Her çalıştırmada dosya
   sıfırdan üretilir.
5. Üç script de `student` tarafından sudo'suz ve tam yol yazmadan
   çalıştırılabilsin; başkası tarafından yazılamasın.

Notlar
------

* Ticket 2 çözülmeden Ticket 3 ve Ticket 4'ün bazı kriterleri
  geçemez: `/srv/proje` 2770 `root:developers` olduğunda o dizine
  yalnız grup üyeleri girebilir. Gün sırayla ilerliyor.
* Ticket 5'in `LABPROC-*` süreçleri ile Ticket 6'nın `vardiya-*`
  servisleri teknik olarak birbirine BAĞLI DEĞİL. Ayrı iki set.
* Ticket 6'da `vardiya-queue` süreci bilerek ayakta değil — bu bir
  hata değil, DEGRADED yolunu görmen için.
* `/srv/reports` senin çıktı dizinin; `/srv/proje`'nin dışında.

Kabul kriterleri
----------------

Ticket 1 (lab 001):
- [ ] 1.1 `/vardiya` root:root ve student için geçilebilir
- [ ] 1.2 gunluk.md root:root, student okuyor ama yazamıyor, içerik sağlam

Ticket 2 (lab 002):
- [ ] 2.1 developers grubu var, GID 4000
- [ ] 2.2 ayse ve mehmet var, ev dizini kendilerinin, kabuk /bin/bash
- [ ] 2.3 ayse/mehmet birincil grubu kendi adı, developers ikincil
- [ ] 2.4 deploybot nologin, developers üyesi, ev dizini yok
- [ ] 2.5 /srv/proje sahiplik root:developers, mod 2770
- [ ] 2.6 ayse dosya açıyor, grup setgid ile developers, mehmet yazabiliyor
- [ ] 2.7 tolga hesabı ve /home/tolga silinmiş
- [ ] 2.8 ayse var ve wheel grubunda değil
- [ ] 2.9 student developers üyesi, /srv/proje'ye sudo'suz girebiliyor

Ticket 3 (lab 003):
- [ ] 3.1 eski .log dosyaları archive/ altında, yeniler yerinde
- [ ] 3.2 0 byte dosyalar temiz; dolu dosyalar ve boş dizin yerinde
- [ ] 3.3 büyük dosyalar big/ altında, küçükler tmp'de
- [ ] 3.4 backup/config metadata ve içerik olarak birebir kopya
- [ ] 3.5 reports/latest en yeni csv'ye işaret eden sembolik link
- [ ] 3.6 tüm .sh'ler student ile çalışıyor; diğer dosyalarda x izni yok

Ticket 4 (lab 004):
- [ ] 4.1 student logları sudo'suz okuyabiliyor
- [ ] 4.2 errors.log sadece 500 satırları, orijinal sırada
- [ ] 4.3 top-ips.txt en çok istek yapan 5 IP, azalan sırada
- [ ] 4.4 unique-users.txt doğru tekil kullanıcı sayısı
- [ ] 4.5 warnings.tsv sadece WARN, TAB ayrımlı, orijinal sırada
- [ ] 4.6 settings.conf: debug kapalı, aktif old-server yok, yorumlar korunmuş
- [ ] 4.7 hosts-clean.txt yorum/boş satır yok, içerik korunmuş

Ticket 5 (lab 005):
- [ ] 5.1 procs.txt LABPROC süreçlerini PID + komut satırıyla listeliyor
- [ ] 5.2 LABPROC-hog süreç tablosunda yok
- [ ] 5.3 LABPROC-rogue süreç tablosunda yok
- [ ] 5.4 LABPROC-batch çalışıyor ve nice değeri >= 10
- [ ] 5.5 batch-nice.txt tek sayı ve sürecin gerçek nice değeriyle aynı

Ticket 6 (lab 006):
- [ ] 6.1 logsum seviye sayımlarını doğru biçim ve değerlerle basıyor
- [ ] 6.2 argümansız logsum: stdout boş, stderr dolu, çıkış kodu 2
- [ ] 6.3 olmayan dosya: stdout boş, stderr dolu, çıkış kodu 3
- [ ] 6.4 okunamayan dosya: çıkış kodu 3, stdout boş
- [ ] 6.5 svccheck sırayı koruyor, biçim doğru, yazılan PID'ler gerçek
- [ ] 6.6 svccheck çıkış kodları: 0 / 1 / 2
- [ ] 6.7 svccheck kendi arama süreci çıktıya karışmıyor
- [ ] 6.8 report DEGRADED yolunda 1 ile çıkıyor
- [ ] 6.9 daily.txt servis durumlarını ve log sayımlarını içeriyor
- [ ] 6.10 report iki kez çalışınca daily.txt büyümüyor
- [ ] 6.11 report HEALTHY yolunda 0 ile çıkıyor
- [ ] 6.12 üç script de student ile tam yolsuz çalışıyor, other-yazma kapalı

Kontrol
-------

    ./labctl check 900-vardiya-01a

Her satır hangi kaynak lab'dan geldiğini söyler. Takılırsan:

    ./labctl hint 900-vardiya-01a

Bu labda yalnız seviye 1 ipucu var. Daha fazlası için satırdaki
kaynak lab'ın kendi `solution.md`'sine bak.
