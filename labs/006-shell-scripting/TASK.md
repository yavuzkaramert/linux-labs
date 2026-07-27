# Lab 006 — Shell Scripting Temeli

## Hikâye

Sistemden sorumlu önceki yönetici ayrılırken arkasında yarım kalmış bir
otomasyon bıraktı. Sabah raporunu üreten üç parçalı bir zincir tasarlamış:
biri log dosyasını özetleyecek, biri servislerin ayakta olup olmadığına
bakacak, üçüncüsü ikisini birleştirip günlük raporu yazacak.

Sadece birincisi yazılmış — o da çalışmıyor. Argüman verilse de vermesen de
aynı dosyaya bakıyor, log satırlarını yanlış bölüyor, hata durumunda bile
"her şey yolunda" diyerek çıkıyor ve hata mesajlarını raporun ortasına
karıştırıyor. Diğer ikisi hiç yazılmamış; ne yapmaları gerektiği aşağıda.

Bu zincir gece otomatik çalışacak. Kimse çıktıyı gözle okumayacak —
başka bir sistem yalnızca **çıkış koduna** bakıp alarm üretecek. Yani
"ekrana doğru şeyi basmak" yetmez; script'in başarısızlığı doğru sinyalle
bildirmesi gerekir.

## Görevler

1. **`/usr/local/bin/logsum` script'ini onar.**
   Kendisine verilen log dosyasını okuyup, her önem seviyesinden kaç satır
   olduğunu standart çıktıya basar. Log satırları `|` karakteriyle ayrılmış
   alanlardan oluşur ve seviye ikinci alandadır. Her seviye için tek bir
   satır basılır, biçim: `SEVIYE:sayı` (örn. `ERROR:12`). Sıralama önemsiz.

2. **`logsum`'ın hata davranışını düzelt.**
   - Hiç argüman verilmezse: kullanım mesajı **standart hata akışına** gider
     ve script **2** ile çıkar.
   - Verilen yol yoksa ya da o kullanıcı tarafından okunamıyorsa: hata
     mesajı **standart hata akışına** gider ve script **3** ile çıkar.
   - Başarılı durumda: sayımlar standart çıktıya gider, çıkış kodu **0**.
   Hiçbir hata durumunda standart çıktıya tek karakter bile yazılmaz.

3. **`/usr/local/bin/svccheck` script'ini yaz.**
   Argüman olarak bir veya daha fazla süreç işareti alır. Verilen her işaret
   için, komut satırında o işaret geçen çalışan bir süreç olup olmadığına
   bakar ve her biri için tek satır basar:
   - çalışıyorsa: `[OK] <işaret> <pid>`
   - çalışmıyorsa: `[FAIL] <işaret>`
   Argümanların sırası korunur. Tek bir tane bile `[FAIL]` varsa script
   **1** ile, hepsi `[OK]` ise **0** ile çıkar. Hiç argüman verilmezse
   kullanım mesajı standart hata akışına gider ve script **2** ile çıkar.
   Kendi arama süreci sonuçlara karışmamalı.

4. **`/usr/local/bin/report` script'ini yaz.**
   `/etc/labs/services.list` dosyasını **satır satır** okur; her satır bir
   servis işaretidir. Boş satırlar ve `#` ile başlayan satırlar atlanır.
   Her işaret için `svccheck`'i çalıştırır ve onun çıktı satırını rapora
   ekler; `svccheck`'in çıkış kodunu izler.
   Ardından `/var/log/labapp/app.log` üzerinde `logsum`'ı çalıştırır ve
   çıktısını rapora ekler.
   Raporu `/srv/reports/daily.txt` dosyasına yazar. Dosyanın **ilk satırı**
   durum özetidir: en az bir servis `[FAIL]` ise `DEGRADED`, hepsi ayaktaysa
   `HEALTHY`. Script'in kendi çıkış kodu bu özeti yansıtır: `DEGRADED` ise
   **1**, `HEALTHY` ise **0**.
   Rapor her çalıştırmada sıfırdan üretilir, öncekinin üstüne eklenmez.

5. **Çalıştırılabilirlik ve izinler.**
   Üç script de `student` kullanıcısı tarafından, tam yol yazmadan ve
   `sudo` kullanmadan çalıştırılabilmeli. Hiçbiri sahibi dışındakiler
   tarafından yazılabilir olmamalı.

## Kabul kriterleri

- `logsum /var/log/labapp/app.log` seviye sayımlarını `SEVIYE:sayı`
  biçiminde standart çıktıya basar, sayımlar dosyanın gerçeğiyle uyuşur
  (ikinci alan, `|` ayırıcısı), çıkış kodu 0.
- `logsum` argümansız çağrıldığında: standart çıktı boş, standart hataya
  mesaj yazılmış, çıkış kodu 2.
- `logsum /var/log/labapp/yok.log` çağrıldığında: standart çıktı boş,
  standart hataya mesaj yazılmış, çıkış kodu 3.
- `logsum` `student` tarafından okunamayan bir dosyayla çağrıldığında da
  çıkış kodu 3 verir (yalnız "dosya var mı" bakılmıyor).
- `svccheck` birden çok işaretle çağrıldığında her işaret için sırayla tek
  satır basar; çalışan süreçler için `[OK] <işaret> <pid>` biçimindedir ve
  yazılan PID gerçekten o sürecin PID'sidir.
- `svccheck` yalnız ayakta olan işaretlerle çağrıldığında 0, aralarında
  ayakta olmayan bir işaret varken 1 ile çıkar; argümansız çağrıldığında 2.
- `svccheck`'in kendi arama süreci çıktıda görünmez.
- `report` çalıştırıldığında `/srv/reports/daily.txt` oluşur; ilk satırı
  `/etc/labs/services.list`'teki servislerin gerçek durumuna göre `HEALTHY`
  veya `DEGRADED`'dir.
- `daily.txt` her servis için bir durum satırı ve log seviye sayımlarını
  içerir; yorum satırları ve boş satırlar rapora servis olarak girmemiştir.
- `report` iki kez üst üste çalıştırıldığında `daily.txt` büyümez, içerik
  tekrarlanmaz.
- `report`'un çıkış kodu raporun ilk satırıyla tutarlıdır (`DEGRADED` → 1,
  `HEALTHY` → 0).
- Üç script de `student` tarafından tam yol ve `sudo` olmadan çalıştırılır;
  hiçbiri "other" için yazılabilir değildir.

## Kontrol

Host terminalinden: `labctl check 006`
Takıldın mı? `labctl hint 006 1` (seviye 1–3, her biri daha spesifik).
