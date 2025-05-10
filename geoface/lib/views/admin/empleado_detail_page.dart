import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/empleado_controller.dart';
import '../../controllers/sede_controller.dart';
import '../../models/empleado.dart';

class EmpleadoDetailPage extends StatefulWidget {
  final String empleadoId;

  const EmpleadoDetailPage({super.key, required this.empleadoId});

  @override
  State<EmpleadoDetailPage> createState() => _EmpleadoDetailPageState();
}

class _EmpleadoDetailPageState extends State<EmpleadoDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController(); // Agregado para DNI
  final _celularController = TextEditingController(); // Agregado para celular
  final _correoController = TextEditingController();
  final _cargoController = TextEditingController();
  String? _sedeSeleccionada;
  bool _isLoading = false;
  bool _isEditing = false;
  Empleado? _empleado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose(); // Dispose del DNI
    _celularController.dispose(); // Dispose del celular
    _correoController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar sedes
      await Provider.of<SedeController>(context, listen: false).getSedes();
      
      // Cargar datos del empleado
      final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
      final empleado = await empleadoController.getEmpleadoById(widget.empleadoId);
      
      if (empleado != null && mounted) {
        setState(() {
          _empleado = empleado;
          _nombreController.text = empleado.nombre;
          _apellidosController.text = empleado.apellidos;
          _dniController.text = empleado.dni; // Inicializar DNI
          _celularController.text = empleado.celular; // Inicializar celular
          _correoController.text = empleado.correo;
          _cargoController.text = empleado.cargo;
          _sedeSeleccionada = empleado.sedeId;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los datos: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
        final success = await empleadoController.updateEmpleado(
          id: widget.empleadoId,
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          dni: _dniController.text.trim(), // Incluir DNI
          celular: _celularController.text.trim(), // Incluir celular
          correo: _correoController.text.trim(),
          cargo: _cargoController.text.trim(),
          sedeId: _sedeSeleccionada!,
          activo: _empleado!.activo,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Empleado actualizado correctamente'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() => _isEditing = false);
          _loadData(); // Recargar datos actualizados
        } else {
          _showErrorMessage('No se pudo actualizar el empleado');
        }
      } catch (error) {
        _showErrorMessage('Error al actualizar: $error');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Obtiene las iniciales del nombre del empleado
  String _getInitials(String nombreCompleto) {
    if (nombreCompleto.isEmpty) return "?";
    
    final names = nombreCompleto.split(' ');
    if (names.length == 1) return names[0][0].toUpperCase();
    
    return '${names[0][0]}${names.length > 1 ? names[names.length > 2 ? 2 : 1][0] : ''}'.toUpperCase();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly || !_isEditing,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
          counterText: '',
        ),
        validator: validator,
        style: TextStyle(
          color: _isEditing ? Colors.black87 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, 
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Empleado' : 'Detalle de Empleado',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (!_isEditing && !_isLoading && _empleado != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                const Text('Cargando información...'),
              ],
            ),
          )
        : _empleado == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontró el empleado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Consumer<SedeController>(
              builder: (context, sedeController, _) {
                final nombreCompleto = '${_nombreController.text} ${_apellidosController.text}';
                final sedes = sedeController.sedes;
                
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Perfil del empleado
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Hero(
                                  tag: 'empleado-avatar-${widget.empleadoId}',
                                  child: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    radius: 40,
                                    child: Text(
                                      _getInitials(nombreCompleto),
                                      style: TextStyle(
                                        fontSize: 24, 
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Hero(
                                  tag: 'empleado-nombre-${widget.empleadoId}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      nombreCompleto,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _cargoController.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _empleado!.activo 
                                      ? Colors.green.shade50 
                                      : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _empleado!.activo 
                                        ? Colors.green.shade200 
                                        : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    _empleado!.activo ? 'Activo' : 'Inactivo',
                                    style: TextStyle(
                                      color: _empleado!.activo 
                                        ? Colors.green.shade700 
                                        : Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Información de Identidad
                          _buildInfoCard(
                            title: 'Información de Identidad',
                            icon: Icons.badge_outlined,
                            children: [
                              _buildTextField(
                                controller: _dniController,
                                label: 'DNI',
                                icon: Icons.credit_card_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                maxLength: 8,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'El DNI es obligatorio';
                                  if (value.length != 8) return 'El DNI debe tener 8 dígitos';
                                  return null;
                                },
                              ),
                              _buildTextField(
                                controller: _nombreController,
                                label: 'Nombre',
                                icon: Icons.person_outline,
                                validator: (value) => 
                                  value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
                              ),
                              _buildTextField(
                                controller: _apellidosController,
                                label: 'Apellidos',
                                icon: Icons.person_outline,
                                validator: (value) => 
                                  value == null || value.isEmpty ? 'Los apellidos son obligatorios' : null,
                              ),
                            ],
                          ),
                          
                          // Información de Contacto
                          _buildInfoCard(
                            title: 'Información de Contacto',
                            icon: Icons.contact_mail,
                            children: [
                              _buildTextField(
                                controller: _celularController,
                                label: 'Número de Celular',
                                icon: Icons.phone_android_outlined,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                maxLength: 9,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'El número de celular es obligatorio';
                                  if (value.length != 9) return 'El número debe tener 9 dígitos';
                                  return null;
                                },
                              ),
                              _buildTextField(
                                controller: _correoController,
                                label: 'Correo Electrónico',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'El correo es obligatorio';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Correo inválido';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          
                          // Información Laboral
                          _buildInfoCard(
                            title: 'Información Laboral',
                            icon: Icons.work,
                            children: [
                              _buildTextField(
                                controller: _cargoController,
                                label: 'Cargo',
                                icon: Icons.work_outline,
                                validator: (value) => 
                                  value == null || value.isEmpty ? 'El cargo es obligatorio' : null,
                              ),
                              
                              // Sede Dropdown
                              if (_isEditing)
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Sede',
                                    prefixIcon: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), 
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  value: _sedeSeleccionada,
                                  items: sedes.map((sede) {
                                    return DropdownMenuItem<String>(
                                      value: sede.id.toString(),
                                      child: Text(sede.nombre),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _sedeSeleccionada = value;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Seleccione una sede' : null,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                                )
                              else
                                // Mostrar sede como texto cuando no está en modo edición
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: TextFormField(
                                    initialValue: sedes
                                        .firstWhere(
                                          (sede) => sede.id.toString() == _sedeSeleccionada,
                                          orElse: () => sedeController.sedes.first,
                                        )
                                        .nombre,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'Sede',
                                      prefixIcon: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              
                            ],
                          ),
                          
                          // Biométricos
                          if (!_isEditing)
                            _buildInfoCard(
                              title: 'Datos Biométricos',
                              icon: Icons.fingerprint,
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _empleado!.hayDatosBiometricos 
                                        ? Colors.blue.shade50 
                                        : Colors.grey.shade100,
                                    child: Icon(
                                      _empleado!.hayDatosBiometricos
                                          ? Icons.fingerprint
                                          : Icons.fingerprint_outlined,
                                      color: _empleado!.hayDatosBiometricos
                                          ? Colors.blue.shade700
                                          : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    _empleado!.hayDatosBiometricos
                                        ? 'Datos biométricos registrados'
                                        : 'Sin datos biométricos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _empleado!.hayDatosBiometricos
                                        ? 'El empleado puede usar reconocimiento facial'
                                        : 'Es necesario registrar datos biométricos',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/admin/empleados/biometricos',
                                        arguments: _empleado,
                                      ).then((_) => _loadData());
                                    },
                                  ),
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Botones de acción
                          if (_isEditing) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _guardarCambios,
                                    icon: _isLoading
                                        ? Container(
                                            width: 24,
                                            height: 24,
                                            padding: const EdgeInsets.all(2.0),
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: Text(
                                      _isLoading ? 'Guardando...' : 'Guardar Cambios',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : () => setState(() => _isEditing = false),
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey.shade700,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text(
                                        'Volver',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: theme.colorScheme.primary,
                                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
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
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}