# Lab 005 — Süreç Yönetimi

## Hikâye

Uygulama sunucusu tuhaf davranıyor. Yük normalin çok üstünde ama trafik
artmamış; birileri sunucuda bir şeyler çalıştırmış ve arkasında başıboş
süreçler bırakmış. İzleme ekibi üç ayrı sorun bildirdi: CPU'yu boşuna yiyen
takılmış bir süreç var, yanlış isimle gizlenmiş şüpheli bir süreç arka planda
dönüyor, ve gece batch işi o kadar yüksek öncelikle çalışıyor ki asıl
uygulamayı aç bırakıyor.

Sunucuyu yeniden başlatmak yok — canlıda müdahale edeceksin. Önce neyin
çalıştığını görmen, sonra doğru olana doğru şekilde dokunman gerekiyor.
Yanlış süreci öldürmek ya da yanlış sinyali göndermek işi büyütür.

## Görevler

1. **Envanteri çıkar.** Şu an çalışan süreçler içinde, komut satırında
   `LABPROC` işareti geçen tüm süreçlerin bir dökümünü `/srv/reports/procs.txt`
   dosyasına yaz. Her satırda o sürecin PID'si ve tam komut satırı olmalı.
   Kendi arama komutun (grep'in kendisi) bu listeye girmemeli.

2. **Takılmış süreci durdur.** İşaretinde `LABPROC-hog` geçen, CPU'yu boşuna
   meşgul eden süreç düzgünce sonlandırılmalı — süreçe önce kendini
   toparlama şansı veren, kibar sonlandırma sinyali gönderilmeli. En sert,
   yakalanamayan sinyal değil.

3. **Kaçak süreci yakala ve öldür.** İşaretinde `LABPROC-rogue` geçen süreç
   yanlış bir isimle çalışıyor ve kibar sinyallere yanıt vermiyor (o sinyali
   yok sayıyor). Bu süreç, yok sayılamayan sinyalle kesin olarak
   sonlandırılmalı.

4. **Önceliği düzelt.** İşaretinde `LABPROC-batch` geçen süreç aşırı yüksek
   öncelikle (çok düşük nice değeriyle) çalışıyor. Bu süreç öldürülmeden,
   çalışır durumdayken önceliği düşürülmeli: nice değeri 10 veya daha yüksek
   (yani daha düşük öncelik) olacak şekilde ayarlanmalı.

5. **Kanıtı sabitle.** 4. adımdan sonra `LABPROC-batch` sürecinin güncel nice
   değeri `/srv/reports/batch-nice.txt` dosyasında tek bir sayı olarak
   bulunmalı.

## Kabul kriterleri

- `/srv/reports/procs.txt`, `LABPROC` işaretli çalışan süreçlerin PID + komut
  satırını içeriyor; grep süreci listede yok, öldürülmüş süreçler doğal
  olarak listede yok.
- `LABPROC-hog` süreci artık çalışmıyor ve kibar sonlandırma sinyaliyle
  gitmiş (süreç tablosunda yok).
- `LABPROC-rogue` süreci artık çalışmıyor; kibar sinyali yok saydığı için
  sert sinyal gerekmiş ve verilmiş.
- `LABPROC-batch` süreci hâlâ çalışıyor ve nice değeri ≥ 10.
- `/srv/reports/batch-nice.txt` tek bir sayı içeriyor ve o sayı sürecin
  gerçek güncel nice değeriyle aynı, ≥ 10.

## Kontrol

Host terminalinden: `labctl check 005`
Takıldın mı? `labctl hint 005 1` (seviye 1–3, her biri daha spesifik).
