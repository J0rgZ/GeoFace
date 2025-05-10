// services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_config.dart';
import '../models/empleado.dart';
import '../models/sede.dart';
import '../models/asistencia.dart';
import '../models/usuario.dart';
import '../models/biometrico.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth methods
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Usuario methods
  Future<Usuario?> getUsuarioByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: email)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        print('Datos del usuario encontrado: $data'); // Para depuración
        return Usuario.fromJson({
          'id': snapshot.docs.first.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario por email: $e');
      throw e;
    }
  }

  Future<List<Asistencia>> getAllAsistencias() async {
    try {
      final querySnapshot = await _firestore
          .collection('asistencias')
          .orderBy('fechaHoraEntrada', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Asistencia.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener todas las asistencias: ${e.toString()}');
      throw Exception('No se pudieron cargar las asistencias');
    }
  }

  // Empleado methods
  Future<List<Empleado>> getEmpleados() async {
    final snapshot = await _firestore.collection(AppConfig.empleadosCollection).get();
    return snapshot.docs.map((doc) => Empleado.fromJson(doc.data())).toList();
  }

  Future<Empleado?> getEmpleadoById(String id) async {
    final doc = await _firestore.collection(AppConfig.empleadosCollection).doc(id).get();
    if (doc.exists) {
      return Empleado.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> addEmpleado(Empleado empleado) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id).set(empleado.toJson());
  }

  Future<void> updateEmpleado(Empleado empleado) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id).update(empleado.toJson());
  }

  Future<void> deleteEmpleado(String id) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(id).delete();
  }

  // Sede methods
  Future<List<Sede>> getSedes() async {
    final snapshot = await _firestore.collection(AppConfig.sedesCollection).get();
    return snapshot.docs.map((doc) => Sede.fromJson(doc.data())).toList();
  }

  Future<Sede?> getSedeById(String id) async {
    final doc = await _firestore.collection(AppConfig.sedesCollection).doc(id).get();
    if (doc.exists) {
      return Sede.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> addSede(Sede sede) async {
    await _firestore.collection(AppConfig.sedesCollection).doc(sede.id).set(sede.toJson());
  }

  Future<void> updateSede(Sede sede) async {
    await _firestore.collection(AppConfig.sedesCollection).doc(sede.id).update(sede.toJson());
  }

  Future<void> deleteSede(String id) async {
    await _firestore.collection(AppConfig.sedesCollection).doc(id).delete();
  }

  // Asistencia methods
  Future<List<Asistencia>> getAsistenciasByEmpleado(String empleadoId) async {
    final snapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where('empleadoId', isEqualTo: empleadoId)
        .orderBy('fechaHoraEntrada', descending: true)
        .get();
    return snapshot.docs.map((doc) => Asistencia.fromJson(doc.data())).toList();
  }

  Future<List<Asistencia>> getAsistenciasBySede(String sedeId) async {
    final snapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where('sedeId', isEqualTo: sedeId)
        .orderBy('fechaHoraEntrada', descending: true)
        .get();
    return snapshot.docs.map((doc) => Asistencia.fromJson(doc.data())).toList();
  }

  Future<Asistencia?> getActiveAsistencia(String empleadoId) async {
    final snapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where('empleadoId', isEqualTo: empleadoId)
        .where('fechaHoraSalida', isNull: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Asistencia.fromJson(snapshot.docs.first.data());
    }
    return null;
  }

  Future<void> registrarEntrada(Asistencia asistencia) async {
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistencia.id).set(asistencia.toJson());
  }

  Future<void> registrarSalida(Asistencia asistencia) async {
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistencia.id).update(asistencia.toJson());
  }

  //Biometricos Services
  Future<Biometrico?> getBiometricoByEmpleadoId(String empleadoId) async {
    try {
      final snapshot = await _firestore
        .collection('biometricos')
        .where('empleadoId', isEqualTo: empleadoId)
        .get();
        
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      return Biometrico.fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Error al obtener datos biométricos: ${e.toString()}');
    }
  }

  Future<Biometrico?> getBiometricoById(String id) async {
    try {
      final snapshot = await _firestore
        .collection('biometricos')
        .doc(id)
        .get();
        
      if (!snapshot.exists) {
        return null;
      }
      
      return Biometrico.fromJson(snapshot.data()!);
    } catch (e) {
      throw Exception('Error al obtener datos biométricos: ${e.toString()}');
    }
  }

  Future<void> addBiometrico(Biometrico biometrico) async {
    try {
      await _firestore
        .collection('biometricos')
        .doc(biometrico.id)
        .set(biometrico.toJson());
    } catch (e) {
      throw Exception('Error al agregar datos biométricos: ${e.toString()}');
    }
  }

  Future<void> updateBiometrico(Biometrico biometrico) async {
    try {
      await _firestore
        .collection('biometricos')
        .doc(biometrico.id)
        .update(biometrico.toJson());
    } catch (e) {
      throw Exception('Error al actualizar datos biométricos: ${e.toString()}');
    }
  }

  Future<void> deleteBiometrico(String id) async {
    try {
      await _firestore
        .collection('biometricos')
        .doc(id)
        .delete();
    } catch (e) {
      throw Exception('Error al eliminar datos biométricos: ${e.toString()}');
    }
  }
}