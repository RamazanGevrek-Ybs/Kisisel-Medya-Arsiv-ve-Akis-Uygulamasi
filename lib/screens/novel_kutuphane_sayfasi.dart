import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../anime_module/services/anilist_servisi.dart'; // KRAL: Yol senin klasörüne göre düzeltildi
import '../models/manga.dart';
import 'epub_okuma_sayfasi.dart';

class LisansliNovellerSayfasi extends StatefulWidget {
  final Color activeColor;
  const LisansliNovellerSayfasi({super.key, required this.activeColor});

  @override
  State<LisansliNovellerSayfasi> createState() => _LisansliNovellerSayfasiState();
}

class _LisansliNovellerSayfasiState extends State<LisansliNovellerSayfasi> {
  Map<String, dynamic> _novelVerileri = {};
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _jsonYukle();
  }

  Future<void> _jsonYukle() async {
    try {
      final String response = await rootBundle.loadString('assets/data/novel_arsivi.json');
      setState(() {
        _novelVerileri = json.decode(response);
        _yukleniyor = false;
      });
    } catch (e) {
      debugPrint("Novel JSON yüklenemedi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) return Scaffold(body: Center(child: CircularProgressIndicator(color: widget.activeColor)));
    List<String> seriler = _novelVerileri.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Lisanslı Noveller", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: seriler.length,
        itemBuilder: (context, index) {
          String seriAdi = seriler[index];
          List bolumlerData = _novelVerileri[seriAdi];

          return FutureBuilder(
            future: AniListServisi.mangaKapakGetir(seriAdi), 
            builder: (context, AsyncSnapshot<String?> snapshot) {
              String kapakUrl = snapshot.data ?? "";
              return GestureDetector(
                onTap: () => _bolumleriGoster(context, seriAdi, bolumlerData, kapakUrl),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: kapakUrl.isNotEmpty ? NetworkImage(kapakUrl) : const AssetImage('assets/images/placeholder.png') as ImageProvider, fit: BoxFit.cover),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      // KRAL: Opacity uyarısı 'withValues' ile çözüldü
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)]),
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.all(8),
                    child: Text(seriAdi, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _bolumleriGoster(BuildContext context, String seriAdi, List bolumler, String kapakUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ListView.builder(
          itemCount: bolumler.length,
          itemBuilder: (context, index) {
            var bolum = bolumler[index];
            return ListTile(
              leading: Icon(Icons.menu_book, color: widget.activeColor),
              title: Text(bolum['isim'] ?? "Bölüm ${index + 1}"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, CupertinoPageRoute(
                  builder: (c) => EpubOkumaSayfasi(
                    novelAdi: "$seriAdi - ${bolum['isim']}",
                    driveLink: bolum['link'], 
                  )
                ));
              },
            );
          },
        );
      },
    );
  }
}