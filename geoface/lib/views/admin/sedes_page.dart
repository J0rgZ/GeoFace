import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../controllers/sede_controller.dart';
import '../../controllers/empleado_controller.dart';
import '../../models/sede.dart';
import 'sede_form_page.dart';

class SedesPage extends StatefulWidget {
  const SedesPage({Key? key}) : super(key: key);

  @override
  State<SedesPage> createState() => _SedesPageState();
}

class _SedesPageState extends State<SedesPage> {
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
    final sedeController = Provider.of<SedeController>(context, listen: false);
    await sedeController.getSedes();
  }

  Future<void> _toggleSedeStatus(Sede sede) async {
    final sedeController = Provider.of<SedeController>(context, listen: false);

    // Crear una copia de la sede con el estado cambiado
    final sedeActualizada = Sede(
      id: sede.id,
      nombre: sede.nombre,
      direccion: sede.direccion,
      radioPermitido: sede.radioPermitido,
      activa: !sede.activa,
      latitud: sede.latitud,
      longitud: sede.longitud,
      fechaCreacion: sede.fechaCreacion,
    );

    final success = await sedeController.updateSede(
      id: sedeActualizada.id,
      nombre: sedeActualizada.nombre,
      direccion: sedeActualizada.direccion,
      latitud: sedeActualizada.latitud,
      longitud: sedeActualizada.longitud,
      radioPermitido: sedeActualizada.radioPermitido,
      activa: sedeActualizada.activa,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado cambiado: ${sedeActualizada.activa ? 'Activa' : 'Inactiva'}'),
          backgroundColor: sedeActualizada.activa
              ? Colors.green.shade700
              : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }


  Future<void> _deleteSede(Sede sede) async {
    final empleadoController = Provider.of<EmpleadoController>(context, listen: false);

    final empleadosSede = await empleadoController.getEmpleadosPorSede(sede.id);

    if (empleadosSede.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se puede eliminar una sede con empleados asignados.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final sedeController = Provider.of<SedeController>(context, listen: false);
    final success = await sedeController.deleteSede(sede.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sede.nombre} eliminada correctamente'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _navigateToDetail(Sede sede) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SedeFormPage(sede: sede),
      ),
    ).then((_) => _loadData());
  }

  void _showSedeOptions(BuildContext context, Sede sede) {
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
                tag: 'sede-avatar-${sede.id}',
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  radius: isSmallScreen ? 36 : 45,
                  child: Icon(
                    MdiIcons.officeBuildingMarker,
                    size: isSmallScreen ? 32 : 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Nombre
              Hero(
                tag: 'sede-nombre-${sede.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    sede.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Dirección
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        sede.direccion,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Radio permitido
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(MdiIcons.radiusOutline, size: 12, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${sede.radioPermitido}m',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                          MdiIcons.officeBuildingMarkerOutline,
                          color: sede.activa ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Estado de la sede',
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
                          sede.activa ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: sede.activa ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch.adaptive(
                          value: sede.activa,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          onChanged: (value) {
                            Navigator.pop(context);
                            _toggleSedeStatus(sede);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              const Divider(),
              
              // Opciones de la sede en forma de grid adaptativo
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
                          label: 'Editar sede',
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToDetail(sede);
                          },
                        ),
                        _buildOptionButton(
                          icon: Icons.map_outlined,
                          color: Colors.blue,
                          label: 'Ver ubicación',
                          onTap: () {
                            Navigator.pop(context);
                            // Implementar navegación a mapa
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Función de mapa por implementar')),
                            );
                          },
                        ),
                        _buildOptionButton(
                          icon: Icons.people_outline,
                          color: Colors.orange,
                          label: 'Empleados',
                          onTap: () {
                            Navigator.pop(context);
                            // Implementar navegación a empleados de la sede
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ver empleados de la sede')),
                            );
                          },
                        ),
                        _buildOptionButton(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red,
                          label: 'Eliminar',
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteConfirmation(sede);
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
  
  void _showDeleteConfirmation(Sede sede) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar sede'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              radius: 28,
              child: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
            ),
            const SizedBox(height: 16),
            Text('¿Estás seguro de eliminar la sede "${sede.nombre}"?'),
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
              _deleteSede(sede);
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

  List<Sede> _filterSedes(List<Sede> sedes) {
    if (_searchQuery.isEmpty) return sedes;
    
    return sedes.where((sede) {
      return sede.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             sede.direccion.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      body: Consumer<SedeController>(
        builder: (context, sedeController, _) {
          if (sedeController.loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      fit: BoxFit.contain,
                    ),
                  ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      sedeController.errorMessage!,
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

          final sedes = _filterSedes(sedeController.sedes);
          
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
                            hintText: 'Buscar sede por nombre o dirección',
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
                              'Sedes',
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
                                '${sedes.length} ${sedes.length == 1 ? 'sede' : 'sedes'}',
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
                if (sedes.isEmpty && _searchQuery.isNotEmpty)
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
                else if (sedes.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(MdiIcons.officeBuildingMarkerOutline, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No hay sedes registradas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el botón + para agregar una nueva sede',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SedeFormPage(),
                                ),
                              ).then((_) => _loadData());
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Nueva sede'),
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
                
                // Lista de sedes
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 24,
                      vertical: isSmallScreen ? 8 : 16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sede = sedes[index];
                          return Column(
                            children: [
                              _buildSedeCard(sede, isSmallScreen),
                              const SizedBox(height: 12), // Espacio entre tarjetas
                            ],
                          );
                        },
                        childCount: sedes.length,
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
              builder: (context) => const SedeFormPage(),
            ),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Sede'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  Widget _buildSedeCard(Sede sede, bool isSmallScreen) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showSedeOptions(context, sede),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar section with icon
                  Hero(
                    tag: 'sede-avatar-${sede.id}',
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      radius: isSmallScreen ? 24 : 28,
                      child: Icon(
                        MdiIcons.officeBuildingMarker,
                        size: isSmallScreen ? 20 : 24,
                        color: theme.colorScheme.primary,
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
                                tag: 'sede-nombre-${sede.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    sede.nombre,
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
                        
                        const SizedBox(height: 4),// Dirección
                        _buildInfoRow(Icons.location_on_outlined, sede.direccion),
                        
                        const SizedBox(height: 2),
                        
                        // Radio permitido
                        _buildInfoRow(MdiIcons.radiusOutline, '${sede.radioPermitido}m de radio'),
                      ],
                    ),
                  ),
                  
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sede.activa 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sede.activa ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sede.activa ? Icons.check_circle : Icons.cancel,
                          size: 12,
                          color: sede.activa ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sede.activa ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: sede.activa ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Divider
              if (isSmallScreen) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 8),
              ],
              
              // Action buttons row
              if (isSmallScreen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Editar',
                      color: theme.colorScheme.primary,
                      onTap: () => _navigateToDetail(sede),
                    ),
                    _buildActionButton(
                      icon: Icons.map_outlined,
                      label: 'Ubicación',
                      color: Colors.blue,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Función de mapa por implementar')),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: sede.activa ? Icons.pause : Icons.play_arrow,
                      label: sede.activa ? 'Pausar' : 'Activar',
                      color: sede.activa ? Colors.orange : Colors.green,
                      onTap: () => _toggleSedeStatus(sede),
                    ),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Eliminar',
                      color: Colors.red,
                      onTap: () => _showDeleteConfirmation(sede),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}