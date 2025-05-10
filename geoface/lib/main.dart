import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geoface/controllers/asistencia_controller.dart';
import 'package:geoface/controllers/theme_provider.dart';
import 'package:geoface/controllers/user_controller.dart';
import 'app_config.dart';
import 'routes.dart';
import 'themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/empleado_controller.dart';
import 'controllers/sede_controller.dart';
import 'controllers/reporte_controller.dart';
import 'controllers/biometrico_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    
    // Inicializar configuraciones
    await AppConfig.initialize();
  } catch (e) {
    // Si hay un error al inicializar Firebase, lo mostramos
    print("Error inicializando Firebase: $e");
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Aquí es donde consumimos el ThemeProvider
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Sistema de Control de Asistencia',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // Aquí usamos el estado del themeProvider para determinar el modo del tema
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: AppRoutes.login,
          // Nota: No necesitas definir 'home' si estás usando 'initialRoute'
        );
      },
    );
  }
}