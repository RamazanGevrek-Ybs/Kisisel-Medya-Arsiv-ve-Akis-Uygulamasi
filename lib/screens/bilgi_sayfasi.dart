import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart'; 
import '../core/settings.dart'; 
import '../models/manga.dart'; 
import '../services/api_service.dart'; 
import '../services/novel_service.dart';
import '../services/yerel_veri_servisi.dart';
import 'okuma_sayfasi.dart';
import 'novel_okuma_sayfasi.dart';
import 'yerel_okuma_sayfasi.dart';

class BilgiSayfasi extends StatefulWidget {
  final Manga manga; 
  final Color activeColor; 

  const BilgiSayfasi({super.key, required this.manga, required this.activeColor});

  @override
  State<BilgiSayfasi> createState() => _BilgiSayfasiState();
}

class _BilgiSayfasiState extends State<BilgiSayfasi> {
  bool kutuphanedeMi = false;
  bool bitirildiMi = false;
  late Future<Map<String, dynamic>> _bolumVerisi;
  late bool isNovel;
  late bool isYerel;

  @override
  void initState() {
    super.initState();
    isNovel = widget.manga.turler.contains('Light Novel') || widget.manga.turler.contains('Novel');
    isYerel = widget.manga.kapakResmi == "yerel_ikon";
    kutuphanedeMi = YerelVeriServisi.favorilerdeVarMi(widget.manga.id, !isNovel);
    bitirildiMi = YerelVeriServisi.seriBitirildiMi(widget.manga.id, !isNovel);
    
    if (isYerel) {
      _bolumVerisi = Future.value({'bolumler': <Bolum>[]});
    } else {
      _bolumVerisi = isNovel 
          ? NovelService.detayVeBolumGetir(widget.manga.id)
          : ApiService.detayVeBolumGetir(widget.manga.id);
    }
  }

  void _okumayaBasla(List<Bolum> hamBolumler, String hedefBolumId, {int? sayfaIndex}) {
    YerelVeriServisi.sonOkunanEkle(widget.manga, !isNovel);

    if (isYerel) {
      List<String> yollar = [];
      if (widget.manga.ozet.startsWith("YerelDosyalar:")) {
        yollar = widget.manga.ozet.replaceFirst("YerelDosyalar:", "").split("|");
      } else {
        yollar = [widget.manga.ozet.split(": ").last];
      }
      
      Navigator.push(context, CupertinoPageRoute(
        builder: (context) => YerelOkumaSayfasi(
          manga: widget.manga, 
          dosyaYollari: yollar, 
          isManga: widget.manga.turler.contains("Manga"),
          baslangicSayfa: sayfaIndex,
        )
      ));
      return;
    }

    final list = List<Bolum>.from(hamBolumler);
    list.sort((a, b) {
      final numA = double.tryParse(a.bolumNo) ?? 0;
      final numB = double.tryParse(b.bolumNo) ?? 0;
      return numA.compareTo(numB);
    });

    final index = list.indexWhere((x) => x.id == hedefBolumId);

    if (isNovel) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => NovelOkumaSayfasi(
          mangaId: widget.manga.id,
          tumBolumler: list, 
          baslangicIndex: index,
          novelAdi: widget.manga.isim,
          baslangicSayfa: sayfaIndex, 
        )
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => OkumaSayfasi(
          mangaId: widget.manga.id,
          tumBolumler: list, 
          baslangicIndex: index,
          mangaAdi: widget.manga.isim,
          baslangicSayfa: sayfaIndex,
        )
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.karanlikTemaModu,
      builder: (context, karanlikMi, _) {
        Color bg = karanlikMi ? AppColors.darkBg : Colors.white;
        Color textC = karanlikMi ? Colors.white : Colors.black87;
        Color cardBg = karanlikMi ? AppColors.cardBg : Colors.grey[200]!;

        return Scaffold(
          backgroundColor: bg,
          body: FutureBuilder<Map<String, dynamic>>(
            future: _bolumVerisi,
            builder: (context, snapshot) {
              final bolumler = snapshot.data?['bolumler'] as List<Bolum>? ?? [];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: bg,
                    leading: IconButton(icon: Icon(Icons.arrow_back, color: textC), onPressed: () => Navigator.pop(context)),
                    title: Text(widget.manga.isim, style: GoogleFonts.bangers(fontSize: 22, color: textC), overflow: TextOverflow.ellipsis),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140, height: 210,
                            decoration: BoxDecoration(
                              color: cardBg, 
                              borderRadius: BorderRadius.circular(12), 
                              border: Border.all(color: widget.activeColor.withValues(alpha: 0.2))
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12), 
                              child: isYerel 
                                ? Container(color: cardBg, child: Icon(Icons.folder, color: widget.activeColor, size: 60))
                                : Image.network(
                                    widget.manga.kapakResmi, 
                                    fit: BoxFit.cover, 
                                    cacheWidth: 400, 
                                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)
                                  )
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.manga.isim, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textC), maxLines: 3),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.yellow, size: 20), 
                                    const SizedBox(width: 5), 
                                    Text(widget.manga.puan.toString(), style: TextStyle(color: textC, fontSize: 18))
                                  ]
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6, 
                                  runSpacing: 6, 
                                  children: widget.manga.turler.take(4).map((t) => Container(
                                    padding: const EdgeInsets.all(4), 
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.2), 
                                      borderRadius: BorderRadius.circular(4)
                                    ), 
                                    child: Text(t, style: const TextStyle(color: Colors.grey, fontSize: 10))
                                  )).toList()
                                ),
                                const SizedBox(height: 20),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() => kutuphanedeMi = !kutuphanedeMi);
                                          YerelVeriServisi.favoriGuncelle(widget.manga, kutuphanedeMi, !isNovel);
                                        },
                                        icon: Icon(kutuphanedeMi ? Icons.bookmark : Icons.bookmark_add, color: textC, size: 16),
                                        label: Text(kutuphanedeMi ? "Eklendi" : "Ekle", style: TextStyle(color: textC, fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: kutuphanedeMi ? widget.activeColor : Colors.transparent, 
                                          side: BorderSide(color: widget.activeColor),
                                          padding: const EdgeInsets.symmetric(vertical: 8)
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() => bitirildiMi = !bitirildiMi);
                                          YerelVeriServisi.seriDurumuGuncelle(widget.manga.id, !isNovel, bitirildiMi);
                                        },
                                        icon: Icon(bitirildiMi ? Icons.task_alt : Icons.radio_button_unchecked, color: Colors.white, size: 16),
                                        label: Text(bitirildiMi ? "BİTTİ" : "BİTİR", style: const TextStyle(color: Colors.white, fontSize: 11)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: bitirildiMi ? Colors.green : Colors.grey[800],
                                          padding: const EdgeInsets.symmetric(vertical: 8)
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Text("ÖZET", style: GoogleFonts.bangers(fontSize: 22, color: widget.activeColor)),
                          const SizedBox(height: 8),
                          Text(
                            widget.manga.ozet.startsWith("YerelDosyalar:") 
                              ? "Bu cihazdan eklenen yerel dosya arşivi." 
                              : widget.manga.ozet, 
                            style: TextStyle(color: karanlikMi ? Colors.grey[300] : Colors.grey[800], height: 1.5)
                          ),
                        ]
                      ),
                    ),
                  ),
                  isYerel
                    ? const SliverToBoxAdapter(child: SizedBox())
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, 
                            crossAxisSpacing: 10, 
                            mainAxisSpacing: 10, 
                            childAspectRatio: 3.2
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (c, i) => InkWell(
                              onTap: () => _okumayaBasla(bolumler, bolumler[i].id),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBg, 
                                  borderRadius: BorderRadius.circular(8), 
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2))
                                ),
                                child: Center(
                                  child: Text("Bölüm ${bolumler[i].bolumNo}", style: TextStyle(color: textC))
                                ),
                              ),
                            ),
                            childCount: bolumler.length,
                          ),
                        ),
                      ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            },
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            color: bg,
            child: ElevatedButton(
              onPressed: () async {
                final kayit = YerelVeriServisi.ilerlemeyiGetir(widget.manga.id);
                if (isYerel) {
                  _okumayaBasla([], "yerel_bolum", sayfaIndex: kayit?['sayfaIndex']);
                  return;
                }
                final data = await _bolumVerisi;
                final list = data['bolumler'] as List<Bolum>;
                if (list.isEmpty) return;
                
                if (kayit != null) {
                  _okumayaBasla(list, kayit['bolumId'], sayfaIndex: kayit['sayfaIndex']);
                } else {
                  _okumayaBasla(list, list.last.id); 
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.activeColor, 
                minimumSize: const Size(double.infinity, 54)
              ),
              child: Text(
                YerelVeriServisi.ilerlemeyiGetir(widget.manga.id) != null ? "DEVAM ET" : "OKUMAYA BAŞLA", 
                style: GoogleFonts.bangers(fontSize: 22, color: Colors.white)
              ),
            ),
          ),
        );
      }
    );
  }
}