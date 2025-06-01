import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/biometrico.dart';

class BiometricoController extends ChangeNotifier {
  // Firebase
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cámara
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  
  // Estado
  String? _errorMessage;
  bool _isProcessing = false;
  
  // Getters
  bool get isCameraInitialized => _isCameraInitialized;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;
  
  // Inicializar la cámara
  Future<void> initCamera() async {
    _errorMessage = null;
    
    try {
      // Detener la cámara si ya estaba inicializada
      await stopCamera();
      
      // Obtener cámaras disponibles
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'No se encontraron cámaras disponibles';
        notifyListeners();
        return;
      }
      
      // Usar cámara frontal si está disponible
      final CameraDescription camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      // Inicializar controlador de cámara
      cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      // Iniciar cámara
      await cameraController!.initialize();
      
      _isCameraInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al inicializar la cámara: ${e.toString()}';
      _isCameraInitialized = false;
      notifyListeners();
    }
  }
  
  // Detener la cámara
  Future<void> stopCamera() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      await cameraController!.dispose();
      cameraController = null;
      _isCameraInitialized = false;
    } catch (e) {
      debugPrint('Error al detener la cámara: ${e.toString()}');
    }
  }
  
  // Capturar foto
  Future<String?> capturePhoto() async {
    _errorMessage = null;
    
    if (cameraController == null || !cameraController!.value.isInitialized) {
      _errorMessage = 'La cámara no está inicializada';
      notifyListeners();
      return null;
    }
    
    try {
      _isProcessing = true;
      notifyListeners();
      
      // Tomar la foto
      final XFile imageFile = await cameraController!.takePicture();
      
      // Guardar la imagen en almacenamiento temporal
      final tempDir = await getTemporaryDirectory();
      final String imagePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(imageFile.path).copy(imagePath);
      
      _isProcessing = false;
      notifyListeners();
      
      return imagePath;
    } catch (e) {
      _errorMessage = 'Error al capturar imagen: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
  
  // Eliminar registros biométricos existentes de un empleado
  Future<void> _eliminarBiometricosExistentes(String empleadoId) async {
    try {
      // Buscar todos los biométricos del empleado
      final querySnapshot = await _firestore
          .collection('biometricos')
          .where('empleadoId', isEqualTo: empleadoId)
          .get();
      
      // Eliminar cada biométrico encontrado
      for (var doc in querySnapshot.docs) {
        final biometricoId = doc.id;
        
        // Eliminar archivo de Storage
        try {
          final String storageRef = 'biometricos/$empleadoId/$biometricoId.jpg';
          await _storage.ref().child(storageRef).delete();
        } catch (e) {
          debugPrint('Error al eliminar archivo: $e');
          // Continuar con el proceso aunque falle la eliminación del archivo
        }
        
        // Eliminar documento de Firestore
        await _firestore.collection('biometricos').doc(biometricoId).delete();
      }
    } catch (e) {
      debugPrint('Error al eliminar biométricos existentes: $e');
      // No lanzamos excepción para continuar con el proceso
    }
  }
  
  // Registrar biométrico (guardar foto en Firebase)
  Future<bool> registerBiometrico(String empleadoId) async {
    _errorMessage = null;
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Primero eliminar cualquier biométrico existente para evitar duplicados
      await _eliminarBiometricosExistentes(empleadoId);
      
      // Capturar rostro
      final imagePath = await capturePhoto();
      
      if (imagePath == null) {
        _errorMessage = 'No se pudo capturar la imagen';
        _isProcessing = false;
        notifyListeners();
        return false;
      }
      
      // Generar ID único
      final String biometricoId = const Uuid().v4();
      
      // Subir la imagen a Firebase Storage
      final String storageRef = 'biometricos/$empleadoId/$biometricoId.jpg';
      final Reference ref = _storage.ref().child(storageRef);
      
      // Subir archivo
      await ref.putFile(File(imagePath));
      
      // Obtener URL de descarga
      final String downloadUrl = await ref.getDownloadURL();
      
      // Crear objeto biométrico - guardando fechas como strings
      final biometrico = Biometrico(
        id: biometricoId,
        empleadoId: empleadoId,
        datoFacial: downloadUrl,
        fechaRegistro: DateTime.now().toIso8601String(),
      );
      
      // Guardar en Firestore
      await _firestore.collection('biometricos').doc(biometricoId).set(biometrico.toMap());
      
      // Actualizar estado del empleado - fecha como string
      await _firestore.collection('empleados').doc(empleadoId).update({
        'hayDatosBiometricos': true,
        'fechaModificacion': DateTime.now().toIso8601String(),
      });
      
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar biométrico: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
  
  // Actualizar biométrico (primero elimina el anterior)
  Future<bool> updateBiometrico(String biometricoId, String empleadoId) async {
    _errorMessage = null;
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Primero eliminar el biométrico actual
      await deleteBiometrico(biometricoId, empleadoId);
      
      // Luego registrar uno nuevo
      return await registerBiometrico(empleadoId);
    } catch (e) {
      _errorMessage = 'Error al actualizar biométrico: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Registrar biométrico con imagen de archivo (galería)
  Future<bool> registerBiometricoWithFile(String empleadoId, File imageFile) async {
    _errorMessage = null;
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Primero eliminar cualquier biométrico existente para evitar duplicados
      await _eliminarBiometricosExistentes(empleadoId);
      
      // Generar ID único
      final String biometricoId = const Uuid().v4();
      
      // Subir la imagen a Firebase Storage
      final String storageRef = 'biometricos/$empleadoId/$biometricoId.jpg';
      final Reference ref = _storage.ref().child(storageRef);
      
      // Subir archivo
      await ref.putFile(imageFile);
      
      // Obtener URL de descarga
      final String downloadUrl = await ref.getDownloadURL();
      
      // Crear objeto biométrico
      final biometrico = Biometrico(
        id: biometricoId,
        empleadoId: empleadoId,
        datoFacial: downloadUrl,
        fechaRegistro: DateTime.now().toIso8601String(),
      );
      
      // Guardar en Firestore
      await _firestore.collection('biometricos').doc(biometricoId).set(biometrico.toMap());
      
      // Actualizar estado del empleado
      await _firestore.collection('empleados').doc(empleadoId).update({
        'hayDatosBiometricos': true,
        'fechaModificacion': DateTime.now().toIso8601String(),
      });
      
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar biométrico: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar biométrico con imagen de archivo (galería)
  Future<bool> updateBiometricoWithFile(String biometricoId, String empleadoId, File imageFile) async {
    _errorMessage = null;
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Primero eliminar el biométrico actual
      await deleteBiometrico(biometricoId, empleadoId);
      
      // Luego registrar uno nuevo con el archivo seleccionado
      return await registerBiometricoWithFile(empleadoId, imageFile);
    } catch (e) {
      _errorMessage = 'Error al actualizar biométrico: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
  
  // Eliminar biométrico
  Future<bool> deleteBiometrico(String biometricoId, String empleadoId) async {
    _errorMessage = null;
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Eliminar archivo de Storage
      try {
        final String storageRef = 'biometricos/$empleadoId/$biometricoId.jpg';
        await _storage.ref().child(storageRef).delete();
      } catch (e) {
        // Continuar incluso si falló la eliminación del archivo
        debugPrint('Error al eliminar archivo: $e');
      }
      
      // Eliminar documento de Firestore
      await _firestore.collection('biometricos').doc(biometricoId).delete();
      
      // Verificar si quedan otros biométricos para este empleado
      final querySnapshot = await _firestore
          .collection('biometricos')
          .where('empleadoId', isEqualTo: empleadoId)
          .get();
      
      // Si no quedan biométricos, actualizar empleado
      if (querySnapshot.docs.isEmpty) {
        await _firestore.collection('empleados').doc(empleadoId).update({
          'hayDatosBiometricos': false,
          'fechaModificacion': DateTime.now().toIso8601String(), // Fecha como string
        });
      }
      
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar biométrico: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
  
  // Obtener biométrico por ID de empleado
  Future<Biometrico?> getBiometricoByEmpleadoId(String empleadoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('biometricos')
          .where('empleadoId', isEqualTo: empleadoId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return Biometrico.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      _errorMessage = 'Error al obtener biométrico: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  // Liberar recursos
  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }
}