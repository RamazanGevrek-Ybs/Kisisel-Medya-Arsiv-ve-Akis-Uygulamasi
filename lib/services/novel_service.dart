import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../models/manga.dart';
import 'package:flutter/foundation.dart';

class NovelService {
  static const String _baseUrl = 'https://www.royalroad.com';

  // Popülerleri getirir (Trendler için)
  static Future<List<Manga>> populerNovellariGetir() async {
    return novelGetir(); 
  }

  // Ana Motor: Hem arama, hem kategori, hem de sayfa desteği eklendi!
  static Future<List<Manga>> novelGetir({String? arama, String? tur, int sayfa = 1}) async {
    try {
      String url;

      // URL'yi duruma göre inşa ediyoruz
      if (arama != null && arama.trim().isNotEmpty) {
        url = '$_baseUrl/fictions/search?title=${Uri.encodeComponent(arama)}&page=$sayfa';
      } else if (tur != null) {
        // KRAL BURASI DÜZELTİLDİ: Artık genre yerine keyword kullanarak doğru kategoriyi arıyor
        url = '$_baseUrl/fictions/search?keyword=$tur&page=$sayfa';
      } else {
        url = '$_baseUrl/fictions/active-popular?page=$sayfa';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var document = parse(response.body);
        var novelElements = document.querySelectorAll('.fiction-list-item');

        return novelElements.map((element) {
          var titleElement = element.querySelector('.fiction-title a');
          var imgElement = element.querySelector('img');
          
          return Manga(
            id: titleElement?.attributes['href'] ?? '',
            isim: titleElement?.text.trim() ?? 'Bilinmeyen Novel',
            kapakResmi: imgElement?.attributes['src'] ?? 'https://via.placeholder.com/150',
            ozet: 'Okumak için tıklayın...',
            turler: ['Light Novel'], // Novel olduğunu anlamak için bunu kullanıyoruz
            puan: 9.0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Kazıma hatası (RoyalRoad): $e");
    }
    return [];
  }

  // YENİ: Novel Detaylarını ve Bölümlerini Kazıma
  static Future<Map<String, dynamic>> detayVeBolumGetir(String path) async {
    try {
      final url = '$_baseUrl$path';
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'});
      
      if (response.statusCode == 200) {
        var document = parse(response.body);
        var chapterElements = document.querySelectorAll('tbody tr');
        
        List<Bolum> bolumler = [];
        int no = 1;
        for (var element in chapterElements) {
          var aTag = element.querySelector('a');
          if (aTag != null && aTag.attributes.containsKey('href')) {
            bolumler.add(Bolum(
              id: aTag.attributes['href']!,
              bolumNo: no.toString(),
              baslik: aTag.text.trim()
            ));
            no++;
          }
        }
        
        // MangaDex listeyi ters gönderdiği için UI bozulmasın diye bunu da ters çeviriyoruz
        return {'bolumler': bolumler.reversed.toList()};
      }
    } catch (e) {
      debugPrint("Novel bölüm kazıma hatası: $e");
    }
    return {'bolumler': <Bolum>[]};
  }

  // YENİ: Tıklanan Bölümün İçeriğini (Metnini) Okuma
  static Future<String> bolumIcerigiGetir(String path) async {
    try {
      final url = '$_baseUrl$path';
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'});
      
      if (response.statusCode == 200) {
        var document = parse(response.body);
        var contentElement = document.querySelector('.chapter-content');
        return contentElement?.innerHtml ?? 'İçerik bulunamadı.';
      }
    } catch (e) {
      debugPrint("Novel metin hatası: $e");
    }
    return 'Bağlantı hatası, içerik çekilemedi.';
  }
}