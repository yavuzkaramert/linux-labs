# Lab 004 — Metin İşleme

## Hikâye

Dün gece web sunucusunda bir şeyler ters gitti. Müşteri destek ekibi sabaha
karşı "site açılmıyor" çağrıları almış, ama kimse ne olduğunu bilmiyor.
Elinde tek şey var: `/srv/logs` altındaki ham log dosyaları.

Saat 11:00'de yönetim toplantısı var ve senden birkaç net rapor bekleniyor —
kaç hata olmuş, en çok istek nereden gelmiş, kaç farklı kullanıcı etkilenmiş.
Ayrıca uygulamanın ayar dosyası hâlâ kapatılmış eski sunucuyu gösteriyor ve
hata ayıklama modu production'da açık unutulmuş; ikisi de düzeltilmeli.

Log dosyaları yüzlerce satır. Elle okuyup saymaya kalkarsan toplantıya
yetişemezsin — dosyaları **süzerek, ayıklayarak ve sayarak** çalışman
gerekiyor.

## Görevler

1. **Loglara erişimi aç.** `/srv/logs` altındaki log dosyaları şu an
   `student` kullanıcısı tarafından okunamıyor. Sahiplik ve/veya izinleri,
   `student` bu dosyaları `sudo` kullanmadan okuyabilecek şekilde düzelt.

2. **Hataları ayıkla.** `/srv/logs/access.log` içinde HTTP durum kodu **500**
   olan istek satırlarının tamamı, orijinal sıraları korunarak
   `/srv/reports/errors.log` dosyasında olmalı. Durum kodu 500 olmayan hiçbir
   satır bu dosyaya girmemeli. Dikkat: log satırlarında 500 sayısı durum kodu
   dışındaki alanlarda da geçebiliyor.

3. **En çok istek yapan adresleri çıkar.** `/srv/reports/top-ips.txt`
   dosyasında, `access.log` içinde en çok isteği yapan **5 IP adresi**,
   istek sayısına göre çoktan aza sıralı olmalı. Her satır: istek sayısı,
   boşluk, IP adresi. Dosyada tam 5 satır olmalı.

4. **Etkilenen kullanıcıları say.** `/srv/reports/unique-users.txt`
   dosyasında **tek bir satır** olmalı ve o satırda sadece bir sayı
   bulunmalı: `access.log` içindeki birbirinden farklı kullanıcı adı sayısı.
   Kullanıcı alanı `-` olan (anonim) istekler sayıma dâhil edilmemeli.

5. **Uyarıları tabloya dök.** `/srv/logs/app.log` dosyasının alanları `|`
   karakteriyle ayrılmış. Bu dosyadaki **sadece WARN** seviyesindeki
   satırların zaman damgası ve mesaj metni, aralarında bir TAB karakteri
   olacak şekilde `/srv/reports/warnings.tsv` dosyasında olmalı. Satır sırası
   orijinaliyle aynı olmalı; INFO, ERROR veya DEBUG satırları bu dosyaya
   girmemeli.

6. **Ayar dosyasını düzelt.** `/etc/webapp/settings.conf` içinde:
   hata ayıklama modu kapalı olmalı, ve kapatılmış eski sunucu adı
   `old-server.local` geçen her yerde `web01.local` ile değiştirilmiş olmalı.
   `#` ile başlayan yorum satırları **hiç değişmemeli** — içlerinde eski
   sunucu adı geçse bile aynı kalmalı. Dosyanın değişiklik öncesi hali
   `/srv/reports/settings.conf.orig` olarak saklanmış olmalı.

7. **Sunucu listesini temizle.** `/etc/webapp/hosts.list` dosyasının boş
   satırlardan ve `#` ile başlayan satırlardan arındırılmış hali
   `/srv/reports/hosts-clean.txt` dosyasında olmalı. Kalan satırların
   içeriği ve sırası değişmemeli.

## Kabul kriterleri

- `su - student -c 'cat /srv/logs/access.log'` ve `app.log` için aynısı
  hatasız çalışıyor.
- `/srv/reports/errors.log`, `access.log`'daki 500 durum kodlu satırların
  tamamını ve **sadece** onları, orijinal sırayla içeriyor.
- `/srv/reports/top-ips.txt` tam 5 satır; her satır "sayı boşluk IP"
  biçiminde ve sayılar azalan sırada.
- `/srv/reports/unique-users.txt` tek satır ve sadece doğru sayıyı içeriyor;
  `-` kullanıcısı sayılmamış.
- `/srv/reports/warnings.tsv` sadece WARN satırlarından oluşuyor, her satırda
  tam bir TAB karakteri var, sıra orijinaliyle aynı.
- `/etc/webapp/settings.conf` içinde etkin hata ayıklama ayarı kapalı,
  etkin satırlarda `old-server.local` kalmamış, yorum satırları orijinaliyle
  birebir aynı.
- `/srv/reports/settings.conf.orig` var ve düzeltme öncesi orijinal içeriği
  taşıyor.
- `/srv/reports/hosts-clean.txt` içinde boş satır ve `#` ile başlayan satır
  yok; kalan satırlar orijinal içerik ve sırayla duruyor.

## Kontrol

Host terminalinden: `labctl check 004`
Takıldın mı? `labctl hint 004 1` (seviye 1–3, her biri daha spesifik).
