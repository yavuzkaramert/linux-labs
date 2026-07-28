# Çözüm — Lab 007b: Regex, Normalleştirme ve Rapor

Önce kendin dene. Bu dosya gerekçe kâğıdıdır. Her kalıbın neden o kalıp
olduğu, hangi eksiğin hangi satırı yanlış sınıflandırdığı yazıyor.

## 0. Dosyaya bak

```bash
less /srv/raw/merged.log
```

Üç şey göreceksin: iki tarih biçimi, ayırıcı çevresinde rastgele
boşluklar, ve hiçbir biçime uymayan satırlar. Sırayla ele alınacaklar —
normalleştirme önce, sınıflandırma sonra. Ters sırada yapılırsa yalnız
boşluk yüzünden düşen satırları "bozuk" sayarsın.

## 1. Normalleştirme

```bash
sed -E -e 's#([0-9]{2})/([0-9]{2})/([0-9]{4})#\3-\2-\1#g' \
       -e 's#[[:space:]]*\|[[:space:]]*#|#g' \
       /srv/raw/merged.log > /srv/work/normal.log
```

**Yakalama grubu.** `([0-9]{2})/([0-9]{2})/([0-9]{4})` üç parça yakalar:
gün, ay, yıl. Değiştirme tarafında `\3-\2-\1` ile sırası değiştirilerek
geri yazılır. Parçalar silinmiyor, yer değiştiriyor — bunu yapmanın tek
yolu yakalayıp geri çağırmaktır.

**BRE ve ERE farkı.** `-E` verdim, o yüzden parantezler ve `{2}` çıplak
yazıldı. `-E` olmadan aynı kalıp şöyle yazılır:

```bash
sed 's#\([0-9]\{2\}\)/\([0-9]\{2\}\)/\([0-9]\{4\}\)#\3-\2-\1#g'
```

Aynı iş, okunmaz. 004 debrief'indeki not tam buydu: `sed`'de `(a|b)`
literal, `grep -E`'de alternatif. İki farklı lehçe var —

| | BRE (varsayılan sed) | ERE (`sed -E`, `grep -E`) |
|---|---|---|
| grup | `\(...\)` | `(...)` |
| tekrar | `\{2\}` | `{2}` |
| alternatif | `\|` | `|` |
| geri çağırma | `\1` | `\1` (ikisinde de) |

— ve karar basittir: **her yerde `-E` kullan.** `grep -E` ile `sed -E`
aynı ağzı konuşur, kalıbı bir araçtan diğerine kopyalarken çevirmen
gerekmez.

**Ayırıcı seçimi.** `s#...#...#` yazdım, `s/.../.../` değil. Kalıpta `/`
karakteri var (tarihler); ayırıcı olarak da `/` seçseydin her birini
kaçırmak zorunda kalırdın (`\/`). `sed`'in `s` komutunda ayırıcı serbesttir;
kalıpta geçmeyen bir karakter seç, kaçış çöplüğü ortadan kalkar.

**Boşluk temizleme.** `[[:space:]]*\|[[:space:]]*` → `|`. Her iki tarafta
`*` var (sıfır veya daha fazla), yani boşluğu olmayan ayırıcılar da
eşleşir ve kendileriyle değiştirilir — zararsız. `\|` burada **literal boru
karakteri**dir; ERE'de çıplak `|` alternatif operatörü olurdu ve kalıp
"boşluk VEYA boşluk" anlamına gelip her şeyi bozardı.

Satır sırası ve sayısı korunuyor: `sed` satır satır çalışır, satır eklemez
silmez.

## 2. Sınıflandırma

```bash
ERE='^[0-9]{4}-[0-9]{2}-[0-9]{2}\|(INFO|WARN|ERROR)\|([0-9]{1,3}\.){3}[0-9]{1,3}\|[^|]+$'

grep -E  "$ERE" /srv/work/normal.log > /srv/work/valid.log
grep -Ev "$ERE" /srv/work/normal.log > /srv/work/invalid.log
```

Kalıbı bir değişkene aldım ve iki kez kullandım. `-v` eşleşmeyenleri basar.
İki dosya **aynı** kalıptan üretildiği için toplamları normal.log'a eşit
olmak zorunda; iki ayrı kalıp yazsan bu garanti kaybolur.

Kalıbın parçaları ve her birinin hangi satırı düşürdüğü:

| parça | ne der | olmazsa ne olur |
|---|---|---|
| `^` | satır burada başlar | `parse hatasi: 2026-07-20|ERROR|...` geçerli sayılır |
| `[0-9]{4}-[0-9]{2}-[0-9]{2}` | tarih tam bu biçimde | — |
| `\|` | literal ayırıcı | çıplak `|` alternatif olur, kalıp dağılır |
| `(INFO|WARN|ERROR)` | seviye bu üçünden biri | `TRACE` ve küçük harf `error` geçer |
| `([0-9]{1,3}\.){3}` | üç kez "sayı nokta" | `10.0.5` geçer (üç oktet) |
| `[0-9]{1,3}` | dördüncü sayı | `10.0.0.9999` geçer (dört hane) |
| `[^|]+` | mesaj boş değil ve ayırıcı içermez | beş alanlı satır geçerli sayılır |
| `$` | satır burada biter | mesajdan sonrası serbest kalır |

### Çapa neden pazarlık konusu değil

Dosyada bu iki satır var:

```
parse hatasi: 2026-07-20|ERROR|10.0.3.7|disk full
orphan kayit -> 2026-07-22|WARN|10.0.4.1|latency spike
```

İçlerinde kusursuz bir kayıt gömülü. `^` olmadan yazılmış bir kalıp bunları
geçerli sayar — ve haklıdır: sorduğun soru "bu satırda böyle bir şey var mı"
oldu. Sorman gereken soru "bu satır baştan sona bu mu" idi. `^` ve `$`
çifti sorunun kapsamını değiştirir; süs değildir.

Aynı mantık öteki uçta:

```
2026-07-08|ERROR|10.0.1.9|disk pressure on node two|extra-column
2026-07-24|INFO|10.0.4.6|backup finished|0
```

Mesaj alanını `.+$` yazsan bu satırlar geçer, çünkü `.` boru karakterini de
kapsar — yani "dört alan" değil "en az dört alan" demiş olursun.
`[^|]+$` "ayırıcı içermeyen, boş olmayan bir kuyruk" der. Karakter sınıfının
içindeki `^` olumsuzlamadır; dışındaki `^` çapadır. Aynı işaret, iki farklı
iş — bağlam belirler.

### `|` karakterinin iki rolü

| yazım | bağlam | anlamı |
|---|---|---|
| `\|` | ERE, kaçırılmış | literal boru karakteri |
| `|` | ERE, çıplak | alternatif ("veya") |
| `|` | karakter sınıfı içinde (`[^|]`) | literal — sınıf içinde kaçış gerekmez |
| `|` | kabukta, tırnaksız | boru hattı — kalıbı **tek tırnak** içine al |

Kalıbı tek tırnakla yazdım; çift tırnak ya da tırnaksız yazsan kabuk `|`'ı
boru hattı sanar ve komut satırı kırılır.

Oktet aralığı (0-255) **kontrol edilmiyor**: TASK "dört sayıdan oluşan bir
IPv4 adresi" diyor, fazlasını istemiyor. Bu yüzden geçersiz IP'ler dört
haneli oktet ve eksik oktet olarak seçildi — kalıbın gerçekten sınadığı
şeyler.

## 3. Özet

```bash
awk -F'|' '
    { n[$2]++
      if (!(($2, $3) in seen)) { seen[$2, $3] = 1; u[$2]++ } }
    END { for (lv in n) print lv, n[lv], u[lv] }
' /srv/work/valid.log > /srv/work/ozet.txt
```

**İlişkisel dizi.** `n[$2]++` — anahtar seviye adı, değer sayaç. awk dizisi
anahtarı string olabilen bir haritadır; önceden tanımlamaya, boyut vermeye
gerek yok. Olmayan anahtar `++` ile ilk kez dokunulduğunda 0'dan başlar.

**Tekil sayım.** Tekil IP saymanın işi hafıza tutmaktır: gördüğün her
`(seviye, ip)` çiftini `seen`'e yaz; ilk kez görüyorsan o seviyenin tekil
sayacını arttır. `($2, $3) in seen` iki anahtarı awk'ın `SUBSEP`
değişkeniyle birleştirir — çok boyutlu dizinin deyimsel hâli.

Alternatif, `length()` ile:

```bash
awk -F'|' '{n[$2]++; ip[$2 SUBSEP $3] = 1}
           END {for (lv in n) {
                    c = 0
                    for (k in ip) if (index(k, lv SUBSEP) == 1) c++
                    print lv, n[lv], c } }' /srv/work/valid.log
```

Çalışır, gereksiz. `length(dizi)` tek boyutlu bir sayımda daha temizdir:

```bash
awk -F'|' '$2 == "ERROR" {ip[$3] = 1} END {print length(ip)}' \
    /srv/work/valid.log
```

**`END` bloğu** girdi bittikten sonra bir kez çalışır. Sayaçları satır satır
basamazsın — toplamı ancak dosya bittiğinde bilirsin.

### Tuzak: alanı değil satırı okumak

Bu üç satır **geçerli** ve mesajlarında seviye adı ile IP geçiyor:

```
2026-07-06|WARN|10.0.1.21|retry to 10.0.0.17 after ERROR
2026-07-06|ERROR|10.0.2.31|peer 10.0.1.24 returned WARN twice
2026-07-13|INFO|10.0.0.13|failover from 10.0.2.33 logged as ERROR
```

Sonuçları:

```bash
grep -c ERROR /srv/work/valid.log                    # fazla sayar
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' valid.log |
    sort -u | wc -l                                  # fazla sayar
```

Birinci komut WARN ve INFO satırlarını da ERROR'a yazar. İkincisi mesajdaki
IP'leri de tekil listeye katar. İkisi de doğru komut, yanlış soru:
seviye **2. alandır**, ip **3. alandır**. `awk -F'|'` bunu bilir, `grep`
bilmez.

Bu 004 ve 005'ten sarkan aynı ders, üçüncü kez: **seçmediğin sütunu
süzemezsin.** 007a'da alan-temelli süzmeyle karşılaştın, burada
alan-temelli **sayma** var.

## 4. report.conf

```bash
vi /etc/labs/report.conf
```

`sudo` yok: dosya `0664 root:student`, sen student grubundasın, yazma
iznin var. `ls -l` ile bak, sudo'ya uzanmadan önce izni oku — 001 ve
006'da iki kez root'a kaçıldı.

vi içinde:

```
:g/^#/d
:%s#/opt/eski#/srv/work#g
```

Sonra `retention` satırına gel ve `90`'ı `30` yap (tek satır, elle).
`:wq` ile kaydet.

`:g/^#/d` — `^` şart. Dosyada bu satır var:

```
subject_prefix = nightly # rapor konusu bu onekle baslar
```

`:g/#/d` yazarsan bu satır da gider ve 12. kriter düşer. `^` "satırın
başında" der.

`:%s#/opt/eski#/srv/work#g` — ayırıcı olarak `/` yerine `#` seçildi, çünkü
değiştirilecek metnin kendisi `/` içeriyor; `/` ayırıcıyla yazsan her birini
kaçırmak zorunda kalırdın (`:%s/\/opt\/eski/\/srv\/work/g`). `sed`'de olduğu
gibi vi'da da `:s` ayırıcısı serbesttir.

Sondaki `g` şart:

```
tmp_dir = /opt/eski/tmp ve yedegi /opt/eski/tmp2
```

Bu satırda iki geçiş var. `g` olmadan yalnız ilki değişir. check geçiş
sayısını sayıyor, satır sayısını değil — eksik `g` buradan yakalanır.

`retention` neden toplu düzenlemeyle değil elle: tek bir satırda tek bir
değer. Toplu düzenleme 6 yorum satırı ve 5 yol geçişi için kazançlı, tek
karakter için değil. Aracı işin boyuna göre seç.

`sed -i` ile üçünü birden yapmak da olur:

```bash
sed -i -E -e '/^#/d' \
          -e 's#/opt/eski#/srv/work#g' \
          -e 's#^(retention[[:space:]]*=[[:space:]]*)[0-9]+#\130#' \
          /etc/labs/report.conf
```

## 5. mkreport

```bash
sudo vi /usr/local/bin/mkreport
sudo chmod 755 /usr/local/bin/mkreport
```

İçeriği:

```bash
#!/usr/bin/env bash
# Gece raporu. Cikis kodu alarm sistemi icin: 0 = CLEAN, 1 = DIRTY.
set -u

RAW=/srv/raw/merged.log
WORK=/srv/work
REPORT=/srv/reports/text-report.txt
ERE='^[0-9]{4}-[0-9]{2}-[0-9]{2}\|(INFO|WARN|ERROR)\|([0-9]{1,3}\.){3}[0-9]{1,3}\|[^|]+$'

# 1. Normallestirme
sed -E -e 's#([0-9]{2})/([0-9]{2})/([0-9]{4})#\3-\2-\1#g' \
       -e 's#[[:space:]]*\|[[:space:]]*#|#g' "$RAW" > "$WORK/normal.log"

# 2. Siniflandirma
grep -E  "$ERE" "$WORK/normal.log" > "$WORK/valid.log"
grep -Ev "$ERE" "$WORK/normal.log" > "$WORK/invalid.log"

# 3. Ozet
awk -F'|' '
    { n[$2]++
      if (!(($2, $3) in seen)) { seen[$2, $3] = 1; u[$2]++ } }
    END { for (lv in n) print lv, n[lv], u[lv] }
' "$WORK/valid.log" > "$WORK/ozet.txt"

# Durum TEK kaynaktan turetilir: atilan satir sayisi.
dropped=$(wc -l < "$WORK/invalid.log")
if [ "$dropped" -gt 0 ]; then
    status=DIRTY
    rc=1
else
    status=CLEAN
    rc=0
fi

# Rapor her kosuda sifirdan uretilir: `>` kullanilir, `>>` degil.
{
    echo "$status"
    echo "--- ozet (seviye toplam tekil_ip) ---"
    cat "$WORK/ozet.txt"
    echo "--- atilan satir: $dropped ---"
} > "$REPORT"

exit "$rc"
```

### Neden bu yapı

**Tek kaynak.** `dropped` bir kez hesaplanır; `status` ve `rc` ikisi de
ondan türer. Alternatif — ilk satırı bir koşulla, `exit`'i başka bir koşulla
yazmak — bugün çalışır, yarın biri koşullardan birini değiştirince rapor
"CLEAN" derken script 1 döner. Alarm sistemi metni okumuyor, kodu okuyor;
ikisi ayrışırsa yanlış şeye bakar. 006'daki `report` sözleşmesi tam olarak
budur ve burada tekrar ediliyor.

**`>` ve `>>`.** Blok tek bir `>` ile yönlendirildi. `>>` yazsan rapor her
gece büyür ve ilk satır ilk koşunun durumu olarak kalır — yani DIRTY olduğu
gün CLEAN yazan bir rapor. check bu yüzden iki koşu karşılaştırıyor.

**`{ ...; } > dosya`.** Beş komutun çıktısı tek yönlendirmeyle gider. Her
satırı ayrı ayrı `>>` ile eklemek de olur ama ilkini `>` yapmayı unutmak
tam olarak yukarıdaki hatadır. Blok, o hatayı yapmayı imkânsız kılar.

**`chmod 755` ve sudo.** Script'i `/usr/local/bin` altına yazmak `sudo`
ister (dizin root'un). Çalıştırmak istemez: `755` herkese `x` verir.
`sudo mkreport` ile çalıştırmak zorunda kalıyorsan `chmod +x` atmayı
unuttun. 006'da bu refleks üç dakika kaybettirdi; iki kere olmasın.

**`set -e` yok.** Bilinçli: `grep -Ev` hiç eşleşme bulamazsa (temiz kaynak
durumu) 1 döner ve `set -e` script'i tam orada öldürürdü. CLEAN yolu hiç
çalışmazdı. 007a'nın 4. görevindeki ders burada bir tuzağa dönüşüyor:
`grep`'in çıkış kodu "hata" değil "cevap"tır, ama `set -e` ikisini
ayırt etmez.

## Kontrol

```bash
mkreport; echo $?          # DIRTY → 1
head -1 /srv/reports/text-report.txt
./labctl check 007b        # host terminalinden
```

`echo $?` alışkanlığı burada da geçerli: script'in sözleşmesini kabukta
gözlemeden "yazdım" deme.
