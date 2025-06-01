import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class RegisterAdminController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = false;
  String? _errorMessage;

  // Getters
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  // Método para registrar un superadministrador
  Future<bool> registerAdmin(String email, String password, Usuario usuario) async {
    try {
      _loading = true;
      notifyListeners();
      
      // Crear el usuario en Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Registrar los datos del usuario en Firestore
      await _firestore.collection('usuarios').doc(userCredential.user?.uid).set({
        'correo': usuario.correo,
        'nombre': usuario.nombreUsuario, // Usa el campo de nombre desde el modelo Usuario
        'tipoUsuario': 'ADMIN',  // Establecer como superadministrador
        'empleadoId': null, // Null si es un administrador
        'activo': true,
        'fechaUltimoAcceso': null, // Se puede poner `null` si es la primera vez
        'fechaCreacion': FieldValue.serverTimestamp(), // Timestamp de registro
      });

      _loading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
