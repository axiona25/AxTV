import 'dart:io';
import 'package:flutter/material.dart';

/// Helper per ottenere informazioni di locale e paese dal dispositivo
class DeviceLocaleHelper {
  /// Ottiene il codice lingua del dispositivo (es: 'it', 'en')
  static String? getLanguageCode(BuildContext? context) {
    if (context != null) {
      final locale = Localizations.localeOf(context);
      return locale.languageCode.toLowerCase();
    }
    
    // Fallback: usa platform locale
    try {
      final platformLocale = Platform.localeName;
      if (platformLocale.isNotEmpty) {
        final parts = platformLocale.split('_');
        return parts.isNotEmpty ? parts[0].toLowerCase() : null;
      }
    } catch (e) {
      // Ignora errori
    }
    
    return null;
  }

  /// Ottiene il codice paese del dispositivo (es: 'IT', 'US')
  static String? getCountryCode(BuildContext? context) {
    if (context != null) {
      final locale = Localizations.localeOf(context);
      if (locale.countryCode != null) {
        return locale.countryCode!.toLowerCase();
      }
    }
    
    // Fallback: usa platform locale
    try {
      final platformLocale = Platform.localeName;
      if (platformLocale.isNotEmpty) {
        final parts = platformLocale.split('_');
        if (parts.length > 1) {
          return parts[1].toLowerCase();
        }
      }
    } catch (e) {
      // Ignora errori
    }
    
    return null;
  }
}
