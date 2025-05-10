import 'dart:math';  // Asegúrate de importar esta librería
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sede.dart';

class SedeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Obtener todas las sedes
  Future<List<Sede>> getSedes() async {
    try {
      final querySnapshot = await _firestore.collection('sedes').get();
      
      return querySnapshot.docs.map((doc) {
        return Sede.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener sedes: $e');
      return [];
    }
  }
  
  // Obtener sede por ID
  Future<Sede?> getSedeById(String id) async {
    try {
      final docSnapshot = await _firestore.collection('sedes').doc(id).get();
      
      if (docSnapshot.exists) {
        return Sede.fromJson({
          'id': docSnapshot.id,
          ...docSnapshot.data()!,
        });
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al obtener sede: $e');
      return null;
    }
  }
  
  // Crear nueva sede
  Future<Sede?> createSede(Sede sede) async {
    try {
      // Crear documento en Firestore
      final docRef = await _firestore.collection('sedes').add({
        'nombre': sede.nombre,
        'direccion': sede.direccion,
        'latitud': sede.latitud,
        'longitud': sede.longitud,
        'radioPermitido': sede.radioPermitido,
        'activa': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
      });
      
      // Obtener la sede creada
      final newSede = await getSedeById(docRef.id);
      return newSede;
    } catch (e) {
      debugPrint('Error al crear sede: $e');
      return null;
    }
  }
  
  // Actualizar sede
  Future<bool> updateSede(Sede sede) async {
    try {
      // Actualizar documento en Firestore
      await _firestore.collection('sedes').doc(sede.id).update({
        'nombre': sede.nombre,
        'direccion': sede.direccion,
        'latitud': sede.latitud,
        'longitud': sede.longitud,
        'radioPermitido': sede.radioPermitido,
        'activa': sede.activa,
        'fechaModificacion': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error al actualizar sede: $e');
      return false;
    }
  }
  
  // Activar/Desactivar sede
  Future<bool> toggleSedeActiva(String id, bool activa) async {
    try {
      await _firestore.collection('sedes').doc(id).update({
        'activa': activa,
        'fechaModificacion': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error al cambiar estado de la sede: $e');
      return false;
    }
  }
  
  // Verificar si las coordenadas están dentro del perímetro de la sede
  bool coordenadasEnPerimetro(Sede sede, double latitud, double longitud) {
    // Calcular distancia en metros usando la fórmula de Haversine
    final double radioTierra = 6371000; // Radio de la Tierra en metros
    final double lat1 = sede.latitud * (pi / 180);  // Usar pi en lugar de 3.14159265359
    final double lat2 = latitud * (pi / 180);      // Usar pi en lugar de 3.14159265359
    final double dLat = (latitud - sede.latitud) * (pi / 180);  // Usar pi en lugar de 3.14159265359
    final double dLon = (longitud - sede.longitud) * (pi / 180); // Usar pi en lugar de 3.14159265359
    
    final double a = 
        pow(sin(dLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);  // Cambié (dLat / 2).sin() por sin(dLat / 2)
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));  // Cambié (a.sqrt()).atan2() por atan2(sqrt(a), sqrt(1 - a))
    final double distancia = radioTierra * c;
    
    // Verificar si la distancia está dentro del radio permitido
    return distancia <= sede.radioPermitido;
  }
}