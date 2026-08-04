Lab 900-vardiya-01b — Vardiya: Öğleden Sonra ve Nöbet Devri
===========================================================

Hikâye
------

Sabahı atlattın. Öğle arası bitti, sıra günün ikinci yarısında.
Destek ekibinin dökümü masanda; günü de sunucunun kendi erişimini
sertleştirerek, gece vardiyasına güvenli bir devir bırakarak
kapatacaksın.

Bu lab 01a'nın devamı gibi anlatılır ama KENDİ container'ında
sıfırdan kurulur. 01a'yı çözmüş olman gerekmez.

Yeni konu yok — yedi ticket, yedi kaynak lab. Süreyi kendin tut,
JOURNAL.md'ye elle yaz.

Ortam
-----

| Konu | Değer |
|---|---|
| PID 1 | systemd (`container-systemd`) |
| Ağ | Ticket 10 için gerekli (gerçek `dnf` işlemleri) |
| Cevap dizini | `/home/student/cevaplar/` (T7, T9, T10 paylaşır) |
| Toplam kriter | 104 |

Ticket haritası
---------------

| # | Konu | Kaynak lab | Kriter |
|---|---|---|---|
| 7  | Destek bileti dökümü | 007a | 13 |
| 8  | Karışık log + otomatik rapor | 007b | 19 |
| 9  | Dosya yerleşimi, bağlantılar, arşiv | 008 | 11 |
| 10 | Paket durumu | 009 | 16 |
| 11 | Dört systemd işi | 010 | 11 |
| 12 | Log, cron ve saat | 011 | 19 |
| 13 | Nöbet devri: SSH + GPG | 012 | 15 |

---

Ticket 7 — Destek bileti dökümü
-------------------------------
**Kaynak: lab 007a · 13 kriter**

**Veri**

    /srv/proje/destek/biletler.csv    ; ayraçlı, başlık satırı var
    /srv/proje/destek/erisim.log
    /srv/proje/destek/notlar.txt

**Çıktılar** — hepsi `/home/student/cevaplar/` altında.
Beş dosya ZATEN VAR ama önceki nöbetten kalma ve hepsi yanlış.

| Dosya | İçerik |
|---|---|
| `01-adet.txt` | Veri satırı sayısı (başlık hariç). Tek satır, yalnız sayı. |
| `02-acik.txt` | Durumu `open` olan biletlerin tam satırları, sıra korunur. |
| `03-oncelik.txt` | Her öncelik için "sayı öncelik". Sıra önemsiz. |
| `04-kod.txt` | `erisim.log`'da `DENIED` aramasının ÇIKIŞ KODU. |
| `05-kod.txt` | Hiç geçmeyen bir kelime için aynı aramanın çıkış kodu. |

**Ayrıca**

* `notlar.txt` yerinde düzenlenecek: `TODO` ile BAŞLAYAN satırlar
  silinecek, `sunucu1` → `web01`. Kalan içerik ve sıra aynı kalacak.
* `biletler.csv` ve `erisim.log` dosyalarına DOKUNMA.

**Dikkat** — Bazı KAPALI biletlerin konu alanında da "open"
geçiyor. `04`/`05` için ekrana hiçbir şey basılmayacak, yalnız
çıkış kodu yazılacak.

---

Ticket 8 — Karışık log'u temizle ve otomatik rapor kur
------------------------------------------------------
**Kaynak: lab 007b · 19 kriter**

**Veri**

    /srv/proje/gunlukler/merged.log   salt okunur kaynak
    /srv/proje/work/                  çalışma dizini
    /etc/proje/report.conf            düzenlenecek yapılandırma

**Yapılacaklar**

1. **Normalize et** → `work/normal.log`
   `GG/AA/YYYY` tarihleri `YYYY-AA-GG`'ye çevir, ayırıcı
   çevresindeki boşlukları sil. Satır sayısı ve sırası aynı kalacak.

2. **İkiye ayır** → `work/valid.log` + `work/invalid.log`
   Geçerli satır: baştan sona TAM OLARAK dört alan
   (`tarih|seviye|ip|mesaj`), seviye INFO/WARN/ERROR, ip dört
   sayıdan oluşuyor. İki dosyanın toplamı `normal.log`'a eşit.

3. **Özet çıkar** → `work/ozet.txt`
   Her seviye için: `seviye toplam_satir tekil_ip_sayisi`.

4. **Yapılandırmayı düzelt** → `/etc/proje/report.conf`
   `#` ile BAŞLAYAN satırlar silinecek, `/opt/eski` → `/srv/work`,
   `retention` = 30. Diğer satırlar ve sıra aynı kalacak.

5. **Script yaz** → `/usr/local/bin/mkreport`
   1-2-3 adımlarını sırayla çalıştırır, sonucu
   `/srv/reports/text-report.txt`'e yazar.

   | Kural | Değer |
   |---|---|
   | İlk satır | `DIRTY` (invalid.log doluysa) / `CLEAN` |
   | Çıkış kodu | ilk satırı yansıtır (DIRTY→1, CLEAN→0) |
   | Tekrar koşu | rapor sıfırdan üretilir, büyümez |
   | Yetki | `student` sudo'suz çalıştırabilir |

**Dikkat** — Bazı GEÇERLİ satırların mesajında da seviye adı ve IP
geçiyor. IP yalnız 3. alandan sayılır. `merged.log` değişmeyecek.

---

Ticket 9 — Aceleyle atılmış dosyalar ve arşivleme
-------------------------------------------------
**Kaynak: lab 008 · 11 kriter**

**1. FHS yerleşimi** — üçünü de TAŞI (kopyalama değil):

| Dosya | Yeni yeri |
|---|---|
| `~/uygulama.log` | `/var/log/myapp/` |
| `~/myapp.conf` | `/etc/myapp/` |
| `~/backup-helper` | `/usr/local/bin/` (çalıştırılabilir olacak) |

İlk iki hedef dizin henüz yok.

**2. Bağlantı kimliği** — `/srv/backup-kaynagi/` içinde
`kaynak1-yedek.txt` ve `kaynak2-kopya.txt` var. Biri gerçek
bağlantı, biri bağımsız kopya. İçerikleri aynı.

→ `cevaplar/baglanti-raporu.txt`, iki satır, Türkçe karakter yok:

    kaynak1-yedek.txt hardlink
    kaynak2-kopya.txt bagimsiz

**3. Bağlantı kur** — `kaynak3.txt` için:

    /home/student/kaynak3-hardlink.txt   aynı inode
    /home/student/kaynak3-symlink.txt    sembolik bağlantı

**4. Disk kullanımı** — `/srv/backup-kaynagi/`'nin diskte GERÇEKTEN
kapladığı yer → `cevaplar/disk-kullanimi.txt`, tek satır, yalnız
sayı (KB), birim harfi yok.

**5. Arşivle** — `/srv/data` → `/srv/backup/data-yedek.tar.gz`.
`gecici/` arşive GİRMEYECEK ama diskten de SİLİNMEYECEK.

**6. Doğrula** — arşivi AÇMADAN →
`cevaplar/arsiv-dogrulama.txt`, iki satır:

    kalici/onemli.txt var
    gecici/silinecek.txt yok

---

Ticket 10 — Paket durumu
------------------------
**Kaynak: lab 009 · 16 kriter · ağ gerekli**

Çıktılar `/home/student/cevaplar/` altında.

**1. Paket sorgusu** → `paket-sorgu.txt`
`tree` komutunun geldiği paketi bul, o paketin kurduğu TÜM
dosyaları listele. İlk satır paket adı, sonrası dosya listesi.

**2. Bütünlük** → `butunluk-raporu.txt`, tam üç satır:

    paket <ad>
    dosya /etc/vimrc
    degisen icerik,izin

`/etc/vimrc` paket kurulumundaki hâlinden farklı. Ait olduğu
paketi bul ve paket yöneticisine doğrulattır.

**3. Eksik komut** → `eksik-komut.txt`
`lsof` sistemde yok. Sağlayan paketi bul, KUR, adını tek satır yaz.

**4. Geçmişi geri al**
`/usr/local/bin/hesapla` çalışmıyor; dayandığı paket bir `dnf`
işlemiyle kaldırılmış. O işlemi geçmişten bul ve GERİ AL.
Paketi elle yeniden kurmak çözüm değil — ve aradığın işlem
listenin en üstündeki DEĞİL.

**5. RPM incele** → `rpm-inceleme.txt`
`/srv/paketler/` altındaki `.rpm`'i **KURMADAN** incele:

    paket-adi: <ad>
    surum: <sürüm>
    dosyalar:
    <dosya listesi>

**6. DEB incele** → `deb-inceleme.txt`
EPEL ve CRB depolarını etkinleştir, `dpkg`'yi kur, `.deb`'i
**KURMADAN** incele. Biçim 5. maddeyle aynı.

**Dikkat** — İncelenen iki paket de sisteme KURULMAYACAK.
`/srv/paketler` altındaki dosyalar değişmeyecek.

---

Ticket 11 — Dört systemd işi
----------------------------
**Kaynak: lab 010 · 11 kriter**

**1. Servis yaz** — `/opt/app/gorevci` için
`/etc/systemd/system/gorevci.service`. Script ön planda kalıyor,
`Type`'ı ona göre seç. `daemon-reload` → başlat → `enable`.

**2. İki hatayı çöz** — `raporcu.service` kurulu ama çöküyor.
İKİ BAĞIMSIZ hata var ve biri diğerini gizliyor. `systemctl
status` çıktısındaki çıkış koduna güven, tahmin etme. Her
düzeltmeden sonra `daemon-reload`. Servis ayakta kalacak.

**3. Bağımlılık kur** — `api.service`, `veritabani.service`'e:

    After=      → sıralama
    Requires=   → gereklilik

İkisi de gerekiyor. Sonra `veritabani.service`'i çalıştır;
`api.service` başarıyla başlayıp ayakta kalmalı.

**4. Varsayılan target** — `multi-user.target` yap.

**Dikkat** — Dört servis dosyası da `/etc/systemd/system/`
altında KALICI olacak. `/run` altındaki geçici birimler kabul
edilmez.

---

Ticket 12 — Log, cron ve saat
-----------------------------
**Kaynak: lab 011 · 19 kriter**

**1. Günlük + bekci.service**

* Sistemin günlüğü şu an yalnız bellekte. KALICI hâle getir.
* `bekci.service` sürekli çöküyor. Günlüğünden sebebi bul (birim
  adına göre süz, hata seviyesi, PID).
* Bulduğunu `/home/student/cevap-bekci.txt` dosyasına yaz:
  eksik dosyanın TAM YOLU ve servisin ÇIKIŞ KODU.
* Sorunu gider. Servis yine çökebilir — **iki kademeli hata var**,
  ikincisini de günlükten oku ve çöz.
* Servis gövdesine (`/opt/bekci/bekci`) DOKUNMA.
* Sonunda servis hatasız çalışacak ve `enabled` olacak.

**2. Cron işi** — `/etc/cron.d/yedek` üç ayrı sebepten çalışmıyor:

    (a) zamanlayıcı servisi kapalı ve açılışta başlamıyor
    (b) saat gece 3'e kurulu
    (c) komut zamanlayıcının ortamında bulunamıyor

Üçünü de çöz, iş her dakika çalışsın.
`/var/log/yedek/yedek.log` içinde GERÇEK bir çalışma satırı
görene kadar bitmiş sayma.

**3. Timer** — `/usr/local/bin/temizlik` hazır ama hiç
zamanlanmamış. İkisini de `/etc/systemd/system/` altında yaz:

| Birim | Özellik |
|---|---|
| `temizlik.service` | bir kez çalışıp biten tip, doğru ExecStart |
| `temizlik.timer` | en geç dakikada bir, açılışta aktif, enabled |

`/var/log/temizlik.log` içinde gerçek satır oluşana kadar bekle.

**4. Saat**

* Saat dilimi `Europe/Istanbul` (KALICI olarak).
* `/etc/chrony.conf`'a geçerli bir zaman sunucusu satırı ekle.
* Senkron servisini aktif + enabled yap.
* Sistem, saat senkronunu AÇIK olarak raporlamalı.

**Not** — Zamanlanmış işler dakikada bir tetiklenir; `labctl check`
gerekirse en fazla 90 saniye bekler.

---

Ticket 13 — Nöbet devri: SSH sertleştirme ve GPG
------------------------------------------------
**Kaynak: lab 012 · 15 kriter**

**1. Anahtarla giriş** — `student`'ın anahtar çifti hazır ama
sunucu tanımıyor. Açık anahtarı `authorized_keys`'e yerleştir ve
izin zincirini kur:

    ev dizini  →  .ssh  →  authorized_keys

Zincirin her halkası yalnız sahibi tarafından yazılabilir olacak.
Sonunda `student` parola kullanmadan, yalnız anahtarla girebilmeli.

**2. sshd sertleştirme** — root girişini ve parola girişini kapat.
Dosyada ayrıca bir **SÖZDİZİMİ HATASI** var. Sırayı bozma:

    önce sözdizimini sına  →  sonra düzelt  →  sonra servisi yeniden başlat

Düzeltmeyi yazmak yetmez; servis eski ayarları belleğinde tutar.

**3. GPG anahtarı ve şifreleme**

* `student@lab.local` için parolasız bir anahtar çifti üret.
* `gizli.txt`'i kendi anahtarına şifrele → `gizli.txt.gpg`
* Çöz ve içeriğin orijinaliyle aynı olduğunu doğrula.

**4. İmza doğrulama**

* `/opt/paket/yayinci-acik.asc`'ı anahtarlığına aktar.
* `surum-a.tar.gz` ve `surum-b.tar.gz` imzalarını doğrula.
* Yolda değiştirileni `/home/student/cevap-paket.txt` dosyasına
  yaz — tek cevap, diğerinin adı geçmeyecek.
* `duyuru.txt` için ayrık bir imza üret (`duyuru.txt.sig`).

---

Kontrol
-------

    ./labctl check 900-vardiya-01b

104 kriter var; çıktı GRUPLU basılır. Her ticket için bir başlık,
altında yalnız DÜŞEN kriterler, sonda özet tablosu:

    === Ticket 7  — Destek bileti dökümü (lab 007a) ====
           hepsi geçti (13/13)

    === Ticket 8  — Log temizleme + rapor (lab 007b) ===
    [FAIL] Ticket 8.3 — normal.log ... (kaynak: lab 007b)
    [FAIL] Ticket 8.9 — ozet.txt yok (kaynak: lab 007b)

    === ÖZET ===========================================
      13/13   Ticket 7  — Destek bileti dökümü (lab 007a)
      17/19   Ticket 8  — Log temizleme + rapor (lab 007b)
      ...
      ----------------------------------------------
      98/104  TOPLAM

Not: taze ortamda 6 kriter baştan `[OK]` görünür. Bunlar kaynak
lab'lardan gelen **korkuluk** kriterleri (7.13, 8.19, 9.11, 10.16)
ve **negatif** testler (10.10, 10.15): "kaynak dosyaya dokunma",
"incelenen paketi kurma". Ödül değil, yan hasar yakalamak için
varlar — bozarsan düşerler.

Geçen kriterlerin tek tek dökümünü de istersen:

    docker exec -e CHECK_VERBOSE=1 -u root \
        lab-900-vardiya-01b bash /lab/check.sh

Takıldığında:

    ./labctl hint 900-vardiya-01b

Bu labda yalnız **seviye 1** ipucu var (kavramsal). Daha fazlası
için satırda yazan kaynak lab'ın kendi `solution.md`'sine bak:

    ./labctl solution 007b-regex-report

Ticket → kriter eşlemesinin tam tablosu `solution.md` dosyasında.
