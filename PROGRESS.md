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
