import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/ad_statistics.dart';
import '../data/ad_statistics_storage.dart';

/// Provider per le statistiche pubblicità (stream in tempo reale)
final adStatisticsProvider = StreamProvider<AdStatistics>((ref) async* {
  // Carica statistiche iniziali
  var stats = await AdStatisticsStorage.loadStatistics();
  yield stats;
  
  // Aggiorna ogni 5 secondi
  final timer = Stream.periodic(const Duration(seconds: 5), (index) => index);
  
  await for (final index in timer) {
    stats = await AdStatisticsStorage.loadStatistics();
    yield stats;
  }
});

/// Provider per le statistiche (Future, senza auto-refresh)
final adStatisticsFutureProvider = FutureProvider<AdStatistics>((ref) async {
  return await AdStatisticsStorage.loadStatistics();
});
