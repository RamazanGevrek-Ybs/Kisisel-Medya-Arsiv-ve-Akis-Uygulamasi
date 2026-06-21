import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../services/api_service.dart';
import 'karsilama_sayfasi.dart';

class SplashEkrani extends StatefulWidget {
  const SplashEkrani({super.key});

  @override
  State<SplashEkrani> createState() => _SplashEkraniState();
}

class _SplashEkraniState extends State<SplashEkrani> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animasyon;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animasyon = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _hazirlikYap();
  }

  Future<void> _hazirlikYap() async {
    // KRAL: Burada API servisini çağırıyoruz. 
    // İçerideki o 1 saniyelik bekleme süreleriyle birlikte tüm verileri güvenle indirecek.
    await ApiService.herSeyiDugumle();

    // Veriler indi! Şimdi ana sayfaya geçebiliriz.
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const KarsilamaSayfasi()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: FadeTransition(
          opacity: _animasyon,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/appicon.png', height: 120, 
                errorBuilder: (c, e, s) => const Icon(Icons.auto_stories, color: AppColors.mangaOrange, size: 80)),
              const SizedBox(height: 30),
              Text("Toshokan", style: GoogleFonts.bangers(fontSize: 36, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text("Manga, Novel ve Anime arşiviniz yükleniyor...", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: AppColors.mangaOrange, strokeWidth: 3),
            ],
          ),
        ),
      ),
    );
  }
}