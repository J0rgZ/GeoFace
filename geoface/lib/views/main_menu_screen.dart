
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;

class TimeService {
  static final TimeService _instance = TimeService._internal();
  factory TimeService() => _instance;
  TimeService._internal();

  // APIs más confiables con diferentes enfoques
  static const List<Map<String, String>> _timeApis = [
    {
      'url': 'https://timeapi.io/api/Time/current/zone?timeZone=America/Lima',
      'name': 'TimeAPI.io',
      'type': 'timeapi'
    },
    {
      'url': 'http://worldclockapi.com/api/json/est/now',
      'name': 'WorldClock API',
      'type': 'worldclock'
    },
  ];

  DateTime? _baseApiTime;
  DateTime? _baseLocalTime;
  String _currentTimeSource = 'Inicializando...';
  bool _isOnline = false;
  bool _hasInternetConnection = true;
  Timer? _connectionCheckTimer;

  String get timeSource => _currentTimeSource;
  bool get isOnline => _isOnline;

  // Método principal para obtener tiempo con mejor lógica
  Future<DateTime> getCurrentTime() async {
    // Si tenemos tiempo base de API, calcularlo dinámicamente
    if (_baseApiTime != null && _baseLocalTime != null) {
      final elapsed = DateTime.now().difference(_baseLocalTime!);
      final calculatedTime = _baseApiTime!.add(elapsed);
      
      // Verificar que el tiempo calculado sea razonable (no más de 1 hora de diferencia)
      final timeDiff = calculatedTime.difference(DateTime.now()).abs();
      if (timeDiff.inHours < 1) {
        return calculatedTime;
      }
    }

    // Intentar sincronizar si no tenemos tiempo base o si es muy antiguo
    await _attemptTimeSync();

    // Si logramos sincronizar, usar tiempo calculado
    if (_baseApiTime != null && _baseLocalTime != null) {
      final elapsed = DateTime.now().difference(_baseLocalTime!);
      return _baseApiTime!.add(elapsed);
    }

    // Fallback: usar tiempo local con ajuste manual para Lima
    return _getLocalTimeLima();
  }

  // Obtener tiempo local ajustado manualmente para Lima (UTC-5)
  DateTime _getLocalTimeLima() {
    _isOnline = false;
    _currentTimeSource = 'Tiempo Local (UTC-5)';
    
    // Obtener UTC y restar 5 horas para Lima
    final utcNow = DateTime.now().toUtc();
    return utcNow.subtract(const Duration(hours: 5));
  }

  // Verificar conexión de manera más eficiente
  Future<bool> _checkConnection() async {
    try {
      final response = await http.head(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 3));
      
      _hasInternetConnection = response.statusCode == 200;
      return _hasInternetConnection;
    } catch (e) {
      _hasInternetConnection = false;
      return false;
    }
  }

  // Intento de sincronización con múltiples APIs
  Future<void> _attemptTimeSync() async {
    if (!await _checkConnection()) {
      _currentTimeSource = 'Sin Conexión - Tiempo Local';
      _isOnline = false;
      return;
    }

    for (final api in _timeApis) {
      try {
        final response = await http.get(
          Uri.parse(api['url']!),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'GeoFace-TimeSync/1.0'
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final apiTime = _parseTimeResponse(api, response.body);
          if (apiTime != null && _isTimeReasonable(apiTime)) {
            _baseApiTime = apiTime;
            _baseLocalTime = DateTime.now();
            _isOnline = true;
            _currentTimeSource = '${api['name']} (Lima)';
            
            print('✓ Sincronizado con: ${api['name']}');
            print('✓ Hora API: ${apiTime.toString()}');
            print('✓ Diferencia con local: ${apiTime.difference(DateTime.now()).inSeconds}s');
            return;
          }
        }
      } catch (e) {
        print('✗ Error con ${api['name']}: $e');
        continue;
      }
    }

    // Si todas las APIs fallan
    _currentTimeSource = 'APIs no disponibles - Tiempo Local';
    _isOnline = false;
  }

  // Parser mejorado para diferentes APIs
  DateTime? _parseTimeResponse(Map<String, String> api, String responseBody) {
    try {
      final data = json.decode(responseBody);
      
      switch (api['type']) {
                  
        case 'timeapi':
          // TimeAPI.io - formato diferente
          final dateTimeString = data['dateTime'] as String;
          return DateTime.parse(dateTimeString);
          
        case 'worldclock':
          // WorldClockAPI - requiere conversión
          final dateTimeString = data['currentDateTime'] as String;
          final utcTime = DateTime.parse(dateTimeString);
          return utcTime.subtract(const Duration(hours: 5)); // UTC-5 para Lima
          
        default:
          return null;
      }
    } catch (e) {
      print('Error parseando ${api['name']}: $e');
      return null;
    }
  }

  // Verificar que el tiempo de la API sea razonable
  bool _isTimeReasonable(DateTime apiTime) {
    final now = DateTime.now();
    final difference = apiTime.difference(now).abs();
    
    // Aceptar diferencias de hasta 12 horas (para manejar zonas horarias)
    return difference.inHours <= 12;
  }

  // Inicializar servicio con verificaciones periódicas
  void initialize() {
    _attemptTimeSync();
    
    // Verificar conexión cada 30 segundos
    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 30), 
      (timer) => _attemptTimeSync()
    );
  }

  // Forzar sincronización manual
  Future<void> forceSync() async {
    _currentTimeSource = 'Sincronizando...';
    await _attemptTimeSync();
  }

  // Limpiar recursos
  void dispose() {
    _connectionCheckTimer?.cancel();
  }

  // Obtener información detallada del estado
  Map<String, dynamic> getStatus() {
    return {
      'isOnline': _isOnline,
      'source': _currentTimeSource,
      'hasConnection': _hasInternetConnection,
      'lastSync': _baseLocalTime?.toString() ?? 'Nunca',
      'timeDrift': _baseApiTime != null && _baseLocalTime != null
          ? DateTime.now().difference(_baseLocalTime!).inSeconds
          : 0,
    };
  }
}

// Clase mejorada para manejo responsivo (sin cambios)
class ResponsiveConfig {
  final double screenWidth;
  final double screenHeight;
  final bool isPortrait;

  ResponsiveConfig({
    required this.screenWidth,
    required this.screenHeight,
  }) : isPortrait = screenHeight > screenWidth;

  bool get isXSmall => screenWidth < 360;
  bool get isSmall => screenWidth >= 360 && screenWidth < 480;
  bool get isMedium => screenWidth >= 480 && screenWidth < 768;
  bool get isLarge => screenWidth >= 768 && screenWidth < 1024;
  bool get isXLarge => screenWidth >= 1024;

  double get dateSize => isXSmall ? 14 : isSmall ? 16 : isMedium ? 18 : 20;
  double get timeSize => isXSmall ? 42 : isSmall ? 52 : isMedium ? 64 : isLarge ? 76 : 88;
  double get titleSize => isXSmall ? 20 : isSmall ? 24 : isMedium ? 28 : 32;
  double get buttonTextSize => isXSmall ? 14 : isSmall ? 16 : 18;
  double get statusSize => isXSmall ? 11 : isSmall ? 12 : 14;

  double get padding => isXSmall ? 12 : isSmall ? 16 : isMedium ? 20 : 24;
  double get margin => isXSmall ? 8 : isSmall ? 12 : isMedium ? 16 : 20;
  double get buttonHeight => isXSmall ? 48 : isSmall ? 52 : isMedium ? 56 : 60;

  double get iconSize => isXSmall ? 20 : isSmall ? 24 : isMedium ? 28 : 32;
  double get buttonIconSize => isXSmall ? 20 : isSmall ? 22 : 24;
}

class MainMenuScreen extends StatefulWidget {
  final void Function(BuildContext context) onMarkAttendance;
  final void Function(BuildContext context) onAdminLogin;

  const MainMenuScreen({
    super.key,
    required this.onMarkAttendance,
    required this.onAdminLogin,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> 
    with TickerProviderStateMixin {
  late DateTime _currentTime;
  late Timer _timer;
  late AnimationController _pulseController;
  late AnimationController _syncController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _syncAnimation;
  
  bool _isMenuOpen = false;
  bool _isInitializing = true;
  bool _isSyncing = false;
  
  final TimeService _timeService = TimeService();

  static const Color _primaryColor = Color(0xFF6A1B9A);
  static const Color _secondaryColor = Color(0xFF00C853);
  static const Color _accentColor = Color(0xFF8E24AA);

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await initializeDateFormatting('es_PE', null);
    _setupAnimations();
    
    // Inicializar servicio de tiempo
    _timeService.initialize();
    await _initializeTime();
    _setupTimers();
    
    setState(() {
      _isInitializing = false;
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _syncController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _syncAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _syncController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeTime() async {
    _currentTime = await _timeService.getCurrentTime();
  }

  void _setupTimers() {
    // Timer principal para actualizar la UI cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        final newTime = await _timeService.getCurrentTime();
        setState(() {
          _currentTime = newTime;
        });
      }
    });
  }

  // Sincronización manual mejorada
  Future<void> _performManualSync() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
    });
    
    _syncController.reset();
    _syncController.forward();
    
    await _timeService.forceSync();
    
    // Pequeña pausa para mostrar la animación
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isSyncing = false;
      });
      
      // Feedback háptico
      HapticFeedback.lightImpact();
      
      // Mostrar resultado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _timeService.isOnline 
              ? '✓ Sincronizado correctamente'
              : '⚠ Sin conexión - usando tiempo local',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: _timeService.isOnline 
            ? _secondaryColor 
            : Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _syncController.dispose();
    _timeService.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig(
          screenWidth: constraints.maxWidth,
          screenHeight: constraints.maxHeight,
        );

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: _buildGradientBackground(),
            child: SafeArea(
              child: Stack(
                children: [
                  _buildMainContent(config),
                  if (_isMenuOpen) _buildMenuOverlay(config),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _primaryColor,
          _accentColor,
          const Color(0xFF4A148C),
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig(
            screenWidth: constraints.maxWidth,
            screenHeight: constraints.maxHeight,
          );
          
          return Center(
            child: Padding(
              padding: EdgeInsets.all(config.padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: config.isXSmall ? 120 : 150,
                    height: config.isXSmall ? 120 : 150,
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      errorBuilder: (context, error, stackTrace) {
                        return CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: config.padding),
                  Text(
                    'Inicializando GeoFace...',
                    style: TextStyle(
                      fontSize: config.buttonTextSize,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: config.margin),
                  Text(
                    'Sincronizando con tiempo de servidores',
                    style: TextStyle(
                      fontSize: config.statusSize,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(ResponsiveConfig config) {
    // Formatear fecha y hora para Lima específicamente
    final limaTimeFormat = DateFormat('EEEE d \'de\' MMMM, yyyy', 'es_PE');
    final clockFormat = DateFormat('HH:mm:ss');

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 
                     MediaQuery.of(context).padding.bottom,
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              _buildHeader(config),
              Expanded(
                child: _buildTimeCard(config, limaTimeFormat, clockFormat),
              ),
              _buildAdminAccess(config),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.all(config.padding),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(config.padding * 0.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.face_retouching_natural,
                    color: Colors.white,
                    size: config.iconSize,
                  ),
                ),
                SizedBox(width: config.margin),
                Flexible(
                  child: Text(
                    'GeoFace',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: config.titleSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _buildSyncIndicator(config),
          SizedBox(width: config.margin),
          _buildMenuButton(config),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator(ResponsiveConfig config) {
    return GestureDetector(
      onTap: _performManualSync,
      child: AnimatedBuilder(
        animation: _syncAnimation,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: config.margin,
              vertical: config.margin * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSyncing)
                  Transform.rotate(
                    angle: _syncAnimation.value * 6.28,
                    child: Icon(
                      Icons.sync,
                      size: 16,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    _timeService.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: _timeService.isOnline ? _secondaryColor : Colors.orange[300],
                  ),
                SizedBox(width: 6),
                Text(
                  _timeService.isOnline ? 'Online' : 'Local',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: config.statusSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuButton(ResponsiveConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: AnimatedRotation(
          turns: _isMenuOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isMenuOpen ? Icons.close : Icons.info_outline,
            color: Colors.white,
            size: config.iconSize * 0.8,
          ),
        ),
        onPressed: _toggleMenu,
        tooltip: 'Información',
        padding: EdgeInsets.all(config.margin),
      ),
    );
  }

  Widget _buildTimeCard(ResponsiveConfig config, DateFormat dateFormat, DateFormat timeFormat) {
    return Container(
      margin: EdgeInsets.all(config.padding),
      padding: EdgeInsets.all(config.padding * 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dateFormat.format(_currentTime).toUpperCase(),
            style: TextStyle(
              color: _primaryColor,
              fontSize: config.dateSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: config.padding),
          
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              timeFormat.format(_currentTime),
              style: TextStyle(
                color: const Color(0xFF4A148C),
                fontSize: config.timeSize,
                fontWeight: FontWeight.bold,
                letterSpacing: -2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          
          SizedBox(height: config.margin),
          
          _buildTimeSource(config),
          
          SizedBox(height: config.padding * 1.5),
          
          _buildAttendanceButton(config),
          
          SizedBox(height: config.padding),
          
          _buildConnectionStatus(config),
        ],
      ),
    );
  }

  Widget _buildTimeSource(ResponsiveConfig config) {
    final isOnline = _timeService.isOnline;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.padding,
        vertical: config.margin * 0.5,
      ),
      decoration: BoxDecoration(
        color: isOnline ? 
          _secondaryColor.withOpacity(0.1) : 
          Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? 
            _secondaryColor.withOpacity(0.3) : 
            Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.language : Icons.smartphone,
            size: config.statusSize,
            color: isOnline ? _secondaryColor : Colors.orange[600],
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              _timeService.timeSource,
              style: TextStyle(
                color: isOnline ? _secondaryColor : Colors.orange[700],
                fontSize: config.statusSize - 1,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(ResponsiveConfig config) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: SizedBox(
        width: double.infinity,
        height: config.buttonHeight,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.onMarkAttendance(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
            shadowColor: _primaryColor.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: config.buttonIconSize,
              ),
              SizedBox(width: config.margin),
              Text(
                'MARCAR ASISTENCIA',
                style: TextStyle(
                  fontSize: config.buttonTextSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(ResponsiveConfig config) {
    final isOnline = _timeService.isOnline;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? _secondaryColor : Colors.orange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isOnline ? _secondaryColor : Colors.orange)
                    .withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Text(
          isOnline 
            ? 'Hora sincronizada Online'
            : 'Tiempo local (UTC-5) - Sin conexión',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: config.statusSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminAccess(ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.all(config.padding),
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.onAdminLogin(context);
        },
        icon: Icon(
          Icons.admin_panel_settings,
          color: Colors.white.withOpacity(0.9),
          size: config.iconSize * 0.7,
        ),
        label: Text(
          'Acceso Administrativo',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
            fontSize: config.statusSize + 2,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: config.padding,
            vertical: config.margin,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOverlay(ResponsiveConfig config) {
    final menuWidth = (config.screenWidth * 0.9).clamp(280.0, 400.0);
    
    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleMenu,
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Stack(
            children: [
              Positioned(
                top: config.padding * 4,
                right: config.padding,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: _isMenuOpen ? Offset.zero : const Offset(1, 0),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: menuWidth,
                    constraints: BoxConstraints(
                      maxHeight: config.screenHeight * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _buildMenuContent(config),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContent(ResponsiveConfig config) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(config.padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _accentColor],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: config.iconSize * 0.8,
              ),
              SizedBox(width: config.margin),
              Expanded(
                child: Text(
                  'Información del Sistema',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: config.buttonTextSize,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(config.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMenuHeader(config),
                SizedBox(height: config.padding),
                Text(
                  'Sistema avanzado de control de asistencia con reconocimiento facial, geolocalización y sincronización de tiempo oficial de Lima.',
                  style: TextStyle(
                    fontSize: config.statusSize + 1,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: config.padding),
                _buildTechnicalInfo(config),
                SizedBox(height: config.padding),
                _buildCopyright(config),
              ],
            ),
          ),
        ),
        
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(config.padding),
          child: ElevatedButton(
            onPressed: _toggleMenu,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: config.margin),
            ),
            child: Text(
              'CERRAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: config.statusSize + 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuHeader(ResponsiveConfig config) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(config.margin),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _accentColor],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.face_retouching_natural,
            size: config.iconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(width: config.margin),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GeoFace',
                style: TextStyle(
                  fontSize: config.buttonTextSize + 2,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              Text(
                'Versión 2.3.0',
                style: TextStyle(
                  fontSize: config.statusSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalInfo(ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            config,
            Icons.build,
            'Build',
            '20250531-TimeSync',
          ),
          SizedBox(height: config.margin),
          _buildInfoRow(
            config,
            Icons.schedule,
            'Fuente de Tiempo',
            _timeService.timeSource,
          ),
          SizedBox(height: config.margin),
          _buildInfoRow(
            config,
            Icons.cloud,
            'Estado de Conexión',
            _timeService.isOnline ? 'Conectado' : 'Sin conexión',
          ),
          SizedBox(height: config.margin),
          _buildInfoRow(
            config,
            Icons.location_on,
            'Zona Horaria',
            'America/Lima (UTC-5)',
          ),
          SizedBox(height: config.margin),
          _buildInfoRow(
            config,
            Icons.phone_android,
            'Plataforma',
            'Flutter Mobile',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ResponsiveConfig config, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: config.iconSize * 0.6,
          color: const Color(0xFF1976D2),
        ),
        SizedBox(width: config.margin),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: config.statusSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: config.statusSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyright(ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.copyright,
                size: config.statusSize,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4),
              Text(
                '2025 GeoFace Systems',
                style: TextStyle(
                  fontSize: config.statusSize,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: config.margin * 0.5),
          Text(
            'Desarrollado para control de asistencia empresarial',
            style: TextStyle(
              fontSize: config.statusSize - 1,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}