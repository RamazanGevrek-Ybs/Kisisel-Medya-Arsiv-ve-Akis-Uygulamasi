import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/anime_model.dart';

class AniListServisi {
  static const String _url = 'https://graphql.anilist.co';

  // KRAL: İŞTE OPTİMİZASYON BURADA! RAM Cache Sözlüğü
  // Uygulama açık kaldığı sürece çekilen kapakları burada hatırlar
  static final Map<String, String> _mangaKapakCache = {};

  static const String _sorgu = '''
    query (\$search: String) {
      Media (search: \$search, type: ANIME) {
        id
        title {
          romaji
          english
        }
        coverImage {
          extraLarge
          large
        }
        description(asHtml: false)
        averageScore
        genres
      }
    }
  ''';

  static const String _mangaKapakSorgusu = '''
    query (\$search: String) {
      Media (search: \$search, type: MANGA) {
        coverImage {
          large
        }
      }
    }
  ''';

  // =========================================================
  // 1. ANİME BİLGİSİ ÇEKME FONKSİYONU (Orijinal Kodun)
  // =========================================================
  static Future<AnimeModel?> animedenBilgiCek(String animeIsmi, List<AnimeBolum> driveBolumleri, {int deneme = 0}) async {
    try {
      String temizIsim = animeIsmi;
      if (deneme == 1) {
         temizIsim = animeIsmi.replaceAll(RegExp(r'(?i)(season|sezon|part)\s*\d+'), '').trim();
      } else if (deneme == 2) {
         List<String> kelimeler = animeIsmi.split(' ');
         if (kelimeler.length > 2) {
             temizIsim = "${kelimeler[0]} ${kelimeler[1]}";
         }
      }

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': _sorgu,
          'variables': {'search': temizIsim},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['errors'] != null || data['data']['Media'] == null) {
            if (deneme < 2) {
                return animedenBilgiCek(animeIsmi, driveBolumleri, deneme: deneme + 1);
            }
            debugPrint("AniList: '$animeIsmi' bulunamadı. Standart ekleniyor.");
            return null;
        }

        final media = data['data']['Media'];

        double hesaplananPuan = media['averageScore'] != null 
            ? (media['averageScore'] / 10).toDouble() 
            : 0.0;

        String temizOzet = media['description'] ?? "Özet bulunmuyor.";
        temizOzet = temizOzet.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');

        return AnimeModel(
          id: media['id'].toString(),
          baslik: media['title']['english'] ?? media['title']['romaji'] ?? animeIsmi,
          kapakResmi: media['coverImage']['extraLarge'] ?? media['coverImage']['large'] ?? '',
          ozet: temizOzet,
          puan: hesaplananPuan,
          turler: List<String>.from(media['genres'] ?? []),
          bolumler: driveBolumleri,
        );

      } else if (response.statusCode == 429) {
        debugPrint("AniList 429 Yedi. 6 saniye dinleniliyor... ($temizIsim)");
        await Future.delayed(const Duration(seconds: 6));
        return animedenBilgiCek(animeIsmi, driveBolumleri, deneme: deneme); 
        
      } else if (response.statusCode == 404) {
         if (deneme < 2) {
            return animedenBilgiCek(animeIsmi, driveBolumleri, deneme: deneme + 1);
         }
         return null;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("AniList İstek Hatası ($animeIsmi): $e");
      return null;
    }
  }

  // =========================================================
  // 2. MANGA KAPAK RESMİ ÇEKME (CACHE DESTEKLİ)
  // =========================================================
  static Future<String> mangaKapakGetir(String mangaAdi, {int deneme = 0}) async {
    // 1. ADIM: Önce Cache'e (Hafızaya) Bak!
    // Eğer bu manganın kapağını daha önce çektiysek, saniyesinde hafızadan döndür
    // AniList'e hiçbir istek (request) gitmez, böylece 429 hatasından kurtuluruz.
    if (_mangaKapakCache.containsKey(mangaAdi)) {
      return _mangaKapakCache[mangaAdi]!;
    }

    try {
      String temizIsim = mangaAdi;
      
      if (deneme == 1) {
        temizIsim = mangaAdi.replaceAll(RegExp(r'\(.*?\)'), '').trim();
      } else if (deneme == 2) {
        List<String> kelimeler = mangaAdi.split(' ');
        if (kelimeler.length > 2) {
            temizIsim = "${kelimeler[0]} ${kelimeler[1]}";
        }
      }

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': _mangaKapakSorgusu,
          'variables': {'search': temizIsim}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['errors'] != null || data['data']['Media'] == null) {
          if (deneme < 2) {
            return mangaKapakGetir(mangaAdi, deneme: deneme + 1);
          }
          return ''; 
        }

        final media = data['data']['Media'];
        if (media != null && media['coverImage'] != null) {
          String url = media['coverImage']['large'] ?? '';
          
          // 2. ADIM: Bulunan URL'yi Cache'e (Hafızaya) Kaydet!
          // Bir sonraki girişinde bir daha indirmesin diye sözlüğe yazıyoruz.
          if (url.isNotEmpty) {
            _mangaKapakCache[mangaAdi] = url;
          }
          return url; 
        }
        return '';

      } else if (response.statusCode == 429) {
        debugPrint("AniList Manga 429 Yedi. 2 saniye dinleniliyor... ($temizIsim)");
        await Future.delayed(const Duration(seconds: 2));
        return mangaKapakGetir(mangaAdi, deneme: deneme);

      } else if (response.statusCode == 404) {
        if (deneme < 2) {
          return mangaKapakGetir(mangaAdi, deneme: deneme + 1);
        }
        return '';
      } else {
        return '';
      }
    } catch (e) {
      debugPrint("AniList Manga Kapak Çekme Hatası ($mangaAdi): $e");
      return '';
    }
  }
}