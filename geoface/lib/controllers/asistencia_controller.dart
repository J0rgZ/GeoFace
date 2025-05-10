import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../models/asistencia.dart';
import '../utils/location_helper.dart';

class AsistenciaController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  final Uuid _uuid = Uuid();
  
  Asistencia? _asistenciaActiva;
  List<Asistencia> _asistencias = [];
  bool _loading = false;
  String? _errorMessage;

  Asistencia? get asistenciaActiva => _asistenciaActiva;
  List<Asistencia> get asistencias => _asistencias;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAsistenciaActiva(String empleadoId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _asistenciaActiva = await _firebaseService.getActiveAsistencia(empleadoId);
    } catch (e) {
      _errorMessage = 'Error al verificar asistencia: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> registrarEntrada({
    required String empleadoId,
    required String sedeId,
    required String capturaEntrada,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Verificar que no haya una entrada activa
      final asistenciaActiva = await _firebaseService.getActiveAsistencia(empleadoId);
      if (asistenciaActiva != null) {
        throw Exception('Ya tiene una asistencia activa');
      }
      
      // Obtener sede
      final sede = await _firebaseService.getSedeById(sedeId);
      if (sede == null) {
        throw Exception('Sede no encontrada');
      }
      
      // Obtener ubicación actual
      final position = await _locationService.getCurrentPosition();
      
      // Verificar que está dentro del radio permitido
      final distancia = LocationHelper.calcularDistancia(
        position.latitude, 
        position.longitude, 
        sede.latitud, 
        sede.longitud
      );
      
      if (distancia > sede.radioPermitido) {
        throw Exception('Está fuera del radio permitido para marcar asistencia');
      }
      
      // Crear asistencia
      final asistencia = Asistencia(
        id: _uuid.v4(),
        empleadoId: empleadoId,
        sedeId: sedeId,
        fechaHoraEntrada: DateTime.now(),
        latitudEntrada: position.latitude,
        longitudEntrada: position.longitude,
        capturaEntrada: capturaEntrada,
      );
      
      await _firebaseService.registrarEntrada(asistencia);
      _asistenciaActiva = asistencia;
      
      // Actualizar la lista de asistencias añadiendo la nueva
      _asistencias = [..._asistencias, asistencia];
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al registrar entrada: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarSalida({
    required String asistenciaId,
    String? capturaSalida,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Obtener asistencia actual
      final asistencia = _asistenciaActiva;
      if (asistencia == null || asistencia.id != asistenciaId) {
        throw Exception('Asistencia no encontrada');
      }
      
      // Obtener ubicación actual
      final position = await _locationService.getCurrentPosition();
      
      // Actualizar asistencia
      final asistenciaActualizada = Asistencia(
        id: asistencia.id,
        empleadoId: asistencia.empleadoId,
        sedeId: asistencia.sedeId,
        fechaHoraEntrada: asistencia.fechaHoraEntrada,
        fechaHoraSalida: DateTime.now(),
        latitudEntrada: asistencia.latitudEntrada,
        longitudEntrada: asistencia.longitudEntrada,
        latitudSalida: position.latitude,
        longitudSalida: position.longitude,
        capturaEntrada: asistencia.capturaEntrada,
        capturaSalida: capturaSalida,
      );
      
      await _firebaseService.registrarSalida(asistenciaActualizada);
      _asistenciaActiva = null;
      
      // Actualizar la asistencia en la lista
      final index = _asistencias.indexWhere((a) => a.id == asistenciaId);
      if (index >= 0) {
        _asistencias[index] = asistenciaActualizada;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al registrar salida: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> getAsistenciasByEmpleado(String empleadoId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _asistencias = await _firebaseService.getAsistenciasByEmpleado(empleadoId);
    } catch (e) {
      _errorMessage = 'Error al cargar asistencias: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  // Nuevo método para obtener todas las asistencias
  Future<void> getAllAsistencias() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _asistencias = await _firebaseService.getAllAsistencias();
    } catch (e) {
      _errorMessage = 'Error al cargar todas las asistencias: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  // Método para obtener asistencias filtradas por fecha
  Future<List<Asistencia>> getAsistenciasByDate(DateTime fecha) async {
    try {
      return _asistencias.where((asistencia) {
        final asistenciaDate = asistencia.fechaHoraEntrada;
        return asistenciaDate.year == fecha.year && 
               asistenciaDate.month == fecha.month && 
               asistenciaDate.day == fecha.day;
      }).toList();
    } catch (e) {
      _errorMessage = 'Error al filtrar asistencias por fecha: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }
  
  // Método para obtener asistencias filtradas por sede y fecha
  Future<List<Asistencia>> getAsistenciasBySedeAndDate(String sedeId, DateTime fecha) async {
    try {
      return _asistencias.where((asistencia) {
        final asistenciaDate = asistencia.fechaHoraEntrada;
        return asistencia.sedeId == sedeId &&
               asistenciaDate.year == fecha.year && 
               asistenciaDate.month == fecha.month && 
               asistenciaDate.day == fecha.day;
      }).toList();
    } catch (e) {
      _errorMessage = 'Error al filtrar asistencias por sede y fecha: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }
}