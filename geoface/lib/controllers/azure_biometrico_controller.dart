import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/biometrico.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AzureBiometricoController extends ChangeNotifier {
  // Azure Face API endpoints
  final String azureEndpoint = 'https://geofaceid.cognitiveservices.azure.com/';
  final String apiKey1; // Inyectar mediante constructor
  
  // Firebase
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Estado de la cámara
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  bool _isDetectorInitialized = false;
  
  // Estado del rostro
  bool _isFaceDetected = false;
  bool _isFaceInBounds = false;
  String? _errorMessage;
  
  // Getters
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isDetectorInitialized => _isDetectorInitialized;
  bool get isFaceDetected => _isFaceDetected;
  bool get isFaceInBounds => _isFaceInBounds;
  bool get isReadyForCapture => _isFaceDetected && _isFaceInBounds;
  String? get errorMessage => _errorMessage;
  
  // Constructor
  AzureBiometricoController({required this.apiKey1});
  
  // Inicializar el controlador
  Future<void> init() async {
    try {
      _isDetectorInitialized = true;
      notifyListeners();
      
      // No necesitamos inicializar ML Kit ya que usaremos Azure
      
    } catch (e) {
      _errorMessage = 'Error al inicializar el detector: ${e.toString()}';
      _isDetectorInitialized = false;
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  // Inicializar la cámara
  Future<void> initCamera() async {
    _errorMessage = null;
    
    try {
      // Detener la cámara si ya estaba inicializada
      await stopImageStream();
      
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
        ResolutionPreset.medium, // Usa medium para mejor rendimiento
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      // Iniciar cámara
      await cameraController!.initialize();
      
      // Iniciar stream de imágenes para detección en tiempo real
      await startImageStream();
      
      _isCameraInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al inicializar la cámara: ${e.toString()}';
      _isCameraInitialized = false;
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  // Iniciar el stream de imágenes para procesamiento en tiempo real
  Future<void> startImageStream() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      await cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      _errorMessage = 'Error al iniciar stream de imágenes: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Detener el stream de imágenes
  Future<void> stopImageStream() async {
    if (cameraController == null || !cameraController!.value.isStreamingImages) {
      return;
    }
    
    try {
      await cameraController!.stopImageStream();
    } catch (e) {
      debugPrint('Error al detener stream: ${e.toString()}');
    }
  }
  
  // Procesar imágenes del stream de la cámara (detección en tiempo real)
  void _processCameraImage(CameraImage image) async {
    // En lugar de procesar en el dispositivo, aquí solo verificamos
    // la calidad de la imagen para determinar si un rostro podría estar presente
    
    // Simulamos detección temporal en base a brillo/contraste
    // En producción, podrías tomar muestras de fotogramas cada X segundos
    // y hacer peticiones a Azure para verificar si hay un rostro
    
    // Calculamos brillo basado en la luminancia promedio (simplificado)
    final luminanceChannel = image.planes[0].bytes;
    int totalLuminance = 0;
    
    // Tomar una muestra representativa para velocidad
    int samplingRate = 10; // Analizar 1 de cada 10 píxeles
    int sampledPixels = 0;
    
    for (int i = 0; i < luminanceChannel.length; i += samplingRate) {
      totalLuminance += luminanceChannel[i];
      sampledPixels++;
    }
    
    final avgLuminance = totalLuminance / sampledPixels;
    
    // Umbral arbitrario para determinar si hay suficiente luz
    // y si la imagen es apropiada para detección facial
    final bool hasGoodLighting = avgLuminance > 50 && avgLuminance < 200;
    
    // Actualizar estado basado en esta heurística simple
    _isFaceDetected = hasGoodLighting;
    _isFaceInBounds = hasGoodLighting;
    
    notifyListeners();
  }
  
  // Tomar una foto y analizarla con Azure Face API
  Future<String?> captureFace() async {
    _errorMessage = null;
    
    if (cameraController == null || !cameraController!.value.isInitialized) {
      _errorMessage = 'La cámara no está inicializada';
      notifyListeners();
      return null;
    }
    
    try {
      // Detener streaming para tomar una foto de mayor calidad
      await stopImageStream();
      
      // Esperar un momento para que la cámara se estabilice
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Tomar la foto
      final XFile imageFile = await cameraController!.takePicture();
      
      // Verificar la foto con Azure Face API
      bool hasFace = await _detectFaceWithAzure(File(imageFile.path));
      
      if (!hasFace) {
        _errorMessage = 'No se detectó un rostro en la imagen';
        await startImageStream(); // Reiniciar stream
        notifyListeners();
        return null;
      }
      
      // Si hay rostro, guardar la imagen en almacenamiento temporal
      final tempDir = await getTemporaryDirectory();
      final String imagePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(imageFile.path).copy(imagePath);
      
      // Reiniciar stream de cámara
      await startImageStream();
      
      return imagePath;
    } catch (e) {
      _errorMessage = 'Error al capturar imagen: ${e.toString()}';
      await startImageStream(); // Intentar reiniciar stream
      notifyListeners();
      return null;
    }
  }
  
  // Captura forzada (sin verificación de rostro)
  Future<String?> captureFaceForced() async {
    _errorMessage = null;
    
    if (cameraController == null || !cameraController!.value.isInitialized) {
      _errorMessage = 'La cámara no está inicializada';
      notifyListeners();
      return null;
    }
    
    try {
      // Detener streaming para tomar una foto de mayor calidad
      await stopImageStream();
      
      // Tomar la foto
      final XFile imageFile = await cameraController!.takePicture();
      
      // Guardar la imagen en almacenamiento temporal
      final tempDir = await getTemporaryDirectory();
      final String imagePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(imageFile.path).copy(imagePath);
      
      // Reiniciar stream de cámara
      await startImageStream();
      
      return imagePath;
    } catch (e) {
      _errorMessage = 'Error al capturar imagen: ${e.toString()}';
      await startImageStream(); // Intentar reiniciar stream
      notifyListeners();
      return null;
    }
  }
  
  // Verificar rostro usando Azure Face API
  Future<bool> _detectFaceWithAzure(File imageFile) async {
    try {
      // URL para el endpoint de detección facial
      final String detectUrl = '$azureEndpoint/face/v1.0/detect';
      
      // Configurar los parámetros de detección
      final Map<String, String> queryParams = {
        'returnFaceId': 'true',
        'returnFaceLandmarks': 'false',
        'returnFaceAttributes': 'age,gender',
        'recognitionModel': 'recognition_04',
        'detectionModel': 'detection_01',
      };
      
      // Crear la URL con parámetros de consulta
      final Uri uri = Uri.parse(detectUrl).replace(queryParameters: queryParams);
      
      // Preparar los bytes de la imagen
      List<int> imageBytes = await imageFile.readAsBytes();
      
      // Realizar la solicitud HTTP
      final http.Response response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Ocp-Apim-Subscription-Key': apiKey1,
        },
        body: imageBytes,
      );
      
      // Procesar la respuesta
      if (response.statusCode == 200) {
        List<dynamic> faces = jsonDecode(response.body);
        return faces.isNotEmpty; // True si se detectó al menos un rostro
      } else {
        debugPrint('Error de Azure: ${response.statusCode} - ${response.body}');
        _errorMessage = 'Error al verificar rostro: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      debugPrint('Error al detectar rostro: $e');
      _errorMessage = 'Error al verificar rostro: ${e.toString()}';
      return false;
    }
  }
  
  // Agregar un biométrico
  Future<bool> addBiometrico(String empleadoId) async {
    _errorMessage = null;
    
    try {
      // Capturar rostro
      final datoFacial = await captureFace();
      
      if (datoFacial == null) {
        _errorMessage = 'No se pudo capturar la imagen facial';
        notifyListeners();
        return false;
      }
      
      // Generar ID único
      final String biometricoId = const Uuid().v4();
      
      // Subir la imagen a Firebase Storage
      final String storageRef = 'biometricos/$empleadoId/$biometricoId.jpg';
      final Reference ref = _storage.ref().child(storageRef);
      
      // Subir archivo
      await ref.putFile(File(datoFacial));
      
      // Obtener URL de descarga
      final String downloadUrl = await ref.getDownloadURL();
      
      // Crear objeto biométrico
      final Biometrico biometrico = Biometrico(
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
        'fechaModificacion': DateTime.now(),
      });
      
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar biométrico: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Actualizar un biométrico existente
  Future<bool> updateBiometrico(String biometricoId) async {
    _errorMessage = null;
    
    try {
      // Obtener biométrico actual
      final docSnapshot = await _firestore.collection('biometricos').doc(biometricoId).get();
      if (!docSnapshot.exists) {
        _errorMessage = 'No se encontró el biométrico';
        notifyListeners();
        return false;
      }
      
      final biometrico = Biometrico.fromMap(docSnapshot.data()!);
      
      // Capturar nuevo rostro
      final datoFacial = await captureFace();
      
      if (datoFacial == null) {
        _errorMessage = 'No se pudo capturar la imagen facial';
        notifyListeners();
        return false;
      }
      
      // Actualizar imagen en Firebase Storage
      final String storageRef = 'biometricos/${biometrico.empleadoId}/$biometricoId.jpg';
      final Reference ref = _storage.ref().child(storageRef);
      
      // Subir archivo
      await ref.putFile(File(datoFacial));
      
      // Obtener nueva URL de descarga
      final String downloadUrl = await ref.getDownloadURL();
      
      // Actualizar biométrico
      await _firestore.collection('biometricos').doc(biometricoId).update({
        'datoFacial': downloadUrl,
        'fechaActualizacion': DateTime.now(),
      });
      
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar biométrico: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Eliminar un biométrico
  Future<bool> deleteBiometrico(String biometricoId, String empleadoId) async {
    _errorMessage = null;
    
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
      
      // Actualizar estado del empleado
      final querySnapshot = await _firestore
          .collection('biometricos')
          .where('empleadoId', isEqualTo: empleadoId)
          .get();
      
      // Si no quedan biométricos, actualizar empleado
      if (querySnapshot.docs.isEmpty) {
        await _firestore.collection('empleados').doc(empleadoId).update({
          'hayDatosBiometricos': false,
          'fechaModificacion': DateTime.now(),
        });
      }
      
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar biométrico: ${e.toString()}';
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
  
  // Liberar recursos al destruir
  void dispose() {
    stopImageStream();
    cameraController?.dispose();
    super.dispose();
  }
}