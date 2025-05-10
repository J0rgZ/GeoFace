// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';

class AuthService {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream para escuchar cambios de autenticación
  Stream<firebase.User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  // Obtener usuario actual
  firebase.User? get currentUser => _firebaseAuth.currentUser;
  
  // Iniciar sesión
  Future<Usuario?> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Actualizar fecha de último acceso
        final userRef = _firestore.collection('usuarios').doc(credential.user!.uid);
        await userRef.update({
          'fechaUltimoAcceso': DateTime.now().toIso8601String(),
        });
        
        // Obtener datos de usuario
        final userDoc = await userRef.get();
        if (userDoc.exists) {
          return Usuario.fromJson({
            'id': userDoc.id,
            ...userDoc.data()!,
          });
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al iniciar sesión: $e');
      rethrow;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
  
  // Obtener información completa del usuario actual
  Future<Usuario?> getCurrentUserData() async {
    if (currentUser == null) return null;
    
    try {
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        return Usuario.fromJson({
          'id': userDoc.id,
          ...userDoc.data()!,
        });
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al obtener datos del usuario: $e');
      return null;
    }
  }
  
  // Verificar si el usuario actual es administrador
  Future<bool> isCurrentUserAdmin() async {
    final userData = await getCurrentUserData();
    return userData?.isAdmin ?? false;
  }
}