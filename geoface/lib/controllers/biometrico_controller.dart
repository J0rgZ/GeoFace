import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../models/biometrico.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class BiometricoController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = Uuid();
  
  bool _loading = false;
  String? _errorMessage;
  Biometrico? _currentBiometrico;
  bool _processingImage = false;
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isFaceDetected = false;
  bool _isFaceInBounds = false;
  bool get isDetectorInitialized => _faceDetector != null;
  
  // Getters
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  Biometrico? get currentBiometrico => _currentBiometrico;
  bool get processingImage => _processingImage;
  List<CameraDescription>? get cameras => _cameras;
  CameraController? get cameraController => _cameraController;
  
  // Setter para cameraController
  set cameraController(CameraController? controller) {
    // Dispose el controlador anterior si existe
    _cameraController?.dispose();
    
    _cameraController = controller;
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      // Asegúrate de que el stream se inicie correctamente
      try {
        _cameraController!.startImageStream(_processCameraImage);
        debugPrint("Stream de cámara iniciado correctamente");
      } catch (e) {
        debugPrint("Error al iniciar stream de cámara: $e");
      }
    }
    notifyListeners();
  }
  
  bool get isFaceDetected => _isFaceDetected;
  bool get isFaceInBounds => _isFaceInBounds;
  bool get isReadyForCapture => _isFaceDetected && _isFaceInBounds && !_processingImage;
  
  // Inicializar detector facial
  Future<void> init() async {
    try {
      debugPrint("Inicializando detector facial...");
      _cameras = await availableCameras();
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true,
          minFaceSize: 0.1, // Reducido para mejorar detección
          performanceMode: FaceDetectorMode.accurate
        ),
      );
      debugPrint("Detector facial inicializado correctamente");
    } catch (e) {
      debugPrint("Error al inicializar detector facial: $e");
      _errorMessage = 'Error al inicializar el detector facial: ${e.toString()}';
      notifyListeners();
    }
  }

  // Método mejorado para inicializar cámara
  Future<void> initCamera() async {
    // Detener cualquier stream anterior si existe
    await stopImageStream();

    if (_cameras == null || _cameras!.isEmpty) {
      _errorMessage = 'No se encontraron cámaras disponibles';
      notifyListeners();
      return;
    }
    
    // Buscar cámara frontal
    final frontCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );
    
    debugPrint("Inicializando cámara frontal...");
    
    // Liberar recursos de la cámara anterior si existe
    await _cameraController?.dispose();
    
    // CAMBIO IMPORTANTE: Usar una resolución aún más baja para mejor compatibilidad
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low, // Usar low en lugar de medium para mejor compatibilidad
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );
    
    try {
      // Inicializar con un timeout por seguridad
      await _cameraController!.initialize().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Tiempo de espera agotado al inicializar la cámara');
        },
      );
      
      debugPrint("Cámara inicializada correctamente");
      
      if (_cameraController!.value.isInitialized) {
        await _cameraController!.setExposureMode(ExposureMode.auto);
        await _cameraController!.setFlashMode(FlashMode.off);
        await _cameraController!.setFocusMode(FocusMode.auto);
        
        // Añadir un pequeño retraso antes de iniciar el stream
        await Future.delayed(Duration(milliseconds: 500));
        
        // Iniciar stream de imágenes de manera segura
        await startImageStream();
        debugPrint("Stream de cámara iniciado");
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error al inicializar cámara: $e");
      _errorMessage = 'Error al inicializar la cámara: ${e.toString()}';
      // Liberar recursos en caso de error
      await _cameraController?.dispose();
      _cameraController = null;
      notifyListeners();
    }
  }

  // Método para iniciar el stream de imágenes de manera segura
Future<void> startImageStream() async {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isStreamingImages) {
      return;
    }
    
    try {
      await _cameraController!.startImageStream(_processCameraImage);
      debugPrint("Stream de imágenes iniciado correctamente");
    } catch (e) {
      debugPrint("Error al iniciar stream de imágenes: $e");
      _errorMessage = 'Error al iniciar el stream de imágenes: ${e.toString()}';
      notifyListeners();
    }
  }

  // Método para detener el stream de imágenes de manera segura
  Future<void> stopImageStream() async {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized ||
        !_cameraController!.value.isStreamingImages) {
      return;
    }
    
    try {
      await _cameraController!.stopImageStream();
      debugPrint("Stream de imágenes detenido correctamente");
    } catch (e) {
      debugPrint("Error al detener stream de imágenes: $e");
    }
  }

  // Método mejorado para capturar imagen
  Future<String?> captureFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _errorMessage = 'La cámara no está inicializada';
      notifyListeners();
      return null;
    }
    
    // Hacer más flexible la captura
    if (!_isFaceDetected) {
      _errorMessage = 'No se detecta ningún rostro';
      notifyListeners();
      return null;
    }
    
    try {
      debugPrint("Capturando imagen...");
      
      // Pausar el stream de la cámara antes de capturar
      await stopImageStream();
      
      // Dar tiempo para estabilizar
      await Future.delayed(Duration(milliseconds: 300));
      
      // Capturar imagen con un timeout por seguridad
      final XFile image = await _cameraController!.takePicture().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Tiempo de espera agotado al capturar imagen');
        },
      );
      
      debugPrint("Imagen capturada: ${image.path}");
      
      // Guardar imagen en almacenamiento
      final savedPath = await _saveImageToStorage(image);
      
      // Reiniciar el stream de la cámara
      await startImageStream();
      
      return savedPath;
    } catch (e) {
      debugPrint("Error al capturar imagen: $e");
      _errorMessage = 'Error al capturar imagen: ${e.toString()}';
      notifyListeners();
      
      // Intentar reiniciar el stream de la cámara
      try {
        await startImageStream();
      } catch (_) {}
      
      return null;
    }
  }
  
  // Método mejorado para procesar imágenes de la cámara
  void _processCameraImage(CameraImage image) async {
    if (_processingImage || _faceDetector == null) return;
    _processingImage = true;
    
    try {
      // Usar un contador para reducir la frecuencia de procesamiento
      // Esto mejora el rendimiento sin afectar demasiado la experiencia
      int frameSkip = 0;
      if (frameSkip < 3) {  // Procesar cada 3 frames
        frameSkip++;
        _processingImage = false;
        return;
      }
      frameSkip = 0;
      
      // Convertir imagen para ML Kit
      final inputImage = _convertCameraImageToInputImage(image);
      
      if (inputImage != null) {
        final faces = await _faceDetector!.processImage(inputImage);
        
        // Debug para verificar detección
        debugPrint("Rostros detectados: ${faces.length}");
        
        // Verificar si se detectó al menos un rostro
        final prevFaceDetected = _isFaceDetected;
        _isFaceDetected = faces.isNotEmpty;
        
        // Verificar si el rostro está dentro de los límites adecuados
        if (_isFaceDetected) {
          final face = faces.first;
          final imageWidth = image.width.toDouble();
          final imageHeight = image.height.toDouble();
          
          // Criterios más flexibles para detección
          final faceWidth = face.boundingBox.width;
          final faceHeight = face.boundingBox.height;
          final centerX = face.boundingBox.left + (faceWidth / 2);
          final centerY = face.boundingBox.top + (faceHeight / 2);
          
          // Aumentar la tolerancia para facilitar detección
          final isCentered = (centerX > imageWidth * 0.15 && centerX < imageWidth * 0.85) &&
                            (centerY > imageHeight * 0.15 && centerY < imageHeight * 0.85);
          
          final hasGoodSize = (faceWidth > imageWidth * 0.15 && faceWidth < imageWidth * 0.95) &&
                           (faceHeight > imageHeight * 0.15 && faceHeight < imageHeight * 0.95);
          
          final prevFaceInBounds = _isFaceInBounds;
          _isFaceInBounds = isCentered && hasGoodSize;
          
          // Log cambios de estado
          if (prevFaceInBounds != _isFaceInBounds) {
            debugPrint("Rostro en posición: $_isFaceInBounds (centrado: $isCentered, buen tamaño: $hasGoodSize)");
            debugPrint("Dimensiones: rostro=${faceWidth}x${faceHeight}, imagen=${imageWidth}x${imageHeight}");
          }
        } else {
          _isFaceInBounds = false;
        }
        
        // Solo notificar si hay cambios
        if (prevFaceDetected != _isFaceDetected || _isFaceDetected) {
          notifyListeners();
        }
      } else {
        debugPrint("No se pudo convertir la imagen para ML Kit");
      }
    } catch (e) {
      debugPrint("Error procesando imagen: $e");
    } finally {
      _processingImage = false;
    }
  }

  
  // Convertir CameraImage a InputImage para ML Kit - SOLUCIONADO
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    final camera = _cameraController?.description;
    if (camera == null) return null;

    // Determinar rotación basada en la orientación del dispositivo y la cámara
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    
    // En Android, necesitamos manejar la rotación manualmente
    if (Platform.isAndroid) {
      var rotationCompensation = 0;
      // TODO: Obtener orientación del dispositivo si es necesario
      // Por ahora usamos la orientación del sensor directamente
      rotationCompensation = sensorOrientation;
      
      switch (rotationCompensation) {
        case 0:
          rotation = InputImageRotation.rotation0deg;
          break;
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }
    } else {
      // En iOS, ML Kit maneja la rotación automáticamente
      rotation = InputImageRotation.rotation0deg;
    }

    // Intentar convertir el formato de la imagen
    // SOLUCIÓN: Usar InputImageFormat.yuv420 para mayor compatibilidad
    final format = InputImageFormat.yuv420;

    try {
      if (Platform.isAndroid) {
        // Método para Android que funciona con la mayoría de formatos YUV
        final planes = image.planes;
        final yBuffer = planes[0].bytes;
        final uBuffer = planes[1].bytes;
        final vBuffer = planes[2].bytes;
        
        final yRowStride = planes[0].bytesPerRow;
        final _ = planes[1].bytesPerRow;
        final _ = planes[1].bytesPerPixel ?? 1;
        
        // Construir la metadata de la imagen
        final metadata = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: yRowStride,
        );
        
        // Crear InputImage con planos separados
        return InputImage.fromBytes(
          bytes: Uint8List.fromList([...yBuffer, ...uBuffer, ...vBuffer]),
          metadata: metadata,
        );
      } else {
        // Para iOS, usamos un enfoque más simple
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();
        
        final metadata = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        );
        
        return InputImage.fromBytes(bytes: bytes, metadata: metadata);
      }
    } catch (e) {
      debugPrint('Error al convertir la imagen para ML Kit: $e');
      return null;
    }
  }

  
  
  
  // Guardar imagen en almacenamiento local
  Future<String?> _saveImageToStorage(XFile image) async {
    try { 
      // Obtener directorio de documentos
      final directory = await getApplicationDocumentsDirectory();
      final imageName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = '${directory.path}/$imageName';
      
      // Copiar imagen al directorio de documentos
      final File imageFile = File(image.path);
      await imageFile.copy(imagePath);
      
      debugPrint("Imagen guardada en: $imagePath");
      return imagePath;
    } catch (e) {
      debugPrint("Error al guardar imagen: $e");
      _errorMessage = 'Error al guardar imagen: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Obtener biométrico de un empleado
  Future<Biometrico?> getBiometricoByEmpleadoId(String empleadoId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final biometrico = await _firebaseService.getBiometricoByEmpleadoId(empleadoId);
      _loading = false;
      _currentBiometrico = biometrico;
      notifyListeners();
      return biometrico;
    } catch (e) {
      _errorMessage = 'Error al cargar datos biométricos: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  // Agregar nuevo biométrico
  Future<bool> addBiometrico(String empleadoId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Capturar datos faciales
      final datoFacial = await captureFace();
      
      if (datoFacial == null) {
        _loading = false;
        notifyListeners();
        return false;
      }
      
      final biometrico = Biometrico(
        id: _uuid.v4(),
        empleadoId: empleadoId,
        datoFacial: datoFacial,
        fechaRegistro: DateTime.now(),
      );
      
      await _firebaseService.addBiometrico(biometrico);
      
      // Actualizar estado del empleado
      final empleado = await _firebaseService.getEmpleadoById(empleadoId);
      if (empleado != null && !empleado.hayDatosBiometricos) {
        final empleadoActualizado = empleado.copyWith(
          hayDatosBiometricos: true,
          fechaModificacion: DateTime.now(),
        );
        await _firebaseService.updateEmpleado(empleadoActualizado);
      }
      
      _currentBiometrico = biometrico;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al agregar datos biométricos: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar biométrico
  Future<bool> updateBiometrico(String biometricoId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final biometricoActual = await _firebaseService.getBiometricoById(biometricoId);
      
      if (biometricoActual == null) {
        throw Exception('Dato biométrico no encontrado');
      }
      
      // Capturar nuevos datos faciales
      final nuevoDatoFacial = await captureFace();
      
      if (nuevoDatoFacial == null) {
        _loading = false;
        notifyListeners();
        return false;
      }
      
      final biometricoActualizado = Biometrico(
        id: biometricoActual.id,
        empleadoId: biometricoActual.empleadoId,
        datoFacial: nuevoDatoFacial,
        fechaRegistro: biometricoActual.fechaRegistro,
        fechaActualizacion: DateTime.now(),
      );
      
      await _firebaseService.updateBiometrico(biometricoActualizado);
      
      _currentBiometrico = biometricoActualizado;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar datos biométricos: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar biométrico
  Future<bool> deleteBiometrico(String biometricoId, String empleadoId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _firebaseService.deleteBiometrico(biometricoId);
      
      // Actualizar estado del empleado
      final empleado = await _firebaseService.getEmpleadoById(empleadoId);
      if (empleado != null && empleado.hayDatosBiometricos) {
        final empleadoActualizado = empleado.copyWith(
          hayDatosBiometricos: false,
          fechaModificacion: DateTime.now(),
        );
        await _firebaseService.updateEmpleado(empleadoActualizado);
      }
      
      _currentBiometrico = null;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar datos biométricos: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Liberar recursos
  @override
  void dispose() {
    stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}