import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:file_picker/file_picker.dart'; 

import '../core/colors.dart';
import '../core/settings.dart';
import '../services/yerel_veri_servisi.dart'; 

class AyarlarSayfasi extends StatefulWidget {
  const AyarlarSayfasi({super.key});

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  String _onbellekBoyutu = "Hesaplanıyor...";
  bool _temizleniyor = false;
  bool _islemYapiliyor = false; 

  @override
  void initState() {
    super.initState();
    _gercekOnbellekHesapla();
  }

  Future<void> _gercekOnbellekHesapla() async {
    try {
      final tempDir = await getTemporaryDirectory();
      double totalSize = await _getDirSize(tempDir);
      
      if (mounted) {
        setState(() {
          _onbellekBoyutu = totalSize > 0 
            ? "${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB" 
            : "0.00 MB";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _onbellekBoyutu = "Bilinmiyor");
      }
    }
  }

  Future<double> _getDirSize(Directory dir) async {
    double size = 0;
    try {
      if (dir.existsSync()) {
        dir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
          if (entity is File) {
            size += entity.lengthSync();
          }
        });
      }
    } catch (e) {
      // Hata olursa es geç
    }
    return size;
  }

  void _onbellekTemizle() async {
    setState(() {
      _temizleniyor = true;
      _onbellekBoyutu = "Temizleniyor...";
    });
    
    await DefaultCacheManager().emptyCache();
    
    await Future.delayed(const Duration(milliseconds: 1500)); 
    await _gercekOnbellekHesapla();
    
    setState(() => _temizleniyor = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Önbellek tertemiz edildi!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    }
  }

  Future<void> _verileriYedekle() async {
    if (_islemYapiliyor) {
      return;
    }
    setState(() => _islemYapiliyor = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final prefsMap = <String, dynamic>{};
      
      for (String key in keys) {
        prefsMap[key] = prefs.get(key);
      }
      
      String jsonString = jsonEncode(prefsMap);

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        
        String dosyaAdi = 'MangaHub_Yedek_${DateTime.now().millisecondsSinceEpoch}.json';
        String filePath = '${dir.path}/$dosyaAdi';
        File file = File(filePath);
        await file.writeAsString(jsonString);

        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Yedek başarıyla alındı!\nKonum: İndirilenler / $dosyaAdi", style: const TextStyle(color: Colors.white)), 
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          )
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yedekleme başarısız oldu. İzinleri kontrol edin."), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _islemYapiliyor = false);
      }
    }
  }

  Future<void> _yedekGeriYukle() async {
    if (_islemYapiliyor) {
      return;
    }
    setState(() => _islemYapiliyor = true);

    try {
      // KRAL: Burada da .platform kelimesini kaldırdık
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        Map<String, dynamic> prefsMap = jsonDecode(jsonString);

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); 
        
        for (String key in prefsMap.keys) {
          var value = prefsMap[key];
          
          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          } else if (value is List) {
            await prefs.setStringList(key, value.map((e) => e.toString()).toList());
          }
        }

        await YerelVeriServisi.baslat();

        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tebrikler! Yedek başarıyla geri yüklendi.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          )
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Geri yükleme hatası: Dosya bozuk veya hatalı!"), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _islemYapiliyor = false);
      }
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
            title: Text("AYARLAR", style: GoogleFonts.bangers(fontSize: 24, color: textC, letterSpacing: 1.2)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textC),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(), 
            children: [
              const Padding(padding: EdgeInsets.all(16.0), child: Text("Görünüm", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
              
              SwitchListTile(
                title: Text("Karanlık Tema", style: TextStyle(fontSize: 18, color: textC)),
                subtitle: Text(karanlikMi ? "Göz yormayan zifiri mod" : "Aydınlık ve ferah mod", style: const TextStyle(color: Colors.grey)),
                activeThumbColor: Colors.orange,
                value: karanlikMi,
                onChanged: (deger) {
                  AppSettings.karanlikTemaModu.value = deger;
                  AppSettings.kaydet('globalKaranlik', deger);
                },
              ),
              
              Divider(color: karanlikMi ? Colors.white24 : Colors.grey[300], height: 30),
              
              const Padding(padding: EdgeInsets.all(16.0), child: Text("Okuyucu Ayarları", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
              _ayarItem("Manga Okuma Stili", AppSettings.mangaDikeyMod, 'mangaDikey', textC),
              _ayarItem("Novel Okuma Stili", AppSettings.novelDikeyMod, 'novelDikey', textC),

              Divider(color: karanlikMi ? Colors.white24 : Colors.grey[300], height: 30),

              const Padding(padding: EdgeInsets.all(16.0), child: Text("Sistem ve Kurtarma", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
              
              ListTile(
                leading: _islemYapiliyor 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
                  : Icon(Icons.cloud_upload_outlined, color: textC),
                title: Text("Verilerimi Yedekle", style: TextStyle(fontSize: 18, color: textC)),
                subtitle: const Text("Kütüphane, geçmiş ve rozetleri cihazına kaydet", style: TextStyle(color: Colors.grey)),
                onTap: _verileriYedekle,
              ),

              ListTile(
                leading: _islemYapiliyor 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
                  : Icon(Icons.restore_page_outlined, color: textC),
                title: Text("Yedeği Geri Yükle", style: TextStyle(fontSize: 18, color: textC)),
                subtitle: const Text("JSON dosyasından tüm hesabını kurtar", style: TextStyle(color: Colors.grey)),
                onTap: _yedekGeriYukle,
              ),

              Divider(color: karanlikMi ? Colors.white24 : Colors.grey[300], height: 30),

              const Padding(padding: EdgeInsets.all(16.0), child: Text("Depolama Temizliği", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
              ListTile(
                leading: _temizleniyor 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2))
                  : Icon(Icons.cleaning_services, color: textC),
                title: Text("Önbelleği Temizle", style: TextStyle(fontSize: 18, color: textC)),
                subtitle: Text("Geçici resim dosyalarını siler ($_onbellekBoyutu)", style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  if (!_temizleniyor && _onbellekBoyutu != "0.00 MB") {
                    _onbellekTemizle();
                  }
                },
              ),
              
              const SizedBox(height: 50),
            ],
          ),
        );
      }
    );
  }

  Widget _ayarItem(String baslik, ValueNotifier<bool> notifier, String key, Color textC) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, dikeyMi, _) {
        return ListTile(
          title: Text(baslik, style: TextStyle(fontSize: 18, color: textC)),
          subtitle: Text(dikeyMi ? "Dikey (Aşağı Kaydır)" : "Yatay (Sayfa Çevir)", style: const TextStyle(color: Colors.grey)),
          trailing: Icon(Icons.swap_horiz, color: textC.withValues(alpha: 0.5)),
          onTap: () {
            notifier.value = !dikeyMi;
            AppSettings.kaydet(key, !dikeyMi);
          },
        );
      }
    );
  }
}