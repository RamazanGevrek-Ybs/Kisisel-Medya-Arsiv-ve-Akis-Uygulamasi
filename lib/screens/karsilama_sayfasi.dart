import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import 'ana_sayfa.dart';

class KarsilamaSayfasi extends StatelessWidget {
  const KarsilamaSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/appicon.png', height: 100, errorBuilder: (c, e, s) => const Icon(Icons.auto_stories, color: Colors.white, size: 80)),
              const SizedBox(height: 40),
              
              Text("KÜTÜPHANEYE HOŞ GELDİN", style: GoogleFonts.bangers(fontSize: 32, color: Colors.white, letterSpacing: 2), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text("Hangi dünyaya adım atmak istersin?", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 50),
              
              _secimButonu(
                context: context,
                baslik: "MANGA OKU",
                altBaslik: "Çizgi roman ve mangaları keşfet",
                ikon: Icons.chat_bubble_outline,
                renk: AppColors.mangaOrange,
                modIndex: 0, // 0: Manga Modu
              ),
              
              const SizedBox(height: 20),

              _secimButonu(
                context: context,
                baslik: "ANİME İZLE",
                altBaslik: "Favori serilerini reklamsız izle",
                ikon: Icons.movie_outlined,
                renk: Colors.deepPurpleAccent, // Anime için özel renk
                modIndex: 1, // 1: Anime Modu
              ),
              
              const SizedBox(height: 20),
              
              _secimButonu(
                context: context,
                baslik: "NOVEL OKU",
                altBaslik: "Light novel ve serileri oku",
                ikon: Icons.menu_book,
                renk: AppColors.novelBlue,
                modIndex: 2, // 2: Novel Modu
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secimButonu({required BuildContext context, required String baslik, required String altBaslik, required IconData ikon, required Color renk, required int modIndex}) {
    return InkWell(
      onTap: () {
        // KRAL: Test işimiz bitti, artık 3 buton da ait olduğu mod ile Ana Sayfaya gidiyor.
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => AnaSayfa(baslangicModu: modIndex)));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: renk.withValues(alpha: 0.5), width: 2),
          boxShadow: [BoxShadow(color: renk.withValues(alpha: 0.15), blurRadius: 15, spreadRadius: 2)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15), 
              decoration: BoxDecoration(color: renk.withValues(alpha: 0.1), shape: BoxShape.circle), 
              child: Icon(ikon, color: renk, size: 32)
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: GoogleFonts.bangers(fontSize: 24, color: Colors.white, letterSpacing: 1.5)),
                  const SizedBox(height: 5),
                  Text(altBaslik, style: const TextStyle(color: Colors.grey, fontSize: 13)), 
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: renk, size: 20),
          ],
        ),
      ),
    );
  }
}