# CONTEXT — Proje Anayasası

Bu dosya, linux-labs projesinin çalışma kurallarını taşır. Yeni bir sohbete
başlarken Claude'a "önce CONTEXT.md ve PROGRESS.md'yi oku" denir; böylece
bağlam hafızadan değil bu dosyadan gelir. README kullanıcıya "nasıl
kullanılır"ı anlatır; bu dosya "hangi kurallarla yürütülür"ü.

## Amaç ve temel prensip

Yavuz IT/Linux becerilerini geliştirmek için bu terminal-tabanlı lab
platformuyla pratik yapıyor. **Platform geliştirmek Linux öğrenmek değildir.**
Tooling'e harcanan süre minimumda tutulur; başarı metriği çözülen lab
sayısıdır. Over-engineering, UI/web katmanı, gereksiz özellik önerilmez.

## Platform

- Docker container (ubuntu:24.04), `student` kullanıcısı, şifresiz sudo.
- `labctl` bash scripti + `labs/` klasörü.
- Mac'te OrbStack/Docker. Repo public: github.com/yavuzkaramert/linux-labs
  (HTTPS + gh credential helper).

## Lab formatı (SABİT — değiştirilmez)

`labs/NNN-konu/` altında 5 dosya:
- `TASK.md` — saf gereksinim: Hikâye + Görevler + Kabul kriterleri.
  İçinde İPUCU YOK. Görevler ve Kabul kriterleri AYRI bölümler olarak durur.
- `setup.sh` — ortamı bozuk kurar; HER kabul kriterini bozar, sıfır bedava OK.
- `check.sh` — kriter başına [OK]/[FAIL], FAIL varsa exit 1, `set -e` YOK
  (accumulator pattern), kullanıcı-perspektifi testleri `su - student -c` ile,
  negatif testler dahil.
- `hints.md` — 3 seviye: `## Seviye 1` (kavramsal, komut adı yok),
  `## Seviye 2` (komut adları, bayrak yok), `## Seviye 3` (bayrak/parametre).
  Tam komut hiçbir seviyede verilmez.
- `solution.md` — komutlar + kısa açıklama.

Lab 001 eski formatta (hints.md yok, TASK.md içinde Hints bölümü var);
bilinçli olarak öyle bırakıldı.

## Tooling donduruldu

labctl'e yeni özellik EKLENMEZ. Ancak lab çözerken gerçek bir ihtiyaç kendini
dayatırsa (örn. systemd günü) konuşulur. Bug düzeltmesi özellik değildir;
serbesttir (örn. auto_commit yalnız PROGRESS.md stage etmeli — geçmişte tüm
ağacı süpürme bug'ı düzeltildi).

## labctl davranışları

- `check` GEÇTİ'de otomatik commit atar (`lab NNN-konu solved`) ve bildirir;
  commit yalnız PROGRESS.md'yi kapsar. KALDI'da git'e dokunmaz.
- Commit geçmişi (git log / GitHub) aynı zamanda ilerleme kaydıdır.
- Kalıcı kayıt yalnız PUSH edilmiş halde görülür. Debrief notu yazıldıktan
  sonra push edilir; sonraki sohbet repodan okur.

## Değişmez kurallar

1. **Onaysız üretim yok.** Yavuz'un açık "onaylıyorum"u olmadan yeni lab
   oluşturulmaz, dosya yazılmaz. Önce konu + kapsam önerilir, onay beklenir.
2. **Her lab bitiminde debrief zorunlu.** Terminal geçmişindeki hatalar tek
   tek analiz edilir: hangi komut, neden yanlış, hata mesajı ne diyordu.
   Hatalar geçiştirilmez, öğrenme malzemesidir. Debrief atlanırsa o labın
   gelişim verisi kalıcı olarak kaybolur (container kapanınca history gider).
3. **Çözüm sorulmadan verilmez.** Tıkanınca sıra: kendi başına dene → `man` →
   `hint 1` → `hint 2` → `hint 3` → `solution.md`. Man'e bakmadan hint istenmez.
   Debrief'te hangi labda hangi hint seviyesine inildiği not edilir (kavramsal
   mı syntax mı takıldığı = zayıf konu tespiti).
4. **systemd konularına** (systemctl/journalctl/servisler) gelince container
   `--privileged` + systemd-enabled image'a geçirilir. O güne kadar konu edilmez.

## Debrief → PROGRESS.md not formatı

Her lab sonrası, çözülen satırın altına girintili notlar eklenir. Örnek:

```
004-text-processing solved (2026-07-26)
  awk alan modeli: -F ayırıcısını kavrayana dek takıldı → çözüldü
  tuzak: awk file | tee file dosyayı sıfırlar → kaynaktan yeniden üret
  zayıf: awk alan modeli, sed adresleme. sağlam: izin, grep süzme
```

Akış: lab çöz → history filtrele → debrief → notu PROGRESS.md'ye ekle →
commit → push → sonraki lab. (Not yazılıp commit'lenmeden sonraki lab
başlatılmaz; yoksa not "solved" commit'ine karışır.)

Terminal geçmişini süzmek için (container kapanmadan önce):
`history | grep -vE '^\s*[0-9]+\s+(cat|ls|cd|clear|pwd|less|head|tail|man)\b'`

## Müfredat haritası (kaba — ilerledikçe oynar)

Sıralama 4 filtreyle: bağımlılık zinciri, günlük iş sıklığı, container'da
test edilebilirlik, debrief'ten gelen zayıf noktalar.

- 001 permissions ✅ (chmod/chown)
- 002 users & groups ✅
- 003 finding-files ✅ (find, cp -a, symlink)
- 004 text-processing ✅ (grep/sed/awk, pipe, yönlendirme)
- 005 processes — ps/pgrep/kill+sinyaller/nice/renice/job control (SIRADAKİ/aktif)
- 006 shell scripting temeli — değişken/koşul/döngü/exit code
- 007 networking basics — ip/ss/curl/dig (container'da yapılabilen kısım)
- 008 paket yönetimi + cron/at
- 009+ systemd (image değişimi burada)

Zayıf konular sonraki lablara doğal serpiştirilir (örn. awk 005'te ps|awk
olarak geri gelir; sed config-düzenleme görevlerinde tekrar eder).

## Güncel durum

En güncel "ne çözüldü / hangi hatalar / hangi konu zayıf" bilgisi için
PROGRESS.md okunur. Bu dosya yalnız kuralları taşır; ilerleme PROGRESS.md'de.
