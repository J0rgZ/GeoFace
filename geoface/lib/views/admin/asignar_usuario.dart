import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../controllers/user_controller.dart';

class AsignarUsuarioPage extends StatefulWidget {
  const AsignarUsuarioPage({Key? key}) : super(key: key);

  @override
  State<AsignarUsuarioPage> createState() => _AsignarUsuarioPageState();
}

class _AsignarUsuarioPageState extends State<AsignarUsuarioPage> {
  final TextEditingController dniController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isLoadingEmpleados = true;
  String? selectedEmpleadoId;
  List<Map<String, dynamic>> empleados = [];

  @override
  void initState() {
    super.initState();
    _loadEmpleados();
  }

  @override
  void dispose() {
    dniController.dispose();
    nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadEmpleados() async {
    setState(() {
      isLoadingEmpleados = true;
    });

    try {
      final userController = Provider.of<UserController>(context, listen: false);
      final result = await userController.getEmpleadosSinUsuario();
      
      if (mounted) {
        setState(() {
          empleados = result;
          isLoadingEmpleados = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar empleados: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoadingEmpleados = false;
        });
      }
    }
  }

  void _onEmpleadoSelected(String empleadoId, String nombre, String dni) {
    setState(() {
      selectedEmpleadoId = empleadoId;
      nombreController.text = nombre;
      dniController.text = dni;
    });
  }

  Future<void> _assignUserToEmpleado() async {
    if (!formKey.currentState!.validate() || selectedEmpleadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un empleado primero'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userController = Provider.of<UserController>(context, listen: false);
      await userController.assignUserToEmpleado(
        empleadoId: selectedEmpleadoId!,
        dni: dniController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario asignado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final primaryColor = isDarkMode 
        ? const Color(0xFFCE93D8)  
        : const Color(0xFF6A1B9A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Usuario a Empleado'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.assignment_ind,
                      size: 64,
                      color: Color(0xFF6A1B9A),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Asignar Usuario a Empleado',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Seleccione un empleado para asignarle un usuario en el sistema.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Lista de empleados
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.people, color: primaryColor),
                                const SizedBox(width: 8),
                                const Text(
                                  'Empleados Disponibles',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isLoadingEmpleados)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Container(
                            constraints: const BoxConstraints(
                              maxHeight: 250,
                              minHeight: 100,
                            ),
                            child: isLoadingEmpleados
                                ? const Center(
                                    child: Text('Cargando empleados...'),
                                  )
                                : empleados.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Text(
                                            'No hay empleados disponibles para asignar',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: empleados.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final empleado = empleados[index];
                                          final isSelected = selectedEmpleadoId == empleado['id'];
                                          return ListTile(
                                            title: Text(
                                              empleado['nombre'] ?? '',
                                              style: TextStyle(
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                            subtitle: Text('DNI: ${empleado['dni'] ?? ''}'),
                                            selected: isSelected,
                                            selectedTileColor: primaryColor.withOpacity(0.1),
                                            onTap: () {
                                              _onEmpleadoSelected(
                                                empleado['id'],
                                                empleado['nombre'],
                                                empleado['dni'],
                                              );
                                            },
                                            trailing: isSelected
                                                ? Icon(Icons.check_circle, color: primaryColor)
                                                : null,
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Información del empleado seleccionado
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información del empleado seleccionado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: nombreController,
                            decoration: InputDecoration(
                              labelText: 'Nombre del empleado',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              floatingLabelStyle: TextStyle(color: primaryColor),
                            ),
                            readOnly: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Seleccione un empleado primero';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: dniController,
                            decoration: InputDecoration(
                              labelText: 'DNI (será el usuario y contraseña inicial)',
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              floatingLabelStyle: TextStyle(color: primaryColor),
                            ),
                            readOnly: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El DNI es obligatorio';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nota: El usuario y contraseña inicial del empleado será su DNI. Podrá cambiarla en el primer inicio de sesión.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    
                    // Botones de acción
                    ElevatedButton(
                      onPressed: (isLoading || selectedEmpleadoId == null) 
                          ? null 
                          : _assignUserToEmpleado,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ASIGNAR USUARIO',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}