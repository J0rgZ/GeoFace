// controllers/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  bool _isDarkMode = false;
  ThemeData _currentTheme = AppTheme.lightTheme;

  // Getters
  bool get isDarkMode => _isDarkMode;
  ThemeData get currentTheme => _currentTheme;

  // Constructor - Inicializa y carga el tema guardado
  ThemeController() {
    _loadThemePreference();
  }

  // Carga la preferencia del tema desde shared preferences
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
  }

  // Guarda la preferencia del tema
  Future<void> _saveThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  // Alterna entre tema claro y oscuro
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    _saveThemePreference();
    notifyListeners();
  }

  // Establece un tema específico
  void setTheme(bool darkMode) {
    if (_isDarkMode != darkMode) {
      _isDarkMode = darkMode;
      _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
      _saveThemePreference();
      notifyListeners();
    }
  }
}