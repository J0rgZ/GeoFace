import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/estadistica_asistencia.dart';

class ReporteController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<EstadisticaAsistencia> _estadisticas = [];
  bool _loading = false;
  String? _errorMessage;

  List<EstadisticaAsistencia> get estadisticas => _estadisticas;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> generarReporteAsistencia(String sedeId, DateTime fecha) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Obtener sede
      final sede = await _firebaseService.getSedeById(sedeId);
      if (sede == null) {
        throw Exception('Sede no encontrada');
      }
      
      // Obtener empleados de la sede
      final empleados = await _firebaseService.getEmpleados();
      final empleadosSede = empleados.where((e) => e.sedeId == sedeId && e.activo).toList();
      
      // Obtener asistencias para la fecha
      final asistenciasSede = await _firebaseService.getAsistenciasBySede(sedeId);
      
      // Filtrar asistencias por fecha
      final fechaInicio = DateTime(fecha.year, fecha.month, fecha.day, 0, 0, 0);
      final fechaFin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
      
      final asistenciasFecha = asistenciasSede.where((a) => 
        a.fechaHoraEntrada.isAfter(fechaInicio) && 
        a.fechaHoraEntrada.isBefore(fechaFin)
      ).toList();
      
      // Contar asistencias
      final totalEmpleados = empleadosSede.length;
      final totalAsistencias = asistenciasFecha.length;
      
      // Contar tardanzas (ejemplo: > 9am)
      final horaEntrada = DateTime(fecha.year, fecha.month, fecha.day, 9, 0, 0);
      final totalTardanzas = asistenciasFecha.where((a) => 
        a.fechaHoraEntrada.isAfter(horaEntrada)
      ).length;
      
      // Calcular ausencias
      final totalAusencias = totalEmpleados - totalAsistencias;
      
      // Calcular porcentaje
      final porcentajeAsistencia = totalEmpleados > 0 
      ? (totalAsistencias / totalEmpleados) * 100.0  // Convierte a double
      : 0.0;  // Asegúrate de usar 0.0 para mantener la coherencia de tipo
      
      // Crear estadística
      final estadistica = EstadisticaAsistencia(
        sedeId: sedeId,
        fecha: fecha,
        totalEmpleados: totalEmpleados,
        totalAsistencias: totalAsistencias,
        totalAusencias: totalAusencias,
        totalTardanzas: totalTardanzas,
        porcentajeAsistencia: porcentajeAsistencia,
      );
      
      _estadisticas = [estadistica];
    } catch (e) {
      _errorMessage = 'Error al generar reporte: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}