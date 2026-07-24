# Çözüm — Lab 004: Metin İşleme

Lab shell'i içinde çalıştır (`labctl shell 004`); `student` parolasız sudo'ya sahip.

## 1. Loglara erişimi aç

```bash
sudo chmod 644 /srv/logs/access.log /srv/logs/app.log
sudo mkdir -p /srv/reports
sudo chown student:student /srv/reports
```

Loglar `root:root 600` durumundaydı. `644` ile `student` okuyabilir hale
gelir. Raporları yazabilmek için `/srv/reports` dizinini de kendine ait yap.

## 2. Hataları ayıkla

```bash
awk '$(NF-1)==500' /srv/logs/access.log > /srv/reports/errors.log
```

Durum kodu, satırın sondan bir önceki alanı (`$(NF-1)`). Sadece bu alanı
hedeflediğimiz için boyutu 500 olan `200` satırları ve yolunda `/500` geçen
satırlar tuzağa düşürmez. `grep 500` kullansaydın hepsini toplardın → FAIL.

## 3. En çok istek yapan adresler

```bash
awk '{print $1}' /srv/logs/access.log | sort | uniq -c | sort -rn | head -5 \
    > /srv/reports/top-ips.txt
```

IP ilk alan (`$1`). `sort | uniq -c` her IP'yi sayar, `sort -rn` sayıya göre
büyükten küçüğe dizer, `head -5` ilk beşi alır. Çıktı "sayı IP" biçiminde.

## 4. Etkilenen kullanıcıları say

```bash
awk '$3!="-"{print $3}' /srv/logs/access.log | sort -u | wc -l \
    > /srv/reports/unique-users.txt
```

Kullanıcı üçüncü alan (`$3`). `-` (anonim) olanları koşulla ele, `sort -u`
ile tekilleştir, `wc -l` ile farklı kullanıcı sayısını al.

## 5. Uyarıları tabloya dök

```bash
awk -F'|' '$2=="WARN"{printf "%s\t%s\n", $1, $3}' /srv/logs/app.log \
    > /srv/reports/warnings.tsv
```

Alan ayracı `|` (`-F'|'`). Sadece seviye alanı `WARN` olan satırlarda zaman
(`$1`) ile mesajı (`$3`) aralarına gerçek bir TAB (`\t`) koyarak yaz.

## 6. Ayar dosyasını düzelt

```bash
sudo cp /etc/webapp/settings.conf /srv/reports/settings.conf.orig
sudo sed -i 's/^debug = true/debug = false/' /etc/webapp/settings.conf
sudo sed -i '/^#/! s/old-server\.local/web01.local/g' /etc/webapp/settings.conf
```

Önce orijinali sakla. `^debug` yorumdaki `#debug` ile eşleşmez, yalnız etkin
satırı kapatır. `/^#/!` seçicisi `#` ile başlayan yorum satırlarını **dışlar**;
değişiklik yalnız etkin satırlarda olur, yorumlar birebir korunur. Global
`sed 's/old-server.local/.../g'` kullansaydın yorumları da bozardın → FAIL.

## 7. Sunucu listesini temizle

```bash
grep -vE '^[[:space:]]*$' /etc/webapp/hosts.list | grep -v '^#' \
    > /srv/reports/hosts-clean.txt
```

İlk `grep -v` boş/boşluk-only satırları atar, ikinci `grep -v '^#'` yorum
satırlarını atar. `db01.local  # primary db` gibi satır başı `#` olmayanlar
kalır; içerik ve sıra değişmez.

## Doğrula

Host'tan: `labctl check 004` — yedi kriterin hepsi `[OK]` basmalı.
