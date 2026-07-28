# Çözüm — Lab 007a: Metin Filtreleri

Önce kendin dene. Bu dosya cevap kâğıdı değil, gerekçe kâğıdıdır: her
komutun neden o komut olduğu yazıyor. Komutu kopyalayıp geçmek labı
boşa harcamaktır.

Tüm komutlar `student` olarak, ev dizininden çalıştırılır. `sudo`
gerekmiyor — cevap dizini senin, notlar dosyası senin.

## 0. Dosyayı önce oku

```bash
less /srv/data/tickets.csv
head -3 /srv/data/tickets.csv
```

Alan sırasını görmeden alan süzemezsin:
`id;tarih;oncelik;durum;atanan;konu` → durum 4., öncelik 3. alan.

Uzun dosyaya `cat` atma. 80 satırlık access.log ekranı süpürür, 8000
satırlık olanı terminali kilitler. `less` sayfalar, `/` ile içinde arama
yapar, `q` ile çıkar. Bu bir alışkanlık meselesi; şimdi kurulur.

## 1. Veri satırı sayısı

```bash
tail -n +2 /srv/data/tickets.csv | wc -l > ~/cevaplar/01-adet.txt
```

`tail -n +2` "2. satırdan itibaren bas" demek — başlığı atar. `-n 2`
ile karıştırma, o **sondan** iki satır verir.

`wc -l /srv/data/tickets.csv` yazsan 61 alırdın: dosyada 61 satır var,
veri 60. Stajyerin hatası tam bu. Boru hattından geçen `wc -l` dosya adı
basmaz, yalnız sayıyı basar — cevap dosyasına giden şeyin temiz olması
bu yüzden bedava geliyor.

## 2. Durumu open olan biletler

```bash
awk -F';' '$4 == "open"' /srv/data/tickets.csv > ~/cevaplar/02-acik.txt
```

`grep open` neden yanlış: `grep` satıra bakar, alana bakmaz. Bu dosyada
beş KAPALI biletin konu alanında `open` geçiyor —

```
T1006;...;closed;mehmet;cannot open config file
T1010;...;closed;mehmet;port 8080 still open after restart
T1017;...;closed;kerem;firewall rule opened for port 443
T1025;...;closed;kerem;ticket left open by mistake
T1037;...;closed;kerem;session left open on kiosk
```

— ve `grep open` 24 satır verir. Doğru cevap 19. Fark tam olarak bu beş
tuzak satırı ve `opened` içindeki `open`.

Alan-temelli süzmenin tek yolu **ayırıcıyı bilen** bir araçtır. `awk -F';'`
dosyayı alanlara böler, `$4` dördüncü alandır, `$4 == "open"` tam eşitlik
arar — `opened` eşleşmez, çünkü karşılaştırma satırda değil alanda.

Gövde yazmadım: awk'ın varsayılan eylemi `{print}`'tir. Koşul doğruysa
satır aynen basılır, sıra bozulmaz — 5. kriter bunu istiyor.

`grep` ile de yapılabilir ama çapa ve alan sayısı elle kurulmak zorundadır:

```bash
grep -E '^[^;]*;[^;]*;[^;]*;open;' /srv/data/tickets.csv
```

Çalışır, okunmaz. Doğru araç awk'tır. Ders: elinde `grep` varken her
problem satır problemi gibi görünür.

## 3. Öncelik dağılımı

```bash
tail -n +2 /srv/data/tickets.csv | cut -d';' -f3 | sort | uniq -c \
    > ~/cevaplar/03-oncelik.txt
```

Dört adım, her biri tek iş yapıyor:

| adım | ne yapar | atlanırsa |
|---|---|---|
| `tail -n +2` | başlığı atar | `oncelik` beşinci bir "öncelik" olur |
| `cut -d';' -f3` | 3. alanı çeker | satırın tamamı tekil olur, hiçbir şey gruplanmaz |
| `sort` | aynıları yan yana getirir | `uniq` yalnız ARDIŞIK tekrarı görür → sessizce yanlış sayar |
| `uniq -c` | grup başına sayar | — |

`sort | uniq -c` neden bu sırada: `uniq` dosyanın tamamını hafızada
tutmaz, yalnız bir önceki satıra bakar. Bu yüzden `low ... normal ...
low` girdisinde `low`'u iki ayrı grup sayar. Hata vermez, yanlış sayar —
sessiz hata, gürültülü hatadan tehlikelidir.

`uniq -c` sayıyı boşluklarla hizalayarak basar (`     12 low`). check bunu
normalleştiriyor, sorun değil. İstersen `awk '{print $1, $2}'` ile
kırpabilirsin.

awk'la tek adımda da olur — 007b'de ilişkisel dizilerle bunu yapacaksın:

```bash
awk -F';' 'NR > 1 {c[$3]++} END {for (p in c) print c[p], p}' \
    /srv/data/tickets.csv
```

## 4. Çıkış kodu

```bash
grep -q DENIED /srv/data/access.log
echo $? > ~/cevaplar/04-kod.txt

grep -q PANIC /srv/data/access.log
echo $? > ~/cevaplar/05-kod.txt
```

`grep -q` hiçbir şey basmaz — ilk eşleşmede durur ve çıkar. Görev "ekrana
hiçbir şey basmamalı" dediği için doğru bayrak budur. `> /dev/null` ile
susturmak da çalışır ama `-q` niyeti söyler ve büyük dosyada daha hızlıdır.

`grep`'in çıkış kodu (`man grep`, EXIT STATUS):

| kod | anlamı |
|---|---|
| 0 | en az bir satır eşleşti |
| 1 | hiç eşleşme yok |
| 2 | hata (dosya yok, okunamıyor, kalıp bozuk) |

Buradaki asıl ders: **çıkış kodu grep'in yan ürünü değil, asıl cevabıdır.**
`-q` verdiğinde geriye başka hiçbir şey kalmaz; tek çıktı o sayıdır. `if`
içindeki `grep`, `&&` ile zincirlenen `grep`, script'in `exit` değeri —
hepsi bu sayıyı okur.

`$?` yalnız **bir önceki** komutun kodunu taşır. Araya `echo`, `ls`, hatta
boş bir `[ ]` girerse değer gider. Bu yüzden iki satır yan yana yazıldı;
`grep`'in hemen ardından `echo $?`.

006'da bu kavram `report` script'inin içine yazıldı — `exit 1` / `exit 0`
sözleşmesi kuruldu, doğru kuruldu. Ama kabukta bir kez bile `echo $?`
yazılmadı, yani sözleşme hiç **gözlenmedi**. Aradaki fark şudur: birinci
durumda kuralı biliyorsun, ikinci durumda kuralın gerçekten öyle
çalıştığını gördün. 007a'nın 4. görevi tam olarak bu boşluk için var.

2 kodunu da bir kez gör, `man`'in doğru söylediğine ikna ol:

```bash
grep -q DENIED /srv/data/yokboyledosya
echo $?          # 2
```

## 5. notlar.txt düzenlemesi

```bash
vi /srv/data/notlar.txt
```

vi içinde, sırayla:

```
:g/^TODO/d
:%s/sunucu1/web01/g
:wq
```

`:g/^TODO/d` — `:g` (global) dosyanın tamamını tarar, kalıba uyan her
satıra sonundaki komutu (`d` = delete) uygular. Beş satır tek komutla gider.

`^` neden şart: dosyada bu satır var —

```
Not: asagidaki maddeler TODO listesinden cikarildi, silmeyin
```

`:g/TODO/d` yazarsan bu satır da silinir ve 12. kriter düşer. `^` "satırın
başında" der; ortadaki eşleşmeyi dışarıda bırakır. Çapa bir süs değil,
kapsam bildirimidir.

`:%s/sunucu1/web01/g` — `%` aralıktır, "tüm dosya" demek (yoksa yalnız
imlecin olduğu satır). Sondaki `g` satır içi kapsamdır. Dosyada bu satır
var —

```
sunucu1 ile sunucu1 arasindaki yedek link test edilmedi
```

`g` olmadan bu satırdaki **ikinci** `sunucu1` olduğu gibi kalır. Toplam
5 geçiş var, 4 satırda; `g` unutulursa 4 tanesi değişir, biri kaçar.
check tam bu farkı ölçüyor: satır sayısı değil, geçiş sayısı sayılıyor.

`%` ve `g` iki farklı kapsamdır ve ikisi de gerekir:

| komut | kapsam |
|---|---|
| `:s/a/b/` | imleç satırı, ilk eşleşme |
| `:s/a/b/g` | imleç satırı, tüm eşleşmeler |
| `:%s/a/b/` | tüm dosya, satır başına ilk eşleşme |
| `:%s/a/b/g` | tüm dosya, tüm eşleşmeler |

`:wq` yaz ve çık. Değişikliği bozduysan `:q!` ile çıkıp `labctl reset 007a`
ile baştan başla — ama o zaman diğer cevapların da gider.

vi yerine `sed -i` ile de yapılabilir:

```bash
sed -i '/^TODO/d; s/sunucu1/web01/g' /srv/data/notlar.txt
```

Aynı iş, aynı çapa, aynı `g`. Kalıp dili ortak; öğrenilen şey editörün
kendisi değil, kalıp ve kapsam kavramı. 007b'de bu ikisini yan yana
kullanacaksın.

## Kontrol

```bash
./labctl check 007a
```

Bir kriter düşerse mesajı oku: beklenen ve gelen değer yazıyor. İkisi
arasındaki fark hangi adımın yanlış olduğunu söyler — dosyayı yeniden
üretmen gereken tek adım o.
