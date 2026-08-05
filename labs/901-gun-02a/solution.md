# Kaynak Haritası — Lab 901-gun-02a

Bu bir **tekrar labı**. Burada tam komut çözümü YOK ve bilerek yok:
her ticket daha önce çözdüğün bir lab'ın aynı beceriyi sınayan yeni
bir senaryosudur. Takıldığın yerde ilgili lab'ın kendi `solution.md`
dosyasını aç.

    ./labctl solution 001-permissions
    ./labctl solution 002-users-groups
    ./labctl solution 003-finding-files
    ./labctl solution 004-text-processing
    ./labctl solution 005-processes
    ./labctl solution 006-shell-scripting

Gün 1'den (900-vardiya-01a) farkı: senaryo, veri, dosya adları ve
kullanıcılar tamamen yenidir. Komut yüzeyi aynı, metin değil.

## Ticket → kaynak lab tablosu

| Ticket | Kaynak lab | Orijinal karşılığı | Bu labda ne değişti |
|---|---|---|---|
| 1.1 | `001-permissions` | sahipliğin korunması | yol `/srv/klinik/gizli`, sahiplik `root:root` KALMALI — chown çözüm değil |
| 1.2 | `001-permissions` | dünyaya açık dosyanın kapatılması | 0644 → 0600, hasta sahibi iletişim verisi |
| 1.3 | `001-permissions` | negatif okuma testi | student'ın okuyamadığı ayrı bir kriter olarak sınanır |
| 1.4 | `001-permissions` | sahiplik devri + mod | `haftalik-notlar.txt` student'a geçer |
| 1.5 | `001-permissions` | **yeni** | işlevsel test: student dosyayı gerçekten düzenleyebiliyor mu |
| 1.6 | `001-permissions` | çalıştırma bitinin eklenmesi | `yedek-al.sh` |
| 1.7 | `001-permissions` | dizin geçiş izni | dizin `0750` → student giremiyor; 1.6 tek başına çözülemez |
| 2.1 | `002-users-groups` | kriter 1 (grup + GID) | grup `vetekip`, GID **4600**; grup hiç yok |
| 2.2 | `002-users-groups` | kriter 2 (kullanıcı, home, shell) | `derya` ve `kaan` sıfırdan açılacak |
| 2.3 | `002-users-groups` | kriter 3 (birincil/ikincil grup) | birebir |
| 2.4 | `002-users-groups` | kriter 4 (servis hesabı) | `randevubot`, nologin + vetekip |
| 2.5 | `002-users-groups` | kriter 4'ün ev dizini şartı | ayrı kriter olarak bölündü |
| 2.6 | `002-users-groups` | kriter 5 (dizin sahiplik + 2770) | yol `/srv/klinik` |
| 2.7 | `002-users-groups` | kriter 6 (setgid davranışı) | probe `derya` açar, `kaan` yazar |
| 2.8 | `002-users-groups` | kriter 7 (ayrılan hesap) | `oguz`, 2 ay önce ayrılmış |
| 2.9 | `002-users-groups` | kriter 8 (wheel'de olmama) | `derya` |
| 2.10 | — | **Gün 1'den taşınan ders** | `student`'ın da `vetekip` üyesi olması; 2770 dizin aksi hâlde Ticket 1/3/4'ü kilitler |
| 3.1 | `003-finding-files` | kriter 1 (eski log arşivi) | kök `/srv/klinik`, hedef `arsiv/`, muayene kayıtları |
| 3.2 | `003-finding-files` | kriter 2 (0 byte temizliği) | yeni dosya adları, `bos-klasor/` boş dizin kanıtı |
| 3.3 | `003-finding-files` | kriter 4 (metadata korumalı kopya) | `ayarlar-yedek/` `cp -r` ile alınmış, metadata kayıp |
| 3.4 | `003-finding-files` | kriter 3 (>1MB taşıma) | röntgen görüntüleri; büyük VE küçük hedef ayrı ayrı sınanır |
| 3.5 | `003-finding-files` | kriter 5 (latest symlink) | `ozet.txt` tuzağı: en yeni dosya ≠ en yeni csv |
| 3.6 | `003-finding-files` | kriter 6 (.sh çalıştırma izni) | alt dizinde saklı `bakim/arsivle.sh`, `notlar.txt` yem |
| 4.1 | `004-text-processing` | kriter 1 (log okunabilirliği) | loglar `/srv/klinik/loglar/` altında, 0600 |
| 4.2 | `004-text-processing` | kriter 2 (`errors.log`) | aynı iki tuzak: boyut alanı 500 ve yolda `/500`; ek olarak 503 çeldirici |
| 4.3 | `004-text-processing` | kriter 3 (`top-ips.txt`) | sayımlar bilerek birbirinden farklı — beraberlik yok, sıra kırılgan değil |
| 4.4 | `004-text-processing` | kriter 4 (`unique-users.txt`) | kullanıcı alanında `derya`/`kaan`/`randevubot`/`oguz` |
| 4.5 | `004-text-processing` | kriter 5 (`warnings.tsv`) | mesaj gövdesinde geçen seviye adları tuzağı korundu |
| 4.6 | `004-text-processing` | kriter 6 (`settings.conf`) | yol `/etc/klinik/sistem.conf`; `/srv/klinik/ayarlar` DEĞİL — Ticket 3.3 ile çakışmasın diye ayrıldı |
| 4.7 | `004-text-processing` | kriter 7 (`hosts-clean.txt`) | cihaz envanteri; satır içi yorumlar korunur |
| 5.1 | `005-processes` | kriter 1 (`procs.txt`) | işaret `KLINIKPROC-*`, çıktı `/srv/rapor` |
| 5.2 | `005-processes` | kriter 3 (SIGKILL gerektiren süreç) | `KLINIKPROC-asili`, TERM/INT/HUP trap'li |
| 5.3 | `005-processes` | kriter 2 (SIGTERM) | `KLINIKPROC-sahte`, `exec -a` ile sahte comm |
| 5.4 | `005-processes` | kriter 4 (nice ≥ 10) | `KLINIKPROC-toplu`, root tarafından `nice -n -15` ile başlatılmış |
| 5.5 | `005-processes` | kriter 5 (`batch-nice.txt`) | `toplu-nice.txt`, değer canlı süreçten doğrulanır |
| 6.1 | `006-shell-scripting` | kriter 1 (`logsum` sayımı) | `logozet.sh`, log `/var/log/klinik/gunsonu.log` |
| 6.2 | `006-shell-scripting` | kriter 2 (argümansız → 2) | birebir |
| 6.3 | `006-shell-scripting` | kriter 3 (olmayan dosya → 3) | birebir |
| 6.4 | `006-shell-scripting` | kriter 4 (okunamayan dosya → 3) | `denetim.log`, 0600 — `[ -f ]` ile `[ -r ]` farkı |
| 6.5 | `006-shell-scripting` | kriter 5 (`svccheck` biçimi) | `durumkontrol.sh`, servisler `randevu-*` |
| 6.6 | `006-shell-scripting` | kriter 6 (çıkış kodları 0/1/2) | birebir |
| 6.7 | `006-shell-scripting` | kriter 7 (self-match) | her `[OK]` satırının PID'i `ps -o comm=` ile doğrulanır |
| 6.8 | `006-shell-scripting` | kriter 8 (DEGRADED yolu) | `gunsonu-rapor.sh`, tuzak servis `randevu-kuyruk` |
| 6.9 | `006-shell-scripting` | kriter 9 (rapor içeriği) | yorumlu `#randevu-eski` satırı atlanmalı |
| 6.10 | `006-shell-scripting` | kriter 10 (idempotency) | `cmp -s` ile bayt bayt |
| 6.11 | `006-shell-scripting` | kriter 11 (HEALTHY yolu) | liste geçici olarak daraltılır, sonra geri alınır |
| 6.12 | `006-shell-scripting` | kriter 12 (izinler + PATH) | üç script, other-yazma biti kapalı |

## Ticket sırası ve bağımlılık

Ticketlar hikâye düzeyinde zincirli ama teknik olarak bağımsız
gradelenir: bir ticket düşse bile diğerlerinin `[OK]`/`[FAIL]`'i ayrı
ayrı basılır. Tek gerçek yumuşak bağ Ticket 2.10'dur — `student`
`vetekip` üyesi olmadan `/srv/klinik` 2770 olduğunda Ticket 1, 3 ve 4
ölçülemez hale gelir. check.sh bu durumu ayrı bir `[NOTE]` satırıyla
söyler ki hata Ticket 1'e yazılmasın.

`/srv/klinik` setup sırasında bilerek `0755 root:root` bırakılır: bu
sayede Ticket 1 ilk saniyeden itibaren ölçülebilir, Ticket 2 doğru
çözüldüğünde de ölçülebilir kalır.
