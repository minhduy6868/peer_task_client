import 'package:flutter/material.dart';

/// Soft violet palette for the product and the public landing.
class AppColors {
  AppColors._(); // Private constructor
  
  // ============ Primary Colors (Màu chủ đạo - Xanh dương nhẹ) ============
  
  /// Soft violet
  static const Color primary = Color(0xFF8B7CFF);
  
  static const Color primaryLight = Color(0xFFC4B8FF);
  
  static const Color primaryDark = Color(0xFF5B4AD4);
  
  static const Color primarySubtle = Color(0xFFF3F0FF);
  
  // ============ Secondary Colors (Màu phụ) ============
  
  static const Color secondary = Color(0xFFA78BFA);
  
  static const Color secondaryLight = Color(0xFFD4C6FF);
  
  static const Color secondaryDark = Color(0xFF7C5CE6);
  
  // ============ Accent Colors (Màu nhấn) ============
  
  static const Color accent = Color(0xFFC084FC);
  
  static const Color accentPurple = Color(0xFFB794F6);
  
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
  
  static const Color info = Color(0xFF8B7CFF);
  
  static const Color infoLight = Color(0xFFE4DFFF);
  
  // ============ Background Colors (Màu nền) ============
  
  static const Color background = Color(0xFFF7F4FF);
  
  /// Surface - Màu bề mặt cards, dialogs
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Surface Variant - Bề mặt biến thể
  static const Color surfaceVariant = Color(0xFFFAFBFD);
  
  static const Color surfaceLight = Color(0xFFF4F0FF);
  
  static const Color surfaceHover = Color(0xFFEDE7FF);
  
  // ============ Text Colors (Màu chữ) ============
  
  static const Color textPrimary = Color(0xFF2C2440);
  
  /// Text Secondary - Chữ phụ
  static const Color textSecondary = Color(0xFF718096);
  
  /// Text Tertiary - Chữ gợi ý
  static const Color textTertiary = Color(0xFFA0AEC0);
  
  /// Text Disabled - Chữ disabled
  static const Color textDisabled = Color(0xFFCBD5E0);
  
  /// Text On Primary - Chữ trên nền primary
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // ============ Border & Divider Colors (Màu viền) ============
  
  /// Border - Viền mặc định
  static const Color border = Color(0xFFE2E8F0);
  
  /// Border Light - Viền nhạt
  static const Color borderLight = Color(0xFFF0F4F8);
  
  static const Color borderFocus = Color(0xFF8B7CFF);
  
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
    colors: [Color(0xFF8B7CFF), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientElegant = LinearGradient(
    colors: [Color(0xFF5B4AD4), Color(0xFF8B7CFF), Color(0xFFC4B8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientSubtle = LinearGradient(
    colors: [Color(0xFFF3F0FF), Color(0xFFFAF8FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [Color(0xFFC4B5FD), Color(0xFF8B7CFF)],
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
    colors: [Color(0xFF8B7CFF), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient2 = LinearGradient(
    colors: [Color(0xFFC084FC), Color(0xFF8B7CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient3 = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF7C5CE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient4 = LinearGradient(
    colors: [Color(0xFFC4B8FF), Color(0xFFE4DFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient5 = LinearGradient(
    colors: [Color(0xFF5B4AD4), Color(0xFF8B7CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient boardGradient6 = LinearGradient(
    colors: [Color(0xFF7C5CE6), Color(0xFFC4B5FD)],
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
  static Color shadowLight = const Color(0xFF8B7CFF).withOpacity(0.08);
  
  /// Shadow Medium - Bóng trung bình
  static Color shadowMedium = const Color(0xFF8B7CFF).withOpacity(0.15);
  
  /// Shadow Heavy - Bóng đậm
  static Color shadowHeavy = const Color(0xFF8B7CFF).withOpacity(0.25);
  
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
      color: const Color(0xFF8B7CFF).withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF8B7CFF).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  /// Hover shadow
  static List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: const Color(0xFF8B7CFF).withOpacity(0.2),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFF8B7CFF).withOpacity(0.1),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
}
