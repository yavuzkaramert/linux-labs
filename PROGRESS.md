# Progress

- 002-users-groups solved (2026-07-24)
- 003-finding-files solved (2026-07-24)
- 004-text-processing solved (2026-07-26)
  - awk alan modeli: -F ayırıcısını kavrayana dek 5 deneme (zaman|SEVİYE|mesaj boşlukla değil | ile bölünüyor) → çözüldü
  - tuzak: aynı dosyayı awk ... file | tee file ile sıfırladı → kaynaktan (app.log) yeniden üretmeyi öğrendi
  - sed BRE vs grep -E: (a|b) sed'de literal, grep -Ev'ye geçerek çözdü → doğru araç seçimi
  - yazım: [[space]]→[[:space:]], sed'e dosya adı vermeyi unutma
  - izin (görev 1): chgrp+chmod g+r tek denemede → 001 tekrarı oturmuş
  - zayıf: awk alan modeli, sed adresleme. sağlam: find sonrası izin, grep süzme
- 005-processes solved (2026-07-27)
  - hint kullanılmadı — ilk hint'siz lab
  - ps -oe ↔ -eo transpozisyonu 4 kez (56,57,59,63) → syntax, kas hafızası
  - "seçmediğin sütunu grepleyemezsin": ps -eo ni | grep LABPROC 4 kez boş
    döndü (63-67) → 68'de ni,cmd ile çözdü. labın en değerli dersi
  - ps aux + awk $11 komut satırını kırptı → 53'te ps -eo pid,args'e geçti
    (004'ten sarkan awk alan modeli zayıflığının tekrarı — HÂLÂ ZAYIF)
  - SIGTERM -15 35: sinyali komut sandı, 1 satırda düzeltti (refleks)
  - bracket trick [L]ABPROC kendi buldu → grep self-match tuzağı sağlam
  - renice -n 19 -p 42 tek denemede → nice ters modeli oturmuş
  - sinyal seçimi (TERM vs KILL) tek denemede doğru
  - boşluk: pgrep/pkill hiç kullanılmadı, hep ps+gözle PID okuma → 011'de tekrar
  - zayıf: awk alan modeli, ps -o sütun seçimi.
  - sağlam: sinyal kavramı, nice modeli, araç değiştirme refleksi
- 006-shell-scripting solved (2026-07-28)
  - echo $? bir kez bile kullanılmadı. Labın merkez kavramı olan çıkış kodu
    hiç gözlemlenmedi; sözleşme yalnız script içine yazıldı, kabukta sınanmadı
  - pgrep/ps komut satırında hiç denenmedi — svccheck doğrudan vim'de yazıldı.
    005'te işaretlenen boşluk kapanmadı, script içine taşındı
  - birim test disiplini yok: logsum ve svccheck tek başına çalıştırılmadı,
    yalnız bileşik report denendi. Hata bileşikte aranınca döngü uzadı
  - awk '{print $2:$1}' → awk'ta birleştirme yan yana yazmaktır, ayırıcı
    string literal olmalı: $2":"$1. 4 saniyede düzeltildi
  - sudo ./report — izin sorununu düzeltmek yerine root'a kaçıldı; chmod +x
    3 dakika sonra geldi. 001'deki aynı refleks
  - ./report ile çalıştırıldı; /usr/local/bin zaten PATH'te, cd gereksizdi
  - man yalnız bir kez (man chmod, chmod +x öncesi — kural doğru işledi).
    awk, pgrep, bash man sayfalarına bakılmadı
  - editör sürtünmesi: nano yok, dnf install denendi, vim'e geçildi
  - zayıf: çıkış kodunun kabukta gözlenmesi, birim test disiplini, pgrep.
    sağlam: awk -F alan modeli (004+005'ten sonra ilk kez tek seferde doğru)
- 007a-text-filters solved (debrief yapılmadı)
- 007b-regex-report solved (debrief yapılmadı)
- 008-links-fhs-archiving solved (2026-07-29)
  - hint kullanılmadı (005'ten sonra ikinci hint'siz lab)
  - alias sudo ile çalışmaz: mvmkdir alias'ı sudo mvmkdir'de
    "command not found" verdi (alias sudo'nun başlattığı
    process'e taşınmıyor) → gerçek script'e geçildi, hızlı
    toparlanma
  - sudo secure_path /usr/local/bin içermiyor (RHEL ailesi
    varsayılanı): script orada çalışmadı, /usr/bin'e taşınınca
    çözüldü — kök sebep deneme-yanılmayla aşıldı, doğrulanmadı
    (sudo -l kontrolü önerilir)
  - awk "{print $1}" (çift tırnak) → $1 shell'de genişledi,
    awk'a boş geldi; '{print $1}' ile düzeltildi. awk alan
    modelinin 004/005/006'dan farklı yüzü: bu kez -F değil,
    tırnak seçimi
  - ls -ı (Türkçe dotless ı, ASCII i değil) geçersiz bayrak —
    klavye kaynaklı, sık kullanılan bayraklarda (-i) tekrar
    riski var
  - görev 2 (hard link tespiti) ~30 dk sürdü, script defalarca
    revize edildi, çıktı dosyası bir kez elle de düzenlendi —
    tıkanma noktası netleşmedi
  - gözlem (gradelenmedi): sudo vim raporla.sh / arsiv_kontrol.sh
    — kendi home dizininde sudo gereksizdi, 001/006 refleksinin
    devamı
  - sağlam: ln/ln -s ayrımı tek denemede doğru, tar --exclude
    tek denemede doğru, tar -tf ile açmadan doğrulama ilk
    seferde doğru araç, mvmkdir soyutlaması, script'i silip
    yeniden çalıştırarak kendiliğinden idempotency testi
  - zayıf: sudo/PATH ilişkisi (secure_path), awk script'inde
    tırnak seçimi. sağlam: link komutları, tar --exclude,
    doğrulama disiplini
- 009-package-management solved (2026-07-29/30)
  - rpm -V paket adı bekler, dosya yolu için -Vf gerekir — 3 kez
    yanlış sözdizimiyle denendi (~7 dk), sonra kalıcı öğrenildi
  - heredoc'ta tırnaklı sınırlayıcı (<< 'EOF') komut ikamesini
    devre dışı bırakır — fark edilip << EOF'a geçildi, sonraki
    iki görevde (5, 6) aynı teknik hatasız uygulandı
  - dnf history: info ile kontrol edip yanlış id'den (5)
    doğrusuna (8) geçiş — körlemesine denemedi, iyi diagnostik
  - crb deposu gerekliliği hata mesajından çıkarıldı, repo adı
    verilmemişti — lab tasarımının hedeflediği tam senaryo
  - sudo refleksi 4. kez tekrarladı (001, 006, 008, 009): kendi
    home dizininde sudo vim
  - tek-harf yazım hataları (tee/tree, rmp/rpm) — hız kaynaklı,
    kavramsal değil
  - sağlam: awk '{print $NF}' ile dpkg-deb çıktısından doğru
    sütun seçimi (004/005/006 dersinin farklı araçta uygulanışı),
    görev 5'te tek seferde temiz --qf format sorgusu
- 010-systemd solved (2026-07-31)
  - privileged image geçişi ilk kez kullanıldı, sorunsuz
  - gorevci: /etc altında sudo'suz vim önce denendi, yazamayınca
    sudo'ya geçildi — 001/006/008/009'daki "gereksiz sudo"
    refleksinin tersi, burada sudo gerçekten gerekliydi ve ilk
    seferde atlandı
  - raporcu: düzenlemeden önce status + unit dosyası + gerçek
    script cat'lendi (iyi diagnostik alışkanlık). Task'ın kasıtlı
    iki-gizli-hata tuzağıyla birebir uyan 2 edit-check döngüsü,
    gecikme değil, tasarımın kendisi
  - api+veritabani (sıralama+gereklilik): en çok iterasyon burada
    (api 4 edit). Requires= yerine BindsTo= denendi ("garanti
    olsun" diye daha güçlü coupling seçildi), check Requires
    bekleyince düzeltildi. Kavramsal anlayış sağlam (BindsTo'nun
    ne yaptığını biliyor) ama RemainAfterExit'li tek-seferlik
    servislerde Requires'ın BindsTo'ya neden tercih edildiği
    (lifecycle coupling farkı) net değil
  - default target: tek denemede doğru
  - zayıf: dependency directive ayrımı (Requires/BindsTo/Wants ne
    zaman hangisi). sağlam: edit-öncesi diagnostik (status+cat),
    enable/start/daemon-reload sırası, target değiştirme
