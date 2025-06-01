// views/admin/empleados_page.dart
import 'package:flutter/material.dart';
import 'package:geoface/views/admin/empleado_detail_page.dart';
import 'package:geoface/views/admin/empleado_form_page.dart';
import 'package:geoface/views/admin/registro_biometrico_page.dart';
import 'package:provider/provider.dart';
import '../../controllers/empleado_controller.dart';
import '../../models/empleado.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({Key? key}) : super(key: key);

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    await empleadoController.getEmpleados();
  }

  Future<void> _toggleEmpleadoStatus(Empleado empleado) async {
    final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    final success = await empleadoController.toggleEmpleadoActivo(empleado);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado cambiado: ${empleado.activo ? 'Activo' : 'Inactivo'}'),
          backgroundColor: empleado.activo 
              ? Colors.green.shade700 
              : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteEmpleado(Empleado empleado) async {
    final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    final success = await empleadoController.deleteEmpleado(empleado.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${empleado.nombreCompleto} eliminado correctamente'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _navigateToDetail(String empleadoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmpleadoDetailPage(empleadoId: empleadoId),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToBiometrico(Empleado empleado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistroBiometricoScreen(empleado: empleado),
      ),
    ).then((_) => _loadData()); // Acción posterior si es necesario
  }

  // Obtiene las iniciales del nombre y apellido
  String _getInitials(String nombreCompleto) {
    if (nombreCompleto.isEmpty) return "?";
    
    final names = nombreCompleto.split(' ');
    if (names.length == 1) return names[0][0].toUpperCase();
    
    // Primera letra del primer nombre y primera letra del primer apellido
    return '${names[0][0]}${names.length > 1 ? names[names.length > 2 ? 2 : 1][0] : ''}'.toUpperCase();
  }

  void _showEmpleadoOptions(BuildContext context, Empleado empleado) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 16, 
            horizontal: isSmallScreen ? 16 : 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              // Avatar
              Hero(
                tag: 'empleado-avatar-${empleado.id}',
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  radius: isSmallScreen ? 36 : 45,
                  child: Text(
                    _getInitials(empleado.nombreCompleto),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 26, 
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Nombre
              Hero(
                tag: 'empleado-nombre-${empleado.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    empleado.nombreCompleto,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Email
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      empleado.correo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cargo
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    empleado.cargo,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Estado actual con toggle switch
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: empleado.activo ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Estado del empleado',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          empleado.activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: empleado.activo ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch.adaptive(
                          value: empleado.activo,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          onChanged: (value) {
                            Navigator.pop(context);
                            _toggleEmpleadoStatus(empleado);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              const Divider(),
              
              // Opciones del empleado en forma de grid adaptativo
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    int crossAxisCount = availableWidth > 500 ? 4 : 2;
                    
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      children: [
                        _buildOptionButton(
                          icon: Icons.edit_note_rounded,
                          color: theme.colorScheme.primary,
                          label: 'Editar perfil',
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToDetail(empleado.id);
                          },
                        ),
                        _buildOptionButton(
                          icon: Icons.fingerprint,
                          color: Colors.blue,
                          label: 'Biométricos',
                          badge: empleado.hayDatosBiometricos,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToBiometrico(empleado); // Llamamos a una función que maneje la navegación
                          },
                        ),
                        _buildOptionButton(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red,
                          label: 'Eliminar',
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteConfirmation(empleado);
                          },
                        ),
                        _buildOptionButton(
                          icon: Icons.history,
                          color: Colors.amber[700]!,
                          label: 'Asistencias',
                          onTap: () {
                            Navigator.pop(context);
                            // Navigator.pushNamed(context, '/admin/empleados/asistencias', arguments: empleado);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOptionButton({
    required IconData icon,
    required Color color,
    required String label,
    bool badge = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    radius: 18,
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(Empleado empleado) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar empleado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              radius: 28,
              child: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
            ),
            const SizedBox(height: 16),
            Text('¿Estás seguro de eliminar a ${empleado.nombreCompleto}?'),
            const SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 14 : 20,
                vertical: 10,
              ),
            ),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEmpleado(empleado);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 14 : 20,
                vertical: 10,
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<Empleado> _filterEmpleados(List<Empleado> empleados) {
    if (_searchQuery.isEmpty) return empleados;
    
    return empleados.where((empleado) {
      return empleado.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             empleado.correo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             empleado.cargo.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      body: Consumer<EmpleadoController>(
        builder: (context, empleadoController, _) {
          if (empleadoController.loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('Cargando empleados...'),
                ],
              ),
            );
          }

          if (empleadoController.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar empleados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      empleadoController.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final empleados = _filterEmpleados(empleadoController.empleados);
          
          return RefreshIndicator(
            onRefresh: _loadData,
            color: theme.colorScheme.primary,
            child: CustomScrollView(
              slivers: [
                // AppBar adaptativo
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  expandedHeight: isSmallScreen ? 130 : 150,
                  collapsedHeight: 65,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: EdgeInsets.fromLTRB(16, 65, 16, isSmallScreen ? 12 : 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar empleado por nombre, correo o cargo',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Empleados',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 18 : 20,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${empleados.length} ${empleados.length == 1 ? 'empleado' : 'empleados'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Estados vacíos
                if (empleados.isEmpty && _searchQuery.isNotEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 70, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron resultados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otra búsqueda',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpiar búsqueda'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (empleados.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No hay empleados registrados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el botón + para agregar un nuevo empleado',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EmpleadoFormPage(),
                                ),
                              ).then((_) => _loadData());
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo empleado'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20, 
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                
                // Lista de empleados
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 24,
                      vertical: isSmallScreen ? 8 : 16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final empleado = empleados[index];
                          return Column(
                            children: [
                              _buildEmpleadoCard(empleado, isSmallScreen),
                              const SizedBox(height: 12), // Espacio entre tarjetas
                            ],
                          );
                        },
                        childCount: empleados.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmpleadoFormPage(),
            ),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Empleado'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  Widget _buildEmpleadoCard(Empleado empleado, bool isSmallScreen) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showEmpleadoOptions(context, empleado),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar section with initials
                  Hero(
                    tag: 'empleado-avatar-${empleado.id}',
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      radius: isSmallScreen ? 24 : 28,
                      child: Text(
                        _getInitials(empleado.nombreCompleto),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16, 
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  
                  // Info section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Hero(
                                tag: 'empleado-nombre-${empleado.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    empleado.nombreCompleto,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 15 : 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Email y cargo en fila o columna según el espacio
                        if (isSmallScreen)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(Icons.email_outlined, empleado.correo),
                              const SizedBox(height: 2),
                              _buildInfoRow(Icons.work_outline, empleado.cargo),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildInfoRow(Icons.email_outlined, empleado.correo),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: _buildInfoRow(Icons.work_outline, empleado.cargo),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Sección inferior con biométricos y switch de estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicador de biométricos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: empleado.hayDatosBiometricos 
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          size: 16,
                          color: empleado.hayDatosBiometricos ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          empleado.hayDatosBiometricos ? 'Registrado' : 'No registrado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: empleado.hayDatosBiometricos ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Switch de estado
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        empleado.activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 13,
                          color: empleado.activo ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch.adaptive(
                        value: empleado.activo,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        onChanged: (value) => _toggleEmpleadoStatus(empleado),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}