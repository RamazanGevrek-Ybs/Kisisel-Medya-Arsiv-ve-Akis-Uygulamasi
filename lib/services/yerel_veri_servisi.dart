import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart'; 
import '../models/manga.dart';
import '../anime_module/models/anime_model.dart';

class YerelVeriServisi {
  static late SharedPreferences _prefs;

  static ValueNotifier<List<Manga>> mangaSonOkunan = ValueNotifier([]);
  static ValueNotifier<List<Manga>> novelSonOkunan = ValueNotifier([]);
  static ValueNotifier<List<AnimeModel>> animeSonOkunan = ValueNotifier([]); 

  static Future<void> baslat() async {
    _prefs = await SharedPreferences.getInstance();
    mangaSonOkunan.value = await sonOkunanlariGetir(true);
    novelSonOkunan.value = await sonOkunanlariGetir(false);
    animeSonOkunan.value = await animeSonOkunanlariGetir(); 
  }

  static Future<void> ayarKaydet(String anahtar, dynamic deger) async {
    if (deger is bool) {
      await _prefs.setBool(anahtar, deger);
    } else if (deger is int) {
      await _prefs.setInt(anahtar, deger);
    } else if (deger is String) {
      await _prefs.setString(anahtar, deger);
    } else if (deger is double) {
      await _prefs.setDouble(anahtar, deger);
    }
  }

  static dynamic ayarGetir(String anahtar) => _prefs.get(anahtar);

  static Future<void> gunlukSeriyiGuncelle() async {
    DateTime simdi = DateTime.now();
    String bugun = "${simdi.year}-${simdi.month.toString().padLeft(2, '0')}-${simdi.day.toString().padLeft(2, '0')}";
    
    DateTime dunTarihi = simdi.subtract(const Duration(days: 1));
    String dun = "${dunTarihi.year}-${dunTarihi.month.toString().padLeft(2, '0')}-${dunTarihi.day.toString().padLeft(2, '0')}";

    String? sonOkumaTarihi = _prefs.getString('son_okuma_tarihi');
    int mevcutSeri = _prefs.getInt('okuma_serisi') ?? 0;

    if (sonOkumaTarihi == bugun) {
      return; 
    } else if (sonOkumaTarihi == dun) {
      mevcutSeri++; 
    } else {
      mevcutSeri = 1; 
    }

    await _prefs.setString('son_okuma_tarihi', bugun);
    await _prefs.setInt('okuma_serisi', mevcutSeri);

    try {
      await HomeWidget.saveWidgetData<int>('streak_count', mevcutSeri);
      await HomeWidget.updateWidget(name: 'StreakWidgetProvider');
    } catch (e) {
      debugPrint("Widget güncellenemedi: $e");
    }
  }

  static int get okumaSerisi => _prefs.getInt('okuma_serisi') ?? 0;

  static Future<void> seriDurumuGuncelle(String id, bool bitenMangaMi, bool bitirildiMi) async {
    String key = bitenMangaMi ? 'biten_mangalar' : 'biten_noveller';
    List<String> bitenler = _prefs.getStringList(key) ?? [];
    if (bitirildiMi) {
      if (!bitenler.contains(id)) {
        bitenler.add(id);
      }
    } else {
      bitenler.remove(id);
    }
    await _prefs.setStringList(key, bitenler);
  }

  static bool seriBitirildiMi(String id, bool bitenMangaMi) {
    String key = bitenMangaMi ? 'biten_mangalar' : 'biten_noveller';
    List<String> bitenler = _prefs.getStringList(key) ?? [];
    return bitenler.contains(id);
  }

  static int bitenSayisiGetir(bool isManga) {
    String key = isManga ? 'biten_mangalar' : 'biten_noveller';
    return (_prefs.getStringList(key) ?? []).length;
  }

  static String? enCokOkunanTuruGetir(bool isManga) {
    List<Manga> kutuphane = favorileriGetir(isManga);
    List<Manga> sonOkunan = isManga ? mangaSonOkunan.value : novelSonOkunan.value;
    
    var tumu = [...kutuphane, ...sonOkunan];
    var benzersizler = {for (var m in tumu) m.id: m}.values.toList();
    
    if (benzersizler.isEmpty) return null; 

    Map<String, int> frekans = {};
    
    for (var m in benzersizler) {
      bool gecerliTurBulundu = false;
      for (var tur in m.turler) {
        if (tur == "Manga" || tur == "Yerel" || tur == "Novel" || tur == "Light Novel") continue;
        if (tur.trim().isEmpty) continue;
        frekans[tur] = (frekans[tur] ?? 0) + 1;
        gecerliTurBulundu = true;
      }
      
      if (!isManga && !gecerliTurBulundu) {
        String isim = m.isim.toLowerCase();
        if (isim.contains("level") || isim.contains("system") || isim.contains("rank") || isim.contains("player") || isim.contains("game") || isim.contains("login")) {
          frekans["System"] = (frekans["System"] ?? 0) + 1;
        } else if (isim.contains("love") || isim.contains("heroine") || isim.contains("villainess") || isim.contains("wife") || isim.contains("romance") || isim.contains("marriage")) {
          frekans["Romance"] = (frekans["Romance"] ?? 0) + 1;
        } else if (isim.contains("martial") || isim.contains("sword") || isim.contains("magic") || isim.contains("demon") || isim.contains("dragon") || isim.contains("god")) {
          frekans["Fantasy"] = (frekans["Fantasy"] ?? 0) + 1;
        } else if (isim.contains("return") || isim.contains("reincarnat") || isim.contains("regress") || isim.contains("rebirth") || isim.contains("time")) {
          frekans["Reincarnation"] = (frekans["Reincarnation"] ?? 0) + 1;
        }
      }
    }

    if (frekans.isEmpty) return null;
    var sirali = frekans.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sirali.first.key; 
  }

  static List<Map<String, dynamic>> rozetleriHesapla() {
    int mBiten = bitenSayisiGetir(true);
    int nBiten = bitenSayisiGetir(false);
    int toplamBiten = mBiten + nBiten;
    
    List<Manga> mKutuphane = favorileriGetir(true);
    List<Manga> nKutuphane = favorileriGetir(false);
    List<AnimeModel> aKutuphane = animeFavorileriGetir(); // KRAL: Animeler de eklendi
    
    var tumKutuphane = [...mKutuphane, ...nKutuphane];
    
    // KRAL: Artık rozet hesaplamasında Animeler de sayılıyor!
    int kutuphaneSayisi = tumKutuphane.length + aKutuphane.length;
    int aktifOkunanSayisi = mangaSonOkunan.value.length + novelSonOkunan.value.length + animeSonOkunan.value.length;

    int aksiyonSayisi = 0; int romantikSayisi = 0; int isekaiSayisi = 0; int fantastikSayisi = 0;
    int bilimKurguSayisi = 0; int korkuSayisi = 0; int komediSayisi = 0; int yasamSayisi = 0; int yerelSayisi = 0;

    for (var m in tumKutuphane) {
      if (m.kapakResmi == "yerel_ikon") yerelSayisi++;
      String tumTurler = m.turler.join(" ").toLowerCase();
      String isim = m.isim.toLowerCase();
      
      if (tumTurler.contains("action") || tumTurler.contains("aksiyon") || tumTurler.contains("martial") || isim.contains("sword")) aksiyonSayisi++;
      if (tumTurler.contains("romance") || tumTurler.contains("romantik") || isim.contains("love") || isim.contains("wife")) romantikSayisi++;
      if (tumTurler.contains("isekai") || tumTurler.contains("reincarnat") || tumTurler.contains("return") || isim.contains("system") || isim.contains("level")) isekaiSayisi++;
      if (tumTurler.contains("fantasy") || tumTurler.contains("fantastik") || isim.contains("magic") || isim.contains("demon")) fantastikSayisi++;
      if (tumTurler.contains("sci-fi") || tumTurler.contains("bilim") || isim.contains("space") || isim.contains("uzay")) bilimKurguSayisi++;
      if (tumTurler.contains("horror") || tumTurler.contains("korku") || tumTurler.contains("thriller") || isim.contains("blood")) korkuSayisi++;
      if (tumTurler.contains("comedy") || tumTurler.contains("komedi") || isim.contains("funny") || isim.contains("komik")) komediSayisi++;
      if (tumTurler.contains("slice of life") || tumTurler.contains("school") || tumTurler.contains("okul") || isim.contains("günlük")) yasamSayisi++;
    }

    return [
      {'id': 'ilk_adim', 'isim': 'İlk Adım', 'ozet': 'Kütüphaneye ilk serini ekledin.', 'acikMi': kutuphaneSayisi >= 1, 'ikon': '🌱', 'seviye': 'Sıradan'},
      {'id': 'manga_okuru', 'isim': 'Manga Okuru', 'ozet': 'İlk Manganı bitirdin.', 'acikMi': mBiten >= 1, 'ikon': '📖', 'seviye': 'Sıradan'},
      {'id': 'novel_okuru', 'isim': 'Novel Okuru', 'ozet': 'İlk Novelini bitirdin.', 'acikMi': nBiten >= 1, 'ikon': '📜', 'seviye': 'Sıradan'},
      {'id': 'yerel_okur', 'isim': 'Yerel Okur', 'ozet': 'Cihazından ilk dosyanı ekledin.', 'acikMi': yerelSayisi >= 1, 'ikon': '📁', 'seviye': 'Sıradan'},
      {'id': 'hevesli', 'isim': 'Hevesli', 'ozet': 'Aynı anda 3 seri okuyorsun.', 'acikMi': aktifOkunanSayisi >= 3, 'ikon': '👀', 'seviye': 'Sıradan'},
      {'id': 'toplayici', 'isim': 'Toplayıcı', 'ozet': 'Kütüphanende 5 seri var.', 'acikMi': kutuphaneSayisi >= 5, 'ikon': '🎒', 'seviye': 'Sıradan'},
      {'id': 'korkusuz_cirak', 'isim': 'Korkusuz Çırak', 'ozet': 'İlk Korku serini ekledin.', 'acikMi': korkuSayisi >= 1, 'ikon': '🕸️', 'seviye': 'Sıradan'},
      {'id': 'kikirdama', 'isim': 'Kıkırdama', 'ozet': 'İlk Komedi serini ekledin.', 'acikMi': komediSayisi >= 1, 'ikon': '🤭', 'seviye': 'Sıradan'},
      {'id': 'siradan_gun', 'isim': 'Sıradan Gün', 'ozet': 'İlk Yaşam serini ekledin.', 'acikMi': yasamSayisi >= 1, 'ikon': '☕', 'seviye': 'Sıradan'},
      {'id': 'uzay_tozu', 'isim': 'Uzay Tozu', 'ozet': 'İlk Bilim Kurgu serini ekledin.', 'acikMi': bilimKurguSayisi >= 1, 'ikon': '☄️', 'seviye': 'Sıradan'},
      {'id': 'manga_kurdu', 'isim': 'Manga Kurdu', 'ozet': '5 Manga bitirdin.', 'acikMi': mBiten >= 5, 'ikon': '🐛', 'seviye': 'Nadir'},
      {'id': 'novel_ogrencisi', 'isim': 'Novel Öğrencisi', 'ozet': '5 Novel bitirdin.', 'acikMi': nBiten >= 5, 'ikon': '🎓', 'seviye': 'Nadir'},
      {'id': 'hizli_baslangic', 'isim': 'Hızlı Başlangıç', 'ozet': 'Toplam 10 seri bitirdin.', 'acikMi': toplamBiten >= 10, 'ikon': '🚀', 'seviye': 'Nadir'},
      {'id': 'koleksiyoncu', 'isim': 'Koleksiyoncu', 'ozet': 'Kütüphanende 15 seri var.', 'acikMi': kutuphaneSayisi >= 15, 'ikon': '📚', 'seviye': 'Nadir'},
      {'id': 'cevrimdisi_kurt', 'isim': 'Çevrimdışı Kurt', 'ozet': 'Cihazından 5 dosya okudun.', 'acikMi': yerelSayisi >= 5, 'ikon': '💾', 'seviye': 'Nadir'},
      {'id': 'kilic_ustasi', 'isim': 'Kılıç Ustası', 'ozet': '5 Aksiyon/Dövüş serisi ekledin.', 'acikMi': aksiyonSayisi >= 5, 'ikon': '⚔️', 'seviye': 'Nadir'},
      {'id': 'ask_bocegi', 'isim': 'Aşk Böceği', 'ozet': '5 Romantik seri ekledin.', 'acikMi': romantikSayisi >= 5, 'ikon': '❤️', 'seviye': 'Nadir'},
      {'id': 'kamyon_magduru', 'isim': 'Kamyon Mağduru', 'ozet': '5 İsekai serisi ekledin.', 'acikMi': isekaiSayisi >= 5, 'ikon': '🚚', 'seviye': 'Nadir'},
      {'id': 'buyucu_ciragi', 'isim': 'Büyücü Çırağı', 'ozet': '5 Fantastik seri ekledin.', 'acikMi': fantastikSayisi >= 5, 'ikon': '🪄', 'seviye': 'Nadir'},
      {'id': 'korkusuz', 'isim': 'Korkusuz', 'ozet': '5 Korku/Gerilim serisi ekledin.', 'acikMi': korkuSayisi >= 5, 'ikon': '🦇', 'seviye': 'Nadir'},
      {'id': 'gulumseten', 'isim': 'Gülümseten', 'ozet': '5 Komedi serisi ekledin.', 'acikMi': komediSayisi >= 5, 'ikon': '😂', 'seviye': 'Nadir'},
      {'id': 'okul_yillari', 'isim': 'Okul Yılları', 'ozet': '5 Yaşam/Okul serisi ekledin.', 'acikMi': yasamSayisi >= 5, 'ikon': '🎒', 'seviye': 'Nadir'},
      {'id': 'uzay_yolcusu', 'isim': 'Uzay Yolcusu', 'ozet': '5 Bilim Kurgu serisi ekledin.', 'acikMi': bilimKurguSayisi >= 5, 'ikon': '🛸', 'seviye': 'Nadir'},
      {'id': 'coklu_gorev', 'isim': 'Çoklu Görev', 'ozet': 'Aynı anda 10 seri okuyorsun.', 'acikMi': aktifOkunanSayisi >= 10, 'ikon': '🐙', 'seviye': 'Nadir'},
      {'id': 'manga_bagimlisi', 'isim': 'Manga Bağımlısı', 'ozet': '10 Manga bitirdin.', 'acikMi': mBiten >= 10, 'ikon': '💊', 'seviye': 'Nadir'},
      {'id': 'novel_bagimlisi', 'isim': 'Novel Bağımlısı', 'ozet': '10 Novel bitirdin.', 'acikMi': nBiten >= 10, 'ikon': '💉', 'seviye': 'Nadir'},
      {'id': 'otaku', 'isim': 'Gerçek Otaku', 'ozet': '15 Manga bitirdin.', 'acikMi': mBiten >= 15, 'ikon': '🎌', 'seviye': 'Destansı'},
      {'id': 'novel_ustasi', 'isim': 'Novel Üstadı', 'ozet': '15 Novel bitirdin.', 'acikMi': nBiten >= 15, 'ikon': '🧙', 'seviye': 'Destansı'},
      {'id': 'yarim_dalya', 'isim': 'Yarım Dalya', 'ozet': 'Toplam 50 seri bitirdin.', 'acikMi': toplamBiten >= 50, 'ikon': '🔥', 'seviye': 'Destansı'},
      {'id': 'buyuk_arsivci', 'isim': 'Büyük Arşivci', 'ozet': 'Kütüphanende 40 seri var.', 'acikMi': kutuphaneSayisi >= 40, 'ikon': '🏛️', 'seviye': 'Destansı'},
      {'id': 'karanlik_ag', 'isim': 'Karanlık Ağ', 'ozet': 'Cihazından 15 dosya okudun.', 'acikMi': yerelSayisi >= 15, 'ikon': '🕵️', 'seviye': 'Destansı'},
      {'id': 'arsiv_muhafizi', 'isim': 'Arşiv Muhafızı', 'ozet': 'Cihazından 30 dosya okudun.', 'acikMi': yerelSayisi >= 30, 'ikon': '🛡️', 'seviye': 'Destansı'},
      {'id': 'savasci_ruhu', 'isim': 'Savaşçı Ruhu', 'ozet': '15 Aksiyon serisi ekledin.', 'acikMi': aksiyonSayisi >= 15, 'ikon': '🩸', 'seviye': 'Destansı'},
      {'id': 'ask_doktoru', 'isim': 'Aşk Doktoru', 'ozet': '15 Romantik seri ekledin.', 'acikMi': romantikSayisi >= 15, 'ikon': '💘', 'seviye': 'Destansı'},
      {'id': 'sistem_kirici', 'isim': 'Sistem Kırıcı', 'ozet': '15 İsekai/Sistem serisi ekledin.', 'acikMi': isekaiSayisi >= 15, 'ikon': '💻', 'seviye': 'Destansı'},
      {'id': 'ejder_suvarisi', 'isim': 'Ejder Süvarisi', 'ozet': '15 Fantastik seri ekledin.', 'acikMi': fantastikSayisi >= 15, 'ikon': '🐉', 'seviye': 'Destansı'},
      {'id': 'galaktik_lider', 'isim': 'Galaktik Lider', 'ozet': '15 Bilim Kurgu serisi ekledin.', 'acikMi': bilimKurguSayisi >= 15, 'ikon': '🌌', 'seviye': 'Destansı'},
      {'id': 'kabus_efendisi', 'isim': 'Kabus Efendisi', 'ozet': '15 Korku serisi ekledin.', 'acikMi': korkuSayisi >= 15, 'ikon': '🧟', 'seviye': 'Destansı'},
      {'id': 'stand_up', 'isim': 'Stand-Up', 'ozet': '15 Komedi serisi ekledin.', 'acikMi': komediSayisi >= 15, 'ikon': '🎤', 'seviye': 'Destansı'},
      {'id': 'maratoncu', 'isim': 'Maratoncu', 'ozet': 'Toplam 30 seri bitirdin.', 'acikMi': toplamBiten >= 30, 'ikon': '🏃', 'seviye': 'Destansı'},
      {'id': 'manga_tanrisi', 'isim': 'Manga Tanrısı', 'ozet': 'İnanılmaz! 50 Manga bitirdin.', 'acikMi': mBiten >= 50, 'ikon': '👑', 'seviye': 'Efsanevi'},
      {'id': 'manga_ilahi', 'isim': 'Manga İlahı', 'ozet': '100 Manga! Sen bir efsanesin.', 'acikMi': mBiten >= 100, 'ikon': '⛩️', 'seviye': 'Efsanevi'},
      {'id': 'sozlerin_efendisi', 'isim': 'Sözlerin Efendisi', 'ozet': '50 Novel bitirdin.', 'acikMi': nBiten >= 50, 'ikon': '🧿', 'seviye': 'Efsanevi'},
      {'id': 'korsan_kral', 'isim': 'Korsan Kral', 'ozet': 'Cihazından 50 yerel dosya okudun.', 'acikMi': yerelSayisi >= 50, 'ikon': '🏴‍☠️', 'seviye': 'Efsanevi'},
      {'id': 'sonsuz_kutuphane', 'isim': 'Sonsuz Kütüphane', 'ozet': 'Kütüphanende tam 100 seri var!', 'acikMi': kutuphaneSayisi >= 100, 'ikon': '♾️', 'seviye': 'Efsanevi'},
      {'id': 'iskenderiye', 'isim': 'İskenderiye', 'ozet': 'Kütüphanende 200 seri var!', 'acikMi': kutuphaneSayisi >= 200, 'ikon': '🏛️', 'seviye': 'Efsanevi'},
      {'id': 'savas_tanrisi', 'isim': 'Savaş Tanrısı', 'ozet': '30 Aksiyon serisi! Kan döküldü.', 'acikMi': aksiyonSayisi >= 30, 'ikon': '🌋', 'seviye': 'Efsanevi'},
      {'id': 'boyut_yolcusu', 'isim': 'Boyut Yolcusu', 'ozet': '30 İsekai! Dünyaları aştın.', 'acikMi': isekaiSayisi >= 30, 'ikon': '🌀', 'seviye': 'Efsanevi'},
      {'id': 'coklu_evren', 'isim': 'Çoklu Evren', 'ozet': 'Aynı anda 50 farklı seri okuyorsun.', 'acikMi': aktifOkunanSayisi >= 50, 'ikon': '🧬', 'seviye': 'Efsanevi'},
      {'id': 'omrunu_veren', 'isim': 'Ömrünü Veren', 'ozet': 'Toplam 200 seri bitirdin. Saygı duyuyoruz.', 'acikMi': toplamBiten >= 200, 'ikon': '🏆', 'seviye': 'Efsanevi'},
    ];
  }

  static Future<void> favoriGuncelle(Manga manga, bool eklensinMi, bool isManga) async {
    String key = isManga ? 'kutuphane_manga' : 'kutuphane_novel';
    List<String> favoriler = _prefs.getStringList(key) ?? [];
    if (eklensinMi) {
      if (!favoriler.any((mJson) => jsonDecode(mJson)['id'] == manga.id)) {
        favoriler.add(jsonEncode(manga.toJson()));
      }
    } else {
      favoriler.removeWhere((mJson) => jsonDecode(mJson)['id'] == manga.id);
    }
    await _prefs.setStringList(key, favoriler);
  }

  static bool favorilerdeVarMi(String mangaId, bool isManga) {
    String key = isManga ? 'kutuphane_manga' : 'kutuphane_novel';
    return (_prefs.getStringList(key) ?? []).any((mJson) => jsonDecode(mJson)['id'] == mangaId);
  }

  static List<Manga> favorileriGetir(bool isManga) {
    String key = isManga ? 'kutuphane_manga' : 'kutuphane_novel';
    List<String> favoriler = _prefs.getStringList(key) ?? [];
    return favoriler.map((mJson) => Manga.fromJson(jsonDecode(mJson))).toList();
  }

  static Future<void> sonOkunanEkle(Manga manga, bool isManga) async {
    await gunlukSeriyiGuncelle(); 
    String key = isManga ? 'son_okunanlar_manga' : 'son_okunanlar_novel';
    List<String> liste = _prefs.getStringList(key) ?? [];
    liste.removeWhere((mJson) => jsonDecode(mJson)['id'] == manga.id);
    liste.insert(0, jsonEncode(manga.toJson()));
    if (liste.length > 15) liste = liste.sublist(0, 15);
    await _prefs.setStringList(key, liste);
    
    if (isManga) {
      mangaSonOkunan.value = await sonOkunanlariGetir(true);
    } else {
      novelSonOkunan.value = await sonOkunanlariGetir(false);
    }
  }

  static Future<List<Manga>> sonOkunanlariGetir(bool isManga) async {
    String key = isManga ? 'son_okunanlar_manga' : 'son_okunanlar_novel';
    return (_prefs.getStringList(key) ?? []).map((mJson) => Manga.fromJson(jsonDecode(mJson))).toList();
  }

  static Future<void> ilerlemeyiKaydet(String mangaId, String bolumId, int sayfaIndex) async {
    await gunlukSeriyiGuncelle();
    await _prefs.setString('kayit_$mangaId', jsonEncode({'bolumId': bolumId, 'sayfaIndex': sayfaIndex}));
  }

  static Map<String, dynamic>? ilerlemeyiGetir(String mangaId) {
    String? res = _prefs.getString('kayit_$mangaId');
    if (res != null) return jsonDecode(res);
    return null;
  }
  
  static Future<void> animeFavoriGuncelle(AnimeModel anime, bool eklensinMi) async {
    List<String> favoriler = _prefs.getStringList('kutuphane_anime') ?? [];
    if (eklensinMi) {
      if (!favoriler.any((mJson) => jsonDecode(mJson)['id'] == anime.id)) {
        favoriler.add(jsonEncode(anime.toJson()));
      }
    } else {
      favoriler.removeWhere((mJson) => jsonDecode(mJson)['id'] == anime.id);
    }
    await _prefs.setStringList('kutuphane_anime', favoriler);
  }

  static List<AnimeModel> animeFavorileriGetir() {
    List<String> favoriler = _prefs.getStringList('kutuphane_anime') ?? [];
    return favoriler.map((mJson) => AnimeModel.fromJson(jsonDecode(mJson))).toList();
  }

  static Future<void> animeSonOkunanEkle(AnimeModel anime) async {
    await gunlukSeriyiGuncelle(); 
    List<String> liste = _prefs.getStringList('son_okunanlar_anime') ?? [];
    liste.removeWhere((mJson) => jsonDecode(mJson)['id'] == anime.id);
    liste.insert(0, jsonEncode(anime.toJson()));
    if (liste.length > 15) liste = liste.sublist(0, 15);
    await _prefs.setStringList('son_okunanlar_anime', liste);
    animeSonOkunan.value = await animeSonOkunanlariGetir();
  }

  static Future<List<AnimeModel>> animeSonOkunanlariGetir() async {
    return (_prefs.getStringList('son_okunanlar_anime') ?? []).map((mJson) => AnimeModel.fromJson(jsonDecode(mJson))).toList();
  }
}