import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../core/settings.dart';
import '../services/yerel_veri_servisi.dart';
import '../models/manga.dart';
import '../anime_module/models/anime_model.dart'; // KRAL: Anime modelini ekledik

class IstatistiklerSayfasi extends StatefulWidget {
  const IstatistiklerSayfasi({super.key});

  @override
  State<IstatistiklerSayfasi> createState() => _IstatistiklerSayfasiState();
}

class _IstatistiklerSayfasiState extends State<IstatistiklerSayfasi> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Manga> _mangaKutuphane = [];
  List<Manga> _mangaSonOkunan = [];
  
  List<Manga> _novelKutuphane = [];
  List<Manga> _novelSonOkunan = [];

  List<AnimeModel> _animeKutuphane = []; // KRAL: Anime eklendi
  List<AnimeModel> _animeSonIzlenen = []; // KRAL: Anime eklendi

  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // KRAL: Sekme sayısı 3 oldu
    _verileriAnalizEt();
  }

  Future<void> _verileriAnalizEt() async {
    _mangaKutuphane = YerelVeriServisi.favorileriGetir(true);
    _novelKutuphane = YerelVeriServisi.favorileriGetir(false);
    
    _mangaSonOkunan = await YerelVeriServisi.sonOkunanlariGetir(true);
    _novelSonOkunan = await YerelVeriServisi.sonOkunanlariGetir(false);

    // KRAL: Anime verilerini yüklüyoruz
    _animeKutuphane = YerelVeriServisi.animeFavorileriGetir();
    _animeSonIzlenen = await YerelVeriServisi.animeSonOkunanlariGetir();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  List<MapEntry<String, int>> _hibritAnaliz(List<Manga> liste1, List<Manga> liste2, bool isManga) {
    Map<String, int> frekans = {};
    var tumu = [...liste1, ...liste2];
    var benzersizler = {for (var m in tumu) m.id: m}.values.toList();

    for (var manga in benzersizler) {
      if (isManga) {
        for (var tur in manga.turler) {
          if (tur == "Manga" || tur == "Yerel") continue;
          frekans[tur] = (frekans[tur] ?? 0) + 1;
        }
      } else {
        bool gecerliTurBulundu = false;
        
        for (var tur in manga.turler) {
          if (tur != "Light Novel" && tur != "Novel" && tur != "Yerel" && tur.trim().isNotEmpty) {
            frekans[tur] = (frekans[tur] ?? 0) + 1;
            gecerliTurBulundu = true;
          }
        }
        
        if (!gecerliTurBulundu) {
          String isim = manga.isim.toLowerCase();
          
          if (isim.contains("level") || isim.contains("system") || isim.contains("rank") || isim.contains("player") || isim.contains("game") || isim.contains("login")) {
            frekans["RPG/Sistem"] = (frekans["RPG/Sistem"] ?? 0) + 1;
          } 
          else if (isim.contains("love") || isim.contains("heroine") || isim.contains("villainess") || isim.contains("wife") || isim.contains("romance") || isim.contains("marriage")) {
            frekans["Romantik"] = (frekans["Romantik"] ?? 0) + 1;
          } 
          else if (isim.contains("martial") || isim.contains("sword") || isim.contains("magic") || isim.contains("demon") || isim.contains("dragon") || isim.contains("god")) {
            frekans["Aksiyon/Fantastik"] = (frekans["Aksiyon/Fantastik"] ?? 0) + 1;
          } 
          else if (isim.contains("return") || isim.contains("reincarnat") || isim.contains("regress") || isim.contains("rebirth") || isim.contains("time")) {
            frekans["İsekai/Zaman Yolculuğu"] = (frekans["İsekai/Zaman Yolculuğu"] ?? 0) + 1;
          } 
          else {
            frekans["Genel Kurgu"] = (frekans["Genel Kurgu"] ?? 0) + 1;
          }
        }
      }
    }

    var siraliListe = frekans.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); 

    return siraliListe.take(5).toList(); 
  }

  // KRAL: Animeye özel hibrit analiz (Kendi kod mantığını birebir animeye uyarladım)
  List<MapEntry<String, int>> _hibritAnalizAnime(List<AnimeModel> liste1, List<AnimeModel> liste2) {
    Map<String, int> frekans = {};
    var tumu = [...liste1, ...liste2];
    var benzersizler = {for (var a in tumu) a.id: a}.values.toList();

    for (var anime in benzersizler) {
      for (var tur in anime.turler) {
        frekans[tur] = (frekans[tur] ?? 0) + 1;
      }
    }

    var siraliListe = frekans.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); 

    return siraliListe.take(5).toList(); 
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.karanlikTemaModu,
      builder: (context, karanlikMi, _) {
        Color bg = karanlikMi ? const Color(0xFF0D0D0D) : Colors.white;
        Color textC = karanlikMi ? Colors.white : Colors.black87;
        Color cardBg = karanlikMi ? const Color(0xFF161616) : Colors.grey[200]!;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textC), 
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "OKUMA & İZLEME ANALİZİ", 
              style: GoogleFonts.bangers(fontSize: 26, color: textC, letterSpacing: 1.5)
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.mangaOrange,
              labelColor: AppColors.mangaOrange,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "MANGA STATS"), 
                Tab(text: "ANİME STATS"), // KRAL: Yeni Sekme
                Tab(text: "NOVEL STATS")
              ],
            ),
          ),
          body: _yukleniyor
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.mangaOrange)
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _istatistikSayfasiOlustur(true, _mangaKutuphane, _mangaSonOkunan, textC, cardBg, AppColors.mangaOrange),
                  _istatistikSayfasiOlusturAnime(_animeKutuphane, _animeSonIzlenen, textC, cardBg, Colors.deepPurpleAccent), // KRAL: Anime Görünümü
                  _istatistikSayfasiOlustur(false, _novelKutuphane, _novelSonOkunan, textC, cardBg, AppColors.novelBlue),
                ],
              ),
        );
      }
    );
  }

  // SENİN YAZDIĞIN ORİJİNAL ÇİZİM VE YAPIN - HİÇBİR ŞEY SİLİNMEDİ
  Widget _istatistikSayfasiOlustur(bool isManga, List<Manga> kutuphane, List<Manga> sonOkunan, Color textC, Color cardBg, Color anaRenk) {
    var enPopulerTurler = _hibritAnaliz(kutuphane, sonOkunan, isManga);
    
    var tumu = [...kutuphane, ...sonOkunan];
    int benzersizEtkilesimSayisi = {for (var m in tumu) m.id: m}.length;
    int bitenSeriSayisi = YerelVeriServisi.bitenSayisiGetir(isManga);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _bilgiKarti("Kütüphane", kutuphane.length.toString(), Icons.library_books, anaRenk, cardBg, textC)
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _bilgiKarti("Aktif Okunan", sonOkunan.length.toString(), Icons.bolt, anaRenk, cardBg, textC)
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _bilgiKarti("Biten Seri", bitenSeriSayisi.toString(), Icons.check_circle_outline, anaRenk, cardBg, textC)
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _bilgiKarti("Okuma Serisi", "${YerelVeriServisi.okumaSerisi} Gün", Icons.local_fire_department, Colors.deepOrangeAccent, cardBg, textC)
              ),
            ],
          ),
          const SizedBox(height: 30),

          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: anaRenk, size: 28),
              const SizedBox(width: 10),
              Text(
                "FAVORİ TÜRLERİN", 
                style: GoogleFonts.bangers(fontSize: 24, color: textC, letterSpacing: 1.2)
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Okuma alışkanlıklarına göre analiz edilmiştir.", 
            style: TextStyle(color: Colors.grey[500], fontSize: 13)
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: anaRenk.withValues(alpha: 0.2)),
            ),
            child: enPopulerTurler.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), 
                      child: Text("Henüz yeterli veri yok.", style: TextStyle(color: textC))
                    )
                  )
                : Column(
                    children: enPopulerTurler.map((entry) {
                      int maxValue = enPopulerTurler.first.value;
                      double percent = entry.value / maxValue;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key, 
                                  style: TextStyle(color: textC, fontWeight: FontWeight.bold, fontSize: 14)
                                ),
                                Text(
                                  "${entry.value} Seri", 
                                  style: TextStyle(color: anaRenk, fontWeight: FontWeight.bold, fontSize: 14)
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  height: 12, 
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.2), 
                                    borderRadius: BorderRadius.circular(10)
                                  )
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: constraints.maxWidth * percent),
                                      duration: const Duration(seconds: 1),
                                      curve: Curves.easeOutQuart,
                                      builder: (context, value, child) {
                                        return Container(
                                          height: 12, 
                                          width: value,
                                          decoration: BoxDecoration(
                                            color: anaRenk,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: anaRenk.withValues(alpha: 0.4), 
                                                blurRadius: 8
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: anaRenk.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: anaRenk.withValues(alpha: 0.3))
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, color: anaRenk, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Sistem, okuduğun $benzersizEtkilesimSayisi farklı eserin meta-verilerini işleyerek okuma profilini oluşturmuştur.", 
                    style: TextStyle(color: textC, fontSize: 12, height: 1.5)
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // KRAL: Yukarıdaki harika orijinal yapını kopyalayıp animeye uyguladık!
  Widget _istatistikSayfasiOlusturAnime(List<AnimeModel> kutuphane, List<AnimeModel> sonIzlenen, Color textC, Color cardBg, Color anaRenk) {
    var enPopulerTurler = _hibritAnalizAnime(kutuphane, sonIzlenen);
    
    var tumu = [...kutuphane, ...sonIzlenen];
    int benzersizEtkilesimSayisi = {for (var a in tumu) a.id: a}.length;
    int bitenSeriSayisi = 0; // İleride eklenebilir

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _bilgiKarti("Kütüphane", kutuphane.length.toString(), Icons.library_books, anaRenk, cardBg, textC)
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _bilgiKarti("Aktif İzlenen", sonIzlenen.length.toString(), Icons.bolt, anaRenk, cardBg, textC)
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _bilgiKarti("Biten Seri", bitenSeriSayisi.toString(), Icons.check_circle_outline, anaRenk, cardBg, textC)
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _bilgiKarti("İzleme Serisi", "${YerelVeriServisi.okumaSerisi} Gün", Icons.local_fire_department, Colors.deepOrangeAccent, cardBg, textC)
              ),
            ],
          ),
          const SizedBox(height: 30),

          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: anaRenk, size: 28),
              const SizedBox(width: 10),
              Text(
                "FAVORİ TÜRLERİN", 
                style: GoogleFonts.bangers(fontSize: 24, color: textC, letterSpacing: 1.2)
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "İzleme alışkanlıklarına göre analiz edilmiştir.", 
            style: TextStyle(color: Colors.grey[500], fontSize: 13)
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: anaRenk.withValues(alpha: 0.2)),
            ),
            child: enPopulerTurler.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), 
                      child: Text("Henüz yeterli veri yok.", style: TextStyle(color: textC))
                    )
                  )
                : Column(
                    children: enPopulerTurler.map((entry) {
                      int maxValue = enPopulerTurler.first.value;
                      double percent = entry.value / maxValue;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key, 
                                  style: TextStyle(color: textC, fontWeight: FontWeight.bold, fontSize: 14)
                                ),
                                Text(
                                  "${entry.value} Seri", 
                                  style: TextStyle(color: anaRenk, fontWeight: FontWeight.bold, fontSize: 14)
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  height: 12, 
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.2), 
                                    borderRadius: BorderRadius.circular(10)
                                  )
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: constraints.maxWidth * percent),
                                      duration: const Duration(seconds: 1),
                                      curve: Curves.easeOutQuart,
                                      builder: (context, value, child) {
                                        return Container(
                                          height: 12, 
                                          width: value,
                                          decoration: BoxDecoration(
                                            color: anaRenk,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: anaRenk.withValues(alpha: 0.4), 
                                                blurRadius: 8
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: anaRenk.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: anaRenk.withValues(alpha: 0.3))
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, color: anaRenk, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Sistem, izlediğin $benzersizEtkilesimSayisi farklı eserin meta-verilerini işleyerek izleme profilini oluşturmuştur.", 
                    style: TextStyle(color: textC, fontSize: 12, height: 1.5)
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _bilgiKarti(String baslik, String deger, IconData ikon, Color renk, Color cardBg, Color textC) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: renk.withValues(alpha: 0.1), 
            blurRadius: 10
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: renk, size: 32),
          const SizedBox(height: 15),
          Text(
            deger, 
            style: GoogleFonts.bangers(fontSize: 36, color: textC)
          ),
          Text(
            baslik, 
            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }
}