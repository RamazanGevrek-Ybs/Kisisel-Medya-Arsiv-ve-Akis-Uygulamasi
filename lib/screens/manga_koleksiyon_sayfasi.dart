import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/settings.dart';
// KRAL: İşte o hayati klasör yapısına göre düzeltilmiş import burası
import '../anime_module/services/anilist_servisi.dart'; 
import 'bulut_manga_bolumler_sayfasi.dart'; 

class LisansliMangalarSayfasi extends StatefulWidget {
  final Color activeColor;

  const LisansliMangalarSayfasi({super.key, required this.activeColor});

  @override
  State<LisansliMangalarSayfasi> createState() => _LisansliMangalarSayfasiState();
}

class _LisansliMangalarSayfasiState extends State<LisansliMangalarSayfasi> {
  List<dynamic> _mangaArsivi = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _jsonYukle();
  }

  Future<void> _jsonYukle() async {
    try {
      final String data = await rootBundle.loadString('assets/data/manga_arsivi.json');
      setState(() {
        _mangaArsivi = jsonDecode(data);
        _yukleniyor = false;
      });
    } catch (e) {
      debugPrint("JSON Yükleme Hatası: $e");
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.karanlikTemaModu,
      builder: (context, karanlikMi, _) {
        Color bg = karanlikMi ? AppColors.darkBg : Colors.white;
        Color textC = karanlikMi ? Colors.white : Colors.black87;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            iconTheme: IconThemeData(color: widget.activeColor),
            title: Text(
              "Bulut Arşivim",
              style: GoogleFonts.bangers(
                color: widget.activeColor, 
                fontSize: 24, 
                letterSpacing: 1.2
              ),
            ),
          ),
          body: _yukleniyor
              ? Center(child: CircularProgressIndicator(color: widget.activeColor))
              : _mangaArsivi.isEmpty
                  ? Center(child: Text("Arşiv bulunamadı.", style: TextStyle(color: textC)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(15),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: _mangaArsivi.length,
                      itemBuilder: (context, index) {
                        final manga = _mangaArsivi[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (c) => BulutMangaBolumlerSayfasi(
                                manga: manga, 
                                activeColor: widget.activeColor
                              )
                            ));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: FutureBuilder<String>(
                                    future: AniListServisi.mangaKapakGetir(manga['manga_adi']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Container(
                                          color: widget.activeColor.withOpacity(0.1),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2, 
                                              color: widget.activeColor
                                            ),
                                          ),
                                        );
                                      } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                        return Image.network(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        );
                                      } else {
                                        return Container(
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.menu_book, 
                                            color: Colors.white54, 
                                            size: 40
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                manga['manga_adi'] ?? "Bilinmeyen Manga",
                                style: TextStyle(
                                  color: textC, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 14
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "${manga['toplam_bolum']} Bölüm",
                                style: TextStyle(
                                  color: widget.activeColor, 
                                  fontSize: 12
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}