import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart'; 

import '../core/colors.dart';
import '../core/settings.dart';
import '../models/manga.dart';
import '../services/yerel_veri_servisi.dart';
import '../screens/kutuphane_sayfasi.dart';
import '../screens/uzantilar_sayfasi.dart';
import '../screens/ayarlar_sayfasi.dart';
import '../screens/yerel_okuma_sayfasi.dart'; 
import '../screens/istatistikler_sayfasi.dart';
import '../screens/rozetler_sayfasi.dart';
import '../screens/karsilama_sayfasi.dart';
import '../screens/manga_koleksiyon_sayfasi.dart'; 
import '../screens/novel_kutuphane_sayfasi.dart'; // BURAYA DİKKAT: Yeni sayfayı ekledik

class YanMenu extends StatelessWidget {
  final Color activeColor;
  final int aktifMod; // 0=Manga, 1=Anime, 2=Novel

  const YanMenu({super.key, required this.activeColor, required this.aktifMod});

  Future<void> _yerelDosyaSec(BuildContext context) async {
    bool isMangaMode = aktifMod == 0;
    
    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: isMangaMode, 
      type: FileType.custom,
      allowedExtensions: isMangaMode ? ['jpg', 'jpeg', 'png', 'pdf'] : ['txt', 'pdf', 'epub'], // epub eklendi
    );

    if (result != null) {
      if (!context.mounted) return;
      Navigator.pop(context); 

      List<String> yollar = result.paths.whereType<String>().toList();
      String dosyaAdi = result.files.single.name;
      
      if (isMangaMode && yollar.length > 1) {
        dosyaAdi = "Yerel Manga (${yollar.length} Sayfa)";
      }

      String tumYollar = yollar.join("|");
      String uniqueId = "yerel_${yollar.first.hashCode}";

      Manga yerelManga = Manga(
        id: uniqueId,
        isim: dosyaAdi,
        kapakResmi: "yerel_ikon", 
        ozet: "YerelDosyalar:$tumYollar",
        puan: 9.9,
        turler: ["Yerel", isMangaMode ? "Manga" : "Novel"],
      );

      await YerelVeriServisi.favoriGuncelle(yerelManga, true, isMangaMode);
      await YerelVeriServisi.sonOkunanEkle(yerelManga, isMangaMode);

      if (!context.mounted) return;

      Navigator.push(context, CupertinoPageRoute(
        builder: (c) => YerelOkumaSayfasi(
          manga: yerelManga, 
          dosyaYollari: yollar, 
          isManga: isMangaMode
        )
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.karanlikTemaModu,
      builder: (context, karanlikMi, _) {
        
        Color bg = karanlikMi ? AppColors.darkBg : Colors.white;
        Color textC = karanlikMi ? Colors.white : Colors.black87;
        Color altTextC = karanlikMi ? Colors.white70 : Colors.black54;
        Color cizgiRengi = karanlikMi ? activeColor.withValues(alpha: 0.5) : activeColor.withValues(alpha: 0.2);

        String baslikYazisi = aktifMod == 0 ? "Manga Edition" : (aktifMod == 1 ? "Anime Edition" : "Novel Edition");

        return Drawer(
          backgroundColor: bg,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: cizgiRengi, width: 1)),
                  gradient: LinearGradient(
                    colors: [activeColor.withValues(alpha: karanlikMi ? 0.1 : 0.05), Colors.transparent],
                    begin: Alignment.topCenter, 
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/appicon.png', 
                        height: 60, 
                        errorBuilder: (c, e, s) => Icon(Icons.auto_awesome, color: activeColor, size: 50)
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Toshokan", 
                        style: GoogleFonts.bangers(fontSize: 22, color: textC, letterSpacing: 2.5)
                      ),
                      Text(
                        baslikYazisi, 
                        style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                      ),
                    ],
                  ),
                ),
              ),
              
              _drawerItem(context, Icons.home_outlined, "Ana Sayfa", () {
                Navigator.pushAndRemoveUntil(
                  context, 
                  CupertinoPageRoute(builder: (c) => const KarsilamaSayfasi()),
                  (route) => false
                );
              }, textC, altTextC),
              
              _drawerItem(context, Icons.library_books_outlined, "Kütüphanem", () {
                Navigator.push(context, CupertinoPageRoute(
                  builder: (c) => KutuphaneSayfasi(activeColor: activeColor, aktifMod: aktifMod)
                ));
              }, textC, altTextC),
              
              if (aktifMod != 1) 
                _drawerItem(context, aktifMod == 0 ? Icons.image_search : Icons.document_scanner, "Cihazdan Oku", () {
                  _yerelDosyaSec(context);
                }, textC, altTextC),

              if (aktifMod == 0)
                _drawerItem(context, Icons.cloud_done_outlined, "Lisanslı Mangalar", () {
                  Navigator.pop(context); 
                  Navigator.push(context, CupertinoPageRoute(
                    builder: (c) => LisansliMangalarSayfasi(activeColor: activeColor)
                  ));
                }, textC, altTextC, ikonRengi: activeColor),

              // YENİ EKLENEN KISIM: Sadece Novel modunda gözükecek
              if (aktifMod == 2)
                _drawerItem(context, Icons.menu_book_outlined, "Lisanslı Noveller", () {
                  Navigator.pop(context); 
                  Navigator.push(context, CupertinoPageRoute(
                    builder: (c) => LisansliNovellerSayfasi(activeColor: activeColor)
                  ));
                }, textC, altTextC, ikonRengi: activeColor),

              _drawerItem(context, Icons.analytics_outlined, "Okuma ve İzleme Analizi", () {
                Navigator.push(context, CupertinoPageRoute(builder: (c) => const IstatistiklerSayfasi()));
              }, textC, altTextC),
              
              _drawerItem(context, Icons.emoji_events_outlined, "Başarılar ve Rozetler", () {
                Navigator.push(context, CupertinoPageRoute(builder: (c) => const RozetlerSayfasi()));
              }, textC, altTextC),

              _drawerItem(context, Icons.extension_outlined, "Uzantılar ve Repo", () {
                Navigator.push(context, CupertinoPageRoute(builder: (c) => const UzantilarSayfasi()));
              }, textC, altTextC),
              
              _drawerItem(context, Icons.settings_outlined, "Ayarlar", () {
                Navigator.push(context, CupertinoPageRoute(builder: (c) => const AyarlarSayfasi()));
              }, textC, altTextC),
              
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "v1.1.1", 
                  style: TextStyle(color: Colors.grey[500], fontSize: 12), 
                  textAlign: TextAlign.center
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String text, VoidCallback onTap, Color textC, Color altTextC, {Color? ikonRengi}) {
    return ListTile(
      leading: Icon(icon, color: ikonRengi ?? altTextC),
      title: Text(text, style: TextStyle(color: textC, fontSize: 16)),
      onTap: onTap,
    );
  }
}