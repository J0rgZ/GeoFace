import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';

class PermissionsHandlerScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionsHandlerScreen({
    Key? key,
    required this.onPermissionsGranted,
  }) : super(key: key);

  @override
  State<PermissionsHandlerScreen> createState() => _PermissionsHandlerScreenState();
}

class _PermissionsHandlerScreenState extends State<PermissionsHandlerScreen> with TickerProviderStateMixin {
  final List<PermissionInfo> _permissions = [
    PermissionInfo(
      permission: Permission.camera,
      title: 'Cámara',
      description: 'Usamos la cámara para reconocimiento facial al registrar tu asistencia.',
      icon: Icons.camera_alt_rounded,
      lottieAsset: 'assets/animations/camera_animation.json',
    ),
    PermissionInfo(
      permission: Permission.location,
      title: 'Ubicación',
      description: 'Verificamos tu ubicación para validar que estés en las instalaciones de la empresa.',
      icon: Icons.location_on_rounded,
      lottieAsset: 'assets/animations/location_animation.json',
    ),
  ];

  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _showSummary = false;
  Map<Permission, PermissionStatus> _permissionStatus = {};
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _updateProgressValue();
    _checkPermissions();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }
  
  void _updateProgressValue() {
    final newValue = (_currentPage + 1) / _permissions.length;
    _progressAnimationController.animateTo(newValue);
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    Map<Permission, PermissionStatus> statuses = {};
    
    for (var permissionInfo in _permissions) {
      final status = await permissionInfo.permission.status;
      statuses[permissionInfo.permission] = status;
    }
    
    setState(() {
      _permissionStatus = statuses;
      _isLoading = false;
    });
    
    _checkAllPermissionsGranted();
  }

  Future<void> _requestCurrentPermission() async {
    if (_isLoading) return;
    
    final permissionInfo = _permissions[_currentPage];
    
    setState(() {
      _isLoading = true;
    });
    
    final status = await permissionInfo.permission.request();
    
    setState(() {
      _permissionStatus[permissionInfo.permission] = status;
      _isLoading = false;
    });
    
    if (status.isGranted) {
      _goToNextPage();
    }
  }
  
  void _goToNextPage() {
    if (_currentPage < _permissions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _checkAllPermissionsGranted();
      setState(() {
        _showSummary = true;
      });
    }
  }
  
  void _checkAllPermissionsGranted() {
    bool allGranted = _permissions.every((p) => 
      _permissionStatus[p.permission]?.isGranted ?? false);
    
    if (allGranted && !_showSummary) {
      // Solo mostramos el resumen en lugar de llamar al callback directamente
      setState(() {
        _showSummary = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: _showSummary 
            ? _buildPermissionsSummary(theme, isDarkMode)
            : _buildPermissionsFlow(theme, isDarkMode),
      ),
    );
  }

  Widget _buildPermissionsFlow(ThemeData theme, bool isDarkMode) {
    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: isDarkMode 
                            ? Colors.grey[800] 
                            : Colors.grey[200],
                        color: theme.primaryColor,
                        minHeight: 6,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Logo y texto superior
        Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.security_rounded,
                  size: 32,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'GeoFace',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configuración de permisos',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // PageView for permissions
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _permissions.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
                _updateProgressValue();
              });
            },
            itemBuilder: (context, index) {
              final permissionInfo = _permissions[index];
              final status = _permissionStatus[permissionInfo.permission];
              final isGranted = status?.isGranted ?? false;
              
              return _buildPermissionPage(
                context,
                permissionInfo,
                isGranted,
                isDarkMode,
                index == _permissions.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSummary(ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Encabezado
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Permisos configurados',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La aplicación está lista para usar',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Lista de permisos
          Expanded(
            child: ListView.separated(
              itemCount: _permissions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final permission = _permissions[index];
                final status = _permissionStatus[permission.permission];
                final isGranted = status?.isGranted ?? false;
                
                return _buildPermissionListItem(permission, isGranted, theme, isDarkMode);
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Botón de continuar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onPermissionsGranted,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: theme.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'CONTINUAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionListItem(
    PermissionInfo info, 
    bool isGranted, 
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withOpacity(0.1)
                  : theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              info.icon,
              color: isGranted ? Colors.green : theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isGranted ? 'Concedido' : 'Denegado',
              style: TextStyle(
                fontSize: 12,
                color: isGranted ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionPage(
    BuildContext context, 
    PermissionInfo info, 
    bool isGranted,
    bool isDarkMode,
    bool isLastPermission,
  ) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 600;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06, // Padding responsive
                vertical: isSmallScreen ? 4.0 : 8.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animación Lottie o icono con tamaño adaptativo
                  SizedBox(
                    height: isSmallScreen ? size.height * 0.25 : size.height * 0.3,
                    child: Center(
                      child: isGranted
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: isSmallScreen ? 60 : 80,
                            ),
                          )
                        : _isLoading
                          ? Center(
                              child: Lottie.asset(
                                'assets/animations/loading.json',
                                width: isSmallScreen ? 90 : 120,
                                height: isSmallScreen ? 90 : 120,
                              ),
                            )
                          : info.lottieAsset.isNotEmpty
                            ? Lottie.asset(
                                info.lottieAsset,
                                width: isSmallScreen ? 150 : 200,
                                height: isSmallScreen ? 150 : 200,
                                fit: BoxFit.contain,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                                child: Icon(
                                  info.icon,
                                  color: theme.primaryColor,
                                  size: isSmallScreen ? 60 : 80,
                                ),
                              ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  
                  // Título y descripción con tamaños responsivos
                  Text(
                    info.title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 22 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                    ),
                    child: Text(
                      info.description,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 32),
                  
                  // Badge de estado
                  AnimatedOpacity(
                    opacity: isGranted ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20, 
                        vertical: isSmallScreen ? 4 : 6
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.green,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Permiso concedido',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  
                  // Sección de botones con gestión mejorada del espacio
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      bottom: isSmallScreen ? 12 : 24,
                      top: isSmallScreen ? 8 : 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón principal con tamaño adaptativo
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isGranted 
                              ? (isLastPermission ? () => setState(() => _showSummary = true) : _goToNextPage)
                              : _requestCurrentPermission,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: isGranted ? Colors.green : theme.primaryColor,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isGranted
                                ? (isLastPermission ? 'VER RESUMEN' : 'CONTINUAR')
                                : 'CONCEDER PERMISO',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
                        // Texto informativo con tamaño adaptativo
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Este permiso es obligatorio para el funcionamiento de la app',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class PermissionInfo {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final String lottieAsset;

  PermissionInfo({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    this.lottieAsset = '',
  });
}