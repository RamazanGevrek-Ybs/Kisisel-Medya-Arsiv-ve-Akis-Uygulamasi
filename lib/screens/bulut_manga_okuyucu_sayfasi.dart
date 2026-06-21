import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

import '../services/yerel_veri_servisi.dart';
import '../models/manga.dart';
import '../anime_module/services/anilist_servisi.dart';

class BulutMangaOkuyucuSayfasi extends StatefulWidget {
  final List<dynamic> tumBolumler;
  final int baslangicIndex;
  final String mangaIsmi;

  const BulutMangaOkuyucuSayfasi({
    super.key, 
    required this.tumBolumler, 
    required this.baslangicIndex, 
    required this.mangaIsmi
  });

  @override
  State<BulutMangaOkuyucuSayfasi> createState() => _BulutMangaOkuyucuSayfasiState();
}

class _BulutMangaOkuyucuSayfasiState extends State<BulutMangaOkuyucuSayfasi> {
  static final Map<String, List<Uint8List>> _cbzCache = {};

  final String apiKey = "BURAYA_KENDI_DRIVE_API_ANAHTARINIZI_YAZIN";
  final ScrollController _scrollController = ScrollController();

  List<Uint8List> _ekrandakiSayfalar = [];
  
  bool _anaYukleniyor = true;
  late int _aktifIndex;
  String _guncelBolumAdi = "";
  bool _menuAcik = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _aktifIndex = widget.baslangicIndex;
    _guncelBolumAdi = widget.tumBolumler[_aktifIndex]['bolum_adi'].toString().replaceAll('.cbz', '');
    
    _ilkBolumuYukle();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Uint8List>> _cbzMotoru(String driveId) async {
    if (_cbzCache.containsKey(driveId)) return _cbzCache[driveId]!;

    try {
      final url = "https://www.googleapis.com/drive/v3/files/$driveId?alt=media&key=$apiKey";
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);
        List<ArchiveFile> dosyalar = archive.where((f) => f.isFile && 
          (f.name.endsWith('.jpg') || f.name.endsWith('.png') || f.name.endsWith('.jpeg'))).toList();
        
        dosyalar.sort((a, b) => a.name.compareTo(b.name));
        List<Uint8List> sayfalar = dosyalar.map((f) => f.content as Uint8List).toList();
        
        _cbzCache[driveId] = sayfalar;
        return sayfalar;
      }
    } catch (e) { debugPrint("CBZ Motor Hatası: $e"); }
    return [];
  }

  Future<void> _ilkBolumuYukle() async {
    final driveId = widget.tumBolumler[_aktifIndex]['drive_id'];
    final sayfalar = await _cbzMotoru(driveId);

    if (sayfalar.isNotEmpty) {
      _gecmiseKaydet();
      setState(() {
        _ekrandakiSayfalar = sayfalar;
        _anaYukleniyor = false;
      });
    }
  }

  Future<void> _gecmiseKaydet() async {
    String driveId = widget.tumBolumler[_aktifIndex]['drive_id'];
    String kapakUrl = await AniListServisi.mangaKapakGetir(widget.mangaIsmi);
    
    // KRAL FIX 1: ID olarak bölümü değil, Manganın adını kullanıyoruz.
    // Böylece listede 5 tane aynı manga görünmez, eski kayıt silinip en üste günceli gelir.
    Manga bulutManga = Manga(
      id: "bulut_${widget.mangaIsmi}", 
      isim: widget.mangaIsmi,
      kapakResmi: kapakUrl.isNotEmpty ? kapakUrl : "bulut_ikon", 
      ozet: "Kaldığın Bölüm: $_guncelBolumAdi", // Oku kısmında hangi bölümde kaldığını gösterecek
      puan: 10.0,
      turler: ["Bulut", "Manga"],
    );
    await YerelVeriServisi.sonOkunanEkle(bulutManga, true);
    
    // KRAL FIX 2: İlerlemeyi kaydediyoruz (Bölüm ID'sini ve şimdilik 0. sayfayı tutuyoruz)
    await YerelVeriServisi.ilerlemeyiKaydet("bulut_${widget.mangaIsmi}", driveId, 0);
  }

  void _sonrakiBolumeGec() {
    if (_aktifIndex + 1 < widget.tumBolumler.length) {
      setState(() {
        _aktifIndex++;
        _guncelBolumAdi = widget.tumBolumler[_aktifIndex]['bolum_adi'].toString().replaceAll('.cbz', '');
        _anaYukleniyor = true;
        _ekrandakiSayfalar = [];
      });
      _ilkBolumuYukle();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, 
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _menuAcik ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !_menuAcik, 
            child: AppBar(
              title: Text("${widget.mangaIsmi} - $_guncelBolumAdi", style: const TextStyle(fontSize: 14)),
              backgroundColor: Colors.black.withOpacity(0.85),
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _menuAcik = !_menuAcik;
          });
        },
        child: _anaYukleniyor 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              controller: _scrollController,
              itemCount: _ekrandakiSayfalar.length + 1,
              itemBuilder: (context, index) {
                if (index == _ekrandakiSayfalar.length) {
                  // KRAL FIX 3: Sonsuz kaydırmayı kaldırdık, yerine şık bir buton ekledik.
                  return _aktifIndex + 1 < widget.tumBolumler.length
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            padding: const EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onPressed: _sonrakiBolumeGec,
                          icon: const Icon(Icons.arrow_downward, color: Colors.white),
                          label: const Text("Sonraki Bölüme Geç", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: Text("Seri Güncele Geldi Kral!", style: TextStyle(color: Colors.grey))),
                      );
                }
                return Image.memory(_ekrandakiSayfalar[index], fit: BoxFit.fitWidth);
              },
            ),
      ),
    );
  }
}