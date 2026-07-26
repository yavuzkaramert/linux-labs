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
