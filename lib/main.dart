import 'dart:io'; // KRAL: Sertifika sorununu çözmek için eklendi
import 'package:flutter/material.dart';
import 'screens/splash_ekrani.dart'; 
import 'core/colors.dart';
import 'services/yerel_veri_servisi.dart';
import 'core/settings.dart';

// KRAL: Güvenlik duvarını (SSL/Sertifika hatalarını) delen özel sınıfımız
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // KRAL DEVRİMİ: Sitelerin "Sertifikan geçersiz" diyerek koyduğu engelleri yoksayan komut
  HttpOverrides.global = MyHttpOverrides();
  
  await YerelVeriServisi.baslat(); 
  AppSettings.yukle(); 
  
  runApp(const MangaApp());
}

class MangaApp extends StatelessWidget {
  const MangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema modunu dinliyoruz
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.karanlikTemaModu,
      builder: (context, karanlikMi, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: karanlikMi ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.orange,
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.darkBg,
          ),
          home: const SplashEkrani(), // KRAL BURASI SPLASH EKRANI OLARAK DEĞİŞTİ
        );
      },
    );
  }
}