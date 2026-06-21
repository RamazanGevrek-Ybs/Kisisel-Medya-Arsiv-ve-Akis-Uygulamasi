import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/anime_model.dart';
import 'anime_player_sayfasi.dart';
import '../../core/settings.dart';
import '../../services/yerel_veri_servisi.dart'; // Favori işlemleri için

class AnimeBilgiSayfasi extends StatefulWidget {
  final AnimeModel anime;
  final Color activeColor;

  const AnimeBilgiSayfasi({super.key, required this.anime, required this.activeColor});

  @override
  State<AnimeBilgiSayfasi> createState() => _AnimeBilgiSayfasiState();
}

class _AnimeBilgiSayfasiState extends State<AnimeBilgiSayfasi> {
  bool _favoriMi = false;

  @override
  void initState() {
    super.initState();
    _favoriKontrolEt();
  }

  void _favoriKontrolEt() {
    // KRAL: YerelVeriServisi'nde anime favorilerini tuttuğunu varsayarak kontrol ediyoruz
    // Eğer YerelVeriServisi'nde bu metodlar yoksa, manga için olanları kopyalayıp animeye uyarlamalısın.
    try {
      final favoriler = YerelVeriServisi.animeFavorileriGetir();
      setState(() {
        _favoriMi = favoriler.any((a) => a.id == widget.anime.id);
      });
    } catch (e) {
      debugPrint("Favori kontrol hatası: $e");
    }
  }

  Future<void> _favoriDegistir() async {
    setState(() => _favoriMi = !_favoriMi);
    try {
      await YerelVeriServisi.animeFavoriGuncelle(widget.anime, _favoriMi);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_favoriMi ? "Kütüphaneye Eklendi" : "Kütüphaneden Çıkarıldı"),
          backgroundColor: widget.activeColor,
        ));
      }
    } catch (e) {
      debugPrint("Favori güncelleme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool karanlikMi = AppSettings.karanlikTemaModu.value;
    Color bg = karanlikMi ? Colors.black : Colors.white;
    Color textC = karanlikMi ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: bg,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white)
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(_favoriMi ? Icons.bookmark : Icons.bookmark_border, color: _favoriMi ? widget.activeColor : Colors.white)
                ),
                onPressed: _favoriDegistir,
              ),
              const SizedBox(width: 10),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(widget.anime.kapakResmi, fit: BoxFit.cover),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [bg, Colors.transparent, bg.withValues(alpha: 0.8), bg],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.3, 0.8, 1.0],
                        )
                      )
                    )
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.anime.baslik, style: GoogleFonts.bangers(fontSize: 32, color: widget.activeColor, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      Text("${widget.anime.puan} / 10", style: TextStyle(color: textC, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 20),
                      Text("${widget.anime.bolumler.length} Bölüm", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.anime.turler.map((tur) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: widget.activeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.activeColor)),
                      child: Text(tur, style: TextStyle(color: widget.activeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text("Özet", style: TextStyle(color: textC, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.anime.ozet, style: TextStyle(color: karanlikMi ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 30),
                  Text("Bölümler", style: TextStyle(color: textC, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                var bolum = widget.anime.bolumler[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(widget.anime.kapakResmi, width: 80, height: 50, fit: BoxFit.cover),
                      ),
                      Container(width: 80, height: 50, color: Colors.black45),
                      const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                    ],
                  ),
                  title: Text("Bölüm ${bolum.bolumNo}", style: TextStyle(color: textC, fontWeight: FontWeight.bold)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // İzleme geçmişine ekleyip oynatıcıyı açıyoruz
                    YerelVeriServisi.animeSonOkunanEkle(widget.anime);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AnimePlayerSayfasi(anime: widget.anime, baslangicBolumIndex: index)));
                  },
                );
              },
              childCount: widget.anime.bolumler.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}