import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../controllers/auth_controller.dart';
import '../../routes.dart';
import '../../utils/validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authController = Provider.of<AuthController>(context, listen: false);

      if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
        authController.setErrorMessage('Por favor, ingresa un correo y contraseña válidos');
        return;
      }

      final success = await authController.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminLayout);
      }
    }
  }

  void _goBack() {
    // CAMBIO PRINCIPAL: Navegar al menú principal en lugar de hacer pop
    Navigator.of(context).pushReplacementNamed(AppRoutes.mainMenu);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    
    // Determinar si es un dispositivo móvil o una pantalla pequeña
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Botón de volver en la esquina superior izquierda
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _goBack,
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: colorScheme.primary,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    tooltip: 'Volver al menú principal',
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    constraints: BoxConstraints(
                      minWidth: isSmallScreen ? 40 : 48,
                      minHeight: isSmallScreen ? 40 : 48,
                    ),
                  ),
                ),
              ),
              
              // Contenido principal del login
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 32.0,
                    vertical: 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 500,
                    ),
                    child: Consumer<AuthController>(
                      builder: (context, authController, _) {
                        return Card(
                          elevation: 6,
                          shadowColor: colorScheme.primary.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 32.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Animación Lottie con tamaño adaptativo
                                  SizedBox(
                                    height: isSmallScreen ? 120 : 150,
                                    child: Center(
                                      child: Lottie.asset(
                                        'assets/animations/admin_login.json',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 24),
                                  
                                  // Título - Adaptable según tamaño
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'GeoFace Control',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Badge adaptativo
                                  Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12, 
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: colorScheme.primary.withOpacity(0.6),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        'ACCESO ADMINISTRADOR',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 10 : 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 24 : 36),
                                  
                                  // Campos de formulario (mantengo el código original)
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Usuario',
                                      hintText: 'Administrador',
                                      prefixIcon: Icon(
                                        Icons.admin_panel_settings, 
                                        color: colorScheme.primary,
                                        size: isSmallScreen ? 20 : 22,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline,
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline.withOpacity(0.7),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary, 
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 12 : 16,
                                        horizontal: 16,
                                      ),
                                      fillColor: colorScheme.surface,
                                      filled: true,
                                    ),
                                    keyboardType: TextInputType.text,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Por favor ingrese su usuario';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      hintText: '••••••••',
                                      prefixIcon: Icon(
                                        Icons.lock_outline, 
                                        color: colorScheme.primary,
                                        size: isSmallScreen ? 20 : 22,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: colorScheme.primary.withOpacity(0.7),
                                          size: isSmallScreen ? 20 : 22,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                        splashRadius: 24,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline,
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline.withOpacity(0.7),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary, 
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 12 : 16,
                                        horizontal: 16,
                                      ),
                                      fillColor: colorScheme.surface,
                                      filled: true,
                                    ),
                                    obscureText: _obscurePassword,
                                    validator: Validators.validatePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(context),
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 20 : 24),
                                  
                                  // Mensaje de error (código original)
                                  if (authController.errorMessage != null)
                                    Container(
                                      margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
                                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: theme.colorScheme.error,
                                                size: isSmallScreen ? 18 : 20,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  authController.errorMessage!,
                                                  style: TextStyle(
                                                    color: theme.colorScheme.onErrorContainer,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isSmallScreen ? 13 : 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Si tiene problemas para iniciar sesión, comuníquese con el equipo de soporte técnico.',
                                            style: TextStyle(
                                              color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
                                              fontSize: isSmallScreen ? 11 : 12,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.support_agent,
                                                size: isSmallScreen ? 14 : 16,
                                                color: theme.colorScheme.onErrorContainer,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'soporte@geoface.com',
                                                style: TextStyle(
                                                  color: theme.colorScheme.onErrorContainer,
                                                  fontSize: isSmallScreen ? 11 : 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  // Botón de inicio de sesión
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: authController.loading
                                          ? null
                                          : () => _login(context),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 14 : 16,
                                        ),
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: authController.loading
                                          ? SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : Wrap(
                                              alignment: WrapAlignment.center,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 8,
                                              children: [
                                                Icon(
                                                  Icons.login_rounded, 
                                                  size: isSmallScreen ? 18 : 20,
                                                ),
                                                Text(
                                                  'Acceder',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 15 : 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  
                                  // Botón de volver (ACTUALIZADO)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _goBack,
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 14,
                                        ),
                                        side: BorderSide(
                                          color: colorScheme.primary.withOpacity(0.7),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        children: [
                                          Icon(
                                            Icons.home_outlined,
                                            size: isSmallScreen ? 16 : 18,
                                            color: colorScheme.primary,
                                          ),
                                          Text(
                                            'Volver al Menú Principal',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 13 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  
                                  // Texto de seguridad
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.shield,
                                          size: isSmallScreen ? 12 : 14,
                                          color: colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Acceso exclusivo para administradores',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 12,
                                            color: colorScheme.onSurface.withOpacity(0.6),
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
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}