import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geoface/controllers/asistencia_controller.dart';
import 'package:geoface/controllers/biometrico_controller.dart';
import 'package:geoface/controllers/theme_provider.dart';
import 'package:geoface/controllers/user_controller.dart';
import 'package:geoface/views/permissions_handler.dart';
import 'package:geoface/views/main_menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_config.dart';
import 'routes.dart';
import 'themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/empleado_controller.dart';
import 'controllers/sede_controller.dart';
import 'controllers/reporte_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    
    // Inicializar datos de localización para las fechas en español
    await initializeDateFormatting('es_ES', null);
    
    // Inicializar configuraciones
    await AppConfig.initialize();
  } catch (e) {
    // Si hay un error al inicializar Firebase, lo mostramos
    print("Error en inicialización: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        // Proveedor para AuthController
        ChangeNotifierProvider(create: (context) => AuthController()),
        
        // Agrega los otros controladores aquí
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => EmpleadoController()),
        ChangeNotifierProvider(create: (context) => SedeController()),
        ChangeNotifierProvider(create: (context) => ReporteController()),
        ChangeNotifierProvider(create: (context) => UserController()),
        ChangeNotifierProvider(create: (context) => AsistenciaController()),
        ChangeNotifierProvider(create: (_) => BiometricoController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFirstLaunch = true;
  bool _isLoading = true; // Para controlar estados de carga
  final String _firstLaunchKey = 'isFirstLaunch';
  final String _permissionsKey = 'permissionsGranted';
  
  @override
  void initState() {
    super.initState();
    _loadAppState();
  }
  
  Future<void> _loadAppState() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
      _isLoading = false;
    });
  }
  
  Future<void> _setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
    setState(() {
      _isFirstLaunch = false;
    });
  }
  
  Future<void> _setPermissionsState(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsKey, granted);
    setState(() {
    });
  }
  
  void _handlePermissionsGranted() {
    _setPermissionsState(true);
    _setFirstLaunchCompleted();
  }
  

  @override
  Widget build(BuildContext context) {
    // Aquí es donde consumimos el ThemeProvider
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'GeoFace - Control de Asistencia',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // Aquí usamos el estado del themeProvider para determinar el modo del tema
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          // Eliminar la declaración de routes estática y usar solo onGenerateRoute
          onGenerateRoute: AppRoutes.generateRoute,
          // El home depende de si es la primera vez que se inicia la app
          home: _isLoading 
            ? _buildLoadingScreen() 
            : _buildInitialScreen(),
        );
      },
    );
  }
  
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.lightTheme.primaryColor,
              AppTheme.lightTheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.face_retouching_natural,
                color: Colors.white,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'GeoFace',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInitialScreen() {
    // Si es la primera vez que se inicia la app, mostramos la pantalla de permisos
    if (_isFirstLaunch) {
      return PermissionsHandlerScreen(
        onPermissionsGranted: _handlePermissionsGranted,
      );
    }
    
    // Si ya se han concedido los permisos o no es la primera vez, mostramos el menú principal
    return MainMenuScreen(
      onMarkAttendance: (context) {
        // Usar pushNamed con argumentos que incluyen el sedeId
        Navigator.of(context).pushNamed(
          AppRoutes.marcarAsistencia,
          arguments: {'sedeId': 'sede_actual_id'}, // Debes reemplazar 'sede_actual_id' con el ID real
        );
      },
      onAdminLogin: (context) {
        Navigator.of(context).pushNamed(AppRoutes.login);
      },
    );
  }
}