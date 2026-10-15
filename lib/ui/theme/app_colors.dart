import 'package:flutter/material.dart';

/// Neutral canvas with one indigo accent.
class AppColors {
  AppColors._(); // Private constructor
  
  // ============ Primary Colors (Màu chủ đạo - Xanh dương nhẹ) ============
  
  /// Soft violet
  static const Color primary = Color(0xFF5E6AD2);
  
  static const Color primaryLight = Color(0xFFB4B9F0);
  
  static const Color primaryDark = Color(0xFF3F4BB8);
  
  static const Color primarySubtle = Color(0xFFEEF0FB);
  
  // ============ Secondary Colors (Màu phụ) ============
  
  static const Color secondary = Color(0xFF5E6AD2);
  
  static const Color secondaryLight = Color(0xFFD5D8F6);
  
  static const Color secondaryDark = Color(0xFF3F4BB8);
  
  // ============ Accent Colors (Màu nhấn) ============
  
  static const Color accent = Color(0xFF5E6AD2);
  
  static const Color accentPurple = Color(0xFF5E6AD2);
  
  /// Accent Teal - Xanh ngọc
  static const Color accentTeal = Color(0xFF38B2AC);
  
  // ============ Semantic Colors (Màu ngữ nghĩa) ============
  
  /// Success - Màu thành công
  static const Color success = Color(0xFF48BB78);
  
  /// Success Light
  static const Color successLight = Color(0xFFC6F6D5);
  
  /// Error - Màu lỗi
  static const Color error = Color(0xFFEF4444);
  
  /// Error Light
  static const Color errorLight = Color(0xFFFED7D7);
  
  /// Warning - Màu cảnh báo
  static const Color warning = Color(0xFFF59E0B);
  
  /// Warning Light
  static const Color warningLight = Color(0xFFFEEBC8);
  
  static const Color info = Color(0xFF5E6AD2);
  
  static const Color infoLight = Color(0xFFEEF0FB);
  
  // ============ Background Colors (Màu nền) ============
  
  static const Color background = Color(0xFFF6F7F9);
  
  /// Surface - Màu bề mặt cards, dialogs
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Surface Variant - Bề mặt biến thể
  static const Color surfaceVariant = Color(0xFFF6F7F9);
  
  static const Color surfaceLight = Color(0xFFF6F7F9);
  
  static const Color surfaceHover = Color(0xFFEEEFF2);
  
  // ============ Text Colors (Màu chữ) ============
  
  static const Color textPrimary = Color(0xFF1F2328);
  
  /// Text Secondary - Chữ phụ
  static const Color textSecondary = Color(0xFF656D76);
  
  /// Text Tertiary - Chữ gợi ý
  static const Color textTertiary = Color(0xFFA0AEC0);
  
  /// Text Disabled - Chữ disabled
  static const Color textDisabled = Color(0xFFCBD5E0);
  
  /// Text On Primary - Chữ trên nền primary
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // ============ Border & Divider Colors (Màu viền) ============
  
  /// Border - Viền mặc định
  static const Color border = Color(0xFFE6E8EB);
  
  /// Border Light - Viền nhạt
  static const Color borderLight = Color(0xFFF0F4F8);
  
  static const Color borderFocus = Color(0xFF5E6AD2);
  
  /// Divider - Đường phân cách
  static const Color divider = Color(0xFFEDF2F7);
  
  // ============ Status Colors (Màu trạng thái) ============
  
  /// Online - Trực tuyến
  static const Color online = Color(0xFF48BB78);
  
  /// Offline - Ngoại tuyến
  static const Color offline = Color(0xFF718096);
  
  /// Away - Vắng mặt
  static const Color away = Color(0xFFF59E0B);
  
  /// Busy - Bận
  static const Color busy = Color(0xFFEF4444);
  
  // ============ Gradients (Màu gradient) ============
  
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF5E6AD2), Color(0xFF5E6AD2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientElegant = LinearGradient(
    colors: [Color(0xFF3F4BB8), Color(0xFF5E6AD2), Color(0xFF5E6AD2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientSubtle = LinearGradient(
    colors: [Color(0xFFF6F7F9), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [Color(0xFF5E6AD2), Color(0xFF5E6AD2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Card Gradient - Gradient cho cards
  static const LinearGradient gradientCard = LinearGradient(
    colors: [Color(0xFFFAFBFD), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============ Board Card Gradients (Gradient cho board cards) ============
  
  static const LinearGradient boardGradient1 = LinearGradient(
    colors: [Color(0xFFEEF0FB), Color(0xFFF6F7F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient2 = LinearGradient(
    colors: [Color(0xFF5E6AD2), Color(0xFF3F4BB8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient3 = LinearGradient(
    colors: [Color(0xFF5E6AD2), Color(0xFF3F4BB8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient4 = LinearGradient(
    colors: [Color(0xFFEEF0FB), Color(0xFFF6F7F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient5 = LinearGradient(
    colors: [Color(0xFF3F4BB8), Color(0xFF5E6AD2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient6 = LinearGradient(
    colors: [Color(0xFF3F4BB8), Color(0xFF5E6AD2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// List of all board gradients
  static const List<LinearGradient> boardGradients = [
    boardGradient1,
    boardGradient2,
    boardGradient3,
    boardGradient4,
    boardGradient5,
    boardGradient6,
  ];
  
  // ============ Shadow Colors (Màu đổ bóng) ============
  
  /// Shadow Light - Bóng nhẹ
  static Color shadowLight = const Color(0xFF000000).withOpacity(0.08);
  
  /// Shadow Medium - Bóng trung bình
  static Color shadowMedium = const Color(0xFF000000).withOpacity(0.12);
  
  /// Shadow Heavy - Bóng đậm
  static Color shadowHeavy = const Color(0xFF000000).withOpacity(0.16);
  
  // ============ Overlay Colors (Màu lớp phủ) ============
  
  /// Overlay Light
  static Color overlayLight = const Color(0xFF000000).withOpacity(0.05);
  
  /// Overlay Medium
  static Color overlayMedium = const Color(0xFF000000).withOpacity(0.15);
  
  /// Overlay Dark
  static Color overlayDark = const Color(0xFF000000).withOpacity(0.5);
  
  // ============ Helper Methods (Các phương thức trợ giúp) ============
  
  /// Get board gradient by index (cycles through)
  static LinearGradient getBoardGradient(int index) {
    return boardGradients[index % boardGradients.length];
  }
  
  /// Create primary shadow
  static List<BoxShadow> createPrimaryShadow({
    double opacity = 0.15,
    double blurRadius = 10,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: primary.withOpacity(opacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }
  
  /// Elegant card shadow
  static List<BoxShadow> elegantCardShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  /// Hover shadow
  static List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.08),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
}
