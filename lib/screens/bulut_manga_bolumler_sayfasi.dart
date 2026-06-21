import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/settings.dart';
import 'bulut_manga_okuyucu_sayfasi.dart';

class BulutMangaBolumlerSayfasi extends StatelessWidget {
  final Map<String, dynamic> manga;
  final Color activeColor;

  const BulutMangaBolumlerSayfasi({super.key, required this.manga, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    List<dynamic> bolumler = manga['bolumler'] ?? [];

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
            iconTheme: IconThemeData(color: activeColor),
            title: Text(
              manga['manga_adi'],
              style: GoogleFonts.bangers(color: activeColor, fontSize: 22, letterSpacing: 1.2),
            ),
          ),
          body: bolumler.isEmpty
              ? Center(child: Text("Bölüm bulunamadı.", style: TextStyle(color: textC)))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: bolumler.length,
                  itemBuilder: (context, index) {
                    final bolum = bolumler[index];
                    return Card(
                      color: karanlikMi ? Colors.grey[900] : Colors.grey[100],
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Icon(Icons.library_books, color: activeColor),
                        title: Text(
                          bolum['bolum_adi'].toString().replaceAll('.cbz', ''),
                          style: TextStyle(color: textC, fontWeight: FontWeight.w500),
                        ),
                        trailing: Icon(Icons.play_arrow, color: activeColor),
                        onTap: () {
                          // KRAL: Artık tüm listeyi ve indexi gönderiyoruz
                          Navigator.push(context, MaterialPageRoute(
                            builder: (c) => BulutMangaOkuyucuSayfasi(
                              tumBolumler: bolumler, 
                              baslangicIndex: index, 
                              mangaIsmi: manga['manga_adi'],
                            )
                          ));
                        },
                      ),
                    );
                  },
                ),
        );
      }
    );
  }
}