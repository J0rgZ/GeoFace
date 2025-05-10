import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores principales - Morado como color primario
  static const Color _primaryColor = Color(0xFF6A1B9A);      // Morado profundo
  static const Color _secondaryColor = Color(0xFF00C853);    // Verde complementario
  static const Color _accentColor = Color(0xFF8E24AA);       // Morado medio

  // Tema Claro
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),  // Fondo gris muy claro
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFF3E5F5),  // Morado muy claro para contenedores
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE8F5E9),  // Verde muy claro para contenedores
      tertiary: _accentColor,
      background: Color(0xFFF8F9FA),
      surface: Colors.white,
      onBackground: Color(0xFF303030),
      onSurface: Color(0xFF505050),
      error: Color(0xFFE53935),
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      shadowColor: Color(0x55000000),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryColor.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _secondaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF303030)),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF303030)),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF303030)),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF303030)),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF303030)),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF303030)),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF505050)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF505050)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF707070)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF3E5F5),
      disabledColor: Colors.grey.shade200,
      selectedColor: _primaryColor,
      secondarySelectedColor: _secondaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(color: Color(0xFF505050)),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 32,
    ),
    iconTheme: const IconThemeData(
      color: _primaryColor,
      size: 24,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Color(0xFF9E9E9E),
      selectedIconTheme: IconThemeData(
        color: _primaryColor,
        size: 26,
      ),
      unselectedIconTheme: IconThemeData(
        color: Color(0xFF9E9E9E),
        size: 24,
      ),
      elevation: 8,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey.shade800,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  // Tema Oscuro
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: _primaryColor.withOpacity(0.8),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF4A148C).withOpacity(0.7),
      secondary: _secondaryColor.withOpacity(0.8),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF2E7D32).withOpacity(0.7),
      tertiary: _accentColor.withOpacity(0.8),
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onBackground: Colors.white.withOpacity(0.9),
      onSurface: Colors.white.withOpacity(0.8),
      error: const Color(0xFFEF5350),
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      centerTitle: true,
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF242424),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: _primaryColor.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor.withOpacity(0.9),
        side: BorderSide(color: _primaryColor.withOpacity(0.7), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _secondaryColor.withOpacity(0.8),
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryColor.withOpacity(0.8), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade300),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      disabledColor: Colors.grey.shade800,
      selectedColor: _primaryColor.withOpacity(0.7),
      secondarySelectedColor: _secondaryColor.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF424242),
      thickness: 1,
      space: 32,
    ),
    iconTheme: IconThemeData(
      color: _primaryColor.withOpacity(0.9),
      size: 24,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: _primaryColor.withOpacity(0.9),
      unselectedItemColor: Colors.grey.shade400,
      selectedIconTheme: IconThemeData(
        color: _primaryColor.withOpacity(0.9),
        size: 26,
      ),
      unselectedIconTheme: IconThemeData(
        color: Colors.grey.shade400,
        size: 24,
      ),
      elevation: 8,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF242424),
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF323232),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}