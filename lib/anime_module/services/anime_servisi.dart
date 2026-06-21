import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // KRAL: Cache için şart!
import '../models/anime_model.dart'; 
import 'anilist_servisi.dart'; 

class AnimeServisi {
  static const String _driveApiKey = "BURAYA_KENDI_DRIVE_API_ANAHTARINIZI_YAZIN";
  static const String _cacheKey = "anime_tam_liste_cache_v2";

  static Future<List<AnimeModel>> animeleriGetir() async {
    try {
      // 1. JSON DOSYASINI OKU
      final String response = await rootBundle.loadString('assets/data/anime_arsiv.json');
      final data = await json.decode(response);
      var taslakListesi = data['animeler'] as List;

      // 2. AKILLI CACHE (ÖNBELLEK) KONTROLÜ (0.1 Saniyede Yükleme İçin)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_cacheKey);

      if (cachedData != null && cachedData.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(cachedData);
        // JSON'daki anime sayısıyla Cache'deki anime sayısı aynıysa direkt telefondan ver!
        if (decoded.length == taslakListesi.length) {
          debugPrint("Animeler Cache'den süper hızlı yüklendi!");
          return decoded.map((e) => AnimeModel.fromJson(e)).toList();
        }
      }

      // 3. CACHE YOKSA VEYA ANİME SAYISI ARTTIYSA API'DEN ÇEK
      debugPrint("Yeni animeler tespit edildi, AniList API'den veriler sırayla çekiliyor...");
      List<AnimeModel> tamListe = [];

      for (var item in taslakListesi) {
        String isim = item['baslik'];
        var driveBolumler = item['bolumler'] as List;

        List<AnimeBolum> islenmisBolumler = driveBolumler.map((b) {
          String dosyaId = b['driveId'];
          return AnimeBolum(
            bolumNo: b['bolumNo'],
            videoUrl: "https://www.googleapis.com/drive/v3/files/$dosyaId?alt=media&key=$_driveApiKey",
          );
        }).toList();

        // Verileri AniList'ten istiyoruz
        AnimeModel? detayliAnime = await AniListServisi.animedenBilgiCek(isim, islenmisBolumler);

        if (detayliAnime != null) {
          tamListe.add(detayliAnime);
        } else {
          tamListe.add(AnimeModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + isim.length.toString(),
            baslik: isim,
            kapakResmi: 'https://via.placeholder.com/300x450?text=Kapak+Yok',
            ozet: 'Bu anime AniList üzerinde bulunamadı.',
            puan: 0.0,
            turler: ["Genel"],
            bolumler: islenmisBolumler,
          ));
        }

        // KRAL: AniList'ten 429 yememek için her istekten sonra 800 milisaniye nefes alıyoruz!
        await Future.delayed(const Duration(milliseconds: 2500));
      }

      // 4. ÇEKİLEN VERİLERİ GELECEK SEFER İÇİN CACHE'E KAYDET
      String encodeEdilmisListe = jsonEncode(tamListe.map((e) => e.toJson()).toList());
      await prefs.setString(_cacheKey, encodeEdilmisListe);

      return tamListe;
    } catch (e) {
      debugPrint("Anime Servis Hatası: $e");
      return [];
    }
  }

  static Future<List<AnimeModel>> animeAra(String sorgu) async {
    List<AnimeModel> tumAnimeler = await animeleriGetir();
    return tumAnimeler.where((a) => a.baslik.toLowerCase().contains(sorgu.toLowerCase())).toList();
  }
}