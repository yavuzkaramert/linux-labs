# Hints — Lab 008: Bağlantılar, FHS ve Arşivleme

## Seviye 1

Kavramsal. Komut adı yok.

- Bir dosyanın kimliği adı değildir. Ad, dizin içinde bir kayıttır ve
  gerçek nesneyi işaret eder. Aynı nesneyi işaret eden iki ad olabilir;
  bu durumda "iki dosya" yoktur, tek dosya ve iki isim vardır.
- İçeriği karşılaştırmak kimliği karşılaştırmaz. Aynı içeriğe sahip iki
  bağımsız dosya da, tek dosyanın iki ismi de içerik olarak birebir
  aynıdır. Ayırt eden şey nesnenin kendi numarasıdır.
- İki tür bağlantı var: biri doğrudan aynı nesneyi gösterir, diğeri bir
  yol metnini saklar ve o yola gider. Birincisinde asıl adı silsen bile
  veri durur; ikincisinde hedef gidince bağlantı boşluğa bakar.
- Diskte yer kaplayan şey ad değil nesnedir. Aynı nesnenin ikinci ismi
  yeni yer kaplamaz — bu yüzden "görünen boyutların toplamı" ile
  "diskte gerçekten kullanılan yer" aynı sayı olmak zorunda değildir.
- Sistemin dizin düzeni keyfi değil, bir standarda dayanır: değişken
  veri, makineye özel yapılandırma ve yerel olarak kurulmuş çalıştırılabilir
  dosyalar ayrı yerlerde durur. Hangi dizinin ne için olduğunu bilmek
  gerekir; bu standart belgelenmiştir, sisteminde de yazılıdır.
- Bir dosyanın çalıştırılabilir olması yerine değil, üzerindeki izin
  bitine bağlıdır. Doğru dizine koymak tek başına yetmez.
- Bir arşivin içinde ne olduğunu öğrenmek için onu açmak gerekmez.
  Arşiv, içindekilerin listesini kendi içinde taşır.
- Bir şeyi arşivin dışında bırakmak ile onu diskten silmek farklı
  işlerdir. Görev birincisini istiyor; ikincisini yaparsan kaynak
  değişmiş olur.

## Seviye 2

Araç adları. Bayrak yok.

- İlgili araçlar: mkdir, mv, chmod, ln, ls, stat, readlink, find, du,
  tar, cat.
- Görev 1 mkdir + mv + chmod işi. Hedef dizinler root'un alanında, o
  yüzden yetki gerekecek.
- Görev 2 ve 3'ün merkezinde ln ve stat var. ln'in iki çalışma kipi
  vardır; hangi kipte olduğunu bir bayrak belirler.
- stat bir dosyanın adının arkasındaki metaveriyi basar: numarası, kaç
  ismi olduğu, kaç blok tuttuğu. ls de bu bilgilerin bir kısmını
  gösterebilir.
- Sembolik bağlantının sakladığı yol metnini okuyan ayrı bir komut var.
- Görev 4 du işi. du'nun ölçtüğü şey ile ls'in gösterdiği şey aynı
  değildir; du'nun bu ayrımı açıkça anlatan bir bayrağı da vardır.
- Görev 5 ve 6 tar işi. tar'ın üç temel kipi var: yaratma, listeleme,
  çıkarma. Görev 6 çıkarma kipini KULLANMAZ.
- Okunacak man sayfaları: man ln, man stat, man du, man tar, man
  hier (dizin düzeni standardı burada anlatılıyor), man 7 symlink.

## Seviye 3

Bayrak ve parametre düzeyi. Tam komut yok.

- ln bayraksız çağrıldığında hard link kurar; -s verildiğinde sembolik
  bağlantı kurar. Sembolik bağlantıda hedefi mutlak yol yazmak, göreli
  yazmaktan daha az sürpriz üretir: bağlantı taşınırsa göreli hedef
  bozulur.
- stat -c ile hangi alanın basılacağını sen seçersin: %i inode numarası,
  %h link sayısı, %s görünen boyut, %b ayrılan 512 baytlık blok sayısı.
  İki dosyanın aynı nesne olup olmadığı tek satırda böyle görülür.
- ls -i inode numarasını gösterir, ls -l çıktısındaki ikinci sütun link
  sayısıdır. Link sayısı 1'den büyükse o nesnenin başka ismi de var
  demektir — ama nerede olduğunu söylemez; onu find -samefile ya da
  find -inum bulur.
- readlink bağlantının sakladığı metni basar; -f verirsen zinciri sonuna
  kadar çözüp gerçek hedefin mutlak yolunu verir.
- du -s bir dizin için tek toplam basar, -h insan okunur birim verir
  (ama görev yalnız sayı istiyor, birim harfi istemiyor). du varsayılan
  olarak KB cinsinden çalışır ve aynı inode'u bir kez sayar.
  --apparent-size bayrağı ölçüyü gerçek kullanımdan görünen boyuta
  çevirir; iki koşuyu karşılaştırmak farkı gözünle görmenin en kısa
  yolu.
- tar'da c yaratma, t listeleme, x çıkarma; f arşiv dosyasının adını
  alır, z gzip sıkıştırmasını devreye sokar, v ne olup bittiğini basar.
  Bayrakların sırası f'ten sonra dosya adının gelmesini gerektirir.
- tar --exclude bir kalıp alır ve bu kalıp arşive YAZILAN yol adıyla
  karşılaştırılır. Yani hangi dizinden başladığın kalıbı da belirler;
  --exclude'u kaynak yolundan önce yazmak alışkanlık hâline getirilir.
- tar -C önce belirtilen dizine geçer, sonra kaynağı okur. Arşiv içindeki
  yolları kısaltmanın ve mutlak yol uyarısından kurtulmanın yolu budur.
- Arşivi doğrulamak listeleme kipinde tek satırdır; çıktı satır satır
  yol adıdır ve grep ile aranabilir.
