import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geoface/services/firebase_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:typed_data';
import 'package:geoface/controllers/asistencia_controller.dart';
import 'package:geoface/models/empleado.dart';
import 'package:intl/intl.dart';
import '/../services/azure_face_service.dart';

class MarcarAsistenciaPage extends StatefulWidget {
  final String sedeId;

  const MarcarAsistenciaPage({
    Key? key, 
    required this.sedeId,
  }) : super(key: key);

  @override
  State<MarcarAsistenciaPage> createState() => _MarcarAsistenciaPage();
}

class _MarcarAsistenciaPage extends State<MarcarAsistenciaPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _locationFound = false;
  Position? _currentPosition;
  bool _isLoading = true;
  String _statusMessage = "Preparando reconocimiento facial...";
  bool _isEntrada = true; // Para determinar si es entrada o salida
  String? _empleadoId;
  bool _usarDNI = false;
  TextEditingController _dniController = TextEditingController();
  Empleado? _empleadoEncontrado;
  
  // Servicio de Azure Face API
  late AzureFaceService _azureFaceService;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Inicializar servicio de Azure Face
    _azureFaceService = AzureFaceService(
      azureEndpoint: 'https://geofaceid.cognitiveservices.azure.com',
      apiKey: 'lA9d0Yecp7LtWRVvumio95p7Ih5BYKYGzvqI3S5A6rN1823aQ8XxJQQJ99BEACYeBjFXJ3w3AAAKACOGvSQn',
    );
    
    _initializeCamera();
    _getCurrentLocation();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController != null) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras!.isEmpty) {
        setState(() {
          _statusMessage = "No se encontró cámara disponible";
          _isLoading = false;
        });
        return;
      }
      
      // Intentar usar la cámara frontal primero
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first, // Si no hay frontal, usar la primera disponible
      );
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
          _statusMessage = "Cámara lista. Posicione su rostro en el marco y presione el botón.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error al inicializar la cámara: $e";
        _isLoading = false;
      });
    }
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = "Los servicios de ubicación están desactivados";
        });
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = "Permiso de ubicación denegado";
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = "Los permisos de ubicación están permanentemente denegados";
        });
        return;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _locationFound = true;
        _currentPosition = position;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error al obtener la ubicación: $e";
      });
    }
  }
  
  Future<Uint8List> _processImageToBytes(XFile photoFile) async {
    // Leer la imagen y optimizarla
    final bytes = await photoFile.readAsBytes();
    final imgLib = img.decodeImage(bytes);
    
    // Redimensionar la imagen para reducir el tamaño pero mantener calidad para reconocimiento
    final resizedImg = img.copyResize(imgLib!, width: 640, height: 480);
    final jpgData = img.encodeJpg(resizedImg, quality: 90);
    
    return Uint8List.fromList(jpgData);
  }

  // Método actualizado para detectar empleado por rostro usando Azure
  Future<Empleado?> _detectarEmpleadoPorRostro(Uint8List imageBytes) async {
    try {
      setState(() {
        _statusMessage = "Analizando rostro con inteligencia artificial...";
      });
      
      // Usar el servicio de Azure Face para identificar al empleado
      final empleado = await _azureFaceService.identificarEmpleadoPorRostro(
        imageBytes, 
        widget.sedeId
      );
      
      if (empleado != null) {
        setState(() {
          _statusMessage = "Empleado identificado: ${empleado.nombre} ${empleado.apellidos}";
        });
        return empleado;
      } else {
        setState(() {
          _statusMessage = "No se pudo identificar al empleado. Verifique que su rostro esté bien iluminado y visible.";
        });
        return null;
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error en reconocimiento facial: $e";
      });
      return null;
    }
  }

 Future<void> _buscarEmpleadoPorDNI() async {
    if (_dniController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese un DNI válido')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = "Buscando empleado...";
    });

    try {
      // Usar el servicio de Firebase directamente aquí
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final empleado = await firebaseService.getEmpleadoByDNI(_dniController.text);

      if (empleado != null) {
        setState(() {
          _empleadoEncontrado = empleado;
          _empleadoId = empleado.id;
          _statusMessage = "Empleado encontrado: ${empleado.nombre} ${empleado.apellidos}";
        });

        // Verificar si tiene una asistencia activa
        await _checkActiveAsistencia(empleado.id);
      } else {
        setState(() {
          _statusMessage = "No se encontró ningún empleado con ese DNI";
          _empleadoEncontrado = null;
          _empleadoId = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error al buscar empleado: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  
  Future<void> _checkActiveAsistencia(String empleadoId) async {
    final asistenciaController = Provider.of<AsistenciaController>(context, listen: false);
    await asistenciaController.checkAsistenciaActiva(empleadoId);
    
    setState(() {
      _isEntrada = asistenciaController.asistenciaActiva == null;
    });
  }
  
  Future<void> _captureAndProcessImage() async {
    if (_isProcessing || !_isCameraInitialized || !_locationFound) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = "Capturando imagen...";
    });
    
    try {
      // Capturar la imagen
      final XFile photoFile = await _cameraController!.takePicture();
      
      setState(() {
        _statusMessage = "Procesando imagen...";
      });
      
      // Convertir a bytes optimizados
      Uint8List imageBytes = await _processImageToBytes(photoFile);
      
      // Intentar detectar al empleado por rostro usando Azure
      final empleado = await _detectarEmpleadoPorRostro(imageBytes);
      
      if (empleado == null) {
        setState(() {
          _statusMessage = "No se pudo identificar al empleado. Puede intentar de nuevo o usar DNI.";
          _usarDNI = true; // Ofrecer alternativa de DNI
        });
        return;
      }
      
      _empleadoId = empleado.id;
      _empleadoEncontrado = empleado;
      
      // Verificar si hay una asistencia activa
      await _checkActiveAsistencia(_empleadoId!);
      
      setState(() {
        _statusMessage = "Empleado identificado correctamente. Registrando asistencia...";
      });
      
      // Proceder con el registro de asistencia
      await _registrarAsistencia(base64Encode(imageBytes));
      
    } catch (e) {
      _showErrorDialog(e.toString());
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  Future<void> _registrarAsistencia(String imageBase64) async {
    if (_empleadoId == null) {
      throw Exception('No hay empleado seleccionado');
    }
    
    final asistenciaController = Provider.of<AsistenciaController>(context, listen: false);
    bool success = false;
    
    if (_isEntrada) {
      // Registrar entrada
      success = await asistenciaController.registrarEntrada(
        empleadoId: _empleadoId!,
        sedeId: widget.sedeId,
        capturaEntrada: imageBase64,
      );
    } else {
      // Registrar salida
      final activeAsistencia = asistenciaController.asistenciaActiva;
      if (activeAsistencia != null) {
        success = await asistenciaController.registrarSalida(
          asistenciaId: activeAsistencia.id,
          capturaSalida: imageBase64,
        );
      } else {
        throw Exception('No hay una asistencia activa para registrar salida');
      }
    }
    
    if (success) {
      await _showSuccessDialog(_isEntrada ? 'Entrada' : 'Salida');
    } else {
      throw Exception(asistenciaController.errorMessage ?? 'Error desconocido');
    }
  }
  
  Future<void> _registrarAsistenciaDNI() async {
    if (_empleadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, busque un empleado primero'))
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = "Procesando...";
    });
    
    try {
      // Como no hay captura facial, usamos una cadena vacía o un placeholder
      String imagePlaceholder = "placeholder_image_dni_auth";
      
      await _registrarAsistencia(imagePlaceholder);
    } catch (e) {
      _showErrorDialog(e.toString());
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  Future<void> _showSuccessDialog(String tipo) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text('$tipo Registrada'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Fecha', DateFormat('dd/MM/yyyy').format(DateTime.now())),
                const SizedBox(height: 8),
                _buildInfoRow('Hora', DateFormat('HH:mm:ss').format(DateTime.now())),
                const SizedBox(height: 8),
                _buildInfoRow('Estado', '$tipo registrada'),
                if (_empleadoEncontrado != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Empleado', '${_empleadoEncontrado!.nombre} ${_empleadoEncontrado!.apellidos}'),
                ],
                if (_currentPosition != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Ubicación', 'Verificada'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Volvemos al menú principal
              },
              child: Text(
                'ACEPTAR',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _showErrorDialog(String error) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'ACEPTAR',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _dniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asistenciaController = Provider.of<AsistenciaController>(context);
    final isAsistenciaLoading = asistenciaController.loading;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEntrada ? 'Marcar Entrada' : 'Marcar Salida'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botón para alternar entre reconocimiento facial y DNI
          IconButton(
            icon: Icon(_usarDNI ? Icons.face : Icons.badge),
            tooltip: _usarDNI ? 'Usar reconocimiento facial' : 'Usar DNI',
            onPressed: () {
              setState(() {
                _usarDNI = !_usarDNI;
                _statusMessage = _usarDNI 
                    ? "Ingrese su DNI para marcar asistencia" 
                    : "Cámara lista. Posicione su rostro en el marco.";
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Contenedor principal (cámara o entrada de DNI)
          Expanded(
            child: _usarDNI 
                ? _buildDNISection()
                : _buildCameraSection(),
          ),
          
          // Panel inferior con controles
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fecha y Hora:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Indicador de ubicación
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _locationFound ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _locationFound ? 'Ubicación verificada' : 'Verificando ubicación...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    
                    // Indicador del tipo de marcación
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isEntrada ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _isEntrada ? 'ENTRADA' : 'SALIDA',
                        style: TextStyle(
                          color: _isEntrada ? Colors.green[800] : Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Botón para capturar o registrar con DNI
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isProcessing || isAsistenciaLoading || 
                              (!_locationFound) || 
                              (_usarDNI && _empleadoId == null))
                        ? null
                        : _usarDNI ? _registrarAsistenciaDNI : _captureAndProcessImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEntrada ? Theme.of(context).primaryColor : Colors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing || isAsistenciaLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Procesando...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_usarDNI ? Icons.badge : Icons.face_retouching_natural),
                              const SizedBox(width: 12),
                              Text(
                                _isEntrada ? 'MARCAR ENTRADA' : 'MARCAR SALIDA',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCameraSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Iniciando cámara...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                if (_isCameraInitialized)
                  CameraPreview(_cameraController!),
                
                // Marco para la cara
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isEntrada ? 
                        Theme.of(context).primaryColor : 
                        Colors.orange,
                      width: 3,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                
                // Instrucciones superpuestas
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildDNISection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingrese su DNI:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dniController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Número de DNI',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _buscarEmpleadoPorDNI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('BUSCAR EMPLEADO'),
            ),
          ),
          const SizedBox(height: 20),
          if (_empleadoEncontrado != null) ...[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_circle,
                            size: 80,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_empleadoEncontrado!.nombre} ${_empleadoEncontrado!.apellidos}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('DNI', _empleadoEncontrado!.dni),
                    const SizedBox(height: 8),
                    _buildInfoRow('Cargo', _empleadoEncontrado!.cargo),
                    const SizedBox(height: 8),
                    _buildInfoRow('Área', _empleadoEncontrado!.sedeId),
                  ],
                ),
              ),
            ),
          ],
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}