import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga.dart';

class ApiService {
  static const String _dexBase = 'https://api.mangadex.org';

  // RAM ÖNBELLEK MOTORU
  static List<Manga> trendMangaCache = [];
  static Map<String, List<Manga>> kategoriCache = {};
  static bool yuklemeTamamlandi = false;

  // BAN YEMEYEN, 1 SANİYE BEKLEMELİ ÖN YÜKLEME
  static Future<void> herSeyiDugumle() async {
    try {
      trendMangaCache = await mangaGetir();
      await Future.delayed(const Duration(seconds: 1));
      
      kategoriCache['Action'] = await mangaGetir(tur: 'Action');
      await Future.delayed(const Duration(seconds: 1));
      
      kategoriCache['Romance'] = await mangaGetir(tur: 'Romance');
      await Future.delayed(const Duration(seconds: 1));
      
      kategoriCache['Fantasy'] = await mangaGetir(tur: 'Fantasy');
      
      yuklemeTamamlandi = true;
    } catch (e) {
      yuklemeTamamlandi = true; 
    }
  }

  // MANGA GETİRME (MangaDex API)
  static Future<List<Manga>> mangaGetir({String? arama, String? tur, int offset = 0}) async {
    final String query = arama ?? tur ?? 'Solo';
    
    // RAM KONTROLÜ
    if (arama == null && offset == 0) {
      if (tur == null && trendMangaCache.isNotEmpty) return trendMangaCache;
      if (tur != null && kategoriCache.containsKey(tur) && kategoriCache[tur]!.isNotEmpty) return kategoriCache[tur]!;
    }

    final url = '$_dexBase/manga?title=$query&limit=20&offset=$offset&includes[]=cover_art&availableTranslatedLanguage[]=en&contentRating[]=safe&contentRating[]=suggestive&hasAvailableChapters=true';

    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body)['data'];
        return data.map((m) => Manga.fromDex(m)).toList();
      }
      return [];
    } catch (e) { 
      return []; 
    }
  }

  // MANGA DETAY VE BÖLÜMLER
  static Future<Map<String, dynamic>> detayVeBolumGetir(String id) async {
    final url = '$_dexBase/manga/$id/feed?translatedLanguage[]=en&limit=500&order[chapter]=desc&includeExternalUrl=0';
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body)['data'];
        return {
          'bolumler': data.map((b) => Bolum(
            id: b['id'], 
            bolumNo: b['attributes']['chapter'] ?? '0', 
            baslik: b['attributes']['title'] ?? 'Bölüm'
          )).toList()
        };
      }
      return {'bolumler': <Bolum>[]};
    } catch (e) { 
      return {'bolumler': <Bolum>[]}; 
    }
  }

  // MANGA SAYFALARI
  static Future<List<String>> sayfalariGetir(String bolumId) async {
    final url = '$_dexBase/at-home/server/$bolumId';
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final String hash = data['chapter']['hash'];
        final List files = data['chapter']['dataSaver'];
        return files.map((f) => 'https://uploads.mangadex.org/data-saver/$hash/$f').toList();
      }
      return [];
    } catch (e) { 
      return []; 
    }
  }
}