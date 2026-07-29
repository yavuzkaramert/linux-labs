# JOURNAL — Oturum Günlüğü

Bu dosya **oturum düzeyinde** kayıt tutar: o gün ne yapıldı, hangi karar
neden verildi, ne açık kaldı.

Ayrımı karıştırma:
- `CONTEXT.md` → kurallar (nasıl çalışıyoruz)
- `PROGRESS.md` → lab kaydı (hangi lab, hangi hata, hangi konu zayıf)
- `JOURNAL.md` → oturum kaydı (hangi karar, neden, sonraki adım)

**Yazma zamanı:** her sohbetin sonunda veya gün sonunda.
**Okuma zamanı:** yeni sohbete başlarken — CONTEXT.md + PROGRESS.md +
JOURNAL.md'nin son girdisi.

Format: en yeni girdi en üstte.

---

## 2026-07-27 — Müfredat sıfırlandı, Rocky'ye geçildi

### Yapılanlar

**Lab 005 (processes) çözüldü ve debrief edildi.** İlk hint'siz lab.
Detaylı hata analizi PROGRESS.md'de. Öne çıkan: `ps -eo` ↔ `-oe`
transpozisyonu 4 kez, "seçmediğin sütunu grepleyemezsin" dersi (4 tur),
`awk $11` komut satırını kırpma hatası — bu sonuncusu 004'ten sarkan
alan modeli zayıflığının tekrarı.

**Müfredatın referans kaynağı sorgulandı.** Ortaya çıkan gerçek: 001–005
arası sıralama dışarıdan tanımlı bir müfredata dayanmıyordu, konu seçimi
serbestti. Lab içeriklerinin doğruluğu man sayfalarına dayanıyordu ama
kapsamın karşılaştırılabileceği bir kontrol listesi yoktu — "yüzde kaçını
bitirdik" sorusunun paydası yoktu.

**Rocky Linux 10 geçişi + oturum kaydı altyapısı** Claude Code'a brief ile
yaptırıldı, tek oturumda bitti.

### Kararlar

**1. Müfredat RHCSA'ya bağlandı.**
- Birincil: RHCSA (EX200, RHEL 10). Seçim gerekçesi biçim uyumu —
  performans-tabanlı, canlı sistemde uygulamalı, man erişimi var, dış
  kaynak yok. Bizim lab formatımızın birebir aynı mantığı.
- Tamamlayıcı: LPIC-1. RHCSA'da olmayan ama alınmaya değer konular:
  metin filtreleri + regex derinliği, vi, link/inode, FHS, dpkg/apt,
  paylaşılan kütüphaneler, GPG, boot sekansı.
- Alınmayacak: LPIC Topic 106 (X11/masaüstü), Topic 108'in yazıcı/MTA
  kısmı. Sunucu işinde karşılığı yok.
- Sertifika almak hedef değil; sertifikaların ölçtüğü yetkinlik hedef.

**2. Harita 001–020 olarak çizildi.** Faz A (006–012) container'da,
Faz B (013–020) VM'de. Detay CONTEXT.md'de.

**3. Base image ubuntu:24.04 → rockylinux/rockylinux:10.**
Gerekçe: RHCSA dağıtım-bağımsız değil. dnf/rpm, firewalld, SELinux,
nmcli Ubuntu'da ya yok ya farklı. Ubuntu üzerinde RHCSA çalışılamaz.
Zamanlama 005 sonrası seçildi: 006–007 dağıtım-bağımsız ama 009'da paket
yönetimine gelince zaten mecburi olacaktı; arada apt kas hafızası kurup
sonra dnf'e geçmek boşa efor.

**4. 013'te VM'e geçiş kararı alındı (uygulama o gün).**
Container RHCSA'nın ~%60'ını taşıyor. SELinux, gerçek blok cihaz üstünde
partition/LVM, boot/GRUB kurtarma, reboot kalıcılığı container'da
yapılamaz. Araç: Lima birincil, UTM yedek.
Taşınacak olan yalnız taşıma katmanı (`docker exec` → `ssh`); lab
dosyaları saf bash+markdown, ortamdan habersiz. Repo host'ta kalır,
git akışı değişmez.
Depolama labları için gerçek disk gerekmiyor: `losetup` ile dosyadan
blok cihaz üretilecek — üstündeki partition/LVM/fstab kernel açısından
gerçek. Snapshot yalnız 019 (boot kurtarma) için.
**5 korkuluk CONTEXT.md'ye yazıldı** — bu projenin en büyük
over-engineering tuzağı burası.

**5. Faz C ufka not düşüldü, planı 015'te yapılacak.**
006–020 zemindir, iş ilanlarının istediği katman değildir. Eksik kalan:
container (podman/docker), Ansible, cloud temeli, nginx+TLS, yedekleme
disiplini, ağ derinliği. Ayrıca 012 civarında ucuz bir VPS alınıp gerçek
bir şey işletilmesi önerildi — lab "verilen problemi çöz"dür, gerçek
sistem "problemi sen fark et"tir.

**6. History kaybı çözüldü.** Sorun: `history` builtin sadece o shell'in
belleğini okur; container silinince `~/.bash_history` hiç yazılmadan
kaybolurdu. Debrief verisi her lab sonrası riskteydi.
Çözüm: `.bashrc`'de `PROMPT_COMMAND='history -a'` + `HISTFILE=/session/...`,
`/session` host'a mount. Ek olarak `exitlog` — her komutun çıkış kodu
kaydediliyor, böylece debrief'te "hangi komut hata verdi" tahmin değil
kayıt. `.sessions/` gitignore'da.

**7. Ev dizini izni 0700 (RHEL native).** Ubuntu 0755 kullanıyordu.
Gerekçe: müfredat RHCSA'ya bağlı, RHEL'in gerçeğini öğretmek gerek.
`HOME_MODE` `/etc/login.defs`'e açıkça yazıldı, varsayılana bırakılmadı.

**8. Reddedilenler.** `.bashrc`'ye prompt/renk (öğrenme değeri yok),
`asciinema`/`script` oturum kaydı (devasa çıktı, history'nin ötesine
faydası yok), otomatik push (debrief→push sırasını bozar), genel ortam
eklenti sistemi, dashboard/istatistik.

**9. `--cap-add SYS_NICE` eklendi.** Bug olarak sınıflandırıldı, özellik
değil: bayrak olmadan 005'in `nice -n -15` kurulumu sessizce başarısız
oluyordu, `LABPROC-batch` nice 0 ile başlıyordu. Sonuç: `nice >= 10`
kriteri bedava sağlanıyordu (CONTEXT.md'nin "sıfır bedava OK" kuralı
ihlali) ve TASK.md'nin iddiası gerçeği yansıtmıyordu. Ubuntu'da da vardı,
migration regresyonu değil — önceden var olan kusur, migration sırasında
ortaya çıktı.

**10. Container TZ Europe/Istanbul.** Kozmetik değil: exitlog/history
damgaları debrief'te kullanılıyor, UTC ile 3 saatlik kayma o veriyi
okunmaz yapıyordu.

### Migration sonuçları

- Image: `rockylinux/rockylinux:10`, arm64 manifest var, fallback'e
  düşülmedi. **Not:** Docker Hub'ın resmi library reposunda `rockylinux:10`
  YOK (9.3'te donmuş); image RESF'in kendi reposundan alınıyor.
- İki sürpriz: `coreutils-single` çakışması (`--allowerasing` ile çözüldü);
  hedefli `dnf reinstall` yetmedi, base image'da hazır gelen paketlerin man
  sayfaları eksik kaldı → `dnf -y reinstall '*'` (39 sn).
- man doğrulaması geçti: `7 signal`, `1 ps`, `1 find`, `5 passwd`,
  `1 renice` + 9 ek sayfa. `whatis` çalışıyor. **Bu kritikti** — man
  çalışmazsa "man'e bakmadan hint istenmez" kuralı işlevsiz kalırdı.
- Oturum kaydı doğrulandı: `labctl reset` ile container silindikten sonra
  host'taki `history` ve `exitlog` durdu, hatalı komut sıfır olmayan kodla
  kayıtlı.
- **Regresyon 001–005: hepsi GEÇTİ.** Kabul kriteri gevşetilmedi.
  Tek düzeltme 002'de: `sudo` grubu → `wheel`, solution.md'deki "on Ubuntu"
  ifadesi RHEL'e çevrildi. 004'te gawk geçişi sorunsuz.

### Açık kalanlar / bilinen kusurlar

- **`/session` sahiplik uyumsuzluğu (kozmetik).** `chown student:student`
  OrbStack bind mount'unda görünmüyor, 755 root kalıyor. Yazma çalışıyor
  (VirtioFS izinleri host kullanıcısına eşliyor). Karar: dokunma; `chown`
  çağrısı başka Docker backend'lerinde gerekecek.
- **Regresyon `check`'i auto_commit tetikliyor.** Toplu doğrulama sırasında
  PROGRESS.md'ye yanlış tarihli "solved" satırı düşüyor. Bu oturumda oldu,
  `git reset --soft` ile temizlendi. `--no-commit` bayrağı bilinçli olarak
  EKLENMEDİ — bir sonraki toplu regresyon 013'teki VM geçişinde; ikinci kez
  ısırırsa eklenecek. Prosedür CONTEXT.md'ye yazıldı.
- **Apple Silicon / aarch64.** VM'ler arm64 olacak. 019'daki GRUB/UEFI
  detayları x86'dan biraz farklı; sınav x86. O gün not düşülecek.

### Sonraki adım

**Lab 006 — shell scripting temeli.** Konu + kapsam önerisi sunulacak,
onay beklenecek, sonra yazılacak. Kapsam adayı: değişken, `$?` exit code,
`if`/`test`, `for`/`while`, argüman işleme (`$1`, `$@`), `read`, basit
fonksiyon. Zayıf konu serpiştirmesi: awk alan modeli (2 kez zayıf çıktı),
`ps -o` sütun seçimi, `pgrep`/`pkill` (005'te hiç kullanılmadı).

Ayrıca "lab öncesi brifing" adımı konuşuldu; Yavuz kendi halledeceğini
söyledi, kural olarak CONTEXT.md'ye yazılmadı.

## 2026-07-28 — Lab 006 kapandı, 007 A/B olarak ikiye ayrıldı

### Yapılanlar

- **Lab 006 (shell scripting) yazıldı, doğrulandı, çözüldü.** Üç script
  zinciri: `logsum` (bozuk hâlde kurulur, onarılır), `svccheck` ve `report`
  sıfırdan yazılır. 12 kriter. Debrief notu PROGRESS.md'ye işlendi.
- **Ghost PID bulgusu ve setup yeniden tasarımı.** İlk tasarımda servis
  süreçleri `#!/bin/bash` sarmalayıcı script'ti; `comm` değeri `bash` olduğu
  için marker yalnız cmdline'da kalıyordu. Sonuç: sade `pgrep` hiç çalışmıyor,
  tek yol `pgrep -f`, o da `svccheck`'in kendi komut satırını, komut
  ikamesinin alt kabuğunu ve `check.sh`'ın `su -c '...'` satırını
  eşleştiriyordu. Yani basit doğru cevap yoktu; çözüm `/proc/PID/cmdline`
  süzmeyi gerektiriyordu ki bu 006'nın kapsamı değil.
  **Karar:** düzeltme hint'e değil ortama ait. Gerçek `sleep` binary'si servis
  adıyla kopyalanıp çalıştırılıyor, `comm` marker'ı taşıyor, sade `pgrep`
  çalışıyor. `-f` yolu tuzak olarak duruyor ama artık hint'lenebilir.
- **`labctl check --no-commit` eklendi.** CONTEXT'teki "ikinci kez ısırırsa
  eklenecek" şartı doldu: doğrulama koşuları her yeni labda PROGRESS.md'ye
  yanlış tarihli "solved" satırı düşürüyordu. Yapısal, tekrarlayan sorun.
- **`labctl debrief_history` eklendi.** GEÇTİ'de container'ın
  `/session/history` dosyası zaman damgalı olarak basılıyor. Pencere
  `DEBRIEF_HOURS` (varsayılan 24). Debrief girdisi elle `cat` çekmekten
  otomatiğe geçti.

### Kararlar

- **TASK.md yazım kuralı değişti.** Dosya terminalde `cat` ile okunuyor;
  `**kalın**`, backtick ve `#` orada ham işaret olarak görünüp okumayı
  zorlaştırıyordu. Yeni kural: setext başlık (altına `---` çizgisi), 72
  sütun sabit sarma, backtick ve kalın yok, yollar çıplak metin, kriterler
  tek satır `[ ]` ile. Setext seçilmesinin sebebi GitHub'da da h2 olarak
  render edilmesi — iki ortam da kazanıyor. 001-006 geriye dönük
  düzeltilmedi: kozmetik churn, öğrenme değeri yok.
- **A/B lab konvansiyonu.** Konu ağırlaştıkça lab ikiye bölünebilir:
  `NNNa` hafif ve tek araçlı (kavram yerleştirme), `NNNb` tam senaryo.
  İkisi de ayrı klasör, 5 dosya kuralı değişmiyor, `labctl`'e dokunulmadı.
  `labctl start 007` "ambiguous" diyor — istenen davranış, tam id yazdırıyor.
- **İş bölümü değişti.** PROGRESS.md ve JOURNAL.md artık Claude Code
  tarafından yazılıyor. Sınır korundu: debrief analizi sohbette yapılıyor,
  Claude Code verilen metni yazıyor, bulgu üretmiyor.
- **007 kapsamı A/B'ye bölündü.** 007a: grep/cut/sort/uniq, grep çıkış kodu,
  vi giriş. 007b: ERE derinleşme, sed yakalama grupları, awk ilişkisel
  dizileri, vi toplu düzenleme, ve 006'nın script + exit code sözleşmesinin
  tekrarı. 007a'nın `echo $?` kriteri doğrudan 006 debrief'inden geldi.

### Açık kalanlar / bilinen kusurlar

- **`nano` kurulu değil.** 006 oturumunda sürtünme yarattı (`dnf install`
  denendi, vim'e geçildi). Dockerfile'a tek kelime ama image rebuild +
  001-006 regresyonu demek. **Karar: şimdi değil**, 013'teki VM geçişinde
  ortam zaten yeniden kurulacak, oraya ertelendi.
- **`/session` sahiplik uyumsuzluğu (kozmetik).** Önceki girdiden devam,
  değişiklik yok.
- **Apple Silicon / aarch64.** Önceki girdiden devam. 019'daki GRUB/UEFI
  detayları x86'dan farklı olacak.

### Sonraki adım

**007a çözülecek.** Ardından `labctl check` GEÇTİ'de basılan debrief history
çıktısı sohbette analiz edilecek, not PROGRESS.md'ye işlenecek, sonra 007b'ye
geçilecek. 007b, 007a'nın çözülmüş olduğunu varsayıyor.

## 2026-07-29 — 008 kapandı, 009 yazıldı, bekleme listesi kurumsallaştı

### Yapılanlar

- **007a/007b/008 kayıtları PROGRESS.md'ye işlendi.** 007a ve 007b'nin
  oturum verisi elde edilemedi (container kapanmış, debrief yapılmadı);
  sürekliliği bozmamak için tek satırlık işaretle geçildi. 008'in tam
  debrief notu yazıldı. Öne çıkan bulgular: alias'ın `sudo` ile
  taşınmaması, `sudo` secure_path'inin `/usr/local/bin` içermemesi,
  `awk "{print $1}"` içindeki çift tırnağın `$1`'i kabukta genişletmesi.
- **Lab 009 (paket yönetimi) yazıldı ve doğrulandı.** 6 görev, 16 kriter:
  `rpm -qf`/`-ql`, `rpm -V` ile bütünlük, `dnf provides`, `dnf history
  undo`, `.rpm` ve `.deb` dosyalarını KURMADAN inceleme, EPEL + crb.
  Bozuk ortamda 13 FAIL / 3 OK; üç OK'ın hepsi "yan hasar" korkuluğu
  (paketlerin kurulu OLMAMASI, kaynak dosyaların değişmemesi) — 008'deki
  aynı istisna sınıfı. Çözülmüş ortamda 16/16 GEÇTİ.
- **Dockerfile'a iki lab varlığı eklendi.** Ayrıntı aşağıda.

### Kararlar

**1. `.deb` dosyası ayrı bir builder stage'de sıfırdan üretiliyor.**
`FROM debian:stable AS debbuilder` içinde `dpkg-deb --build` ile
`ogrenci-arac_1.0_all.deb` yaratılıp son (Rocky) stage'e `COPY --from` ile
taşınıyor. Gerekçe: gerçek bir Debian paketi indirmek network bağımlılığı
ve sürüm belirsizliği getirirdi; burada paket adı, sürümü ve içeriği
sabit, `check.sh` sürüm sürüklenmesine yakalanmıyor. `Architecture: all`
olduğu için builder stage'in mimarisi (arm64/amd64) sonucu etkilemiyor.

**2. Lab varlıkları `/opt/lab-assets` altında image'da duruyor,
`setup.sh` oradan kopyalıyor.** Böylece `labctl reset` öğrencinin bozduğu
dosyaları gerçekten eski hâline döndürüyor ve setup dosya indirmiyor.
`.rpm` tarafında `ed` seçildi (~80 KB, baseos, image'da kurulu değil);
build sırasında `dnf download` ile indiriliyor, bunun için Dockerfile'a
`dnf-plugins-core` eklendi.

**3. crb deposu ayrı bir kabul kriteri oldu.** Brief'te 15 kriter vardı,
16'ya çıktı. Sebep tahmin değil ölçüm: Rocky 10'da `dnf install dpkg`
EPEL açıkken bile `nothing provides libz-ng.so.2` ile düşüyor; `zlib-ng`
crb (CodeReady Builder) deposunda ve crb varsayılan olarak KAPALI.
"EPEL etkin" ile "crb etkin" farklı kavramlar, ayrı ölçülüyor. TASK.md
öğrenciye deponun adını vermiyor, "bağımlılık hatası alırsan eksik olan
depodur, paket değil" diyor.

**4. `/etc/vimrc` `vim-enhanced`'a değil `vim-common`'a ait.** Brief
vim-enhanced diyordu, `rpm -qf /etc/vimrc` aksini söyledi. `rpm -V
vim-enhanced` bu dosya için hiçbir şey basmıyor ve rc 0 dönüyor — yani
yanlış pakete sorulduğunda "her şey yolunda" görünüyor. Bu tuzak
solution.md'ye açıkça yazıldı.

**5. Bekleme listesi JOURNAL.md'ye taşındı.** Şimdiye kadar zayıf konular
PROGRESS.md debrief notlarına ve JOURNAL "Sonraki adım"a dağılmıştı;
"hangi konu hangi laba serpiştirilecek" sorusunun tek bir adresi yoktu.
Artık aşağıdaki bölümde tutuluyor, her lab yazımında oradan seçiliyor.

### Doğrulama sırasında çıkan iki kusur (ikisi de düzeltildi)

- **`set -o pipefail` + `rpm -V` tuzağı.** setup.sh'ın kendi kendini
  doğrulama bloğunda `rpm -V vim-common | grep -q '^..5'` yazılmıştı.
  `rpm -V` fark bulunca 1 döner; pipefail altında grep eşleşse bile
  pipeline 1 verir, yani kontrol HER ZAMAN ters sonuç üretiyordu. Çıktı
  önce değişkene alınıp `case` ile sınanıyor.
- **`dnf reinstall` config dosyasını geri getirmiyor.** setup.sh ikinci
  kez koşturulduğunda bozma satırı `/etc/vimrc`'ye iki kez ekleniyordu:
  dosya pakette config (`c`) işaretli, rpm değiştirilmiş bir config
  dosyasının üzerine yazmıyor, yenisini `.rpmnew` olarak bırakıyor.
  Çözüm: kurulum anındaki kopya build sırasında `/opt/lab-assets/
  vimrc.pristine` olarak saklanıyor, setup her koşuda `cp -p` ile geri
  yüklüyor (`-p` mtime'ı da koruyor, geri yükleme sonrası `rpm -V`
  tertemiz dönüyor).

### Bekleme listesi — sonraki lablara serpiştirilecek

009'a GÖMÜLMEDİ; ilgili konu geldiğinde doğal olarak yerleştirilecek.

- **pgrep / pkill** — 005'te hiç kullanılmadı, 006'da da kullanılmadı
  (svccheck doğrudan vim'de yazıldı). Aday: 011 (journalctl/logging).
- **sudo refleksi** — 001, 006 ve 008'de tekrarladı: izin sorununu
  düzeltmek yerine root'a kaçma, kendi home dizininde `sudo vim`.
- **Birim test disiplini** — 006: scriptler tek başına çalıştırılmadan
  bileşik akışta denendi, hata bileşikte arandı, döngü uzadı.
- **sudo secure_path / PATH ilişkisi** — 008: `/usr/local/bin`
  secure_path'te yok, script sudo altında bulunamadı. Kök sebep
  deneme-yanılmayla aşıldı, `sudo -l` ile doğrulanmadı.
- **awk'ta tırnak koruması** — 008: `awk "{print $1}"` içindeki `$1`
  kabukta genişledi. 004/005/006'daki `-F` alan modeli sorunundan FARKLI
  bir yüz; alan modeli değil tırnak seçimi problemi.

### Açık kalanlar / bilinen kusurlar

- **`labs/008-links-fhs-archiving/` git'te izlenmiyor, Dockerfile
  değişiklikleri commit'lenmedi.** `labctl auto_commit` yalnız
  PROGRESS.md'yi stage ettiği için `lab 008 solved` commit'i lab
  dosyalarını kapsamadı. 009 dosyaları da aynı durumda. Bilinçli
  bırakıldı: debrief sonrası Yavuz commit'leyip push edecek.
- **009 network gerektiriyor.** `setup.sh` bc'yi gerçekten kurup
  gerçekten kaldırıyor (iki gerçek history işlemi); öğrenci de lsof,
  epel-release ve dpkg'yi depodan kuruyor. Container ağsız çalıştırılırsa
  lab kurulamaz. Bu bilinçli: sahte bir history kaydı `dnf history undo`
  ile geri alınamaz.
- **`/session` sahiplik uyumsuzluğu (kozmetik).** Önceki girdiden devam.
- **Apple Silicon / aarch64.** Önceki girdiden devam.

### Sonraki adım

**009 çözülecek.** Ardından debrief → PROGRESS.md → 010 (systemd,
privileged image geçişi burada).
