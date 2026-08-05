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

## 2026-08-05 — Gün 2 (901-gun-02a/02b) yazıldı: PatiVet / Yedek Sunucu Günü

### Yapılanlar

- **Genel Tekrar İzi'nin ikinci turu yazıldı.** `labs/901-gun-02a`
  (ticket 1-6, `container`, 47 kriter) ve `labs/901-gun-02b`
  (ticket 7-13, `container-systemd`, 104 kriter). Toplam 151 kriter,
  001-012'nin tamamını kapsıyor.
- **Senaryo tamamen yeni: PatiVet Klinikleri / Yedek Sunucu Günü.**
  UPS arızası ana sunucuyu götürmüş, yarım yapılandırılmış DR
  makinesi üretime alınıyor. CONTEXT.md'nin "Gün 2'den itibaren
  tamamen yeni iş senaryosu" kuralı uygulandı: Gün 1'in hiçbir adı,
  yolu veya çerçevesi kullanılmadı. Yeni kadro derya/kaan/oguz/
  randevubot, grup `vetekip` (GID 4600), kök `/srv/klinik`.
  DR çerçevesinin faydası: setup'ın her kriteri bozuk kurmasının
  artık diegetik bir gerekçesi var, ticket başına hikâye uydurmaya
  gerek kalmıyor.
- **Her iki lab da container'da 0'dan N'e çözülerek doğrulandı**,
  sonra resetlendi: 02a 0/47 → 47/47 → 0/47, 02b 3/104 → 104/104 →
  3/104. Çözücü scriptler scratchpad'de kaldı, repoya girmedi.

### Kararlar

- **TASK.md yazımında CONTEXT.md kuralına dönüldü.** Gün 1'in
  TASK.md'leri kalın, backtick ve markdown tablo kullanıyordu; bu
  CONTEXT.md'nin açık kuralına aykırıydı. Gün 2 sıkı biçimde yazıldı:
  setext başlık, 72 sütun, düz metin yollar, tablo yok. Gün 1
  dosyaları geriye dönük düzeltilmedi.
- **Ticketlar hikâye düzeyinde zincirli, teknik olarak bağımsız.**
  Sert bağımlılık kurulmadı; takılan öğrenci günün geri kalanından
  yine geri bildirim alabiliyor. Tek yumuşak bağ 02a Ticket 2.10
  (`student` → `vetekip`): o olmadan 2770 dizin Ticket 1/3/4'ü
  ölçülemez yapıyor. check.sh bu durumda ayrı bir `[NOTE]` basıyor
  ki hata Ticket 1'e yazılmasın. `/srv/klinik` setup'ta bilerek
  `0755 root:root` bırakıldı, böylece Ticket 1 ilk saniyeden
  itibaren ölçülebiliyor.
- **Ticket 4'ün ayar dosyaları `/etc/klinik` altına alındı.** Brief
  onları `/srv/klinik/ayarlar` altında istiyordu ama Ticket 3
  "`ayarlar/` ile `ayarlar-yedek/` birebir aynı olmalı" diyor;
  aynı dosyada iki ticket çakışırdı. Ayrıldılar.
- **Yeni asset üretilmedi, Dockerfile değişmedi.** 02b'nin GPG ve
  paket varlıkları image'daki `/opt/lab-assets` altından geliyor,
  setup onları `/opt/paket`'e kopyalıyor.
- **`data/` dizini 5 dosya kuralının bilinçli istisnası.**
  `901-gun-02b/data/epel.repo` kapalı (`enabled=0`) olarak kuruluyor;
  öğrenci onu etkinleştirecek. `labctl` klasörün tamamını kopyaladığı
  için ek dosya sorun çıkarmıyor.

### Yazarken çıkan ve düzeltilen hatalar

- **Bedava geçen kriterler.** İlk koşuda 02a'da 2, 02b'de 6 kriter
  başlangıç durumunda geçiyordu. İkisi gerçek check hatasıydı
  (02a 6.7: script yokken döngü hiç dönmüyor, kriter sessizce
  geçiyordu; 02b 12.16: var olmayan birimde `systemctl show` 0
  döndürüyor, "0 saniye kaldı" sanılıyordu). Kalanlar için setup
  sıkılaştırıldı. Geriye yalnız üç **korkuluk kriteri** kaldı
  (7.13, 9.11, 10.16) — "bu dosyaya dokunma" diyen, tanımı gereği
  bozulamayan kriterler.
- **`gpg --list-secret-keys` boş anahtarlıkta da 0 dönüyor.** Kimlik
  verilmeden yapılan sınama hep "anahtar var" diyordu; hem setup'ın
  kendi doğrulaması hem check 13.10 kimlik verecek şekilde düzeltildi.
- **`sshd` yeniden başlatıldı mı sınaması toleransa takılıyordu.**
  Monotonik saati epoch'a çevirmek yuvarlama getiriyor; config mtime
  ile servis başlangıcı arasındaki 2 saniyelik fark 1 saniyelik
  toleransla yutuluyordu. check artık önce mutlak `ActiveEnterTimestamp`
  okuyor, setup da aradaki boşluğu 4 saniyeye çıkardı.
- **Aynı normalizasyon iki tarafa da uygulanmalı.** 10.14'te beklenen
  ve bulunan `.deb` dosya listeleri farklı sırada süzülüyordu
  (`./` girdisi ancak sondaki eğik çizgi atıldıktan SONRA boşalıyor);
  tek bir yardımcı fonksiyona indirildi.
- **`sort -rn` beraberlikte kırılgan.** 02a Ticket 4.3'ün IP sayımları
  başta beraberlik içeriyordu; `head -5` sıralaması son-çare satır
  karşılaştırmasına düşüyordu. Veri, sayımlar birbirinden farklı
  olacak şekilde yeniden kuruldu.

### Sonraki adım

Yavuz `901-gun-02a` ve `901-gun-02b`'yi kendi başına çözecek, debrief
yapılacak, PROGRESS.md güncellenecek. Gün 3 tasarlanırken yine yeni
bir senaryo zorunlu (CONTEXT.md kuralı) ve Gün 1 ile Gün 2'nin
çerçeveleri kontrol edilecek.

---

## 2026-07-31 — 010 debrief'i işlendi, lab 011 yazıldı

### Yapılanlar

- **010-systemd debrief notu PROGRESS.md'ye işlendi.** Öne çıkanlar:
  privileged image geçişi sorunsuz; `/etc` altında sudo'suz vim denemesi
  (001/006/008/009'daki "gereksiz sudo" refleksinin tersi — burada sudo
  gerçekten gerekliydi ve ilk seferde atlandı); `Requires=` yerine
  `BindsTo=` seçimi (kavram biliniyor ama `RemainAfterExit`'li oneshot
  serviste hangisinin neden tercih edildiği net değil).
- **Dockerfile'a `chrony` eklendi.** Lab 011'in saat senkronu görevi
  `chronyd.service` ve `/etc/chrony.conf` üstüne kurulu; paket image'da
  yoktu (`cronie` ve `tzdata` vardı). Image yeniden derlendi, 001-010
  regression sweep'i temiz geçti.
- **Lab 011 (`labs/011-journalctl-cron-zaman/`) yazıldı ve doğrulandı.**
  4 görev, 19 kriter: kalıcı journal + `journalctl` ile iki katmanlı
  teşhis, cron ortam tuzağı, systemd timer çifti, saat dilimi + chronyd.
  Bozuk ortamda 19/19 FAIL (sıfır bedava OK), çözülmüş ortamda 19/19
  GEÇTİ. Negatif testler: `PATH=` alternatifi geçiyor, 10 dakikalık timer
  aralığı kriter 13'ü düşürüyor, enabled-ama-durdurulmuş timer kriter
  11'i düşürüyor, `/run/systemd/system` altındaki birim kalıcılık
  kriterini düşürüyor. Solved state üzerine `setup.sh` tekrar koşturuldu
  ve fresh `reset` denendi — ikisinde de 19/19 FAIL'e dönüyor.

### Kararlar

**1. `container-systemd` ENV etiketi kural olarak yazıya geçirildi.**
Etiket 010 oturumunda `labctl`'e eklenmişti ama CONTEXT.md'nin "Ortam
geçişleri" bölümünde adı geçmiyordu; yalnız setup.sh'lerde yaşıyordu.
Artık üç değerli olduğu (`container` / `container-systemd` / `vm`) ve
**010'dan itibaren geçerli olduğu** yazılı. 010 ve 011 bu etiketi
taşıyor, 001-009 `container` ile kalıyor — geriye dönük düzeltmeye gerek
yok, o labların hiçbiri PID 1 systemd istemiyor. Ölçüt netleştirildi:
kabul kriterlerinden biri bile systemd'yi PID 1 olarak gerektiriyorsa
(birim enable/start, timer, crond, chronyd, target) etiket konur. Salt
`--privileged` yetmez; etiketi gören `labctl` container'ı
`/usr/sbin/init` entrypoint'i, `--cgroupns=host` ve `/sys/fs/cgroup`
bağlamasıyla açıyor ve `is-system-running` hazır olana kadar bekliyor.
Etiket yoksa PID 1 `sleep infinity` kalır, `systemctl` çalışmaz.

**2. "System clock synchronized: yes" kabul kriteri olarak kullanılmadı.**
Kernel'in NTP-sync bayrağı host'a (Docker Desktop VM) ait; privileged
container'daki `chronyd` onu `adjtimex` ile çevirirse tüm VM'i etkiler,
üstelik sonuç dış UDP 123 erişimine bağlı olduğu için check flaky olurdu.
Yerine beş deterministik kriter kondu: `Timezone`, `/etc/localtime`
symlink kalıcılığı, `chrony.conf`'ta geçerli `pool`/`server` satırı,
`chronyd` active+enabled, `timedatectl` `NTP=yes`. `chronyc tracking`
TASK'ta teşhis yolu olarak anılıyor ama ölçülmüyor.

**3. Zamanlanmış iş doğrulaması gerçek tetiklenmeye dayanıyor.**
Yapılandırma denetimi "iş çalıştı" demez. `check.sh` iki log dosyasını
TEK ortak döngüde, paralel bekliyor (üst sınır 90s); dosyalar zaten
varsa anında geçiyor, yani tipik koşu hızlı.

### İki tuzak (CONTEXT.md'ye işlendi)

- **`systemctl show ... NextElapseUSecMonotonic --value` ham mikrosaniye
  DÖNDÜRMÜYOR.** Biçimlendirilmiş süre string'i geliyor:
  `4d 14h 51min 4.501888s`. Sayı sanıp aritmetiğe sokmak sessizce boş
  sonuç veriyor — kriter 13 ilk turda tam da bu yüzden FAIL etti.
  Ayrıştırmadan karşılaştırma yapılamaz. Aynı sınıf: 010'daki
  `systemctl show -p A -p B` çıktı sırası sorunu.
- **`set -- $cron_line` tırnaksız kullanımı `*` alanlarını glob'a
  açıyor.** cron zamanlama alanları dosya adlarına genişliyor ve hata
  mesajı `zamanlama alanı 'afs'`, `'bin'`, `'boot'` diye anlamsızlaşıyor.
  Alanlara bölmeden önce `set -f` şart.

### Açık kalanlar

- **`labctl` lab dosyalarını container'a yalnız `start` sırasında
  kopyalıyor.** Lab yazarken `check.sh` düzenlendikten sonra `start`/
  `reset` atılmazsa eski sürüm çalışmaya devam ediyor — bir tur boşa
  gitti. Geçici çözüm `docker cp`; CONTEXT.md'ye not düşüldü, davranış
  değiştirilmedi.
- **Container saati host'tan ~4 saat ileri** (Docker Desktop VM clock
  skew). Lab içi tutarlı olduğu için kriterleri etkilemiyor, ama debrief
  zaman damgaları host ile karşılaştırılırken akılda tutulmalı.
- **`student` `systemd-journal` grubunda değil**: `journalctl` sudo'suz
  çalışınca çıkış kodu 0 dönüp boş çıktı veriyor. Bilinçli bırakıldı,
  gerçek sunucu davranışı; solution.md'de ve hints Seviye 2'de yazılı.

### Sonraki adım

**Lab 011 çözülecek.** Ardından debrief → PROGRESS.md → 012. 013'ten
itibaren ortam VM'e taşınıyor.

---

## 2026-07-30 — labctl'e systemd desteği, lab 010

### Yapılanlar

**labctl'in ilk yapısal değişikliği yapıldı.** CONTEXT.md'de "tooling
donduruldu" kuralının önceden onaylanmış iki istisnasından birincisi
(systemd günü privileged image) kullanıldı. Değişiklik tasarlanmadan
önce ortam fiilen ölçüldü.

**Lab 010 (systemd) yazıldı ve uçtan uca doğrulandı.** 4 görev,
11 kabul kriteri, 11/11 GEÇTİ, `labctl reset` sonrası 11/11 FAIL.

### Kararlar

**1. OrbStack privileged + systemd PID 1 GERÇEKTEN çalışıyor —
ölçüldü, varsayılmadı.** Deneme container'ında sınananlar ve sonuçlar:

| Kapı | Sonuç |
|---|---|
| systemd boot | ~2 sn, `is-system-running` = running, failed unit yok |
| PID 1 | `systemd` |
| cgroup v2 | `cpuset cpu io memory pids`, yazılabilir |
| unit start / enable | çalışıyor, symlink kuruluyor |
| `Type=oneshot` + `RemainAfterExit` | `active (exited)` üretiliyor |
| `set-default` | çalışıyor |
| `docker exec` + `su - student` | çalışıyor, `sudo systemctl` rc=0 |

Gereken flag seti kullanıcının verdiğiyle birebir aynı çıktı:
`--privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw` +
`/usr/sbin/init` entrypoint. Fazladan hiçbir şey (tmpfs mount, unit
maskeleme, `SYS_ADMIN` ince ayarı) gerekmedi.

**2. systemd image'da YOKTU, Dockerfile'a eklendi.**
`rpm -q systemd` → "not installed", `/usr/sbin/init` yok. Rocky
container image'ı systemd'siz geliyor. Paket kuruldu ama
**`CMD ["sleep","infinity"]` DEĞİŞMEDİ** — `/usr/sbin/init` yalnız
010'da entrypoint olarak çağrılıyor. Image tek ve paylaşılan olduğu
için bu ayrım kritik; normal lablar systemd'yi sadece diskte taşır,
PID 1 olarak koşturmaz.

**3. Ortam işareti mevcut `# ENV:` alanına bindirildi.** CONTEXT.md
zaten setup.sh'ın ilk satırında `# ENV: container|vm` istiyordu; üçüncü
değer `container-systemd` eklendi. Yeni bir metadata mekanizması
yazılmadı. `lab_env()` işareti okunamazsa `container` döner, yani
001-009 hiç dokunulmadan eski davranışını sürdürür.

**4. labctl'e eklenen toplam yüzey: 2 fonksiyon + 1 if.**
- `lab_env()` — setup.sh ilk 3 satırından işareti okur.
- `wait_systemd()` — `is-system-running` `running|degraded` verene dek
  30 sn poll eder. `degraded` bilerek kabul ediliyor: setup.sh kasten
  bozuk servis bırakıyor, `running` beklenirse her koşuda zaman aşımı
  olurdu.
- `cmd_start()` içinde tek `if`: docker run argümanları diziye alındı,
  systemd dalı ayrı dizi kullanıyor. **`container` yolundaki argüman
  listesi bugünküyle birebir aynı** — regresyon riski buradan
  kapatıldı. `cmd_shell`/`cmd_check`/`cmd_hint`/`cmd_solution` hiç
  değişmedi; `docker exec` PID 1'in ne olduğuna bakmıyor.

CONTEXT.md korkuluğuna sadık kalındı: genel bir "ortam eklenti
sistemi" yazılmadı, tek if/else.

**5. Lab 010'un kapsamı journalctl ve timer'ı DIŞARIDA bıraktı.**
İkisi de 011'in konusu (journalctl + logging + cron/systemd timer).
010 yalnız unit yazımı, enable/disable, teşhis, After/Requires ve
varsayılan target'ta kalıyor. `journalctl -u` hints seviye 2'de teşhis
aracı olarak geçiyor ama kriterlerin hiçbiri onu ölçmüyor.

### 010 tasarım notları

**Görev 2'nin hata sırası ölçüldü, varsayılmadı.** `raporcu.service`
iki bağımsız hata taşıyor (yok olan `User=`, yanlış `ExecStart`).
Ölçüm: systemd önce `217/USER` veriyor ve `203/EXEC`'i TAMAMEN
maskeliyor — kullanıcı düzeltilmeden yol hatası hiç görünmüyor.
Bu tesadüfi değil, systemd süreci başlatırken önce kullanıcıya geçiyor.
TASK.md ve hints.md bu gerçek davranışa göre yazıldı ("biri diğerini
gizliyor, ilkini düzeltmeden ikincisi görünmez"). Katmanlı teşhis
labın en değerli parçası oldu.

**Kalıcılık kriteri bedava geçmiyor.** 008 ve 009'da "kaynak dosyalar
değişmemiş" korkuluk kriteri başlangıçta doğal olarak OK veriyordu ve
istisna olarak belgelenmişti. 010'da bu istisnaya gerek kalmadı:
kriter dört birimin de `FragmentPath`'ini istiyor, `gorevci.service`
başlangıçta hiç olmadığı için FragmentPath boş dönüyor ve kriter de
FAIL veriyor. Bozuk başlangıç **11/11 FAIL**.

**Durum systemd'ye soruluyor, dosyadan okunmuyor.** check.sh baştan
sona `systemctl show -p <özellik> --value` kullanıyor. Bunun somut
karşılığı `NeedDaemonReload` kriteri: öğrenci unit dosyasını düzeltip
`daemon-reload` yapmazsa dosya doğru görünür ama sistem eski tanımı
taşır. Fiilen sınandı — reload'suz durumda servis `failed` kalıyor ve
`NeedDaemonReload=yes` dönüyor.

**`systemctl show -p A -p B --value` argüman sırasını KORUMUYOR.**
Çıktı systemd'nin kendi sırasında geliyor. check.sh bu yüzden her
özelliği tek tek soruyor; toplu sorup sırayla okumak sessizce yanlış
eşleşme üretirdi. Ölçülen örnek — istenen sıra
`MainPID, SubState, Type, ExecStart`, gelen sıra
`Type, MainPID, ExecStart, SubState`; konumsal okuma `MainPID=oneshot`,
`SubState=0` verirdi.

### Bilinen davranış: get-default neden graphical.target

`systemd` kurulumundan sonra `systemctl get-default` `graphical.target`
dönüyor. Kaynağı ölçüldü (temiz container'da), GUI sızıntısı DEĞİL:

- `/etc/systemd/system/default.target` **yok** — yerel bir override
  kurulmamış.
- `/usr/lib/systemd/system/default.target` → `graphical.target`
  sembolik bağı, sahibi `systemd-257-23.el10_2.2.rocky.0.1`.
  Yani upstream systemd paketinin kendi varsayılanı.
- `rpm -qa | grep -iE 'gdm|gnome|display-manager|xorg|wayland|plasma|kde'`
  → hiçbiri kurulu değil. `display-manager.service` diye bir birim yok;
  `graphical.target` onu yalnız `Wants` ediyor, zorunlu tutmuyor.
- Preset dosyalarının sahibi `rocky-release` (zaten base image'da vardı)
  ve `systemd`. `85-display-manager.preset` içindeki `enable gdm.service`
  satırları atıl — o birimler sistemde yok. Ayrıca preset'ler birim
  enable/disable'ını yönetir, varsayılan target'ı belirlemez.
- Dockerfile satırı düz paket adı: `... ncurses dnf-plugins-core systemd`.
  `@minimal-environment` / `@server-product` gibi bir grup çekilmiyor.
  Kurulu toplam paket: 193.

Sonuç: Dockerfile daraltılmadı, image'a dokunulmadı. Bu davranış lab
010 görev 4'ün konusu zaten (`set-default multi-user.target`), yani
labın öğrettiği gerçek RHEL davranışıyla birebir örtüşüyor. CONTEXT.md'
nin "LPIC Topic 106 (X11/masaüstü) ALINMAYACAK" kuralıyla çelişki yok.

### Doğrulama sırasında çıkan iki kusur

- **bash 3.2 + boş dizi + `set -u`.** macOS'ta `/usr/bin/env bash`
  3.2.57 veriyor; orada boş bir dizinin `"${arr[@]}"` genişlemesi
  "unbound variable" hatası. `docker run` komut dizisi normal
  lablarda boş olduğu için labctl her lab'da patlardı.
  `${run_cmd[@]+"${run_cmd[@]}"}` koruması eklendi.
- **İlk kalıcılık negatif testi geçersizdi.** Birim `/etc`'den
  `/run`'a KOPYALANDIĞINDA kriter OK vermeye devam etti — çünkü
  `/etc/systemd/system` `/run/systemd/system`'den önceliklidir ve
  systemd hâlâ `/etc`'deki dosyayı okuyordu. Test taşımaya (`mv`)
  çevrilince kriter beklendiği gibi FAIL verdi. Bu öncelik kuralı
  solution.md'ye tuzak olarak eklendi.

### Regresyon

Image systemd ile yeniden kuruldu, labctl değişti; 001-009 tek tek
`start` + `check --no-commit` ile koşuldu.

| Lab | start | OK / FAIL | Sonuç |
|---|---|---|---|
| 001 | OK | 2 / 4 | KALDI |
| 002 | OK | 0 / 8 | KALDI |
| 003 | OK | 0 / 6 | KALDI |
| 004 | OK | 0 / 7 | KALDI |
| 005 | OK | 0 / 5 | KALDI |
| 006 | OK | 0 / 12 | KALDI |
| 007a | OK | 1 / 12 | KALDI |
| 007b | OK | 1 / 18 | KALDI |
| 008 | OK | 1 / 10 | KALDI |
| 009 | OK | 3 / 13 | KALDI |

Hepsi çözülmemiş ortamda KALDI — doğru sonuç. 009'un 3 OK / 13 FAIL
dağılımı değişiklik öncesi kayıtla birebir aynı. PID 1 karşılaştırması
da doğrulandı: `lab-009` → `sleep`, privileged=false;
`lab-010` → `systemd`, privileged=true.

### Bekleme listesine eklenenler

Aşağıdaki "Bekleme listesi" bölümüne üç madde eklendi (010'a
GÖMÜLMEDİ): sudo refleksi 4. tekrarıyla güncellendi, tek-harf yazım
hataları ve rpm/dpkg bayrak modeli yeni girdiler.

### Sonraki adım

011 — journalctl + logging + cron/systemd timer + saat senkronu.
Ortam işareti yine `container-systemd` olacak (journalctl systemd
gerektiriyor); labctl tarafında ek iş yok.

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
- **sudo refleksi** — 001, 006, 008 ve 009'da tekrarladı: **4. tekrar**.
  İzin sorununu düzeltmek yerine root'a kaçma, kendi home dizininde
  `sudo vim`. Artık tesadüf değil, yerleşmiş bir alışkanlık; bilinçli
  bir görevle kırılması gerekiyor.
- **Birim test disiplini** — 006: scriptler tek başına çalıştırılmadan
  bileşik akışta denendi, hata bileşikte arandı, döngü uzadı.
- **sudo secure_path / PATH ilişkisi** — 008: `/usr/local/bin`
  secure_path'te yok, script sudo altında bulunamadı. Kök sebep
  deneme-yanılmayla aşıldı, `sudo -l` ile doğrulanmadı.
- **awk'ta tırnak koruması** — 008: `awk "{print $1}"` içindeki `$1`
  kabukta genişledi. 004/005/006'daki `-F` alan modeli sorunundan FARKLI
  bir yüz; alan modeli değil tırnak seçimi problemi.
- **Tek-harf yazım hataları** — 009: `tee`/`tree`, `rmp`/`rpm`;
  008: Türkçe dotless `ı` ile `ls -ı`. Hız kaynaklı, kavramsal değil.
  Ayrı bir lab konusu değil; debrief'te izlenmeye devam edilecek,
  tekrar ederse yazma hızının maliyeti konuşulacak.
- **rpm/dpkg bayrak modeli** — 009: `rpm -V` PAKET adı bekler, dosya
  yolu için `-Vf` gerekir; 3 kez yanlış sözdizimiyle denendi (~7 dk).
  Aynı model `-q` / `-qf` / `-qp` ailesinde de geçerli: ikinci harf
  sorunun neye sorulduğunu belirliyor. Aday: paket yönetimi tekrar
  ettiğinde (Faz C, container/image konusu).

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

## 2026-08-05 — Gün 1 (900-vardiya-01a/01b) yazıldı, Genel Tekrar İzi kuruldu

### Yapılanlar

- 001-012'nin tamamını kapsayan genel tekrar senaryosu tasarlandı,
  Claude Code'a brief olarak verildi: labs/900-vardiya-01a (ticket
  1-6, container) ve labs/900-vardiya-01b (ticket 7-13,
  container-systemd).
- İki lab da 5 dosya kuralına uydu. Toplam 145 kriter (41+104),
  container içinde taze 0/41 ve 0/104'ten 41/41 ve 104/104'e
  çözülerek doğrulandı, sonra reset ile taze hale getirildi (Yavuz
  henüz kendi çözümünü yapmadı).
- Bu iz için üç kalıcı format sapması kabul edildi: hints.md yalnız
  Seviye 1, check.sh çıktısında kaynak lab etiketi, solution.md tam
  çözüm değil kaynak-haritası.
- "Gün N" adlandırması kuruldu ("Vardiya N" yerine); CONTEXT.md'ye
  "Genel Tekrar Günleri" bölümü eklendi.

### Kararlar

- Gün 1'in orijinal labların hikaye/verisini neredeyse birebir
  uyarlaması ilk tekrar için kabul edilebilir bulundu, ama bilinçli
  olarak tek seferlik: Gün 2'den itibaren her gün tamamen yeni bir
  iş senaryosu kullanacak.
- Dizin adlandırması: Gün 1 tarihsel nedenle 900-vardiya-01a/01b
  adını korur. Gün 2'den itibaren labs/90N-gun-0Nx/, her günün kendi
  3 haneli öneki var.
- 01a Ticket 2'ye setup sırasında fark edilen bir boşluk düzeltildi:
  /srv/proje 2770 root:developers olunca student group üyeliği
  olmadan hiçbir şey göremiyordu — kriter eklendi.
- 01b, ticket 11/12/13 systemd/cron/timer/chrony gerektirdiği için
  container-systemd ortamında açıldı (mevcut üç değerli ortam
  etiketine uygun, yeni kural değil).

### Açık kalanlar / bilinen kusurlar

- Yavuz henüz kendi çözümünü yapmadı; debrief bu yüzden bekliyor.

### Sonraki adım

Gün 1 commit+push edildi. Yavuz Gün 1'i (01a+01b) çözecek, debrief
yapılacak, PROGRESS.md'ye işlenecek. Ardından yeni bir sohbette Gün 2
tasarlanacak — CONTEXT.md'deki "Genel Tekrar Günleri" bölümü ve Gün
1'in kararları (yeni senaryo zorunluluğu) başlangıç noktası olacak.
