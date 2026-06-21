import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../services/api_service.dart';
import '../services/yerel_veri_servisi.dart';
import '../core/settings.dart';
import '../models/manga.dart';

class MangaSayfaModel {
  final String bolumId;
  final String url;
  final int bolumIciIndex;
  MangaSayfaModel(this.bolumId, this.url, this.bolumIciIndex);
}

class OkumaSayfasi extends StatefulWidget {
  final String mangaId;
  final List<Bolum> tumBolumler;
  final int baslangicIndex;
  final String mangaAdi;
  final int? baslangicSayfa;

  const OkumaSayfasi({
    super.key,
    required this.mangaId,
    required this.tumBolumler,
    required this.baslangicIndex,
    required this.mangaAdi,
    this.baslangicSayfa,
  });

  @override
  State<OkumaSayfasi> createState() => _OkumaSayfasiState();
}

class _OkumaSayfasiState extends State<OkumaSayfasi> {
  final List<MangaSayfaModel> _sayfalar = [];
  late int _mevcutBolumIndex;
  late int _mevcutEnKucukBolumIndex; 
  bool _yukleniyor = false;
  bool _menuyuGoster = false;

  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _mevcutBolumIndex = widget.baslangicIndex;
    _mevcutEnKucukBolumIndex = widget.baslangicIndex;
    
    int baslangic = widget.baslangicSayfa ?? 0;
    if (widget.baslangicIndex > 0) baslangic += 1;
    _pageController = PageController(initialPage: baslangic);
    
    _bolumYukle(ilkYukleme: true);

    _scrollController.addListener(() {
      if (AppSettings.mangaDikeyMod.value && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 800) {
        _sonrakiBolumuYukle();
      }
    });
  }

  Future<void> _bolumYukle({bool ilkYukleme = false}) async {
    if (_yukleniyor || _mevcutBolumIndex >= widget.tumBolumler.length) return;
    setState(() => _yukleniyor = true);

    final id = widget.tumBolumler[_mevcutBolumIndex].id;
    final yeniSayfalar = await ApiService.sayfalariGetir(id);

    if (mounted) {
      setState(() {
        for(int i = 0; i < yeniSayfalar.length; i++) {
          _sayfalar.add(MangaSayfaModel(id, yeniSayfalar[i], i));
        }
        _yukleniyor = false;
      });

      if (ilkYukleme && widget.baslangicSayfa != null && AppSettings.mangaDikeyMod.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            double offset = widget.baslangicSayfa! * 500.0;
            if (widget.baslangicIndex > 0) offset += 100.0; 
            _scrollController.jumpTo(offset);
          }
        });
      }
    }
  }

  void _oncekiBolumuYukle() async {
    if (!_yukleniyor && _mevcutEnKucukBolumIndex > 0) {
      setState(() {
        _mevcutEnKucukBolumIndex--;
        _mevcutBolumIndex = _mevcutEnKucukBolumIndex;
        _sayfalar.clear();
      });
      
      await _bolumYukle(ilkYukleme: false);
      
      if (!AppSettings.mangaDikeyMod.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_mevcutEnKucukBolumIndex > 0 ? 1 : 0);
          }
        });
      }
    }
  }

  void _kaydet(int index) {
    if (index < 0 || index >= _sayfalar.length) return;
    final sayfa = _sayfalar[index];
    YerelVeriServisi.ilerlemeyiKaydet(widget.mangaId, sayfa.bolumId, sayfa.bolumIciIndex);
  }

  void _sonrakiBolumuYukle() {
    if (!_yukleniyor && _mevcutBolumIndex < widget.tumBolumler.length - 1) {
      _mevcutBolumIndex++;
      _bolumYukle();
    }
  }

  void _menuyuTetikle() {
    setState(() => _menuyuGoster = !_menuyuGoster);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.mangaDikeyMod,
      builder: (context, dikeyMi, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              _sayfalar.isEmpty && _yukleniyor
                  ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                  : dikeyMi 
                      ? _buildDikeyOkuma() 
                      : _buildYatayOkuma(), 

              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: _menuyuGoster ? 0 : -110,
                left: 0, right: 0,
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.only(top: 45, left: 10, right: 10),
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(widget.mangaAdi, style: GoogleFonts.bangers(fontSize: 18, color: Colors.white), overflow: TextOverflow.ellipsis),
                        Text("BÖLÜM ${widget.tumBolumler[_mevcutBolumIndex].bolumNo}", style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                      ])),
                      IconButton(
                        icon: Icon(dikeyMi ? Icons.swap_vert : Icons.swap_horiz, color: Colors.white),
                        onPressed: () {
                          AppSettings.mangaDikeyMod.value = !dikeyMi;
                          AppSettings.kaydet('mangaDikey', !dikeyMi);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDikeyOkuma() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      // KRAL: RAM düşmanı cacheExtent: 3000 satırını sildik! 
      itemCount: _sayfalar.length + (_yukleniyor ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _mevcutEnKucukBolumIndex > 0 
            ? Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: TextButton.icon(onPressed: _oncekiBolumuYukle, icon: const Icon(Icons.keyboard_double_arrow_up, color: Colors.orange), label: const Text("Önceki Bölüm", style: TextStyle(color: Colors.orange, fontSize: 18))))
            : const SizedBox(height: 50);
        }
        
        final gercekIndex = index - 1;
        if (gercekIndex == _sayfalar.length) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Colors.orange)));
        
        return VisibilityDetector(
          key: Key("manga_page_${_sayfalar[gercekIndex].bolumId}_$gercekIndex"),
          onVisibilityChanged: (info) { if (info.visibleFraction > 0.6) _kaydet(gercekIndex); },
          child: GestureDetector(
            onTap: _menuyuTetikle,
            behavior: HitTestBehavior.opaque,
            child: InteractiveViewer(
              minScale: 1.0, maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: _sayfalar[gercekIndex].url,
                fit: BoxFit.fitWidth, 
                width: double.infinity,
                memCacheWidth: 800, // KRAL DEVRİMİ: Online resimler artık RAM'i yutamaz!
                placeholder: (context, url) => const SizedBox(height: 400, child: Center(child: CircularProgressIndicator(color: Colors.orange))),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white24, size: 60),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYatayOkuma() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _sayfalar.length + (_mevcutEnKucukBolumIndex > 0 ? 1 : 0),
      onPageChanged: (index) {
        if (_mevcutEnKucukBolumIndex > 0 && index == 0) return; 
        final gercekIndex = _mevcutEnKucukBolumIndex > 0 ? index - 1 : index;
        _kaydet(gercekIndex);
        if (gercekIndex >= _sayfalar.length - 2) _sonrakiBolumuYukle();
      },
      itemBuilder: (context, index) {
        if (_mevcutEnKucukBolumIndex > 0 && index == 0) {
          return Center(child: ElevatedButton.icon(onPressed: _oncekiBolumuYukle, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), icon: const Icon(Icons.arrow_back_ios, color: Colors.black), label: const Text("Önceki Bölüm", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))));
        }
        final gercekIndex = _mevcutEnKucukBolumIndex > 0 ? index - 1 : index;
        
        return GestureDetector(
          onTap: _menuyuTetikle,
          behavior: HitTestBehavior.opaque,
          child: InteractiveViewer(
            minScale: 1.0, maxScale: 4.0,
            child: SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: _sayfalar[gercekIndex].url,
                fit: BoxFit.contain, 
                memCacheWidth: 800, // KRAL DEVRİMİ: Yatayda da RAM güvende
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white24, size: 60),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}