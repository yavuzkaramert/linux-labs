# Çözüm — Lab 003: Dosya Bulma ve Yönetme

Lab shell'i içinde çalıştır (`labctl shell 003`); `student` parolasız sudo'ya sahip.

## 1. Eski logları arşivle

```bash
sudo mkdir -p /srv/data/archive
sudo find /srv/data -path /srv/data/archive -prune -o \
    -type f -name '*.log' -mtime +30 -exec mv -t /srv/data/archive {} +
```

`-mtime +30` = 30 günden eski. `-prune` arşivin kendisini aramanın dışında
tutar; `mv` mtime'ı korur, bu yüzden taşınan loglar arşivde de "eski" kalır.

## 2. Sıfır byte artıkları sil

```bash
sudo find /srv/data -type f -empty -delete
```

`-type f` sayesinde yalnız normal dosyalar silinir — boş dizinlere dokunulmaz.

## 3. Büyük dosyaları ayır

```bash
sudo mkdir -p /srv/data/big
sudo find /srv/data/tmp -maxdepth 1 -type f -size +1M -exec mv -t /srv/data/big {} +
```

`-size +1M` = 1 MB'den büyük; `session-*.dat` gibi küçükler tmp'de kalır.

## 4. Metadata koruyan yedek

```bash
sudo mkdir -p /srv/data/backup
sudo cp -a /srv/data/config /srv/data/backup/config
```

`-a` (arşiv modu) izin, sahiplik ve mtime'ı birebir korur. Sahipliği
koruyabilmek için root olmak gerekir — `sudo` bu yüzden şart.
Düz `cp -r` kullansaydın mtime bugüne, sahiplik sana dönerdi → FAIL.

## 5. latest sembolik linki

```bash
newest=$(ls -t /srv/data/reports/*.csv | head -1)
sudo ln -sfn "$newest" /srv/data/reports/latest
```

`ls -t` mtime'a göre yeniden eskiye sıralar; `*.csv` kalıbı sayesinde daha
yeni olan `summary.txt` tuzağına düşülmez. `-s` sembolik link, `-f` varsa
üzerine yaz, `-n` link hedefi dizinse içine girme.

## 6. Script'lere çalıştırma izni

```bash
sudo find /srv/data/scripts -type f -name '*.sh' -exec chmod 755 {} +
```

`find` sayesinde alt dizindeki `maintenance/rotate.sh` de bulunur —
`chmod /srv/data/scripts/*.sh` onu kaçırırdı. `notes.txt`'ye izin
verilmediği için negatif kriter de geçer (`chmod -R +x` kullanma!).

## Doğrula

Host'tan: `labctl check 003` — altı kriterin hepsi `[OK]` basmalı.
