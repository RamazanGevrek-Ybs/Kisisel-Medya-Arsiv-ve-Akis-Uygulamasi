import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../services/novel_service.dart';
import '../services/yerel_veri_servisi.dart';
import '../core/settings.dart';
import '../models/manga.dart';
import '../core/colors.dart';

class NovelSayfasiModel {
  final String bolumId;
  final String bolumNo;
  final String metin;
  final int bolumIciIndex;
  NovelSayfasiModel(this.bolumId, this.bolumNo, this.metin, this.bolumIciIndex);
}

class NovelOkumaSayfasi extends StatefulWidget {
  final String mangaId;
  final List<Bolum> tumBolumler;
  final int baslangicIndex;
  final String novelAdi;
  final int? baslangicSayfa;

  const NovelOkumaSayfasi({
    super.key,
    required this.mangaId,
    required this.tumBolumler,
    required this.baslangicIndex,
    required this.novelAdi,
    this.baslangicSayfa,
  });

  @override
  State<NovelOkumaSayfasi> createState() => _NovelOkumaSayfasiState();
}

class _NovelOkumaSayfasiState extends State<NovelOkumaSayfasi> {
  final List<NovelSayfasiModel> _sayfalar = [];
  late int _siradakiBolumIndex;
  late int _mevcutEnKucukBolumIndex;
  bool _yukleniyor = false;
  bool _menuyuGoster = false;
  bool _ilkYukleme = true;

  final List<List<Color>> _temalar = [
    [const Color(0xFF121212), Colors.white70], 
    [const Color(0xFFF4ECD8), const Color(0xFF5B4636)], 
    [Colors.white, Colors.black87], 
  ];

  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _siradakiBolumIndex = widget.baslangicIndex;
    _mevcutEnKucukBolumIndex = widget.baslangicIndex;
    
    int baslangic = widget.baslangicSayfa ?? 0;
    if (widget.baslangicIndex > 0) baslangic += 1;
    _pageController = PageController(initialPage: baslangic);
    
    _bolumYukle();

    _scrollController.addListener(() {
      if (AppSettings.novelDikeyMod.value && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
        _bolumYukle();
      }
    });
  }

  void _oncekiBolumuYukle() async {
    if (!_yukleniyor && _mevcutEnKucukBolumIndex > 0) {
      setState(() {
        _mevcutEnKucukBolumIndex--;
        _siradakiBolumIndex = _mevcutEnKucukBolumIndex;
        _sayfalar.clear();
      });
      
      await _bolumYukle();
      
      if (!AppSettings.novelDikeyMod.value) {
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

  List<String> _sayfalaraBol(String metin) {
    List<String> sayfalar = [];
    List<String> kelimeler = metin.split(' '); 
    StringBuffer guncelSayfa = StringBuffer();

    for (String kelime in kelimeler) {
      if (guncelSayfa.length + kelime.length > 550) {
        sayfalar.add(guncelSayfa.toString().trim());
        guncelSayfa.clear();
        guncelSayfa.write("$kelime ");
      } else {
        guncelSayfa.write("$kelime ");
      }
    }
    if (guncelSayfa.isNotEmpty) sayfalar.add(guncelSayfa.toString().trim());
    if (sayfalar.isEmpty) sayfalar.add("İçerik bulunamadı.");
    return sayfalar;
  }

  Future<void> _bolumYukle() async {
    if (_yukleniyor || _siradakiBolumIndex >= widget.tumBolumler.length) return;
    setState(() => _yukleniyor = true);

    final bolum = widget.tumBolumler[_siradakiBolumIndex];
    
    final icerik = await NovelService.bolumIcerigiGetir(bolum.id);
    final temizMetin = _htmlTemizle(icerik);
    
    List<String> parcalar = _sayfalaraBol(temizMetin);
    if (mounted) {
      setState(() {
        for (int i = 0; i < parcalar.length; i++) {
          String baslik = (i == 0) ? "BÖLÜM ${bolum.bolumNo}\n\n" : "";
          _sayfalar.add(NovelSayfasiModel(bolum.id, bolum.bolumNo, baslik + parcalar[i], i));
        }
        _siradakiBolumIndex++;
        _yukleniyor = false;
      });

      // KRAL: Novel Dikey Modda kalınan sayfaya nokta atışı gidiş
      if (_ilkYukleme && widget.baslangicSayfa != null && AppSettings.novelDikeyMod.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(widget.baslangicSayfa! * 500.0);
          }
        });
        _ilkYukleme = false;
      }
    }
  }

  String _htmlTemizle(String html) {
    String text = html.replaceAll('<br>', '\n').replaceAll('</p>', '\n\n').replaceAll('</div>', '\n');
    return text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  }

  void _menuyuTetikle() {
    setState(() => _menuyuGoster = !_menuyuGoster);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSettings.novelTemasi,
      builder: (context, temaIndex, _) {
        Color bg = _temalar[temaIndex][0];
        Color textC = _temalar[temaIndex][1];

        return Scaffold(
          backgroundColor: bg,
          body: Stack(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: AppSettings.novelDikeyMod,
                builder: (context, dikeyMi, _) {
                  if (_sayfalar.isEmpty && _yukleniyor) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.novelBlue));
                  }
                  return dikeyMi ? _buildDikeyView(textC) : _buildYatayView(textC);
                },
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                top: _menuyuGoster ? 0 : -110,
                left: 0, right: 0,
                child: _ustBar(),
              ),
              
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                bottom: _menuyuGoster ? 0 : -100,
                left: 0, right: 0,
                child: _altAyarBar(temaIndex),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ustBar() {
    return Container(
      height: 110,
      padding: const EdgeInsets.only(top: 50, left: 10, right: 10),
      color: Colors.black.withValues(alpha: 0.9),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.novelAdi, style: GoogleFonts.bangers(color: Colors.white, fontSize: 18), overflow: TextOverflow.ellipsis),
            Text(_sayfalar.isNotEmpty ? "BÖLÜM ${_sayfalar.last.bolumNo}" : "Yükleniyor...", style: const TextStyle(color: AppColors.novelBlue, fontSize: 12, fontWeight: FontWeight.bold)),
          ])),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _altAyarBar(int temaIndex) {
    return Container(
      height: 100,
      color: Colors.black.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(AppSettings.novelDikeyMod.value ? Icons.swap_vert : Icons.swap_horiz, color: Colors.white, size: 30),
            onPressed: () {
              AppSettings.novelDikeyMod.value = !AppSettings.novelDikeyMod.value;
              AppSettings.kaydet('novelDikey', AppSettings.novelDikeyMod.value);
            },
          ),
          _temaButonu(0, const Color(0xFF121212), temaIndex),
          _temaButonu(1, const Color(0xFFF4ECD8), temaIndex),
          _temaButonu(2, Colors.white, temaIndex),
        ],
      ),
    );
  }

  Widget _temaButonu(int index, Color renk, int seciliIndex) {
    return InkWell(
      onTap: () {
        AppSettings.novelTemasi.value = index;
        AppSettings.kaydet('novelTema', index);
      },
      child: Container(
        width: 35, height: 35,
        decoration: BoxDecoration(color: renk, shape: BoxShape.circle, border: Border.all(color: seciliIndex == index ? AppColors.novelBlue : Colors.grey, width: 2)),
      ),
    );
  }

  Widget _buildDikeyView(Color textColor) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _sayfalar.length + (_yukleniyor ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _mevcutEnKucukBolumIndex > 0 
            ? Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: TextButton.icon(onPressed: _oncekiBolumuYukle, icon: const Icon(Icons.keyboard_double_arrow_up, color: AppColors.novelBlue), label: const Text("Önceki Bölüm", style: TextStyle(color: AppColors.novelBlue, fontSize: 18))))
            : const SizedBox(height: 20);
        }
        
        final gercekIndex = index - 1;
        if (gercekIndex == _sayfalar.length) return const Center(child: CircularProgressIndicator(color: AppColors.novelBlue));
        
        return VisibilityDetector(
          key: Key("novel_page_${_sayfalar[gercekIndex].bolumId}_$gercekIndex"),
          onVisibilityChanged: (info) { if (info.visibleFraction > 0.6) _kaydet(gercekIndex); },
          child: GestureDetector(
            onTap: _menuyuTetikle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Text(_sayfalar[gercekIndex].metin, style: TextStyle(color: textColor, fontSize: 18, height: 1.8)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYatayView(Color textColor) {
    return PageView.builder(
      controller: _pageController,
      itemCount: _sayfalar.length + (_mevcutEnKucukBolumIndex > 0 ? 1 : 0),
      onPageChanged: (index) {
        if (_mevcutEnKucukBolumIndex > 0 && index == 0) return; 
        final gercekIndex = _mevcutEnKucukBolumIndex > 0 ? index - 1 : index;
        _kaydet(gercekIndex);
        if (gercekIndex >= _sayfalar.length - 2) _bolumYukle();
      },
      itemBuilder: (context, index) {
        if (_mevcutEnKucukBolumIndex > 0 && index == 0) {
          return Center(child: ElevatedButton.icon(onPressed: _oncekiBolumuYukle, style: ElevatedButton.styleFrom(backgroundColor: AppColors.novelBlue), icon: const Icon(Icons.arrow_back_ios, color: Colors.black), label: const Text("Önceki Bölüm", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))));
        }
        final gercekIndex = _mevcutEnKucukBolumIndex > 0 ? index - 1 : index;
        return GestureDetector(
          onTap: _menuyuTetikle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 120, 25, 100),
            child: Text(_sayfalar[gercekIndex].metin, style: TextStyle(color: textColor, fontSize: 18, height: 1.8)),
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