# Lab 003 — Dosya Bulma ve Yönetme

## Hikâye

Şirketin sistem yöneticisi iki hafta önce işten ayrıldı ve arkasında
`/srv/data` dizinini bıraktı. Kimse aylardır bu dizine dokunmadı; disk
uyarıları gelmeye başladı, gece çalışan rapor script'leri "permission
denied" hatası veriyor ve raporları çeken uygulama `/srv/data/reports/latest`
yolunu arıyor ama böyle bir şey yok.

Dizin ağacı derin ve dağınık — dosyalar üç dört seviye içeride, isimleri
tutarsız, aralarında sıfır byte'lık artıklar var. Tek tek `cd` yapıp elle
gezerek bu işi bitiremezsin; dosyaları **arayarak** bulman gerekiyor.

Sabah 09:00'da uygulama ekibi sunucuyu kullanmaya başlayacak. Ortalığı
toparlaman lazım.

## Görevler

1. **Eski logları arşivle.** `/srv/data` ağacının herhangi bir yerindeki
   `.log` uzantılı dosyalardan 30 günden eski olanlar `/srv/data/archive/`
   dizinine taşınmış olmalı. Daha yeni loglar bulundukları yerde kalmalı —
   arşive girmemeli.

2. **Sıfır byte'lık artıkları temizle.** `/srv/data` altında boş (0 byte)
   olan tüm normal dosyalar silinmiş olmalı. İçeriği olan hiçbir dosya
   silinmemeli; boş dizinler de silinmemeli.

3. **Büyük dosyaları ayır.** `/srv/data/tmp` altındaki 1 MB'den büyük
   dosyalar `/srv/data/big/` dizinine taşınmış olmalı. Küçük dosyalar `tmp`
   içinde kalmalı.

4. **Yedeği aslına sadık al.** `/srv/data/config` dizininin bir kopyası
   `/srv/data/backup/config` olarak duruyor olmalı. Kopyada dosyaların
   izinleri, sahipliği ve değiştirilme zamanları orijinaliyle birebir aynı
   olmalı.

5. **`latest` bağlantısını kur.** `/srv/data/reports/latest`, `reports/`
   içindeki en son değiştirilmiş `.csv` raporuna işaret eden bir sembolik
   link olmalı. Kopya değil, link.

6. **Script'leri çalışır hale getir.** `/srv/data/scripts` altındaki (alt
   dizinler dâhil) tüm `.sh` dosyaları `student` kullanıcısı tarafından
   doğrudan çalıştırılabilir olmalı. `.sh` olmayan dosyalara çalıştırma izni
   verilmemeli.

## Kabul kriterleri

- `/srv/data/archive/` var; 30 günden eski tüm `.log` dosyaları burada, yeni
  `.log` dosyaları burada **değil**.
- `/srv/data` altında 0 byte'lık normal dosya kalmadı; dolu dosyaların
  hiçbiri kaybolmadı.
- `/srv/data/big/` var; `tmp` içindeki >1 MB dosyalar burada, ≤1 MB dosyalar
  hâlâ `tmp` içinde.
- `/srv/data/backup/config` içindeki her dosyanın mod, sahip:grup ve mtime
  değeri `/srv/data/config` içindeki karşılığıyla aynı.
- `/srv/data/reports/latest` bir sembolik link ve hedefi, `reports/`
  içindeki en güncel `.csv`.
- `su - student -c '/srv/data/scripts/.../X.sh'` çalışıyor (tüm `.sh`'ler
  için); `scripts/` içindeki `.txt` dosyası çalıştırılabilir **değil**.

## Kontrol

Host terminalinden: `labctl check 003`
Takıldın mı? `labctl hint 003 1` (seviye 1–3, her biri daha spesifik).
