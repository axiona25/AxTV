import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper per rilevare la piattaforma
class PlatformHelper {
  /// Verifica se l'app è su desktop (macOS, Windows, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Verifica se l'app è su mobile (iOS, Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Verifica se l'app è su macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Verifica se l'app è su iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Verifica se l'app è su Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }
}
