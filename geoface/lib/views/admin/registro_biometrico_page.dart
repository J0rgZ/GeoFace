import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../controllers/biometrico_controller.dart';
import '../../models/empleado.dart';
import '../../models/biometrico.dart';

class RegistroBiometricoScreen extends StatefulWidget {
  final Empleado empleado;

  const RegistroBiometricoScreen({Key? key, required this.empleado}) : super(key: key);

  @override
  _RegistroBiometricoScreenState createState() => _RegistroBiometricoScreenState();
}

class _RegistroBiometricoScreenState extends State<RegistroBiometricoScreen> with WidgetsBindingObserver {
  late BiometricoController _biometricoController;
  bool _isInitialized = false;
  Biometrico? _biometrico;
  bool _isCapturing = false;
  CameraController? _cameraController;
  
  // Mejora en initState para evitar problemas de inicialización
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Usar un Future.delayed para asegurarnos de que el widget está completamente montado
    Future.delayed(Duration.zero, () {
      _biometricoController = Provider.of<BiometricoController>(context, listen: false);
      _requestPermissions();
    });
  }
  
  // Mejora en el método _requestPermissions
  Future<void> _requestPermissions() async {
    debugPrint("Solicitando permisos...");
    
    try {
      // Solicitar permisos de cámara
      PermissionStatus cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
      }
      
      // Solicitar permisos de almacenamiento
      PermissionStatus storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      
      if (cameraStatus.isGranted) {
        debugPrint("Permiso de cámara concedido");
        await _initializeController();
      } else {
        debugPrint("Permiso de cámara denegado");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se requieren permisos de cámara para el registro biométrico'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Configuración',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      
      if (!storageStatus.isGranted) {
        debugPrint("Permiso de almacenamiento denegado");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se requieren permisos de almacenamiento para guardar imágenes'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al solicitar permisos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al solicitar permisos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initializeController() async {
    debugPrint("Inicializando controlador...");
    // Verificar si ya existen datos biométricos para este empleado
    final biometrico = await _biometricoController.getBiometricoByEmpleadoId(widget.empleado.id);
    
    setState(() {
      _biometrico = biometrico;
      _isInitialized = true;
    });
    
    // Si no hay una sesión activa de cámara, iniciarla
    if (_biometrico == null) {
      // Inicializar el detector facial primero
      await _biometricoController.init();
      
      // Iniciar la cámara con nuestras propias configuraciones
      await _initializeCamera();
    }
  }
  
  Future<void> _initializeCamera() async {
    debugPrint("Inicializando cámara...");

    try {
      // Primera inicialización del detector facial
      if (!_biometricoController.isDetectorInitialized) {
        await _biometricoController.init();
        debugPrint("Detector facial inicializado desde la pantalla");
      }
      
      // Usar el método mejorado del controlador para inicializar la cámara
      await _biometricoController.initCamera();
      
      // Obtener la referencia al controlador
      _cameraController = _biometricoController.cameraController;
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error inicializando cámara: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al inicializar la cámara: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Manejar cambios de estado de la aplicación para la cámara
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _biometricoController.cameraController = null;
    } else if (state == AppLifecycleState.resumed && _biometrico == null) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _captureFace() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      // Asegurarse de que el controlador actual esté en el biometricoController
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        _biometricoController.cameraController = _cameraController;
      }
      
      // Detener el stream antes de capturar
      await _biometricoController.stopImageStream();
      
      // Pequeña pausa para estabilizar
      await Future.delayed(Duration(milliseconds: 300));
      
      final success = await _biometricoController.addBiometrico(widget.empleado.id);
      
      if (success) {
        setState(() {
          _biometrico = _biometricoController.currentBiometrico;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos biométricos registrados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_biometricoController.errorMessage ?? 'Error al capturar datos biométricos'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Reiniciar stream solo si hubo error y seguimos en la pantalla de captura
        if (_biometrico == null) {
          await _biometricoController.startImageStream();
        }
      }
    } catch (e) {
      debugPrint("Error en captura: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Reiniciar stream
      await _biometricoController.startImageStream();
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _updateFace() async {
    if (_isCapturing || _biometrico == null) return;
    
    setState(() {
      _isCapturing = true;
    });

    // Inicializar cámara si es necesario
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initializeCamera();
    }
    
    // Asegurarse de que el controlador actual esté en el biometricoController
    _biometricoController.cameraController = _cameraController;
    
    final success = await _biometricoController.updateBiometrico(_biometrico!.id);
    
    if (success) {
      setState(() {
        _biometrico = _biometricoController.currentBiometrico;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Datos biométricos actualizados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_biometricoController.errorMessage ?? 'Error al actualizar datos biométricos'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isCapturing = false;
    });
  }

  Future<void> _deleteFace() async {
    if (_biometrico == null) return;
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar datos biométricos'),
        content: Text('¿Está seguro de que desea eliminar los datos biométricos de este empleado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldDelete) return;
    
    setState(() {
      _isCapturing = true;
    });
    
    final success = await _biometricoController.deleteBiometrico(
      _biometrico!.id, 
      widget.empleado.id
    );
    
    if (success) {
      setState(() {
        _biometrico = null;
      });
      
      // Inicializar cámara después de eliminar
      await _initializeCamera();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Datos biométricos eliminados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_biometricoController.errorMessage ?? 'Error al eliminar datos biométricos'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isCapturing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro Biométrico'),
        actions: [
          if (_biometrico != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteFace,
              tooltip: 'Eliminar datos biométricos',
            ),
        ],
      ),
      body: !_isInitialized
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info básica del empleado
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nombre: ${widget.empleado.nombreCompleto}'),
                          Text('DNI: ${widget.empleado.dni}'),
                          Text('Estado: ${_biometrico != null ? 'Registrado' : 'Pendiente'}'),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: Consumer<BiometricoController>(
                      builder: (context, controller, child) {
                        // Si ya existe un registro biométrico, mostrar la imagen guardada
                        if (_biometrico != null) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.file(
                                File(_biometrico!.datoFacial),
                                height: 300,
                                width: 300,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Registro completado',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Fecha: ${_biometrico!.fechaRegistro.toString().substring(0, 10)}',
                                style: TextStyle(fontSize: 16),
                              ),
                              if (_biometrico!.fechaActualizacion != null)
                                Text(
                                  'Actualizado: ${_biometrico!.fechaActualizacion.toString().substring(0, 10)}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: Icon(Icons.refresh),
                                label: Text('Actualizar registro'),
                                onPressed: _isCapturing ? null : _updateFace,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        }
                        
                        // Si no hay registro biométrico y la cámara está disponible
                        if (_cameraController != null && _cameraController!.value.isInitialized) {
                          return Column(
                            children: [
                              // Vista previa de la cámara
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: 300,
                                  width: 300,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Vista de la cámara
                                      CameraPreview(_cameraController!),
                                      
                                      // Guía para el rostro
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: controller.isFaceDetected
                                                ? (controller.isFaceInBounds ? Colors.green : Colors.yellow)
                                                : Colors.red,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(150),
                                        ),
                                        height: 200,
                                        width: 200,
                                      ),
                                      
                                      // Indicador de detección facial
                                      Positioned(
                                        bottom: 10,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: controller.isFaceDetected
                                                ? (controller.isFaceInBounds ? Colors.green.withOpacity(0.7) : Colors.yellow.withOpacity(0.7))
                                                : Colors.red.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            controller.isFaceDetected
                                                ? (controller.isFaceInBounds ? 'Rostro detectado' : 'Centre su rostro')
                                                : 'No se detecta rostro',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: Icon(Icons.camera_alt),
                                label: Text('Capturar imagen'),
                                onPressed: (controller.isReadyForCapture && !_isCapturing) ? _captureFace : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                controller.isFaceDetected
                                    ? (controller.isFaceInBounds
                                        ? 'Puede tomar la foto'
                                        : 'Coloque su rostro dentro del círculo')
                                    : 'Mire directamente a la cámara',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          );
                        }
                        
                        // Si no hay cámara disponible
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Cámara no disponible',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _initializeCamera,
                              child: Text('Reintentar'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                
                // Espacio para los botones o estado de procesamiento
                Container(
                  padding: EdgeInsets.all(16),
                  child: _isCapturing
                      ? Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text('Procesando...'),
                            ],
                          ),
                        )
                      : Container(),
                ),
              ],
            ),
    );
  }
}