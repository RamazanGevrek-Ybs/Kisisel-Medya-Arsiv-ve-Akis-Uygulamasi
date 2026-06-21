import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../core/settings.dart';
import '../services/yerel_veri_servisi.dart';
import '../models/manga.dart';
import '../anime_module/models/anime_model.dart';
import 'bilgi_sayfasi.dart';
import '../anime_module/screens/anime_bilgi_sayfasi.dart'; // Yeni sayfamız

class KutuphaneSayfasi extends StatefulWidget {
  final Color activeColor;
  final int aktifMod; // 0=Manga, 1=Anime, 2=Novel

  const KutuphaneSayfasi({super.key, required this.activeColor, required this.aktifMod});

  @override
  State<KutuphaneSayfasi> createState() => _KutuphaneSayfasiState();
}

class _KutuphaneSayfasiState extends State<KutuphaneSayfasi> {
  List<Manga> _mangaVeyaNovelFavoriler = [];
  List<AnimeModel> _animeFavoriler = [];

  @override
  void initState() {
    super.initState();
    _favorileriYukle();
  }

  void _favorileriYukle() {
    setState(() {
      if (widget.aktifMod == 1) {
        _animeFavoriler = YerelVeriServisi.animeFavorileriGetir();
      } else {
        bool isManga = widget.aktifMod == 0;
        _mangaVeyaNovelFavoriler = YerelVeriServisi.favorileriGetir(isManga);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.karanlikTemaModu,
      builder: (context, karanlikMi, _) {
        Color bg = karanlikMi ? AppColors.darkBg : Colors.white;
        Color textC = karanlikMi ? Colors.white : Colors.black87;
        Color cardBg = karanlikMi ? AppColors.cardBg : Colors.grey[200]!;
        
        bool isAnimeMode = widget.aktifMod == 1;
        bool listeBosMu = isAnimeMode ? _animeFavoriler.isEmpty : _mangaVeyaNovelFavoriler.isEmpty;
        int listeUzunlugu = isAnimeMode ? _animeFavoriler.length : _mangaVeyaNovelFavoriler.length;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: textC), onPressed: () => Navigator.pop(context)),
            title: Text("KÜTÜPHANEM", style: GoogleFonts.bangers(fontSize: 24, color: widget.activeColor)),
            elevation: 0,
          ),
          body: listeBosMu 
            ? const Center(child: Text("Henüz bir şey eklemedin.", style: TextStyle(color: Colors.grey, fontSize: 16)))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.65),
                itemCount: listeUzunlugu, 
                itemBuilder: (context, index) {
                  String kapakResmi = "";
                  String isim = "";
                  Widget gidilecekSayfa;

                  if (isAnimeMode) {
                    final a = _animeFavoriler[index];
                    kapakResmi = a.kapakResmi;
                    isim = a.baslik;
                    gidilecekSayfa = AnimeBilgiSayfasi(anime: a, activeColor: widget.activeColor);
                  } else {
                    final m = _mangaVeyaNovelFavoriler[index];
                    kapakResmi = m.kapakResmi;
                    isim = m.isim;
                    gidilecekSayfa = BilgiSayfasi(manga: m, activeColor: widget.activeColor);
                  }

                  return InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => gidilecekSayfa)).then((_) => _favorileriYukle()),
                    child: Container(
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.activeColor.withValues(alpha: 0.2))),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              child: Image.network(kapakResmi, fit: BoxFit.cover, width: double.infinity, cacheWidth: 300, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(isim, style: TextStyle(fontSize: 12, color: textC), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        );
      }
    );
  }
}