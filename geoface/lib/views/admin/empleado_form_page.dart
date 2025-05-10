// views/admin/empleado_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/empleado_controller.dart';
import '../../controllers/sede_controller.dart';

class EmpleadoFormPage extends StatefulWidget {
  const EmpleadoFormPage({Key? key}) : super(key: key);

  @override
  State<EmpleadoFormPage> createState() => _EmpleadoFormPageState();
}

class _EmpleadoFormPageState extends State<EmpleadoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _celularController = TextEditingController();
  final _correoController = TextEditingController();
  final _cargoController = TextEditingController();
  String? _sedeSeleccionada;
  bool _isLoading = false;
  
  // Errores específicos para campos únicos
  String? _dniError;
  String? _correoError;
  
  // Almacenar referencia al controlador
  EmpleadoController? _empleadoController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SedeController>(context, listen: false).getSedes();
      // Guardar referencia al controlador
      _empleadoController = Provider.of<EmpleadoController>(context, listen: false);
      _empleadoController?.addListener(_checkControllerErrors);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Otra opción es obtener la referencia aquí
    // _empleadoController = Provider.of<EmpleadoController>(context, listen: false);
  }

  void _checkControllerErrors() {
    // Usar referencia guardada en lugar de Provider.of en tiempo de ejecución
    if (_empleadoController?.errorMessage != null && mounted) {
      final error = _empleadoController!.errorMessage!;
      
      setState(() {
        _dniError = error.contains('DNI') ? error : null;
        _correoError = error.contains('correo') ? error : null;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _celularController.dispose();
    _correoController.dispose();
    _cargoController.dispose();
    
    // Eliminar el listener usando la referencia guardada
    if (_empleadoController != null) {
      _empleadoController!.removeListener(_checkControllerErrors);
    }
    
    super.dispose();
  }

  Future<void> _guardarEmpleado() async {
    // Resetear errores específicos
    setState(() {
      _dniError = null;
      _correoError = null;
    });
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Usar variable guardada
        final success = await _empleadoController!.addEmpleado(
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          dni: _dniController.text.trim(),
          celular: _celularController.text.trim(),
          correo: _correoController.text.trim(),
          cargo: _cargoController.text.trim(),
          sedeId: _sedeSeleccionada!,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Empleado registrado correctamente',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          // Los errores específicos se manejan en _checkControllerErrors()
          // Este bloque es para errores generales
          if (_empleadoController!.errorMessage != null && 
              !_empleadoController!.errorMessage!.contains('DNI') && 
              !_empleadoController!.errorMessage!.contains('correo')) {
            _mostrarErrorSnackbar(_empleadoController!.errorMessage!);
          }
          
          // Forzar revalidación del formulario para mostrar errores específicos
          _formKey.currentState!.validate();
        }
      } catch (e) {
        if (mounted) {
          _mostrarErrorSnackbar('Error inesperado: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _mostrarErrorSnackbar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? specificError,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final hasError = specificError != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272727) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: hasError 
              ? Colors.red.shade400
              : isDark 
                  ? const Color(0xFF444444) 
                  : Colors.grey.shade200,
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText,
              counterText: '',
              prefixIcon: Icon(
                icon, 
                color: hasError ? Colors.red.shade400 : primaryColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              labelStyle: TextStyle(
                color: hasError 
                    ? Colors.red.shade400
                    : isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            validator: (value) {
              // Primero verificar errores específicos de unicidad
              if (specificError != null) return specificError;
              // Luego validar normalmente
              return validator != null ? validator(value) : null;
            },
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                specificError,
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Registrar Empleado'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        centerTitle: theme.appBarTheme.centerTitle,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _guardarEmpleado,
            icon: _isLoading
                ? Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(2.0),
                    child: CircularProgressIndicator(
                      color: theme.appBarTheme.foregroundColor,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            tooltip: 'Guardar Empleado',
          ),
        ],
      ),
      body: Consumer<SedeController>(
        builder: (context, sedeController, _) {
          final sedes = sedeController.sedes;
          final bool isSedesLoading = sedeController.loading;

          if (isSedesLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text('Cargando sedes...'),
                ],
              ),
            );
          }

          if (sedeController.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar sedes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(sedeController.errorMessage!),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Provider.of<SedeController>(context, listen: false).getSedes();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card con animación mejorada
                    _buildHeaderCard(primaryColor, isDark),

                    // Sección: Información de Identidad
                    _buildSectionHeader(
                      title: 'Información de Identidad', 
                      icon: Icons.badge_outlined,
                      theme: theme,
                    ),
                    
                    _buildFormField(
                      controller: _dniController,
                      label: 'DNI',
                      icon: Icons.credit_card_outlined,
                      hintText: 'Ingrese el número de documento',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 8,
                      specificError: _dniError,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El DNI es obligatorio';
                        if (value.length != 8) return 'El DNI debe tener 8 dígitos';
                        return null;
                      },
                    ),
                    
                    _buildFormField(
                      controller: _nombreController,
                      label: 'Nombre',
                      icon: Icons.person_outline,
                      hintText: 'Ingrese el nombre',
                      validator: (value) => value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
                    ),
                    
                    _buildFormField(
                      controller: _apellidosController,
                      label: 'Apellidos',
                      icon: Icons.person_outline,
                      hintText: 'Ingrese los apellidos',
                      validator: (value) => value == null || value.isEmpty ? 'Los apellidos son obligatorios' : null,
                    ),
                    
                    // Sección: Información de Contacto
                    _buildSectionHeader(
                      title: 'Información de Contacto', 
                      icon: Icons.contact_mail_outlined,
                      theme: theme,
                    ),
                    
                    _buildFormField(
                      controller: _celularController,
                      label: 'Número de Celular',
                      icon: Icons.phone_android_outlined,
                      hintText: 'Ingrese el número de celular',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 9,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El número de celular es obligatorio';
                        if (value.length != 9) return 'El número debe tener 9 dígitos';
                        return null;
                      },
                    ),
                    
                    _buildFormField(
                      controller: _correoController,
                      label: 'Correo Electrónico',
                      icon: Icons.email_outlined,
                      hintText: 'ejemplo@correo.com',
                      keyboardType: TextInputType.emailAddress,
                      specificError: _correoError,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El correo es obligatorio';
                        final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegExp.hasMatch(value)) return 'Ingrese un correo válido';
                        return null;
                      },
                    ),
                    
                    // Sección: Información Laboral
                    _buildSectionHeader(
                      title: 'Información Laboral', 
                      icon: Icons.work_outline,
                      theme: theme,
                    ),
                    
                    _buildFormField(
                      controller: _cargoController,
                      label: 'Cargo',
                      icon: Icons.work_outline,
                      hintText: 'Ej. Gerente, Analista, etc.',
                      validator: (value) => value == null || value.isEmpty ? 'El cargo es obligatorio' : null,
                    ),
                    
                    // Dropdown de Sede con diseño mejorado
                    _buildSedeDropdown(theme, isDark, primaryColor, sedes),
                    
                    // Botones de Acción mejorados
                    _buildActionButtons(isDark),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, bool isDark) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.2),
              primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuevo Empleado',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Complete la información para registrar un nuevo empleado en el sistema.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey.shade800.withOpacity(0.5) 
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark 
                      ? Colors.grey.shade700 
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.amber : Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El DNI y correo electrónico son únicos para cada empleado y no pueden duplicarse.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeDropdown(ThemeData theme, bool isDark, Color primaryColor, List sedes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272727) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF444444) : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Sede',
          prefixIcon: Icon(Icons.location_on_outlined, color: primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        value: _sedeSeleccionada,
        items: sedes.map((sede) {
          return DropdownMenuItem<String>(
            value: sede.id.toString(),
            child: Text(
              sede.nombre,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _sedeSeleccionada = value;
          });
        },
        validator: (value) => value == null ? 'Seleccione una sede' : null,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
        dropdownColor: isDark ? const Color(0xFF303030) : Colors.white,
        menuMaxHeight: 300,
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _guardarEmpleado,
            icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _isLoading ? 'Guardando...' : 'Guardar Empleado',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                width: 1.5,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader({
    required String title, 
    required IconData icon,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon, 
              color: primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}