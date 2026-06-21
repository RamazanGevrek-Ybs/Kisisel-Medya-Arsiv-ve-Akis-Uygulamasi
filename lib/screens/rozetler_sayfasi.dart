import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../core/settings.dart';
import '../services/yerel_veri_servisi.dart';

class RozetlerSayfasi extends StatefulWidget {
  const RozetlerSayfasi({super.key});

  @override
  State<RozetlerSayfasi> createState() => _RozetlerSayfasiState();
}

class _RozetlerSayfasiState extends State<RozetlerSayfasi> {
  late List<Map<String, dynamic>> _tumRozetler;
  
  @override
  void initState() {
    super.initState();
    _tumRozetler = YerelVeriServisi.rozetleriHesapla();
  }

  List<Map<String, dynamic>> _rozetleriFiltrele(String seviye) {
    return _tumRozetler.where((r) => r['seviye'] == seviye).toList();
  }

  Color _seviyeRengiGetir(String seviye) {
    switch (seviye) {
      case 'Efsanevi': return Colors.amber; 
      case 'Destansı': return Colors.deepPurpleAccent; 
      case 'Nadir': return Colors.lightBlueAccent; 
      default: return Colors.grey.shade400; 
    }
  }

  String _seviyeBasligiGetir(String seviye) {
    switch (seviye) {
      case 'Efsanevi': return "👑 EFSANEVİ BAŞARIMLAR (İMKANSIZ)";
      case 'Destansı': return "🔥 DESTANSI BAŞARIMLAR (ZOR)";
      case 'Nadir': return "⚡ NADİR BAŞARIMLAR (ORTA)";
      default: return "🌱 SIRADAN BAŞARIMLAR (KOLAY)";
    }
  }

  @override
  Widget build(BuildContext context) {
    int kazanilanSayisi = _tumRozetler.where((r) => r['acikMi'] == true).length;
    double ilerlemeYuzdesi = kazanilanSayisi / _tumRozetler.length;

    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.karanlikTemaModu,
      builder: (context, karanlikMi, _) {
        Color bg = karanlikMi ? const Color(0xFF0D0D0D) : Colors.white;
        Color textC = karanlikMi ? Colors.white : Colors.black87;
        Color cardBg = karanlikMi ? const Color(0xFF161616) : Colors.grey[100]!;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: textC), onPressed: () => Navigator.pop(context)),
            title: Text("BAŞARIMLAR VE ROZETLER", style: GoogleFonts.bangers(fontSize: 24, color: textC, letterSpacing: 1.5)),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.mangaOrange.withValues(alpha: 0.3)),
                    boxShadow: [BoxShadow(color: AppColors.mangaOrange.withValues(alpha: 0.1), blurRadius: 15)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Manga Hub Koleksiyonu", style: TextStyle(color: textC, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("$kazanilanSayisi / ${_tumRozetler.length}", style: const TextStyle(color: AppColors.mangaOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: ilerlemeYuzdesi,
                          minHeight: 14,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mangaOrange),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          ilerlemeYuzdesi == 1.0 ? "Efsanesin! Uygulamanın zirvesine ulaştın." : "Karanlık başarımlar seni bekliyor, okumaya devam et!",
                          style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _kategoriAlaniOlustur('Efsanevi', cardBg, textC),
              _kategoriAlaniOlustur('Destansı', cardBg, textC),
              _kategoriAlaniOlustur('Nadir', cardBg, textC),
              _kategoriAlaniOlustur('Sıradan', cardBg, textC),
              
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      }
    );
  }

  Widget _kategoriAlaniOlustur(String seviye, Color cardBg, Color textC) {
    List<Map<String, dynamic>> liste = _rozetleriFiltrele(seviye);
    if (liste.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    Color seviyeRengi = _seviyeRengiGetir(seviye);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Row(
              children: [
                Icon(Icons.stars, color: seviyeRengi, size: 20),
                const SizedBox(width: 8),
                Text(
                  _seviyeBasligiGetir(seviye), 
                  style: GoogleFonts.bangers(fontSize: 18, color: seviyeRengi, letterSpacing: 1.2)
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              crossAxisSpacing: 12, 
              mainAxisSpacing: 12, 
              // KRAL DEVRİMİ: 0.68'den 0.60'a düşürüldü, kartlar daha uzun oldu. Alt taşma hatası (RenderFlex) çözüldü!
              childAspectRatio: 0.60 
            ),
            itemCount: liste.length,
            itemBuilder: (context, index) {
              return _rozetKartiOlustur(liste[index], seviyeRengi, cardBg, textC);
            },
          ),
        ],
      ),
    );
  }

  Widget _rozetKartiOlustur(Map<String, dynamic> rozet, Color seviyeRengi, Color cardBg, Color textC) {
    bool acikMi = rozet['acikMi'];
    
    Color aktifRenk = acikMi ? seviyeRengi : Colors.grey.withValues(alpha: 0.3);
    Color arkaplanRengi = acikMi ? seviyeRengi.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: arkaplanRengi,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: aktifRenk, width: acikMi ? 2.0 : 1.0),
        boxShadow: acikMi && (rozet['seviye'] == 'Efsanevi' || rozet['seviye'] == 'Destansı')
            ? [BoxShadow(color: seviyeRengi.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                rozet['ikon'], 
                style: TextStyle(
                  fontSize: 34, 
                  color: acikMi ? null : Colors.grey.withValues(alpha: 0.2) 
                )
              ),
              if (!acikMi) 
                Icon(Icons.lock_outline, color: Colors.grey.withValues(alpha: 0.8), size: 26),
            ],
          ),
          const SizedBox(height: 10),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              acikMi ? rozet['isim'] : "GİZLİ", 
              style: TextStyle(
                color: acikMi ? textC : Colors.grey, 
                fontWeight: FontWeight.bold, 
                fontSize: 12
              ), 
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          
          // KRAL DEVRİMİ: Expanded içine alınarak aşağı taşması %100 engellendi!
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: Text(
                  rozet['ozet'], 
                  style: TextStyle(
                    color: Colors.grey[500], 
                    fontSize: 10,
                    height: 1.1
                  ), 
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: aktifRenk.withValues(alpha: acikMi ? 0.2 : 0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14), 
                bottomRight: Radius.circular(14)
              ),
            ),
            child: Text(
              rozet['seviye'].toUpperCase(),
              style: TextStyle(
                color: acikMi ? seviyeRengi : Colors.grey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0
              ),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}