import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Platform detection utility
class PlatformUtils {
  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  /// Check if running on mobile (Android, iOS)
  static bool get isMobile => isAndroid || isIOS;

  /// Check if can use native sockets (for LAN P2P)
  static bool get canUseNativeSockets => !kIsWeb;

  /// Get platform name for display
  static String get platformName {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  /// Get P2P capability message
  static String get p2pCapabilityMessage {
    if (kIsWeb) {
      return '⚠️ Web browser không hỗ trợ P2P LAN trực tiếp.\n'
          'Để sử dụng P2P offline, vui lòng cài đặt app desktop hoặc mobile.';
    }
    return '✅ P2P LAN sẵn sàng! Các thiết bị trên cùng mạng WiFi có thể kết nối.';
  }

  /// Check if P2P LAN is supported
  static bool get isP2PLanSupported => !kIsWeb;
}
