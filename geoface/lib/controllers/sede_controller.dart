import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../models/sede.dart';

class SedeController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = Uuid();
  
  List<Sede> _sedes = [];
  bool _loading = false;
  String? _errorMessage;

  List<Sede> get sedes => _sedes;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> getSedes() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _sedes = await _firebaseService.getSedes();
    } catch (e) {
      _errorMessage = 'Error al cargar sedes: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addSede({
    required String nombre, 
    required String direccion, 
    required double latitud, 
    required double longitud, 
    required int radioPermitido
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final sede = Sede(
        id: _uuid.v4(),
        nombre: nombre,
        direccion: direccion,
        latitud: latitud,
        longitud: longitud,
        radioPermitido: radioPermitido,
        activa: true,
        fechaCreacion: DateTime.now(),
      );
      
      await _firebaseService.addSede(sede);
      await getSedes();
      return true;
    } catch (e) {
      _errorMessage = 'Error al agregar sede: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSede({
    required String id,
    required String nombre, 
    required String direccion, 
    required double latitud, 
    required double longitud, 
    required int radioPermitido,
    required bool activa
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final sedeActual = await _firebaseService.getSedeById(id);
      
      if (sedeActual == null) {
        throw Exception('Sede no encontrada');
      }
      
      final sedeActualizada = sedeActual.copyWith(
        nombre: nombre,
        direccion: direccion,
        latitud: latitud,
        longitud: longitud,
        radioPermitido: radioPermitido,
        activa: activa,
        fechaModificacion: DateTime.now(),
      );
      
      await _firebaseService.updateSede(sedeActualizada);
      await getSedes();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar sede: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSede(String id) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _firebaseService.deleteSede(id);
      await getSedes();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar sede: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}// TODO Implement this library.