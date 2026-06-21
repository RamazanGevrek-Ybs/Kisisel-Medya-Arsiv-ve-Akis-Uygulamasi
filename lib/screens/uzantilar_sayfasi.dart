import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/colors.dart';
import '../core/settings.dart';

class UzantilarSayfasi extends StatefulWidget {
  const UzantilarSayfasi({super.key});

  @override
  State<UzantilarSayfasi> createState() => _UzantilarSayfasiState();
}

class _UzantilarSayfasiState extends State<UzantilarSayfasi> {
  final TextEditingController _repoController = TextEditingController();
  final List<String> _ekliRepolar = [
    "https://api.mangadex.org (Varsayılan Manga)",
    "https://www.royalroad.com (Varsayılan Novel)"
  ];

  @override
  void initState() {
    super.initState();
    _repolariYukle();
  }

  Future<void> _repolariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? kayitli = prefs.getStringList('repo_keys');
    if (kayitli != null && kayitli.isNotEmpty) {
      setState(() {
        _ekliRepolar.addAll(kayitli);
      });
    }
  }

  Future<void> _repoEkle(String url) async {
    if (url.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> kayitli = prefs.getStringList('repo_keys') ?? [];
    
    if (!kayitli.contains(url) && !_ekliRepolar.contains(url)) {
      kayitli.add(url);
      await prefs.setStringList('repo_keys', kayitli);
      
      if (!mounted) return; // Asenkron sonrası güvenlik
      
      setState(() {
        _ekliRepolar.add(url);
        _repoController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni repo başarıyla eklendi!")));
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
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            title: Text("UZANTILAR VE REPO", style: GoogleFonts.bangers(fontSize: 24, color: textC)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textC),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Yeni Kaynak Ekle", style: TextStyle(color: AppColors.novelBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Harici manga/novel havuzlarına erişmek için Repo Key veya URL girin.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
                        child: TextField(
                          controller: _repoController,
                          style: TextStyle(color: textC),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Örn: https://raw.githubusercontent...",
                            hintStyle: TextStyle(color: Colors.grey)
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.novelBlue,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () => _repoEkle(_repoController.text),
                      child: const Icon(Icons.add, color: Colors.white),
                    )
                  ],
                ),
                
                const SizedBox(height: 30),
                const Text("Aktif Uzantılar", style: TextStyle(color: AppColors.mangaOrange, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _ekliRepolar.length,
                    itemBuilder: (context, index) {
                      bool varsayilanMi = index < 2; 
                      return Card(
                        color: cardBg,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Icon(Icons.extension, color: varsayilanMi ? Colors.green : AppColors.novelBlue),
                          title: Text(_ekliRepolar[index], style: TextStyle(color: textC, fontSize: 14)),
                          trailing: varsayilanMi 
                            ? const Icon(Icons.lock_outline, color: Colors.grey, size: 20)
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  List<String> kayitli = prefs.getStringList('repo_keys') ?? [];
                                  kayitli.remove(_ekliRepolar[index]);
                                  await prefs.setStringList('repo_keys', kayitli);
                                  setState(() => _ekliRepolar.removeAt(index));
                                },
                              ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }
}