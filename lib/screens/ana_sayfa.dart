import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../core/settings.dart';
import '../widgets/yan_menu.dart';
import '../services/api_service.dart';
import '../services/novel_service.dart'; 
import '../services/yerel_veri_servisi.dart'; 
import '../models/manga.dart';
import 'bilgi_sayfasi.dart';
import 'yerel_okuma_sayfasi.dart';

import '../anime_module/models/anime_model.dart';
import '../anime_module/services/anime_servisi.dart'; 
import '../anime_module/screens/anime_bilgi_sayfasi.dart';

class AnaSayfa extends StatefulWidget {
  final int baslangicModu; 
  const AnaSayfa({super.key, this.baslangicModu = 0});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  late int _aktifMod; 
  bool aramaModu = false; 
  final TextEditingController _aramaController = TextEditingController();
  
  final ScrollController _scrollControllerManga = ScrollController();
  final ScrollController _scrollControllerNovel = ScrollController();
  final ScrollController _scrollControllerAnime = ScrollController();

  List<Manga> _aramaSonuclari = [];
  List<AnimeModel> _aramaSonuclariAnime = []; 
  bool _aramaYukleniyor = false;

  List<Manga> _trendMangalar = [];
  List<Manga> _kesfetMangalar = [];
  int _mangaOffset = 0;
  bool _mangaYukleniyor = false;

  final List<Manga> _kesfetNovellar = [];
  int _novelSayfa = 1;
  bool _novelYukleniyor = false;
  Future<List<Manga>> _novelTrendler = Future.value([]);

  List<AnimeModel> _kesfetAnimeler = [];
  bool _animeYukleniyor = false;

  List<Manga> _onerilenMangalar = [];
  List<Manga> _onerilenNoveller = [];
  String _oneriMesajiManga = "";
  String _oneriMesajiNovel = "";

  @override
  void initState() {
    super.initState();
    _aktifMod = widget.baslangicModu; 
    _ilkVerileriYukle();
    
    _scrollControllerManga.addListener(() {
      if (_scrollControllerManga.position.pixels >= _scrollControllerManga.position.maxScrollExtent - 300) {
        if (!_mangaYukleniyor && !aramaModu) _dahaFazlaMangaYukle();
      }
    });

    _scrollControllerNovel.addListener(() {
      if (_scrollControllerNovel.position.pixels >= _scrollControllerNovel.position.maxScrollExtent - 300) {
        if (!_novelYukleniyor && !aramaModu) _dahaFazlaNovelYukle();
      }
    });
  }

  void _ilkVerileriYukle() {
    setState(() {
      _trendMangalar = ApiService.trendMangaCache;
      if (_trendMangalar.isEmpty) {
        if (_kesfetMangalar.isEmpty) _dahaFazlaMangaYukle(); 
      } else {
        if (_kesfetMangalar.isEmpty) {
          _kesfetMangalar = List.from(_trendMangalar);
          _mangaOffset = 20;
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() { _novelTrendler = NovelService.populerNovellariGetir(); });
      if (_kesfetNovellar.isEmpty) _dahaFazlaNovelYukle(); 
      if (_kesfetAnimeler.isEmpty) _yerelAnimeleriYukle();
    });

    _akilliOnerileriGetir();
  }

  Future<void> _yerelAnimeleriYukle() async {
    setState(() => _animeYukleniyor = true);
    final animeler = await AnimeServisi.animeleriGetir();
    if (mounted) {
      setState(() {
        _kesfetAnimeler = animeler;
        _animeYukleniyor = false;
      });
    }
  }

  Future<void> _akilliOnerileriGetir() async {
    String? favoriMangaTuru = YerelVeriServisi.enCokOkunanTuruGetir(true);
    if (favoriMangaTuru != null) {
      try {
        var sonuclar = await ApiService.mangaGetir(arama: favoriMangaTuru);
        if (mounted) setState(() { _onerilenMangalar = sonuclar; _oneriMesajiManga = "Okuma geçmişindeki '$favoriMangaTuru' ağırlığına göre seçildi."; });
      } catch (e) {
        debugPrint("Manga öneri hatası: $e");
      }
    }

    String? favoriNovelTuru = YerelVeriServisi.enCokOkunanTuruGetir(false);
    if (favoriNovelTuru != null) {
      try {
        var sonuclar = await NovelService.novelGetir(arama: favoriNovelTuru);
        if (mounted) setState(() { _onerilenNoveller = sonuclar; _oneriMesajiNovel = "Kütüphanendeki '$favoriNovelTuru' yoğunluğuna göre seçildi."; });
      } catch (e) {
        debugPrint("Novel öneri hatası: $e");
      }
    }
  }

  Future<void> _aramaYap(String sorgu) async {
    if (sorgu.trim().isEmpty) return;
    setState(() { aramaModu = true; _aramaYukleniyor = true; _aramaSonuclari.clear(); _aramaSonuclariAnime.clear(); });
    try {
      if (_aktifMod == 0) {
        _aramaSonuclari = await ApiService.mangaGetir(arama: sorgu);
      } else if (_aktifMod == 1) {
        _aramaSonuclariAnime = await AnimeServisi.animeAra(sorgu); 
      } else if (_aktifMod == 2) {
        _aramaSonuclari = await NovelService.novelGetir(arama: sorgu);
      }
      if (mounted) setState(() { _aramaYukleniyor = false; });
    } catch (e) {
      debugPrint("Arama hatası: $e");
      if (mounted) setState(() => _aramaYukleniyor = false);
    }
  }

  void _aramayiIptalEt() {
    setState(() { aramaModu = false; _aramaController.clear(); _aramaSonuclari.clear(); _aramaSonuclariAnime.clear(); FocusScope.of(context).unfocus(); });
  }

  Future<void> _dahaFazlaMangaYukle() async {
    if (_mangaYukleniyor) return;
    setState(() => _mangaYukleniyor = true);
    try {
      final yeni = await ApiService.mangaGetir(offset: _mangaOffset);
      if (mounted) setState(() { _kesfetMangalar.addAll(yeni); _mangaOffset += 20; _mangaYukleniyor = false; });
    } catch (e) { 
      debugPrint("Manga yükleme hatası: $e");
      setState(() => _mangaYukleniyor = false); 
    }
  }

  Future<void> _dahaFazlaNovelYukle() async {
    if (_novelYukleniyor) return;
    setState(() => _novelYukleniyor = true);
    try {
      final yeni = await NovelService.novelGetir(sayfa: _novelSayfa);
      if (mounted) setState(() { _kesfetNovellar.addAll(yeni); _novelSayfa++; _novelYukleniyor = false; });
    } catch (e) { 
      debugPrint("Novel yükleme hatası: $e");
      setState(() => _novelYukleniyor = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.karanlikTemaModu,
      builder: (context, karanlikMi, _) {
        Color bg = karanlikMi ? AppColors.darkBg : Colors.white;
        Color textC = karanlikMi ? Colors.white : Colors.black87;
        Color cardBg = karanlikMi ? AppColors.cardBg : Colors.grey[200]!;
        Color activeColor = _aktifMod == 0 ? AppColors.mangaOrange : (_aktifMod == 1 ? Colors.deepPurpleAccent : AppColors.novelBlue);

        return Scaffold(
          backgroundColor: bg,
          drawer: YanMenu(activeColor: activeColor, aktifMod: _aktifMod),
          body: SafeArea(
            child: Column(
              children: [
                _ustAramaBari(activeColor, cardBg, textC),
                Expanded(
                  child: IndexedStack(
                    index: aramaModu ? 3 : _aktifMod,
                    children: [
                      _buildSayfa(_scrollControllerManga, _mangaSayfasi(activeColor, textC, cardBg), activeColor),
                      _buildSayfa(_scrollControllerAnime, _animeSayfasi(activeColor, textC, cardBg), activeColor),
                      _buildSayfa(_scrollControllerNovel, _novelSayfasi(activeColor, textC, cardBg), activeColor),
                      SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(children: _aramaSonucSayfasi(activeColor, textC, cardBg))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _altNavigasyon(activeColor, bg),
        );
      }
    );
  }

  Widget _buildSayfa(ScrollController sc, List<Widget> children, Color activeColor) {
    return RefreshIndicator(
      onRefresh: () async { _ilkVerileriYukle(); },
      color: activeColor,
      child: SingleChildScrollView(controller: sc, physics: const AlwaysScrollableScrollPhysics(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
    );
  }

  Widget _ustAramaBari(Color activeColor, Color cardBg, Color textC) {
    String hint = _aktifMod == 0 ? "Manga ara..." : (_aktifMod == 1 ? "Anime ara..." : "Novel ara...");
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Builder(builder: (c) => IconButton(icon: Icon(Icons.menu, color: textC), onPressed: () => Scaffold.of(c).openDrawer())),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: _aramaController,
                style: TextStyle(color: textC, fontSize: 14),
                onSubmitted: _aramaYap,
                onChanged: (deger) { if (deger.isEmpty && aramaModu) _aramayiIptalEt(); },
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _aramaController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: _aramayiIptalEt) : null,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Image.asset('assets/images/appicon.png', height: 48, errorBuilder: (c, e, s) => Icon(Icons.flash_on, color: activeColor)),
        ],
      ),
    );
  }

  // --- ANİME SAYFASI GÜNCELLEMESİ (PREMIUM & FILTRELI) ---
  List<Widget> _animeSayfasi(Color activeColor, Color textC, Color cardBg) {
    Map<String, List<AnimeModel>> kategoriGruplari = {};
    
    // KRAL: Filtrelenecek türleri buraya ekliyoruz
    List<String> yasakliTurler = ['ecchi', 'hentai'];

    for (var anime in _kesfetAnimeler) {
      for (var tur in anime.turler) {
        // Tür yasaklı listesindeyse kategori olarak ekleme
        if (yasakliTurler.contains(tur.toLowerCase())) continue;

        if (!kategoriGruplari.containsKey(tur)) {
          kategoriGruplari[tur] = [];
        }
        kategoriGruplari[tur]!.add(anime);
      }
    }

    return [
      _animeYatayKategoriListesiNotifier("🕒 İzlemeye Devam Et", activeColor, YerelVeriServisi.animeSonOkunan, textC, cardBg),
      
      ...kategoriGruplari.entries.map((entry) {
        return _animeYatayListe(entry.key.toUpperCase(), activeColor, entry.value, textC, cardBg);
      }),

      if (_kesfetAnimeler.isEmpty && !_animeYukleniyor) 
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: Text("Henüz anime eklenmedi.", style: TextStyle(color: Colors.grey))),
        ),

      if (_animeYukleniyor) _yukleniyorIkonu(activeColor),
      const SizedBox(height: 80),
    ];
  }

  Widget _animeYatayListe(String baslik, Color renk, List<AnimeModel> liste, Color textC, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 25, bottom: 12), 
          child: Text(baslik, style: GoogleFonts.bangers(fontSize: 22, color: renk, letterSpacing: 1.5))
        ),
        SizedBox(
          height: 200, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, 
            padding: const EdgeInsets.only(left: 16), 
            itemCount: liste.length, 
            itemBuilder: (context, index) => _animeOzelKart(liste[index], renk, cardBg)
          ),
        ),
      ],
    );
  }

  Widget _animeOzelKart(AnimeModel a, Color renk, Color cardBg) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: () => _animeOynat(a), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      a.kapakResmi, 
                      fit: BoxFit.cover, 
                      width: double.infinity, 
                      height: double.infinity, 
                      errorBuilder: (c, e, s) => Container(color: cardBg, child: const Icon(Icons.movie, color: Colors.grey))
                    ),
                    Positioned(
                      top: 5, right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 10), 
                            const SizedBox(width: 3),
                            Text(a.puan.toString(), style: const TextStyle(color: Colors.white, fontSize: 9))
                          ]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              a.baslik, 
              style: TextStyle(
                color: AppSettings.karanlikTemaModu.value ? Colors.white : Colors.black, 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              ), 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis
            ),
          ],
        ),
      ),
    );
  }

  Widget _animeYatayKategoriListesiNotifier(String baslik, Color renk, ValueNotifier<List<AnimeModel>> notifier, Color textC, Color cardBg) {
    return ValueListenableBuilder<List<AnimeModel>>(
      valueListenable: notifier,
      builder: (context, liste, _) {
        if (liste.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(left: 16, top: 20, bottom: 10), child: Text(baslik, style: GoogleFonts.bangers(fontSize: 20, color: textC, letterSpacing: 1.2))),
            SizedBox(height: 160, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 16), itemCount: liste.length, itemBuilder: (context, index) => _animeYatayKart(liste[index], renk, cardBg))),
          ],
        );
      }
    );
  }

  Widget _animeYatayKart(AnimeModel a, Color renk, Color cardBg) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: () => _animeOynat(a), 
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(a.kapakResmi, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Container(color: cardBg)),
              Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center)))),
              Positioned(bottom: 8, left: 8, right: 8, child: Text(a.baslik, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animeGridListe(List<AnimeModel> liste, Color renk, Color cardBg) {
    if (liste.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text("Sonuç bulunamadı.", style: TextStyle(color: Colors.grey))),
      );
    }
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
      itemCount: liste.length,
      itemBuilder: (context, index) => _animeGridKart(liste[index], renk, cardBg),
    );
  }

  Widget _animeGridKart(AnimeModel a, Color renk, Color cardBg) {
    return InkWell(
      onTap: () => _animeOynat(a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(a.kapakResmi, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Container(color: cardBg, child: const Icon(Icons.movie, color: Colors.grey)))),
                const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 45)),
                Positioned(top: 5, right: 5, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(5)), child: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 12), const SizedBox(width: 3), Text(a.puan.toString(), style: const TextStyle(color: Colors.white, fontSize: 10))]))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(a.baslik, style: TextStyle(color: AppSettings.karanlikTemaModu.value ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Future<void> _animeOynat(AnimeModel a) async {
    // KRAL: Artik direkt bilgi sayfasina yonlendiriyoruz
    Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeBilgiSayfasi(anime: a, activeColor: Colors.deepPurpleAccent)));
  }

  List<Widget> _mangaSayfasi(Color activeColor, Color textC, Color cardBg) {
    return [
      _yatayKategoriListesiNotifier("🕒 Okumaya Devam Et", activeColor, YerelVeriServisi.mangaSonOkunan, textC, cardBg),
      if (_onerilenMangalar.isNotEmpty) _oneriListesi("✨ Senin İçin Seçtiklerimiz", _oneriMesajiManga, activeColor, _onerilenMangalar, textC, cardBg),
      if (_trendMangalar.isNotEmpty) _yatayListe("🔥 Trend Mangalar", activeColor, _trendMangalar, textC, cardBg),
      _bolumBasligi("MANGA KEŞFET", activeColor),
      _dikeyGridListe(_kesfetMangalar, activeColor, cardBg),
      if (_mangaYukleniyor) _yukleniyorIkonu(activeColor),
      const SizedBox(height: 80),
    ];
  }

  List<Widget> _novelSayfasi(Color activeColor, Color textC, Color cardBg) {
    return [
      _yatayKategoriListesiNotifier("🕒 Okumaya Devam Et", activeColor, YerelVeriServisi.novelSonOkunan, textC, cardBg),
      if (_onerilenNoveller.isNotEmpty) _oneriListesi("✨ Senin İçin Seçtiklerimiz", _oneriMesajiNovel, activeColor, _onerilenNoveller, textC, cardBg),
      _yatayKategoriListesiFuture("🔥 Popüler Romanlar", activeColor, _novelTrendler, textC, cardBg),
      _bolumBasligi("NOVEL KEŞFET", activeColor),
      _dikeyGridListe(_kesfetNovellar, activeColor, cardBg),
      if (_novelYukleniyor) _yukleniyorIkonu(activeColor),
      const SizedBox(height: 80),
    ];
  }

  Widget _yatayListe(String baslik, Color renk, List<Manga> liste, Color textC, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 16, top: 20, bottom: 10), child: Text(baslik, style: GoogleFonts.bangers(fontSize: 20, color: textC, letterSpacing: 1.2))),
        SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 16), itemCount: liste.length, itemBuilder: (context, index) => _kucukKart(liste[index], renk, cardBg))),
      ],
    );
  }

  Widget _oneriListesi(String baslik, String altBaslik, Color renk, List<Manga> liste, Color textC, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 16, top: 20, bottom: 2), child: Text(baslik, style: GoogleFonts.bangers(fontSize: 22, color: renk, letterSpacing: 1.2))),
        Padding(padding: const EdgeInsets.only(left: 16, bottom: 12, right: 16), child: Text(altBaslik, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic))),
        SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 16), itemCount: liste.length, itemBuilder: (context, index) => _kucukKart(liste[index], renk, cardBg))),
      ],
    );
  }

  Widget _yatayKategoriListesiNotifier(String baslik, Color renk, ValueNotifier<List<Manga>> notifier, Color textC, Color cardBg) {
    return ValueListenableBuilder<List<Manga>>(
      valueListenable: notifier,
      builder: (context, liste, _) {
        if (liste.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(left: 16, top: 20, bottom: 10), child: Text(baslik, style: GoogleFonts.bangers(fontSize: 20, color: textC, letterSpacing: 1.2))),
            SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 16), itemCount: liste.length, itemBuilder: (context, index) => _kucukKart(liste[index], renk, cardBg))),
          ],
        );
      }
    );
  }

  Widget _yatayKategoriListesiFuture(String baslik, Color renk, Future<List<Manga>> veri, Color textC, Color cardBg) {
    return FutureBuilder<List<Manga>>(
      future: veri,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final liste = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(left: 16, top: 20, bottom: 10), child: Text(baslik, style: GoogleFonts.bangers(fontSize: 20, color: textC, letterSpacing: 1.2))),
            SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 16), itemCount: liste.length, itemBuilder: (context, index) => _kucukKart(liste[index], renk, cardBg))),
          ],
        );
      },
    );
  }

  Widget _dikeyGridListe(List<Manga> liste, Color renk, Color cardBg) {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 12, childAspectRatio: 0.65),
      itemCount: liste.length,
      itemBuilder: (context, index) => _kucukKart(liste[index], renk, cardBg),
    );
  }

  Widget _kucukKart(Manga m, Color renk, Color cardBg) {
    bool isYerel = m.kapakResmi == "yerel_ikon";
    return InkWell(
      onTap: () {
        if (isYerel) {
          List<String> yollar = m.ozet.startsWith("YerelDosyalar:") ? m.ozet.replaceFirst("YerelDosyalar:", "").split("|") : [m.ozet.split(": ").last];
          final kayit = YerelVeriServisi.ilerlemeyiGetir(m.id);
          Navigator.push(context, CupertinoPageRoute(builder: (c) => YerelOkumaSayfasi(manga: m, dosyaYollari: yollar, isManga: m.turler.contains("Manga"), baslangicSayfa: kayit?['sayfaIndex'])));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (c) => BilgiSayfasi(manga: m, activeColor: renk)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10), 
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: renk.withValues(alpha: 0.1))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isYerel 
            ? Container(width: 110, color: cardBg, padding: const EdgeInsets.all(8), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open, color: renk, size: 40), const SizedBox(height: 5), Text(m.isim, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)]))
            : SizedBox(width: 110, child: Image.network(m.kapakResmi, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: cardBg, child: const Icon(Icons.broken_image, color: Colors.grey)))),
        ),
      ),
    );
  }

  Widget _bolumBasligi(String metin, Color renk) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 35, 16, 15), child: Row(children: [Icon(Icons.explore_outlined, color: renk, size: 28), const SizedBox(width: 8), Text(metin, style: GoogleFonts.bangers(fontSize: 26, color: renk, letterSpacing: 1.5))]));
  }

  Widget _yukleniyorIkonu(Color renk) => Padding(padding: const EdgeInsets.symmetric(vertical: 25), child: Center(child: CircularProgressIndicator(color: renk)));

  List<Widget> _aramaSonucSayfasi(Color activeColor, Color textC, Color cardBg) {
    if (_aramaYukleniyor) return [_yukleniyorIkonu(activeColor)];
    
    bool bosMu = _aktifMod == 1 ? _aramaSonuclariAnime.isEmpty : _aramaSonuclari.isEmpty;
    if (bosMu) return [const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: Text("Sonuç bulunamadı.")))];
    
    return [
      _bolumBasligi("ARAMA SONUÇLARI", activeColor), 
      _aktifMod == 1 ? _animeGridListe(_aramaSonuclariAnime, activeColor, cardBg) : _dikeyGridListe(_aramaSonuclari, activeColor, cardBg)
    ];
  }

  Widget _altNavigasyon(Color activeColor, Color bg) {
    return BottomNavigationBar(
      backgroundColor: bg, currentIndex: _aktifMod, selectedItemColor: activeColor, unselectedItemColor: Colors.grey,
      onTap: (index) => setState(() { _aktifMod = index; _aramayiIptalEt(); }),
      items: const [BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: 'Manga'), BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Anime'), BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Novel')],
    );
  }
}