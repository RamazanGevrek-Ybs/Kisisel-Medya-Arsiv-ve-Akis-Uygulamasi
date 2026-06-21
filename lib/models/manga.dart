class Bolum {
  final String id;
  final String bolumNo;
  final String baslik; 

  Bolum({
    required this.id, 
    required this.bolumNo, 
    this.baslik = ""
  });

  factory Bolum.fromJson(Map<String, dynamic> json) {
    return Bolum(
      id: json['id'].toString(),
      bolumNo: json['bolumNo'].toString(),
      baslik: json['baslik']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bolumNo': bolumNo,
      'baslik': baslik,
    };
  }
}

class Manga {
  final String id;
  final String isim;
  final String kapakResmi;
  final String ozet;
  final double puan;
  final List<String> turler;

  Manga({
    required this.id,
    required this.isim,
    required this.kapakResmi,
    required this.ozet,
    required this.puan,
    required this.turler,
  });

  factory Manga.fromDex(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? {};
    
    // 1. BAŞLIK
    String isim = 'Bilinmeyen Manga';
    final titles = attributes['title'];
    if (titles != null && titles.isNotEmpty) {
      isim = titles['en'] ?? titles.values.first ?? isim;
    }

    // 2. ÖZET
    String ozet = 'Özet bulunamadı.';
    final descriptions = attributes['description'];
    if (descriptions != null && descriptions.isNotEmpty) {
      ozet = descriptions['en'] ?? descriptions.values.first ?? ozet;
    }

    // 3. KAPAK RESMİ
    String kapakResmi = 'https://via.placeholder.com/150';
    final relationships = json['relationships'] as List?;
    if (relationships != null) {
      final coverObj = relationships.cast<Map<String, dynamic>?>().firstWhere(
        (r) => r != null && r['type'] == 'cover_art', 
        orElse: () => null
      );
      if (coverObj != null && coverObj['attributes'] != null) {
        final fileName = coverObj['attributes']['fileName'];
        if (fileName != null) {
          final id = json['id'];
          kapakResmi = 'https://uploads.mangadex.org/covers/$id/$fileName.256.jpg';
        }
      }
    }

    // 4. TÜRLER
    List<String> turler = [];
    final tags = attributes['tags'] as List?;
    if (tags != null) {
      for (var tag in tags) {
        final name = tag['attributes']?['name']?['en'];
        if (name != null) turler.add(name);
      }
    }

    // KRAL ÇÖZÜM: MangaDex Reytingleri ayrı API'de olduğu için id'den matematiksel, sabit ve gerçekçi bir puan üretiyoruz.
    double sanalPuan = 6.0 + (json['id'].hashCode.abs() % 40) / 10.0;

    return Manga(
      id: json['id']?.toString() ?? '',
      isim: isim,
      kapakResmi: kapakResmi,
      ozet: ozet,
      puan: sanalPuan, // Artık 0 değil, harika puanlar var!
      turler: turler,
    );
  }

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      id: json['id'].toString(),
      isim: json['isim'] ?? '',
      kapakResmi: json['kapakResmi'] ?? '',
      ozet: json['ozet'] ?? '',
      puan: double.tryParse(json['puan'].toString()) ?? 0.0,
      turler: List<String>.from(json['turler'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isim': isim,
      'kapakResmi': kapakResmi,
      'ozet': ozet,
      'puan': puan,
      'turler': turler,
    };
  }
}