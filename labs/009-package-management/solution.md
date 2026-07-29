# Solution — Lab 009: Paket Yönetimi

Aşağıdaki komutlar `student` olarak çalıştırılır. Sistemi değiştiren
işlemler (kurulum, depo etkinleştirme, geri alma) `sudo` ister; sorgular
istemez.

```bash
mkdir -p ~/cevaplar
```

## Görev 1 — Dosya → paket → dosya listesi

```bash
rpm -qf /usr/bin/tree                       # dosya kimin: tree
rpm -qf --qf '%{NAME}\n' /usr/bin/tree > ~/cevaplar/paket-sorgu.txt
rpm -ql tree                               >> ~/cevaplar/paket-sorgu.txt
```

`rpm -qf` bir DOSYADAN pakete gider, `rpm -ql` PAKETTEN dosyalarına.
`--qf '%{NAME}\n'` sürüm/mimari eklerini kırpar; çıplak `rpm -qf`
`tree-2.1.0-8.el10.aarch64` gibi tam NEVRA basar (check ikisini de kabul
eder).

## Görev 2 — Bütünlük doğrulama

```bash
rpm -qf /etc/vimrc          # vim-common-9.1.083-9.el10_2.7.aarch64
rpm -V vim-common           # SM5....T.  c /etc/vimrc
```

Önce dosyanın paketini bulmak, `rpm -Va` ile tüm sistemi taramaktan hem
hızlı hem gürültüsüzdür (`-Va` çıktısında container'a özgü onlarca
normal fark da vardır).

Çıktının okunuşu: `S` boyut, `M` izin/mod, `5` içerik özeti, `T` mtime
değişmiş. Baştaki `c` dosyanın bir yapılandırma dosyası olduğunu söyler.
Yani hem içerik hem izin bozulmuş:

```bash
printf '%s\n' 'paket vim-common' 'dosya /etc/vimrc' 'degisen icerik,izin' \
    > ~/cevaplar/butunluk-raporu.txt
```

Not: `/etc/vimrc` `vim-enhanced`'a değil `vim-common`'a aittir —
`rpm -V vim-enhanced` bu dosya için hiçbir şey basmaz. Paketi tahmin
etmek yerine dosyaya sormak tam olarak bu yüzden gerekli.

## Görev 3 — Eksik komut → sağlayan paket

```bash
command -v lsof             # ciktisi bos: komut yok
dnf provides lsof           # lsof-4.98.0-7.el10.aarch64 ... Repo: baseos
sudo dnf -y install lsof
echo lsof > ~/cevaplar/eksik-komut.txt
lsof -v
```

`dnf provides` depo metaverisine bakar, kurulu olmayan paketleri de
bulur. Tam yol da verilebilir: `dnf provides /usr/bin/lsof`.

## Görev 4 — İşlem geçmişini geri alma

```bash
dnf history list            # islemler, en yeni ustte
dnf history info 5          # "Command Line: -y remove bc"
sudo dnf -y history undo 5
echo "2+2" | hesapla        # 4
```

Aranan işlem `Action(s)` sütununda `Removed` yazan ve komut satırı
`remove bc` olan kayıttır. Id her ortamda aynı olmayabilir; listeden
okunur, ezberlenmez.

`history undo` paketi elle kurmakla aynı şey değildir: geri alınan şey
paket değil İŞLEMDİR. Kaldırma işlemini geri almak paketi (ve o işlemde
kaldırılmış başka paket varsa onları da) geri kurar.

## Görev 5 — .rpm'i kurmadan inceleme

```bash
rpm -qip /srv/paketler/ed-1.20-5.el10.aarch64.rpm    # metaveri
rpm -qlp /srv/paketler/ed-1.20-5.el10.aarch64.rpm    # dosya listesi

{
  rpm -qp --qf 'paket-adi: %{NAME}\nsurum: %{VERSION}\n' /srv/paketler/*.rpm
  echo 'dosyalar:'
  rpm -qlp /srv/paketler/*.rpm
} > ~/cevaplar/rpm-inceleme.txt
```

`-p` soruyu veritabanına değil DOSYAYA yöneltir. Paket kurulmaz;
`rpm -q ed` hâlâ "not installed" demeli.

## Görev 6 — EPEL + crb + dpkg

```bash
sudo dnf -y install epel-release
sudo dnf -y install dpkg
# Error: nothing provides libz-ng.so.2()(64bit) needed by dpkg ... from epel
```

Hata paketin bozuk olduğunu değil, bağımlılığın bulunamadığını söylüyor.
`zlib-ng` Rocky'nin crb (CodeReady Builder) deposunda ve crb varsayılan
olarak KAPALI:

```bash
dnf repolist --all | grep -i crb        # crb ... disabled
sudo crb enable                         # epel-release ile gelen komut
# ya da: sudo dnf config-manager --set-enabled crb
sudo dnf -y install dpkg
```

Sonra .deb kurulmadan incelenir:

```bash
dpkg-deb -I /srv/paketler/ogrenci-arac_1.0_all.deb   # control / metaveri
dpkg-deb -c /srv/paketler/ogrenci-arac_1.0_all.deb   # icerik listesi

{
  echo "paket-adi: $(dpkg-deb -f /srv/paketler/*.deb Package)"
  echo "surum: $(dpkg-deb -f /srv/paketler/*.deb Version)"
  echo 'dosyalar:'
  dpkg-deb -c /srv/paketler/*.deb | awk '$1 !~ /^d/ {print $NF}'
} > ~/cevaplar/deb-inceleme.txt
```

`dpkg-deb -c` çıktısı `tar -tv` biçimindedir: ilk sütun izinler, son
sütun yol. `$1 !~ /^d/` dizin satırlarını eler, geriye dosyalar kalır.
`dpkg-deb -f <dosya> <Alan>` tek bir control alanını basar — `-I`
çıktısını `grep`/`awk` ile ayıklamaktan temizdir.

## Tuzaklar

- `.rpm` ve `.deb` KURULMAZ. `dnf install ./ed-*.rpm` ya da
  `dpkg -i ogrenci-arac_1.0_all.deb` iki kriteri birden düşürür.
- `/srv/paketler` altındaki dosyalar silinmez, değiştirilmez.
- Görev 4 `dnf install bc` ile de "çalışır" görünür ama kriter
  geçmişten geri almayı öğretiyor; `hesapla` çalışsa bile öğrenilen
  şey kaçırılmış olur.
- `rpm -V vim-enhanced` boş döner ve rc 0 verir; yanlış pakete
  sorulduğu için "her şey yolunda" sanılabilir.
