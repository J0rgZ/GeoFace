import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class UserController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Crear usuario administrador
  Future<void> createAdminUser({
    required String nombreUsuario,
    required String correo,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Verificar que el correo no esté en uso
      final existingUserQuery = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();
      
      if (existingUserQuery.docs.isNotEmpty) {
        throw Exception('El correo electrónico ya está registrado');
      }
      
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );
      
      final uid = userCredential.user!.uid;
      
      // Crear el registro en Firestore
      final usuarioData = {
        'nombreUsuario': nombreUsuario,
        'correo': correo,
        'tipoUsuario': 'ADMIN',
        'empleadoId': null,
        'activo': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'fechaUltimoAcceso': null,
      };
      
      await _firestore.collection('usuarios').doc(uid).set(usuarioData);
      
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('El correo electrónico ya está en uso');
          case 'weak-password':
            throw Exception('La contraseña es demasiado débil');
          case 'invalid-email':
            throw Exception('El correo electrónico no es válido');
          default:
            throw Exception('Error al crear usuario: ${e.message}');
        }
      } else {
        throw Exception('Error al crear usuario: ${e.toString()}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Obtener la lista de empleados sin usuario asignado
  Future<List<Map<String, dynamic>>> getEmpleadosSinUsuario() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Obtener todos los empleados
      final empleadosSnapshot = await _firestore.collection('empleados').get();
      
      // Obtener usuarios con tipo EMPLEADO
      final usuariosSnapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'EMPLEADO')
          .get();
      
      // Crear conjunto de IDs de empleados que ya tienen usuario
      final empleadosConUsuario = Set<String>.from(
        usuariosSnapshot.docs.map((doc) => doc['empleadoId'] as String)
      );
      
      // Filtrar empleados que no tienen usuario asignado
      final empleadosSinUsuario = empleadosSnapshot.docs
          .where((doc) => !empleadosConUsuario.contains(doc.id))
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
      
      return empleadosSinUsuario;
    } catch (e) {
      print('Error al obtener empleados sin usuario: $e');
      throw Exception('Error al cargar los empleados: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Asignar usuario a un empleado existente
  Future<void> assignUserToEmpleado({
    required String empleadoId,
    required String dni,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Verificar que el empleado exista
      final empleadoDoc = await _firestore.collection('empleados').doc(empleadoId).get();
      
      if (!empleadoDoc.exists) {
        throw Exception('El empleado no existe');
      }
      
      final empleadoData = empleadoDoc.data() as Map<String, dynamic>;
      final nombreEmpleado = empleadoData['nombre'] as String;
      
      // Verificar que el DNI coincida con el del empleado
      if (empleadoData['dni'] != dni) {
        throw Exception('El DNI no coincide con el del empleado');
      }
      
      // Crear correo para el empleado basado en su DNI
      final correo = '$dni@geoface.com';
      
      // Verificar si ya existe un usuario con ese correo
      final existingUserQuery = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();
      
      if (existingUserQuery.docs.isNotEmpty) {
        throw Exception('Ya existe un usuario con este DNI');
      }
      
      // Crear usuario en Firebase Auth (usando DNI como correo y contraseña)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: dni, // Contraseña inicial igual al DNI
      );
      
      final uid = userCredential.user!.uid;
      
      // Crear el registro en Firestore
      final usuarioData = {
        'nombreUsuario': nombreEmpleado,
        'correo': correo,
        'tipoUsuario': 'EMPLEADO',
        'empleadoId': empleadoId,
        'activo': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'fechaUltimoAcceso': null,
      };
      
      await _firestore.collection('usuarios').doc(uid).set(usuarioData);
      
      // Actualizar el empleado para indicar que tiene usuario asignado
      await _firestore.collection('empleados').doc(empleadoId).update({
        'tieneUsuario': true,
      });
      
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('Ya existe un usuario con este DNI');
          case 'weak-password':
            throw Exception('El DNI no cumple los requisitos como contraseña');
          case 'invalid-email':
            throw Exception('No se pudo crear un correo válido con el DNI');
          default:
            throw Exception('Error al crear usuario: ${e.message}');
        }
      } else {
        throw Exception('Error al asignar usuario: ${e.toString()}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Obtener todos los usuarios
  Future<List<Usuario>> getAllUsers() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final usersSnapshot = await _firestore.collection('usuarios').get();
      
      final users = usersSnapshot.docs.map((doc) {
        return Usuario.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
      
      return users;
    } catch (e) {
      print('Error al obtener usuarios: $e');
      throw Exception('Error al cargar los usuarios: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Activar/Desactivar usuario
  Future<void> toggleUserActive(String userId, bool isActive) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('usuarios').doc(userId).update({
        'activo': isActive,
      });
      
    } catch (e) {
      print('Error al cambiar estado del usuario: $e');
      throw Exception('Error al actualizar el usuario: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}