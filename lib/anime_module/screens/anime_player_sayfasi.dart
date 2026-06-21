import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:ui';
import 'dart:async';
import '../models/anime_model.dart';

class AnimePlayerSayfasi extends StatefulWidget {
  final AnimeModel anime;
  final int baslangicBolumIndex;

  const AnimePlayerSayfasi({super.key, required this.anime, this.baslangicBolumIndex = 0});

  @override
  State<AnimePlayerSayfasi> createState() => _AnimePlayerSayfasiState();
}

class _AnimePlayerSayfasiState extends State<AnimePlayerSayfasi> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  late int aktifBolumIndex;
  bool _arayuzGoster = false;
  bool _otomatikGecisBasladi = false;

  @override
  void initState() {
    super.initState();
    aktifBolumIndex = widget.baslangicBolumIndex;
    _oynaticiyiKur();
  }

  Future<void> _oynaticiyiKur() async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
      _chewieController?.dispose();
    }
    _otomatikGecisBasladi = false;

    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    String url = widget.anime.bolumler[aktifBolumIndex].videoUrl;
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));

    await _videoPlayerController!.initialize();
    _videoPlayerController!.addListener(_videoBitisiDinle);

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      fullScreenByDefault: false,
      allowedScreenSleep: false,
      hideControlsTimer: const Duration(seconds: 3),
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.deepPurpleAccent,
        handleColor: Colors.white,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.deepPurple.withValues(alpha: 0.5),
      ),
    );

    if (mounted) setState(() {});
  }

  void _videoBitisiDinle() {
    if (_videoPlayerController!.value.isInitialized &&
        !_videoPlayerController!.value.isPlaying &&
        _videoPlayerController!.value.position == _videoPlayerController!.value.duration) {
      
      if (!_otomatikGecisBasladi) {
        _otomatikGecisBasladi = true;
        if (aktifBolumIndex < widget.anime.bolumler.length - 1) {
          _otomatikSonrakiBolumeGec();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sezon Bitti!"), backgroundColor: Colors.deepPurpleAccent));
          _cikisYap();
        }
      }
    }
  }

  void _otomatikSonrakiBolumeGec() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Sonraki bölüme geçiliyor..."),
      backgroundColor: Colors.deepPurpleAccent,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(label: "İptal", textColor: Colors.white, onPressed: () {
        _cikisYap();
      }),
    ));

    Timer(const Duration(seconds: 3), () {
      if (mounted) _bolumDegistir(aktifBolumIndex + 1);
    });
  }

  void _bolumDegistir(int yeniIndex) {
    setState(() {
      aktifBolumIndex = yeniIndex;
      _chewieController?.dispose();
      _chewieController = null;
    });
    _oynaticiyiKur();
  }

  void _cikisYap() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoBitisiDinle);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int bolumNo = widget.anime.bolumler[aktifBolumIndex].bolumNo;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _arayuzGoster = !_arayuzGoster),
        child: Stack(
          children: [
            Positioned.fill(
              child: _chewieController != null && _videoPlayerController!.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.deepPurpleAccent),
                          SizedBox(height: 15),
                          Text("Yükleniyor...", style: TextStyle(color: Colors.white54, fontSize: 16)),
                        ],
                      ),
                    ),
            ),
            if (_arayuzGoster)
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24), onPressed: _cikisYap),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text("${widget.anime.baslik} - Bölüm $bolumNo", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
            if (_arayuzGoster && widget.anime.bolumler.length > 1)
              Positioned(
                right: 20, bottom: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 250, height: 180,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24, width: 1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.all(12.0), child: Text("Bölümler", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: widget.anime.bolumler.length,
                              itemBuilder: (context, index) {
                                bool aktifMi = index == aktifBolumIndex;
                                return ListTile(
                                  dense: true,
                                  title: Text("Bölüm ${widget.anime.bolumler[index].bolumNo}", style: TextStyle(color: aktifMi ? Colors.deepPurpleAccent : Colors.white70, fontWeight: aktifMi ? FontWeight.bold : FontWeight.normal)),
                                  trailing: aktifMi ? const Icon(Icons.play_arrow, color: Colors.deepPurpleAccent, size: 18) : null,
                                  onTap: () { if (!aktifMi) _bolumDegistir(index); },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}