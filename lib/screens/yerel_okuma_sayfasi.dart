import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; 
import 'package:visibility_detector/visibility_detector.dart'; 
import '../core/colors.dart';
import '../core/settings.dart';
import '../models/manga.dart';
import '../services/yerel_veri_servisi.dart';

List<String> _metniSayfalaraBol(String metin) {
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
  return sayfalar;
}

class YerelOkumaSayfasi extends StatefulWidget {
  final Manga manga;
  final List<String> dosyaYollari;
  final bool isManga;
  final int? baslangicSayfa;

  const YerelOkumaSayfasi({super.key, required this.manga, required this.dosyaYollari, required this.isManga, this.baslangicSayfa});

  @override
  State<YerelOkumaSayfasi> createState() => _YerelOkumaSayfasiState();
}

class _YerelOkumaSayfasiState extends State<YerelOkumaSayfasi> {
  bool _menuyuGoster = false;
  bool _isPdf = false; 
  
  List<String> _novelSayfalar = [];
  
  late PdfViewerController _pdfController;
  late ScrollController _scrollController;
  late PageController _pageController;

  final List<List<Color>> _temalar = [
    [const Color(0xFF121212), Colors.white70], 
    [const Color(0xFFF4ECD8), const Color(0xFF5B4636)], 
    [Colors.white, Colors.black87], 
  ];

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _scrollController = ScrollController();
    
    final kayit = YerelVeriServisi.ilerlemeyiGetir(widget.manga.id);
    int acilacakSayfa = widget.baslangicSayfa ?? (kayit != null ? (kayit['sayfaIndex'] ?? 0) : 0);
    _pageController = PageController(initialPage: acilacakSayfa);
    
    if (widget.dosyaYollari.isNotEmpty) {
      _isPdf = widget.dosyaYollari.first.toLowerCase().endsWith('.pdf');
    }

    if (!widget.isManga && !_isPdf && widget.dosyaYollari.isNotEmpty) {
      _novelDosyasiOku(widget.dosyaYollari.first);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (acilacakSayfa > 0) {
        if (_isPdf) {
          _pdfController.jumpToPage(acilacakSayfa + 1); 
        } else if (widget.isManga && AppSettings.mangaDikeyMod.value) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(acilacakSayfa * MediaQuery.of(context).size.height * 0.8);
          }
        } else if (!widget.isManga && !_isPdf && AppSettings.novelDikeyMod.value) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(acilacakSayfa * 500.0);
          }
        }
      }
    });
  }

  Future<void> _novelDosyasiOku(String yol) async {
    try {
      String metin = await File(yol).readAsString();
      List<String> sayfalar = await compute(_metniSayfalaraBol, metin);
      if (mounted) setState(() => _novelSayfalar = sayfalar);
    } catch (e) {
      if (mounted) setState(() => _novelSayfalar = ["Dosya okunamadı. TXT formatında olduğundan emin olun."]);
    }
  }

  void _ilerlemeyiKaydet(int index) {
    YerelVeriServisi.ilerlemeyiKaydet(widget.manga.id, "yerel_bolum", index);
  }

  void _menuyuTetikle() {
    setState(() => _menuyuGoster = !_menuyuGoster);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.karanlikTemaModu,
      builder: (context, karanlikMi, _) {
        return ValueListenableBuilder<int>(
          valueListenable: AppSettings.novelTemasi,
          builder: (context, temaIndex, _) {
            
            Color bg = (_isPdf || widget.isManga) ? (karanlikMi ? AppColors.darkBg : Colors.white) : _temalar[temaIndex][0];
            Color textC = (_isPdf || widget.isManga) ? (karanlikMi ? Colors.white : Colors.black87) : _temalar[temaIndex][1];

            return Scaffold(
              backgroundColor: bg,
              body: Stack(
                children: [
                  _isPdf 
                      ? _buildPdfOkuyucu(bg, temaIndex) // KRAL: temaIndex içeri gönderildi
                      : (widget.isManga ? _buildMangaOkuyucu() : _buildNovelOkuyucu(textC)),

                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.25,
                    bottom: MediaQuery.of(context).size.height * 0.25,
                    left: MediaQuery.of(context).size.width * 0.25,
                    right: MediaQuery.of(context).size.width * 0.25,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _menuyuTetikle,
                      child: Container(),
                    ),
                  ),

                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
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
                            Text(widget.manga.isim, style: GoogleFonts.bangers(fontSize: 18, color: Colors.white), overflow: TextOverflow.ellipsis),
                            Text(_isPdf ? "Yerel PDF Okuyucu" : (widget.isManga ? "Yerel Manga Okuyucu" : "Yerel Novel Okuyucu"), style: TextStyle(color: widget.isManga ? Colors.orange : Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                          ])),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),

                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    bottom: _menuyuGoster ? 0 : -100,
                    left: 0, right: 0,
                    child: Container(
                      height: 100,
                      color: Colors.black.withValues(alpha: 0.9),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: widget.isManga ? AppSettings.mangaDikeyMod : AppSettings.novelDikeyMod,
                            builder: (context, dikeyMi, _) {
                              return IconButton(
                                icon: Icon(dikeyMi ? Icons.swap_vert : Icons.swap_horiz, color: Colors.white, size: 30),
                                onPressed: () {
                                  if (widget.isManga) {
                                    AppSettings.mangaDikeyMod.value = !dikeyMi;
                                    AppSettings.kaydet('mangaDikey', !dikeyMi);
                                  } else {
                                    AppSettings.novelDikeyMod.value = !dikeyMi;
                                    AppSettings.kaydet('novelDikey', !dikeyMi);
                                  }
                                },
                              );
                            }
                          ),
                          
                          // KRAL DEVRİMİ: Artık PDF okurken de tema butonları açılacak!
                          if (!widget.isManga || _isPdf) ...[
                            _temaButonu(0, const Color(0xFF121212), temaIndex),
                            _temaButonu(1, const Color(0xFFF4ECD8), temaIndex),
                            _temaButonu(2, Colors.white, temaIndex),
                          ]
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

  // KRAL: PDF için Optik Lens Filtresi (Matris Algoritması)
  Widget _buildPdfOkuyucu(Color bgColor, int temaIndex) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isManga ? AppSettings.mangaDikeyMod : AppSettings.novelDikeyMod,
      builder: (context, dikeyMi, _) {
        
        Widget pdfWidget = Container(
          color: bgColor, 
          padding: const EdgeInsets.only(top: 40), 
          child: SfPdfViewer.file(
            File(widget.dosyaYollari.first),
            controller: _pdfController,
            canShowScrollHead: false, 
            pageSpacing: 4, 
            pageLayoutMode: dikeyMi ? PdfPageLayoutMode.continuous : PdfPageLayoutMode.single,
            scrollDirection: dikeyMi ? PdfScrollDirection.vertical : PdfScrollDirection.horizontal,
            onPageChanged: (details) => _ilerlemeyiKaydet(details.newPageNumber - 1),
          ),
        );

        // Tema 0: Gece Modu (Bütün renklerin değerlerini matematsel olarak tersine çevir - Invert Matrix)
        if (temaIndex == 0) {
          return ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              -1,  0,  0, 0, 255,
               0, -1,  0, 0, 255,
               0,  0, -1, 0, 255,
               0,  0,  0, 1,   0,
            ]),
            child: pdfWidget,
          );
        } 
        // Tema 1: Sepya / Kitap Modu (Multiply tekniğiyle beyaz renkleri eski kitap sarısına boyar, siyahı korur)
        else if (temaIndex == 1) {
          return ColorFiltered(
            colorFilter: const ColorFilter.mode(Color(0xFFD7C4A5), BlendMode.multiply),
            child: pdfWidget,
          );
        }
        
        // Tema 2: Normal Beyaz (Filtresiz)
        return pdfWidget;
      }
    );
  }

  Widget _buildMangaOkuyucu() {
    if (widget.dosyaYollari.isEmpty) return const Center(child: Text("Resim seçilmedi."));
    
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.mangaDikeyMod,
      builder: (context, dikeyMi, _) {
        return dikeyMi 
          ? ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              cacheExtent: 100, 
              addAutomaticKeepAlives: false, 
              addRepaintBoundaries: true,
              itemCount: widget.dosyaYollari.length,
              itemBuilder: (context, index) {
                return VisibilityDetector(
                  key: Key("yerel_manga_$index"),
                  onVisibilityChanged: (info) { if (info.visibleFraction > 0.6) _ilerlemeyiKaydet(index); },
                  child: InteractiveViewer(
                    minScale: 1.0, maxScale: 4.0,
                    child: Image.file(
                      File(widget.dosyaYollari[index]), 
                      fit: BoxFit.fitWidth, 
                      width: double.infinity, 
                      gaplessPlayback: true,
                      cacheWidth: 720, 
                      filterQuality: FilterQuality.none, 
                    ),
                  ),
                );
              },
            )
          : PageView.builder(
              controller: _pageController,
              allowImplicitScrolling: false, 
              itemCount: widget.dosyaYollari.length,
              onPageChanged: (i) => _ilerlemeyiKaydet(i),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0, maxScale: 4.0,
                  child: SizedBox.expand(
                    child: Image.file(
                      File(widget.dosyaYollari[index]), 
                      fit: BoxFit.contain, 
                      gaplessPlayback: true,
                      cacheWidth: 720, 
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                );
              },
            );
      }
    );
  }

  Widget _buildNovelOkuyucu(Color textColor) {
    if (_novelSayfalar.isEmpty) return const Center(child: CircularProgressIndicator());
    
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.novelDikeyMod,
      builder: (context, dikeyMi, _) {
        return dikeyMi
          ? ListView.builder(
              controller: _scrollController,
              itemCount: _novelSayfalar.length,
              itemBuilder: (context, index) {
                return VisibilityDetector(
                  key: Key("yerel_novel_$index"),
                  onVisibilityChanged: (info) { if (info.visibleFraction > 0.6) _ilerlemeyiKaydet(index); },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                    child: Text(_novelSayfalar[index], style: TextStyle(color: textColor, fontSize: 18, height: 1.8)),
                  ),
                );
              },
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: _novelSayfalar.length,
              onPageChanged: (i) => _ilerlemeyiKaydet(i),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(25, 120, 25, 100),
                  child: Text(_novelSayfalar[index], style: TextStyle(color: textColor, fontSize: 18, height: 1.8)),
                );
              },
            );
      }
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _pdfController.dispose();
    super.dispose();
  }
}