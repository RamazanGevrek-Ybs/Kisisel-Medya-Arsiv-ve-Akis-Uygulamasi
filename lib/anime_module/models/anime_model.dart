class AnimeBolum {
  final int bolumNo;
  final String videoUrl; 

  AnimeBolum({required this.bolumNo, required this.videoUrl});

  factory AnimeBolum.fromJson(Map<String, dynamic> json) => AnimeBolum(
        bolumNo: json['bolumNo'] ?? 1,
        videoUrl: json['videoUrl'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'bolumNo': bolumNo,
        'videoUrl': videoUrl,
      };
}

class AnimeModel {
  final String id;
  final String baslik;
  final String kapakResmi;
  final String ozet;
  final double puan;
  final List<String> turler; // KRAL: Kategoriler için yeni eklendi
  final List<AnimeBolum> bolumler;

  AnimeModel({
    required this.id,
    required this.baslik,
    required this.kapakResmi,
    required this.ozet,
    required this.puan,
    required this.turler,
    required this.bolumler,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    var bolumlerListesi = json['bolumler'] as List? ?? [];
    List<AnimeBolum> bolumNesneleri = bolumlerListesi.map((i) => AnimeBolum.fromJson(i)).toList();
    
    var turlerListesi = json['turler'] as List? ?? [];

    return AnimeModel(
      id: json['id'] ?? '',
      baslik: json['baslik'] ?? '',
      kapakResmi: json['kapakResmi'] ?? 'https://via.placeholder.com/300x450?text=Resim+Yok',
      ozet: json['ozet'] ?? 'Özet bulunmuyor.',
      puan: (json['puan'] ?? 0.0).toDouble(),
      turler: turlerListesi.map((e) => e.toString()).toList(),
      bolumler: bolumNesneleri,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'baslik': baslik,
        'kapakResmi': kapakResmi,
        'ozet': ozet,
        'puan': puan,
        'turler': turler,
        'bolumler': bolumler.map((e) => e.toJson()).toList(),
      };
}