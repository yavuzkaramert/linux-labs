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

Nihai hedef: "Linux biliyorum, bu alanda çalışabilirim" diyebilmek —
sertifika almak değil, sertifikaların ölçtüğü yetkinliğe sahip olmak.

## Referans müfredat (2026-07-27'de kararlaştırıldı)

Müfredat artık serbest sıralama değil, iki dış kaynağa bağlı:

- **Birincil: RHCSA (EX200, RHEL 10).** Sebep: performans-tabanlı, canlı
  sistemde uygulamalı, 3 saat; bizim lab formatımızla birebir aynı mantık.
  Kapsam: paket yönetimi (dnf/rpm/flatpak), kullanıcı/grup/izin, depolama
  (partition/LVM/swap), systemd servis ve target, ağ, SELinux, firewalld,
  shell scripting. NOT: Podman/container hedefleri RHCSA 10'dan çıkarıldı.
- **Tamamlayıcı: LPIC-1 (101-500 / 102-500).** RHCSA'da olmayan ama alınmaya
  değer konular: metin filtreleri + regex derinliği (Topic 103, en ağır
  başlık), vi, link/inode, FHS, dpkg/apt tarafı, paylaşılan kütüphaneler,
  GPG, boot sekansı.
- **ALINMAYACAK LPIC konuları:** Topic 106 (X11/masaüstü), Topic 108'in
  yazıcı ve MTA kısmı. Sunucu işinde karşılığı yok.

Hedef listeleri periyodik olarak Red Hat'in kendi EX200 sayfasından
doğrulanır; üçüncü parti kaynaklar eskiyor.

## Platform

- Docker container, `student` kullanıcısı, şifresiz sudo.
- Base image: **rockylinux/rockylinux:10** (RHEL 10 uyumlu; Docker Hub'ın resmi
  library reposundaki `rockylinux` tag'leri güncellenmiyor — 9.3'te donmuş,
  image RESF'in kendi reposundan alınıyor). 005'e kadar ubuntu:24.04
  kullanıldı; RHCSA'ya yönelme kararıyla 006'dan itibaren Rocky'ye geçildi.
  Sebep: dnf/rpm, firewalld, SELinux, nmcli Ubuntu'da ya yok ya farklı.
- `labctl` bash scripti + `labs/` klasörü.
- Mac'te OrbStack/Docker. Repo public: github.com/yavuzkaramert/linux-labs
  (HTTPS + gh credential helper).
- 013'ten itibaren ortam VM'e taşınır — aşağıdaki "Ortam geçişleri"ne bak.

## Lab formatı (SABİT — değiştirilmez)

`labs/NNN-konu/` altında 5 dosya:
- `TASK.md` — saf gereksinim: Hikâye + Görevler + Kabul kriterleri.
  İçinde İPUCU YOK. Görevler ve Kabul kriterleri AYRI bölümler olarak durur.
  TASK.md terminalde `cat` ile okunur; markdown işaretleri orada ham metin
  olarak görünüp okumayı zorlaştırıyor. Yazım kuralları:
  - Başlıklar setext biçiminde: başlık satırı, altına `---` çizgisi.
    Terminalde çizgi gibi, GitHub'da h2 olarak görünür. `#` kullanılmaz.
  - Satırlar 72 sütunda sabit sarılır.
  - Kalın (`**`) ve backtick KULLANILMAZ. Yollar ve komut adları çıplak
    metin olarak yazılır: /usr/local/bin/logsum
  - Görev ve kriter maddeleri arasında boş satır bırakılır.
  - Kabul kriterleri tek satırda, 72 karakteri aşmadan, `[ ] ` ile başlar.
    Uzun cümle yerine kısa ve sınanabilir ifade.
  - Yalnız "Kontrol" bölümündeki komutlar 4 boşluk girintili blok olur.
  Kural 007'den itibaren geçerlidir; 001-006 geriye dönük düzeltilmez.
- `setup.sh` — ortamı bozuk kurar; HER kabul kriterini bozar, sıfır bedava OK.
  İlk satırında ortam işareti taşır: `# ENV: container` veya `# ENV: vm`.
  systemd'nin PID 1 olması gereken lablarda `# ENV: container-systemd`.
  `labctl` lab dosyalarını container'a YALNIZ `start` sırasında kopyalar;
  check.sh düzenlendikten sonra `start`/`reset` atılmadan yeni sürüm
  çalışmaz (lab yazarken `docker cp` ile elle güncellemek gerekir).
- `check.sh` — kriter başına [OK]/[FAIL], FAIL varsa exit 1, `set -e` YOK
  (accumulator pattern), kullanıcı-perspektifi testleri `su - student -c` ile,
  negatif testler dahil.
  - `systemctl show` ile birden çok property sorgulanacaksa HER BİRİ AYRI
    çağrı olmalı: `-p A -p B --value` çıktı sırası garantili değil, systemd
    kendi iç sırasında basar. Konumsal okuma sessizce yanlış eşleşir.
  - `NextElapseUSecMonotonic` / `NextElapseUSecRealtime` gibi süre-zaman
    property'leri `--value` ile HAM mikrosaniye DEĞİL, insan okur biçimde
    döner: `4d 14h 51min 4.501888s`. Sayı sanıp aritmetiğe sokmak sessizce
    boş sonuç verir; ayrıştırmadan karşılaştırma yapılamaz.
  - cron satırı gibi `*` içeren metinler `set -- $line` ile alanlara
    bölünüyorsa önce `set -f` gerekir; yoksa `*` dosya adlarına genişler.
- `hints.md` — 3 seviye: `## Seviye 1` (kavramsal, komut adı yok),
  `## Seviye 2` (komut adları, bayrak yok), `## Seviye 3` (bayrak/parametre).
  Tam komut hiçbir seviyede verilmez.
- `solution.md` — komutlar + kısa açıklama.

Lab 001 eski formatta (hints.md yok, TASK.md içinde Hints bölümü var);
bilinçli olarak öyle bırakıldı.

  Konu ağırlaştıkça lab ikiye bölünebilir: NNNa (hafif, tek araçlı, kavram
  yerleştirme) ve NNNb (tam senaryo, zincir ve script). İkisi de AYRI lab
  klasörüdür ve 5 dosya kuralına birebir uyar; format değişmez. NNNb,
  NNNa'nın çözülmüş olduğunu varsayar. `labctl start 007` iki klasörü de
  eşleştirip "ambiguous" der; bu istenen davranıştır, tam id yazılır.

## Tooling donduruldu

labctl'e yeni özellik EKLENMEZ. Ancak lab çözerken gerçek bir ihtiyaç kendini
dayatırsa konuşulur. Bug düzeltmesi özellik değildir; serbesttir (örn.
auto_commit yalnız PROGRESS.md stage etmeli — geçmişte tüm ağacı süpürme
bug'ı düzeltildi).

Bu istisnanın bilinen iki kullanımı: (1) systemd günü privileged image,
(2) 013'teki VM taşıma katmanı. İkisi de aşağıda sınırlandırılmıştır.

## Ortam geçişleri

### systemd (010'dan itibaren)
Container `--privileged` + systemd-enabled image'a geçirilir.

Ortam işareti üç değerlidir: `container` (varsayılan), `container-systemd`,
`vm`. `container-systemd` 010 ile tanıtıldı ve 010'dan itibaren geçerlidir;
010 ve 011 bu etiketi taşır, 001-009 `container` ile kalır — geriye dönük
düzeltme yok, gerek de yok (o labların hiçbiri PID 1 systemd istemiyor).

Ne zaman `container-systemd`: labın kabul kriterlerinden biri bile systemd'yi
PID 1 olarak gerektiriyorsa (birim başlatma/enable, systemd timer, crond,
chronyd, target değiştirme). Salt `--privileged` yetmez — `labctl` bu etiketi
görünce container'ı `/usr/sbin/init` entrypoint'i, `--cgroupns=host` ve
`/sys/fs/cgroup` bağlamasıyla açar, ayrıca `is-system-running` hazır olana
kadar bekler. Etiket yoksa PID 1 `sleep infinity` kalır ve `systemctl`
çalışmaz.

### VM (013'ten itibaren)
Container RHCSA'nın kabaca %60'ını taşır. Şunlar container'da YAPILAMAZ:
SELinux, gerçek blok cihaz üstünde partition/LVM, boot/GRUB kurtarma,
reboot kalıcılığı testi. Bu yüzden 013'ten itibaren ortam Rocky 10 VM olur.

Araç: **Lima birincil, UTM yedek.** OrbStack "machines" kullanılmadan önce
SELinux + gerçek blok cihaz + gerçek reboot verdiği test edilmeli.
Apple Silicon'da VM aarch64 olur; 019'daki GRUB/UEFI detayları x86'dan
biraz farklıdır, o gün not düşülür.

Taşınan şey yalnızca **taşıma katmanı**: `docker exec` → `ssh`.
Lab dosyaları saf bash + markdown; ortamdan habersiz. Repo Mac host'ta
kalır, VM'e sadece `labs/NNN/` kopyalanır. Git/commit/push/PROGRESS.md
akışı DEĞİŞMEZ.

labctl'e eklenecek: `env_up`, `env_exec`, `env_reset` — her birinde tek bir
`if [ "$env" = vm ]` dalı. Ayrıca `check --reboot` (VM'i yeniden başlatıp
sonra check.sh çalıştırır; RHCSA'nın karakteristik testi).

Depolama labları (016, 017) gerçek disk gerektirmez: VM içinde dosya +
`losetup` ile blok cihaz üretilir. Üstündeki partition, LVM, filesystem,
fstab kaydı kernel açısından gerçektir. Reset = dosyayı sil, yeniden yarat.
Snapshot yalnız 019 (boot/GRUB kurtarma) için gerekir.

### VM adaptasyonu — KORKULUKLAR (bu projenin en büyük over-engineering tuzağı)
1. Genel "ortam eklenti sistemi" YAZILMAZ. İki dal, if/else, bitti.
2. VM provisioning otomatize EDİLMEZ. VM bir kez elle kurulur, README'ye
   10 satır not düşülür.
3. Container labları VM'e TAŞINMAZ. 006–012 container'da kalır. Hibrit kalıcı.
4. Tek oturum timebox. O oturumda bitmezse durulur.
5. Fallback her zaman vardır: tooling hiç adapte edilmese bile VM'e ssh ile
   girip setup.sh ve check.sh elle çalıştırılabilir. Kaybedilen tek şey
   otomatik commit'tir, o da elle atılır. Sistemin batma riski sıfırdır.

## labctl davranışları

- `check` GEÇTİ'de otomatik commit atar (`lab NNN-konu solved`) ve bildirir;
  commit yalnız PROGRESS.md'yi kapsar. KALDI'da git'e dokunmaz.
- Commit geçmişi (git log / GitHub) aynı zamanda ilerleme kaydıdır.
- Kalıcı kayıt yalnız PUSH edilmiş halde görülür. Debrief notu yazıldıktan
  sonra push edilir; sonraki sohbet repodan okur.
- Regresyon/doğrulama amaçlı koşularda `check <id> --no-commit` kullanılır:
  check normal çalışır, GEÇTİ/KALDI normal basılır, git'e ve PROGRESS.md'ye
  dokunulmaz. Bayrak yokken davranış eskisiyle birebir aynıdır. Bayrak
  006 yazımı sırasında eklendi: doğrulama koşuları PROGRESS.md'ye yanlış
  tarihli "solved" satırı düşürüp elle `git reset --soft` gerektiriyordu ve
  bu her yeni labda tekrarlayan yapısal bir sorundu.

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
4. **Ortam değişimleri yalnız "Ortam geçişleri" bölümündeki sınırlar
   içinde yapılır.** Korkuluklar aşılacaksa önce konuşulur.

## Debrief → PROGRESS.md not formatı

Her lab sonrası, çözülen satırın altına girintili notlar eklenir. Örnek:

```
004-text-processing solved (2026-07-26)
  awk alan modeli: -F ayırıcısını kavrayana dek takıldı → çözüldü
  tuzak: awk file | tee file dosyayı sıfırlar → kaynaktan yeniden üret
  zayıf: awk alan modeli, sed adresleme. sağlam: izin, grep süzme
```

Akış: lab çöz → `labctl check` GEÇTİ'de basılan debrief history çıktısı
sohbette analiz edilir → çıkan not Claude Code'a verilir → Claude Code
notu PROGRESS.md'ye ekler ve commit'ler → sonraki lab. Aynı biçimde
JOURNAL.md oturum girdisini de Claude Code yazar. Yavuz yalnız push eder.

Kayıt tutan taraf bulguyu ÜRETMEZ: debrief analizi sohbette yapılır,
Claude Code kendisine verilen metni yazar. Terminal geçmişini görmeyen
tarafın bulgu uydurması, kaydın değerini sıfırlar.

(Not yazılıp commit'lenmeden sonraki lab başlatılmaz; yoksa not "solved"
commit'ine karışır.)

Debrief girdisi artık otomatik: `labctl check` GEÇTİ verdiğinde oturumun
komut geçmişi zaman damgalı olarak basılır. Pencere DEBRIEF_HOURS ile
ayarlanır (varsayılan 24 saat).

## Günlük kaydı — JOURNAL.md

PROGRESS.md "hangi lab, hangi hata" tutar. JOURNAL.md ise oturum düzeyinde
"o gün ne yapıldı, hangi karar neden verildi" tutar. İkisi farklı şeyler;
karıştırılmaz.

JOURNAL.md'ye yazılanlar: alınan kararlar ve gerekçeleri, ortam/altyapı
değişiklikleri, açık kalan maddeler, sonraki oturumun başlangıç noktası.
Yazılmayanlar: lab hata analizi (o PROGRESS.md'de), sohbet dökümü.

Ne zaman: her sohbetin sonunda, ya da gün sonunda. Yeni sohbete
başlarken CONTEXT.md + PROGRESS.md + JOURNAL.md'nin son girdisi okunur.

## Müfredat haritası

Sıralama 4 filtreyle: bağımlılık zinciri, günlük iş sıklığı, ortamda
test edilebilirlik, debrief'ten gelen zayıf noktalar. Kapsam RHCSA + LPIC-1
hedeflerine bağlı (yukarı bak).

### Tamamlanan (ubuntu:24.04 container)
- 001 permissions ✅ (chmod/chown)
- 002 users & groups ✅
- 003 finding-files ✅ (find, cp -a, symlink)
- 004 text-processing ✅ (grep/sed/awk, pipe, yönlendirme)
- 005 processes ✅ (ps/pgrep/kill+sinyaller/nice/renice)

### Faz A — container (rockylinux:10)
- 006 shell scripting temeli — değişken/koşul/döngü/exit code
- 007a text-filters — grep/cut/sort/uniq, grep çıkış kodu, vi giriş
- 007b regex-report — ERE derinleşme, sed, awk dizileri, vi toplu düzenleme
- 008 link/inode, FHS, tar/arşivleme
- 009 paket yönetimi — dnf/rpm birincil, dpkg/apt eki
- 010 systemd — servis, target, unit yazımı (privileged image burada)
- 011 journalctl + logging + cron/systemd timer + saat senkronu
- 012 SSH anahtar kimlik doğrulama, sshd config, GPG

### Faz B — VM (rocky 10, Lima)
- 013 ağ — nmcli, hostname, DNS, ss/ip ile teşhis (VM geçişi burada)
- 014 firewalld / nftables
- 015 SELinux — modlar, context, boolean, sorun giderme
- 016 depolama 1 — partition, filesystem, swap, fstab + UUID kalıcılık
- 017 depolama 2 — LVM (PV/VG/LV, hacim genişletme)
- 018 NFS / autofs
- 019 boot sorun giderme — GRUB, rescue mode, root parola kurtarma
- 020 bileşik teşhis labı — "sunucu açılmıyor" senaryosu

### Faz C — istihdam katmanı (planı 015'te yapılacak, şimdi planlanmaz)
006–020 zemindir; iş ilanlarının istediği katman değildir. Ufka not:
container (podman/docker, image, compose), Ansible/otomasyon, cloud temeli
(instance, cloud-init, SSH anahtar yönetimi), nginx/Apache + TLS,
yedekleme/geri dönüş disiplini, ağ derinliği (subnet, tcpdump).

Ek olarak 012 civarında ucuz bir VPS alınıp üstünde gerçekten kullanılan
bir şey işletilmesi önerildi. Lab "verilen problemi çöz"dür; gerçek sistem
"problemi sen fark et"tir. İkincisi mülakatta anlaşılır.

Zayıf konular sonraki lablara doğal serpiştirilir (örn. awk 005'te ps|awk
olarak geri geldi; sed config-düzenleme görevlerinde tekrar eder).

## Genel Tekrar Günleri (Gün N)

Ana müfredata (001-012, sonrası Faz B/C) paralel, ayrı bir tekrar izi.
Amaç ezber değil, aşinalığı taze tutmak — bilgi birikince öğrenilenler
hızla soğur, bu iz onu önler. Ana müfredatla numaralandırması ayrıdır,
karışmaz.

Dizin: labs/90N-gun-0Nx/ (N = gün numarası, x = a/b — gün ikiye
bölünür, a/b sabah-öğleden sonra gibi gevşek bir çerçeve, zorunlu
değil). Gün 1 tarihsel nedenle labs/900-vardiya-01a/ ve
labs/900-vardiya-01b/ adını taşıyor ("vardiya" terimi o an
kullanılıyordu, yeniden adlandırılmadı). Gün 2'den itibaren
labs/901-gun-02a/, labs/901-gun-02b/ şeklinde devam eder; her günün
kendi 3 haneli öneki vardır (901, 902, ...) — aksi halde labctl'in
"ambiguous" eşleştirmesi gün sayısı arttıkça yönetilemez hale gelir.

5 dosya kuralı ve genel format aynen geçerlidir, ancak bu iz için üç
kalıcı format sapması vardır:
- hints.md yalnız Seviye 1 (kavramsal) içerir; Seviye 2/3 yerine
  "bu konuyu lab NNN'de gördün" referansı.
- check.sh çıktısında her satırda kaynak lab etiketi bulunur:
  [OK]/[FAIL] Ticket X.Y — ... (kaynak: lab NNN).
- solution.md dosya adı değişmez (labctl bunu arar) ama içerik tam
  komut çözümü değil, ticket → kaynak lab kriteri haritasıdır.

Kapsam kuralı: her Gün, o ana kadar TAMAMLANMIŞ olan ana müfredat
konularının tamamını kapsar (şu an 001-012). Faz B/C ilerledikçe
kapsam genişler; geçmiş günler geriye dönük güncellenmez.

En kritik kural — Gün 1'den öğrenilen ders: Gün 1, orijinal labların
hikaye ve verisini büyük ölçüde birebir uyarladı (aynı dosya adları,
aynı örnek veri kalıpları — ayşe/mehmet, /srv/proje, vardiya günlüğü).
İlk tekrar için kabul edilebilirdi ama tekrarın amacı gerçek aşinalık,
ezber değil. Gün 2'DEN İTİBAREN her gün TAMAMEN YENİ bir iş senaryosu
kullanır: farklı kurum, farklı dosya/kullanıcı adları, farklı spesifik
veri — aynı komut/konu yüzeyi korunur ama önceki günlerin metninden
veya verisinden kopyalanmaz. Yeni bir Gün tasarlanmadan önce önceki
günlerin hikaye çerçeveleri kontrol edilir ve tekrar edilmez.

Süre kaydı script'lerin işi değil; Yavuz kendi JOURNAL.md'sine elle
not düşer.

### Gün kaydı

- **Gün 1** = `labs/900-vardiya-01a` + `900-vardiya-01b`. İlk gün / gece
  vardiyası çerçevesi, 145 kriter. Orijinal labların hikaye ve verisini
  büyük ölçüde uyarladı (tek seferlik istisna).
- **Gün 2** = `labs/901-gun-02a` + `901-gun-02b`. **PatiVet Klinikleri /
  Yedek Sunucu Günü** (UPS arızası sonrası DR sunucusunu üretime alma),
  001-012'nin tamamını kapsar. 02a: 6 ticket / 47 kriter / `container`.
  02b: 7 ticket / 104 kriter / `container-systemd` + ağ. Tamamen yeni
  senaryo, veri ve isimler: derya/kaan/oguz/randevubot, grup `vetekip`
  (GID 4600), `/srv/klinik`. Gün 1'in hiçbir adı veya yolu kullanılmadı.

Bu izde iki kalıcı uygulama notu daha:

- **Korkuluk kriterleri.** "Şu dosyaya dokunma" diyen kriterler tanımı
  gereği bozulamaz, dolayısıyla ilk koşuda geçerler ve "sıfır bedava OK"
  kuralının bilinen istisnasıdır. Amaçları ödül değil yan hasarı
  yakalamaktır. Gün 1'de altı, Gün 2'de dört tane var (02a: 0, 02b: 3 —
  01a'daki gizli dosya sahiplik kriteri Gün 2'de bilerek bozulur hâle
  getirildi). Sayıları solution.md'de açıkça yazılır.
- **`data/` dizini.** 5 dosya kuralının tek istisnası: `901-gun-02b`
  altında `data/epel.repo` durur, setup onu `/etc/yum.repos.d/`'ye
  kapalı olarak kurar. `labctl` lab klasörünü `docker cp "$LAB_DIR/."`
  ile kopyaladığı için ek dosyalar sorunsuz taşınır. GPG ve paket
  varlıkları image'daki `/opt/lab-assets` altından gelir; yeni asset
  üretilmez, Dockerfile değişmez.

## Portföy notu

Public repo + tarihli commit geçmişi + debrief notları, "Linux biliyorum"
iddiasının kanıtlanabilir hâlidir. PROGRESS.md notları bu yüzden yalnız
öğrenme aracı değil, işe alım materyalidir; ona göre yazılır.

## Güncel durum

En güncel "ne çözüldü / hangi hatalar / hangi konu zayıf" bilgisi için
PROGRESS.md okunur. Bu dosya yalnız kuralları taşır; ilerleme PROGRESS.md'de.
