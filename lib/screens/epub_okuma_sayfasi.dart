import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:http/http.dart' as http; // KRAL: Sadece bu kütüphane yeterli!

class EpubOkumaSayfasi extends StatefulWidget {
  final String novelAdi;
  final String driveLink;

  const EpubOkumaSayfasi({super.key, required this.novelAdi, required this.driveLink});

  @override
  State<EpubOkumaSayfasi> createState() => _EpubOkumaSayfasiState();
}

class _EpubOkumaSayfasiState extends State<EpubOkumaSayfasi> {
  EpubController? _epubController;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _epubIndirVeAc();
  }

  Future<void> _epubIndirVeAc() async {
    try {
      // KRAL: EPUB dosyasını doğrudan linkten çekiyoruz
      final response = await http.get(Uri.parse(widget.driveLink));
      
      if (response.statusCode == 200) {
        Uint8List bytes = response.bodyBytes;
        setState(() {
          _epubController = EpubController(
            document: EpubDocument.openData(bytes),
          );
          _yukleniyor = false;
        });
      } else {
        throw Exception("Dosya indirilemedi. Durum Kodu: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("EPUB İndirme Hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dosya yüklenemedi! Linki kontrol edin.")));
        Navigator.pop(context); // Hata varsa sayfadan çıksın
      }
    }
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.novelAdi, style: const TextStyle(fontSize: 16)),
        // KRAL: Hata veren buton sistemden söküldü
        actions: const [], 
      ),
      body: _yukleniyor 
          ? const Center(child: CircularProgressIndicator())
          : EpubView(
              controller: _epubController!,
              builders: EpubViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                chapterDividerBuilder: (_) => const Divider(),
              ),
            ),
    );
  }
}