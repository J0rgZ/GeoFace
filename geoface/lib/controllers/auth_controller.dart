import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/usuario.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // 🔧 Agregado

  AuthStatus _status = AuthStatus.initial;
  Usuario? _currentUser;
  String? _errorMessage;
  bool _loading = false;

  AuthStatus get status => _status;
  Usuario? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get loading => _loading;

  AuthController() {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    final user = _firebaseService.getCurrentUser();

    if (user != null) {
      try {
        final usuario = await _firebaseService.getUsuarioByEmail(user.email!);
        if (usuario != null) {
          _currentUser = usuario;
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        _formatErrorMessage(e.toString());
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Construye el correo automáticamente
      final email = '$username@admin.com';

      // Inicia sesión con Firebase usando el correo generado
      await _firebaseService.signInWithEmailAndPassword(email, password);

      final usuario = await _firebaseService.getUsuarioByEmail(email);
      if (usuario != null) {
        if (!usuario.activo) {
          _errorMessage = 'Su cuenta de administrador está desactivada. Contacte a soporte.';
          _status = AuthStatus.unauthenticated;
          return false;
        }

        if (!usuario.isAdmin) {
          _errorMessage = 'Este usuario no tiene permisos de administrador.';
          _status = AuthStatus.unauthenticated;
          await _firebaseService.signOut(); // Cierra sesión si no es admin
          return false;
        }

        _currentUser = usuario;
        _status = AuthStatus.authenticated;
        return true;
      } else {
        _errorMessage = 'No se encontró una cuenta asociada a este usuario.';
        _status = AuthStatus.unauthenticated;
        return false;
      }
    } catch (e) {
      _formatErrorMessage(e.toString());
      _status = AuthStatus.unauthenticated;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _formatErrorMessage(String errorMsg) {
    errorMsg = errorMsg.toLowerCase();

    if (errorMsg.contains('user-not-found')) {
      _errorMessage = 'No existe una cuenta con este correo electrónico.';
    } else if (errorMsg.contains('wrong-password') || errorMsg.contains('invalid-credential')) {
      _errorMessage = 'La contraseña ingresada es incorrecta.';
    } else if (errorMsg.contains('invalid-email')) {
      _errorMessage = 'El formato del correo electrónico no es válido.';
    } else if (errorMsg.contains('user-disabled')) {
      _errorMessage = 'Esta cuenta ha sido deshabilitada. Contacte a soporte técnico.';
    } else if (errorMsg.contains('too-many-requests')) {
      _errorMessage = 'Demasiados intentos fallidos. Intente nuevamente más tarde.';
    } else if (errorMsg.contains('network-request-failed')) {
      _errorMessage = 'Error de conexión. Verifique su conexión a internet.';
    } else if (errorMsg.contains('email-already-in-use')) {
      _errorMessage = 'Este correo electrónico ya está registrado.';
    } else if (errorMsg.contains('operation-not-allowed')) {
      _errorMessage = 'Esta operación no está permitida. Contacte a soporte.';
    } else if (errorMsg.contains('weak-password')) {
      _errorMessage = 'La contraseña proporcionada es demasiado débil.';
    } else {
      _errorMessage = 'Ha ocurrido un error al iniciar sesión. Por favor, intente nuevamente.';
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseService.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _formatErrorMessage(e.toString());
    }
    notifyListeners();
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      _loading = true;
      notifyListeners();

      final user = _auth.currentUser; // ✅ Ya no da error porque _auth está definido
      if (user == null) {
        throw Exception('No hay una sesión activa');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('La contraseña actual es incorrecta');
          case 'too-many-requests':
            throw Exception('Demasiados intentos fallidos. Intente más tarde');
          case 'requires-recent-login':
            throw Exception('Esta operación es sensible y requiere reautenticación reciente');
          default:
            throw Exception('Error al cambiar la contraseña: ${e.message}');
        }
      } else {
        throw Exception('Error al cambiar la contraseña: ${e.toString()}');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
