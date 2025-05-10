import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../models/empleado.dart';

class EmpleadoController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = Uuid();
  
  List<Empleado> _empleados = [];
  bool _loading = false;
  String? _errorMessage;

  List<Empleado> get empleados => _empleados;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> getEmpleados() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _empleados = await _firebaseService.getEmpleados();
    } catch (e) {
      _errorMessage = 'Error al cargar empleados: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Empleado?> getEmpleadoById(String id) async {
    try {
      return await _firebaseService.getEmpleadoById(id);
    } catch (e) {
      _errorMessage = 'Error al cargar empleado: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  Future<List<Empleado>> getEmpleadosPorSede(String sedeId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final todosEmpleados = await _firebaseService.getEmpleados();
      final empleadosSede = todosEmpleados.where((emp) => emp.sedeId == sedeId).toList();
      _loading = false;
      notifyListeners();
      return empleadosSede;
    } catch (e) {
      _errorMessage = 'Error al cargar empleados por sede: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return [];
    }
  }

  // Método para verificar si ya existe un empleado con el mismo DNI
  Future<bool> existeEmpleadoConDni(String dni) async {
    await getEmpleados();
    return _empleados.any((empleado) => empleado.dni == dni);
  }

  // Método para verificar si ya existe un empleado con el mismo correo
  Future<bool> existeEmpleadoConCorreo(String correo) async {
    await getEmpleados();
    return _empleados.any((empleado) => empleado.correo == correo);
  }

  Future<Map<String, String?>> validarDatosUnicos({
    required String dni,
    required String correo,
  }) async {
    Map<String, String?> errores = {};
    
    // Validar DNI único
    if (await existeEmpleadoConDni(dni)) {
      errores['dni'] = 'Ya existe un empleado con este DNI';
    }
    
    // Validar correo único
    if (await existeEmpleadoConCorreo(correo)) {
      errores['correo'] = 'Ya existe un empleado con este correo';
    }
    
    return errores;
  }

  Future<bool> addEmpleado({
    required String nombre,
    required String apellidos,
    required String dni,
    required String celular,
    required String correo,
    required String cargo,
    required String sedeId,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Validar que DNI y correo sean únicos
      final errores = await validarDatosUnicos(dni: dni, correo: correo);
      
      if (errores.isNotEmpty) {
        String mensaje = '';
        errores.forEach((campo, error) {
          if (error != null) mensaje += '$error. ';
        });
        
        _errorMessage = mensaje.trim();
        _loading = false;
        notifyListeners();
        return false;
      }
      
      final empleado = Empleado(
        id: _uuid.v4(),
        nombre: nombre,
        apellidos: apellidos,
        dni: dni,
        celular: celular,
        correo: correo,
        cargo: cargo,
        sedeId: sedeId,
        hayDatosBiometricos: false,
        activo: true,
        fechaCreacion: DateTime.now(),
      );
      
      await _firebaseService.addEmpleado(empleado);
      await getEmpleados();
      return true;
    } catch (e) {
      _errorMessage = 'Error al agregar empleado: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleEmpleadoActivo(Empleado empleado) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final empleadoActualizado = empleado.copyWith(
        activo: !empleado.activo,
        fechaModificacion: DateTime.now(),
      );
      await _firebaseService.updateEmpleado(empleadoActualizado);
      await getEmpleados();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar estado del empleado: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmpleado({
    required String id,
    required String nombre,
    required String apellidos,
    required String dni,
    required String celular,
    required String correo,
    required String cargo,
    required String sedeId,
    required bool activo,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final empleadoActual = await _firebaseService.getEmpleadoById(id);
      
      if (empleadoActual == null) {
        throw Exception('Empleado no encontrado');
      }
      
      // Si el DNI o correo han cambiado, verificar que sean únicos
      Map<String, String?> errores = {};
      
      if (empleadoActual.dni != dni && await existeEmpleadoConDni(dni)) {
        errores['dni'] = 'Ya existe un empleado con este DNI';
      }
      
      if (empleadoActual.correo != correo && await existeEmpleadoConCorreo(correo)) {
        errores['correo'] = 'Ya existe un empleado con este correo';
      }
      
      if (errores.isNotEmpty) {
        String mensaje = '';
        errores.forEach((campo, error) {
          if (error != null) mensaje += '$error. ';
        });
        
        _errorMessage = mensaje.trim();
        _loading = false;
        notifyListeners();
        return false;
      }
      
      final empleadoActualizado = empleadoActual.copyWith(
        nombre: nombre,
        apellidos: apellidos,
        dni: dni,
        celular: celular,
        correo: correo,
        cargo: cargo,
        sedeId: sedeId,
        activo: activo,
        fechaModificacion: DateTime.now(),
      );
      
      await _firebaseService.updateEmpleado(empleadoActualizado);
      await getEmpleados();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar empleado: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmpleado(String id) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _firebaseService.deleteEmpleado(id);
      await getEmpleados();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar empleado: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}