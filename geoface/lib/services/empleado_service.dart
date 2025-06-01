// services/empleado_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/empleado.dart';

class EmpleadoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Obtener todos los empleados
  Future<List<Empleado>> getEmpleados() async {
    try {
      final querySnapshot = await _firestore.collection('empleados').get();
      
      return querySnapshot.docs.map((doc) {
        return Empleado.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener empleados: $e');
      return [];
    }
  }
  
  // Obtener empleado por ID
  Future<Empleado?> getEmpleadoById(String id) async {
    try {
      final docSnapshot = await _firestore.collection('empleados').doc(id).get();
      
      if (docSnapshot.exists) {
        return Empleado.fromJson({
          'id': docSnapshot.id,
          ...docSnapshot.data()!,
        });
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al obtener empleado: $e');
      return null;
    }
  }
  
  // Crear nuevo empleado
  Future<Empleado?> createEmpleado(Empleado empleado, File? fotoFile) async {
    try {
      String fotoUrl = '';
      
      // Si hay foto, subirla al storage
      if (fotoFile != null) {
        final storageRef = _storage.ref().child('empleados/fotos/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(fotoFile);
        final taskSnapshot = await uploadTask;
        fotoUrl = await taskSnapshot.ref.getDownloadURL();
      }
      
      // Crear documento en Firestore
      final docRef = await _firestore.collection('empleados').add({
        'nombre': empleado.nombre,
        'apellidos': empleado.apellidos,
        'correo': empleado.correo,
        'cargo': empleado.cargo,
        'sedeId': empleado.sedeId,
        'fotoPerfil': fotoUrl,
        'hayDatosBiometricos': false,
        'activo': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
      });
      
      // Obtener el empleado creado
      final newEmpleado = await getEmpleadoById(docRef.id);
      return newEmpleado;
    } catch (e) {
      debugPrint('Error al crear empleado: $e');
      return null;
    }
  }
  
  // Actualizar empleado
  Future<bool> updateEmpleado(Empleado empleado, File? fotoFile) async {
    try {
      Map<String, dynamic> updateData = {
        'nombre': empleado.nombre,
        'apellidos': empleado.apellidos,
        'correo': empleado.correo,
        'cargo': empleado.cargo,
        'sedeId': empleado.sedeId,
        'activo': empleado.activo,
        'fechaModificacion': DateTime.now().toIso8601String(),
      };
      
      // Si hay nueva foto, subirla al storage
      if (fotoFile != null) {
        final storageRef = _storage.ref().child('empleados/fotos/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(fotoFile);
        final taskSnapshot = await uploadTask;
        final fotoUrl = await taskSnapshot.ref.getDownloadURL();
        
        updateData['fotoPerfil'] = fotoUrl;
      }
      
      // Actualizar documento en Firestore
      await _firestore.collection('empleados').doc(empleado.id).update(updateData);
      
      return true;
    } catch (e) {
      debugPrint('Error al actualizar empleado: $e');
      return false;
    }
  }
  
  // Activar/Desactivar empleado
  Future<bool> toggleEmpleadoActivo(String id, bool activo) async {
    try {
      await _firestore.collection('empleados').doc(id).update({
        'activo': activo,
        'fechaModificacion': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error al cambiar estado del empleado: $e');
      return false;
    }
  }
  
  // Registrar datos biométricos
  Future<bool> registrarBiometricos(String empleadoId, String datoFacial) async {
    try {
      // Crear registro biométrico
      await _firestore.collection('biometricos').add({
        'empleadoId': empleadoId,
        'datoFacial': datoFacial,
        'fechaRegistro': DateTime.now().toIso8601String(),
      });
      
      // Actualizar estado biométrico del empleado
      await _firestore.collection('empleados').doc(empleadoId).update({
        'hayDatosBiometricos': true,
        'fechaModificacion': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error al registrar datos biométricos: $e');
      return false;
    }
  }
  
  // Obtener empleados por sede
  Future<List<Empleado>> getEmpleadosBySede(String sedeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('empleados')
          .where('sedeId', isEqualTo: sedeId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        return Empleado.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener empleados por sede: $e');
      return [];
    }
  }
}
    