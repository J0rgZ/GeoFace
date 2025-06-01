import 'package:flutter/material.dart';
import 'views/auth/login_page.dart';
import 'views/admin/dashboard_page.dart';
import 'views/admin/empleados_page.dart';
import 'views/admin/sedes_page.dart';
import 'views/admin/reportes_page.dart';
import 'views/admin/empleado_detail_page.dart';
import 'views/admin/registro_biometrico_page.dart';
import 'views/admin/sede_detail_page.dart';
import 'views/empleado/marcar_asistencia_page.dart';
import 'views/admin/admin_layout.dart';

class AppRoutes {
  static const String mainMenu = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String empleados = '/empleados';
  static const String empleadoDetail = '/empleado-detail';
  static const String sedes = '/sedes';
  static const String sedeDetail = '/sede-detail';
  static const String reportes = '/reportes';
  static const String marcarAsistencia = '/marcar-asistencia';
  static const String biometrico = '/biometricos';
  

  // Rutas para Admin:
  static const String adminLayout = '/admin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case empleados:
        return MaterialPageRoute(builder: (_) => const EmpleadosPage());
      case empleadoDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => EmpleadoDetailPage(empleadoId: args['empleadoId']));
      case sedes:
        return MaterialPageRoute(builder: (_) => const SedesPage());
      case sedeDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => SedeDetailPage(sedeId: args['sedeId']));
      case reportes:
        return MaterialPageRoute(builder: (_) => const ReportesPage());
      case marcarAsistencia:
        // Ensure we get the sedeId from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MarcarAsistenciaPage(
            sedeId: args?['sedeId'] ?? '', // Use empty string as fallback
          )
        );
      case biometrico:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => RegistroBiometricoScreen(empleado: args['empleado']),);
        
      // Layout del Administrador
      case adminLayout:
        return MaterialPageRoute(builder: (_) => const AdminLayout());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no definida para ${settings.name}'),
            ),
          ),
        );
    }
  }
}