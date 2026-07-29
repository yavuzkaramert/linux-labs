# Çözüm — Lab 008: Bağlantılar, FHS ve Arşivleme

Önce kendin dene. Bu dosya gerekçe kâğıdıdır: hangi komutun neden o
komut olduğu, hangi kısayolun hangi kriteri düşürdüğü yazıyor.

Lab shell'i içinde çalıştır: `labctl shell 008`.

## 1. FHS'e taşıma

```bash
sudo mkdir -p /var/log/myapp /etc/myapp
sudo mv ~/uygulama.log /var/log/myapp/
sudo mv ~/myapp.conf   /etc/myapp/
sudo mv ~/backup-helper /usr/local/bin/
sudo chmod +x /usr/local/bin/backup-helper
```

**Neden bu üç dizin.** FHS keyfi bir gelenek değil, belgelenmiş bir
standart — `man hier` ile sisteminde de okuyabilirsin:

| dizin | ne için | neden burası |
|---|---|---|
| `/var/log` | boyutu zamanla değişen, makineye özgü değişken veri | log büyür, yedeklenmez, `/var` bunun için ayrılmıştır |
| `/etc` | makineye özgü statik yapılandırma | derlenmiş bir şey değil, elle düzenlenir, makineye aittir |
| `/usr/local/bin` | yerel olarak kurulmuş, paket yöneticisine ait olmayan çalıştırılabilirler | `/usr/bin` dağıtımın alanıdır; senin script'in dnf'in kaydında yok |

**`mv`, `cp` değil.** Kriterler eski konumda dosya kalmamasını istiyor —
üçünün de negatif testi var. `cp` yapıp sonra silmek de aynı sonucu
verir ama iki adımdır ve ikincisini unutmak kolaydır. Taşımak tek
işlemdir.

**`chmod +x` ayrı bir adım.** Doğru dizine koymak dosyayı
çalıştırılabilir yapmaz; çalıştırılabilirlik dizinin değil dosyanın
özelliğidir. `/usr/local/bin` zaten PATH'te olduğu için izin bitini
verdiğin anda `backup-helper` adıyla, yol yazmadan çağrılır. Çalıştırmak
için `sudo` GEREKMEZ; gerekiyorsa `+x` atmayı unutmuşsundur.

## 2. Hangisi hard link, hangisi bağımsız kopya

```bash
mkdir -p ~/cevaplar
ls -li /srv/backup-kaynagi
stat -c '%i %h %n' /srv/backup-kaynagi/*
```

Çıktıda ilk sütun inode numarasıdır. `kaynak1.txt` ile
`kaynak1-yedek.txt` **aynı numarayı** taşır ve link sayıları 2'dir;
`kaynak2.txt` ile `kaynak2-kopya.txt` farklı numara taşır, link sayıları
1'dir.

Tuzağın çalıştığı yer burası — içerik karşılaştırması hiçbir şey
söylemez:

```bash
diff /srv/backup-kaynagi/kaynak2.txt /srv/backup-kaynagi/kaynak2-kopya.txt
echo $?          # 0 — fark yok
diff /srv/backup-kaynagi/kaynak1.txt /srv/backup-kaynagi/kaynak1-yedek.txt
echo $?          # 0 — fark yok
```

İkisi de "aynı" der, çünkü sorduğun soru içerikti. Sorman gereken soru
kimlikti: **aynı içerik ≠ aynı dosya.** Bir dosyanın kimliği inode
numarasıdır; ad yalnızca dizin içinde o numaraya işaret eden bir
kayıttır. Hard link ikinci bir kayıt açar, veri tektir. `cp` yeni bir
nesne üretir, iki veri vardır.

Bir dosyanın başka isimlerinin nerede olduğunu da sorabilirsin:

```bash
find /srv/backup-kaynagi -samefile /srv/backup-kaynagi/kaynak1.txt
```

Cevabı yaz:

```bash
cat > ~/cevaplar/baglanti-raporu.txt <<'EOF'
kaynak1-yedek.txt hardlink
kaynak2-kopya.txt bagimsiz
EOF
```

## 3. Yeni bağlantılar

```bash
ln    /srv/backup-kaynagi/kaynak3.txt ~/kaynak3-hardlink.txt
ln -s /srv/backup-kaynagi/kaynak3.txt ~/kaynak3-symlink.txt
```

Tek bayrak iki farklı nesne üretir:

| | hard link (`ln`) | symlink (`ln -s`) |
|---|---|---|
| ne saklar | doğrudan aynı inode'u | hedefin yol metnini |
| inode | kaynakla aynı | kendine ait, ayrı |
| kaynak silinirse | veri durur, link sayısı düşer | bağlantı kırılır (dangling) |
| dosya sistemi sınırı | aşamaz | aşar |
| dizine kurulabilir mi | hayır | evet |

`ls -l ~` çıktısında symlink `->` ile hedefini gösterir, hard link
gösteremez — çünkü gösterecek bir "hedefi" yoktur, kendisi zaten o
dosyadır.

```bash
readlink    ~/kaynak3-symlink.txt   # sakladığı metin
readlink -f ~/kaynak3-symlink.txt   # zincirin sonundaki gerçek yol
stat -c '%i %n' ~/kaynak3-hardlink.txt /srv/backup-kaynagi/kaynak3.txt
```

**Symlink hedefi neden mutlak yazıldı.** Göreli hedef, bağlantının
bulunduğu dizine göre çözülür. `~` altında duran bir bağlantıya
`kaynak3.txt` diye göreli hedef yazsan `/home/student/kaynak3.txt`
aranır ve bağlantı doğduğu anda kırık olur.

**Neden student bu hard link'i kurabiliyor.** Kernel'de
`fs.protected_hardlinks=1` açıktır: kendine ait olmayan ve yazma iznin
bulunmayan bir dosyaya hard link kuramazsın. Bu labda kaynak dosyaların
sahibi student, o yüzden çalışır. Sunucuda root'a ait bir dosyaya link
kurmayı denediğinde alacağın hata bundandır — izin hatası dosyanın
okunabilirliğiyle ilgili değildir.

## 4. Gerçek disk kullanımı

```bash
du -s /srv/backup-kaynagi                    # gerçek kullanım
du -s --apparent-size /srv/backup-kaynagi    # görünen boyut toplamı
du -a /srv/backup-kaynagi                    # dosya dosya
```

`du` blok kullanımını sayar ve **aynı inode'u bir kez** sayar. Dizinde
5 ad var ama 4 nesne: `kaynak1-yedek.txt` diskte yeni yer kaplamaz.
`ls -l` çıktısındaki boyutları toplarsan hard link'i ikinci kez sayarsın
ve fazla bir sayı bulursun. check tam olarak bu sayıyı tanır ve FAIL
mesajında adıyla söyler.

`--apparent-size` içerik uzunluğunu, bayraksız koşu diskte ayrılmış
blokları raporlar; buradaki 254 ile 260 farkı blok yuvarlamasından gelir.
Dikkat: `du` **iki kipte de** aynı inode'u bir kez sayar, yani hard link
farkını görmek için `du`'yu `du` ile değil, `du`'yu `ls -l` boyut
toplamıyla karşılaştırman gerekir. Fazla sayan taraf her zaman "adları
toplayan" taraftır.

```bash
du -s /srv/backup-kaynagi | cut -f1 > ~/cevaplar/disk-kullanimi.txt
cat ~/cevaplar/disk-kullanimi.txt
```

`du -sh` yazma: `h` birim harfi ekler (`260K`), görev yalnız sayı
istiyor. `cut -f1` ilk alanı alır — `du` çıktısı sekme ile ayrılmıştır.

## 5. Arşivleme

```bash
tar -czf /srv/backup/data-yedek.tar.gz -C /srv --exclude='data/gecici' data
```

Bayraklar: `c` yaratma, `z` gzip, `f` arşiv dosyasının adı. `f`'ten
hemen sonra dosya adı gelir — sıra pazarlık konusu değildir.

**`-C /srv ... data` neden.** `-C` önce o dizine geçer, sonra kaynağı
okur. Böylece arşiv içindeki yollar `data/...` olur. Doğrudan
`/srv/data` yazsaydın `tar` mutlak yolun baştaki `/` işaretini atardığını
söyleyen bir uyarı basar ve arşiv `srv/data/...` diye açılırdı. Arşivi
nereye açacağını **açan** kişi seçmelidir; arşiv mutlak yol taşımaz.

**`--exclude` kalıbı neye göre değerlendirilir.** Arşive yazılacak yol
adına göre. `-C /srv` ile başladığın için yollar `data/` ile başlar, o
yüzden kalıp `data/gecici`. Kalıp tırnak içinde yazılır ki joker
kullandığında kabuk onu önce genişletmesin.

**Dizini silmek çözüm değil.** `rm -rf /srv/data/gecici` yapıp sonra
arşivlemek de aynı arşivi üretir ama 11. kriter düşer: arşivleme kaynağı
değiştirmez. Yedek almanın anlamı budur.

## 6. Açmadan doğrulama

```bash
tar -tzf /srv/backup/data-yedek.tar.gz
tar -tzf /srv/backup/data-yedek.tar.gz | grep 'kalici/onemli.txt'
tar -tzf /srv/backup/data-yedek.tar.gz | grep 'gecici'   # çıktı yok, kod 1
echo $?
```

`t` listeleme kipidir; arşivi diske açmaz, yalnız içindekilerin adlarını
basar. Bir yedeğin doğruluğunu sınamak için onu açmak zorunda değilsin —
ve üretimde açmamalısın da; açmak var olan dosyaların üstüne yazabilir.

`grep`'in çıkış kodu burada da cevaptır, hata değil: eşleşme yoksa 1
döner ve bu "gecici arşivde yok" demektir (007a'daki ders).

```bash
cat > ~/cevaplar/arsiv-dogrulama.txt <<'EOF'
kalici/onemli.txt var
gecici/silinecek.txt yok
EOF
```

## Kontrol

```bash
ls -li /srv/backup-kaynagi ~            # inode'lar
du -s /srv/backup-kaynagi               # cevapla karşılaştır
tar -tzf /srv/backup/data-yedek.tar.gz  # arşiv listesi
./labctl check 008                      # host terminalinden
```
