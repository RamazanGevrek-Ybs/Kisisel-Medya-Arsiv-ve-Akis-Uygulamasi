import 'package:flutter/material.dart';
import '../services/yerel_veri_servisi.dart';

class AppSettings {
  // Okuma Yönü: true = Dikey, false = Yatay
  static ValueNotifier<bool> mangaDikeyMod = ValueNotifier(true);
  static ValueNotifier<bool> novelDikeyMod = ValueNotifier(true);

  // Novel İç Teması: 0 = Karanlık, 1 = Kitap/Sepia, 2 = Aydınlık
  static ValueNotifier<int> novelTemasi = ValueNotifier(0);

  // GLOBAL UYGULAMA TEMASI: true = Karanlık, false = Aydınlık
  static ValueNotifier<bool> karanlikTemaModu = ValueNotifier(true);

  // Ayarları yükle
  static void yukle() {
    mangaDikeyMod.value = YerelVeriServisi.ayarGetir('mangaDikey') ?? true;
    novelDikeyMod.value = YerelVeriServisi.ayarGetir('novelDikey') ?? true;
    novelTemasi.value = YerelVeriServisi.ayarGetir('novelTema') ?? 0;
    karanlikTemaModu.value = YerelVeriServisi.ayarGetir('globalKaranlik') ?? true;
  }

  // Ayarları Kaydet
  static void kaydet(String anahtar, dynamic deger) {
    YerelVeriServisi.ayarKaydet(anahtar, deger);
  }
}