import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static late SharedPreferences _prefs;
  
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static bool get isFirstRun => _prefs.getBool('is_first_run') ?? true;
  
  static Future<void> setFirstRun(bool value) async {
    await _prefs.setBool('is_first_run', value);
  }
  
  // Configuraciones generales de la app
  static const String appName = 'Sistema de Control de Asistencia';
  static const String appVersion = '1.0.0';
  
  // Configuración para APIs y servicios externos
  static const String apiBaseUrl = 'https://api.example.com';
  
  // Configuración para la geolocalización
  static const int geoFenceRadius = 100; // metros
  static const Duration locationUpdateInterval = Duration(minutes: 1);

  // Nuevas constantes para las colecciones de Firestore
  static const String usuariosCollection = 'usuarios';
  static const String empleadosCollection = 'empleados';
  static const String sedesCollection = 'sedes';
  static const String asistenciasCollection = 'asistencias';
}