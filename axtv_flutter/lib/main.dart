import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  // Inizializza AdMob solo su iOS e Android (non supportato su macOS/web)
  if (Platform.isIOS || Platform.isAndroid) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
      // Non bloccare l'avvio dell'app se AdMob fallisce
    }
  }

  runApp(const ProviderScope(child: App()));
}
