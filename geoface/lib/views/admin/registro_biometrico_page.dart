import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '/../controllers/biometrico_controller.dart';
import '/../models/empleado.dart';
import '/../models/biometrico.dart';

class RegistroBiometricoScreen extends StatefulWidget {
  final Empleado empleado;

  const RegistroBiometricoScreen({
    super.key,
    required this.empleado,
  });

  @override
  State<RegistroBiometricoScreen> createState() => _RegistroBiometricoScreenState();
}

class _RegistroBiometricoScreenState extends State<RegistroBiometricoScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late BiometricoController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  bool _hasExistingBiometric = false;
  Biometrico? _currentBiometrico;
  bool _showCamera = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = Provider.of<BiometricoController>(context, listen: false);
    
    // Inicializar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Inicializar después del build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initController();
      if (widget.empleado.hayDatosBiometricos) {
        _checkExistingBiometric();
      } else {
        setState(() {
          _hasExistingBiometric = false;
          _currentBiometrico = null;
        });
      }
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_showCamera) _controller.initCamera();
    } else if (state == AppLifecycleState.inactive ||
               state == AppLifecycleState.paused ||
               state == AppLifecycleState.detached) {
      _controller.stopCamera();
    }
  }

  Future<void> _initController() async {
    try {
      setState(() => _isLoading = true);
      await _controller.initCamera();
    } catch (e) {
      _showErrorDialog('Error al inicializar', 
        'No se pudo inicializar la cámara: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkExistingBiometric() async {
    try {
      setState(() => _isLoading = true);
      
      final biometrico = await _controller.getBiometricoByEmpleadoId(widget.empleado.id);
      
      setState(() {
        _hasExistingBiometric = biometrico != null;
        _currentBiometrico = biometrico;
      });
      
    } catch (e) {
      debugPrint('Error al verificar biométrico: ${e.toString()}');
      setState(() {
        _hasExistingBiometric = false;
        _currentBiometrico = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Seleccionar imagen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    title: 'Cámara',
                    subtitle: 'Tomar foto',
                    onTap: () {
                      Navigator.pop(context);
                      _toggleCamera();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.photo_library,
                    title: 'Galería',
                    subtitle: 'Elegir foto',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCamera() {
    setState(() {
      _showCamera = !_showCamera;
    });
    if (_showCamera) {
      _controller.initCamera();
    } else {
      _controller.stopCamera();
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        await _processSelectedImage(image.path);
      }
    } catch (e) {
      _showErrorDialog('Error', 'No se pudo seleccionar la imagen: ${e.toString()}');
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      setState(() => _isLoading = true);
      
      bool result;
      if (_hasExistingBiometric && _currentBiometrico != null) {
        result = await _controller.updateBiometrico(_currentBiometrico!.id, widget.empleado.id);
      } else {
        result = await _controller.registerBiometrico(widget.empleado.id);
      }
      
      if (result) {
        _showSuccessMessage('Biométrico registrado correctamente');
        setState(() {
          _hasExistingBiometric = true;
          _showCamera = false;
        });
        await _checkExistingBiometric();
      } else {
        _showErrorDialog('Error', _controller.errorMessage ?? 'No se pudo guardar el biométrico');
      }
      
    } catch (e) {
      _showErrorDialog('Error', 'Error al capturar imagen: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processSelectedImage(String imagePath) async {
    try {
      setState(() => _isLoading = true);
      
      // Aquí deberías implementar la lógica para subir la imagen desde galería
      // Por ahora simulo el proceso
      bool result;
      if (_hasExistingBiometric && _currentBiometrico != null) {
        result = await _controller.updateBiometrico(_currentBiometrico!.id, widget.empleado.id);
      } else {
        result = await _controller.registerBiometrico(widget.empleado.id);
      }
      
      if (result) {
        _showSuccessMessage('Biométrico actualizado correctamente');
        setState(() {
          _hasExistingBiometric = true;
        });
        await _checkExistingBiometric();
      } else {
        _showErrorDialog('Error', _controller.errorMessage ?? 'No se pudo procesar la imagen');
      }
      
    } catch (e) {
      _showErrorDialog('Error', 'Error al procesar imagen: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBiometric() async {
    if (_currentBiometrico == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      final result = await _controller.deleteBiometrico(_currentBiometrico!.id, widget.empleado.id);
      
      if (result) {
        _showSuccessMessage('Biométrico eliminado correctamente', Colors.orange);
        setState(() {
          _hasExistingBiometric = false;
          _currentBiometrico = null;
          _showCamera = false;
        });
      } else {
        _showErrorDialog('Error', _controller.errorMessage ?? 'No se pudo eliminar el biométrico');
      }
      
    } catch (e) {
      _showErrorDialog('Error', 'Error al eliminar biométrico: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color ?? Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Eliminar biométrico'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas eliminar el registro biométrico? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBiometric();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No disponible';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Registro Biométrico'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.empleado.nombreCompleto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${widget.empleado.id}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildBiometricImageSection(),
                  const SizedBox(height: 16),
                  if (_currentBiometrico != null) _buildDateInfoCard(),
                  if (_currentBiometrico != null) const SizedBox(height: 16),
                  if (_showCamera) _buildCameraSection(),
                  if (_showCamera) const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _hasExistingBiometric
                ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                : [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasExistingBiometric ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _hasExistingBiometric ? Icons.verified_user : Icons.face_retouching_natural,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasExistingBiometric ? 'Biométrico Registrado' : 'Sin Registro Biométrico',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _hasExistingBiometric ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hasExistingBiometric 
                        ? 'El empleado tiene datos biométricos válidos'
                        : 'Es necesario registrar datos biométricos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricImageSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Imagen Biométrica',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 200,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _hasExistingBiometric && _currentBiometrico?.datoFacial != null
                      ? CachedNetworkImage(
                          imageUrl: _currentBiometrico!.datoFacial,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, size: 40, color: Colors.red),
                                const SizedBox(height: 8),
                                Text('Error al cargar imagen', 
                                  style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.face_retouching_natural,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sin imagen\nbiométrica',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información de Fechas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDateRow(
              icon: Icons.add_circle_outline,
              label: 'Fecha de Registro',
              date: _formatDate(_currentBiometrico?.fechaRegistro),
              color: Colors.green,
            ),
            if (_currentBiometrico?.fechaActualizacion != null) ...[
              const SizedBox(height: 12),
              _buildDateRow(
                icon: Icons.update,
                label: 'Última Actualización',
                date: _formatDate(_currentBiometrico?.fechaActualizacion),
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow({
    required IconData icon,
    required String label,
    required String date,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Vista de Cámara',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _toggleCamera,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 300,
                width: double.infinity,
                child: Consumer<BiometricoController>(
                  builder: (context, controller, _) {
                    if (!controller.isCameraInitialized) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Inicializando cámara...'),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: controller.cameraController?.value.aspectRatio ?? 1.0,
                          child: controller.cameraController != null 
                              ? CameraPreview(controller.cameraController!)
                              : Container(color: Colors.black),
                        ),
                        Container(
                          width: 200,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.8),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Coloca tu rostro dentro del marco',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _captureFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('CAPTURAR FOTO'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón principal: Agregar/Actualizar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: Icon(_hasExistingBiometric ? Icons.update : Icons.add_a_photo),
            label: Text(
              _hasExistingBiometric ? 'ACTUALIZAR BIOMÉTRICO' : 'AGREGAR BIOMÉTRICO',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _hasExistingBiometric 
                  ? Theme.of(context).primaryColor 
                  : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        // Si hay biométrico, mostrar botón eliminar
        if (_hasExistingBiometric) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showDeleteConfirmDialog,
              icon: const Icon(Icons.delete_outline),
              label: const Text(
                'ELIMINAR BIOMÉTRICO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Procesando...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: non_constant_identifier_names
CachedNetworkImage({required String imageUrl, required BoxFit fit, required Container Function(dynamic context, dynamic url) placeholder, required Container Function(dynamic context, dynamic url, dynamic error) errorWidget}) {
}