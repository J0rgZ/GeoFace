import 'package:flutter/material.dart';
import 'package:geoface/controllers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/usuario.dart';
import '../../routes.dart';
import 'dashboard_page.dart';
import 'sedes_page.dart';
import 'empleados_page.dart';
import 'reportes_page.dart';
import 'crear_administrador.dart';
import 'asignar_usuario.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({Key? key}) : super(key: key);

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Cache de páginas para mejorar rendimiento
  late final List<Widget> _pageCache;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Inicializar cache de páginas
    _pageCache = [
      DashboardPage(onNavigateToTab: _onItemTapped),
      const SedesPage(),
      const EmpleadosPage(),
      const ReportesPage(),
    ];
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _tabController.animateTo(index);
      });
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          return AlertDialog(
            title: const Text('Cambiar Contraseña'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña actual',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su contraseña actual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su nueva contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirme su nueva contraseña';
                      }
                      if (value != newPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                // ignore: dead_code
                onPressed: isLoading ? null : () {
                  // Liberar controladores antes de cerrar para evitar fugas de memoria
                  currentPasswordController.dispose();
                  newPasswordController.dispose();
                  confirmPasswordController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    // ignore: dead_code
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            isLoading = true;
                          });
                          
                          final authController = Provider.of<AuthController>(context, listen: false);
                          try {
                            await authController.changePassword(
                              currentPasswordController.text,
                              newPasswordController.text
                            );
                            
                            if (context.mounted) {
                              // Liberar controladores
                              currentPasswordController.dispose();
                              newPasswordController.dispose();
                              confirmPasswordController.dispose();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Contraseña actualizada correctamente')),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.toString()}')),
                              );
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Está seguro que desea cerrar la sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authController = Provider.of<AuthController>(context, listen: false);
              await authController.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddAdmin() {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CrearAdministradorPage(),
      ),
    );
  }

  void _navigateToAssignUser() {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AsignarUsuarioPage(),
      ),
    );
  }

  void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Colores personalizados desde el tema
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final unselectedColor = isDarkMode 
        ? const Color(0xFF9E9E9E) 
        : const Color(0xFF9E9E9E);
    final containerColor = isDarkMode
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.primaryContainer;

    // Obtener datos del usuario actual
    final authController = Provider.of<AuthController>(context);
    final Usuario? currentUser = authController.currentUser;
    final String userName = currentUser?.nombreUsuario ?? "Administrador";
    final String userEmail = currentUser?.correo ?? "admin@geoface.com";

    final List<String> _titles = [
      'Dashboard',
      'Sedes',
      'Empleados',
      'Reportes',
    ];

    final List<IconData> _icons = [
      Icons.dashboard_rounded,
      Icons.location_city_rounded,
      Icons.people_rounded,
      Icons.assessment_rounded,
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            _titles[_selectedIndex],
            key: ValueKey<String>(_titles[_selectedIndex]),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          // Botón de cambio de tema
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: isDarkMode ? 'Tema Claro' : 'Tema Oscuro',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      drawer: _buildDrawer(
        primaryColor: primaryColor,
        isDarkMode: isDarkMode,
        userName: userName, 
        userEmail: userEmail,
        titles: _titles,
        icons: _icons,
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Desactivar deslizamiento
        children: _pageCache,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(
        surfaceColor: surfaceColor,
        primaryColor: primaryColor,
        containerColor: containerColor,
        unselectedColor: unselectedColor,
        icons: _icons,
        titles: _titles,
        isDarkMode: isDarkMode,
      ),
    );
  }
  
  Widget _buildDrawer({
    required Color primaryColor,
    required bool isDarkMode,
    required String userName,
    required String userEmail,
    required List<String> titles,
    required List<IconData> icons,
  }) {
    return Drawer(
      elevation: 10,
      child: SafeArea(
        child: Column(
          children: [
            // Header con información del usuario
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                color: isDarkMode ? Colors.black : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: TextStyle(
                                color: isDarkMode ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Menú de navegación principal
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'MENÚ PRINCIPAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  // Items de navegación principal
                  for (int i = 0; i < titles.length; i++)
                    _buildDrawerItem(
                      icon: icons[i],
                      title: titles[i],
                      isSelected: _selectedIndex == i,
                      onTap: () {
                        _onItemTapped(i);
                        Navigator.pop(context);
                      },
                      primaryColor: primaryColor,
                    ),
                  
                  const Divider(height: 32),
                  
                  // Sección de Administración de Usuarios
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'ADMINISTRACIÓN DE USUARIOS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Agregar Administrador',
                    isSelected: false,
                    onTap: _navigateToAddAdmin,
                    primaryColor: primaryColor,
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.assignment_ind,
                    title: 'Asignar Usuario a Empleado',
                    isSelected: false,
                    onTap: _navigateToAssignUser,
                    primaryColor: primaryColor,
                  ),
                  
                  const Divider(height: 32),
                  
                  // Sección de Configuración Personal
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'CONFIGURACIÓN PERSONAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.password,
                    title: 'Cambiar Contraseña',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showChangePasswordDialog();
                    },
                    primaryColor: primaryColor,
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.dark_mode,
                    title: isDarkMode ? 'Cambiar a Tema Claro' : 'Cambiar a Tema Oscuro',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _toggleTheme();
                    },
                    primaryColor: primaryColor,
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmation();
                    },
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
            
            // Pie del Drawer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black12 : Colors.grey[100],
                border: Border(
                  top: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.face_retouching_natural,
                    color: primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GeoFace',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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

  Widget _buildBottomNavigationBar({
    required Color surfaceColor,
    required Color primaryColor,
    required Color containerColor,
    required Color unselectedColor,
    required List<IconData> icons,
    required List<String> titles,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(icons.length, (index) {
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () => _onItemTapped(index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? containerColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: isSelected ? 4 : 0,
                          width: isSelected ? 24 : 0,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Icon(
                          icons[index],
                          color: isSelected ? primaryColor : unselectedColor,
                          size: isSelected ? 26 : 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          titles[index],
                          style: TextStyle(
                            color: isSelected ? primaryColor : unselectedColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : null,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? primaryColor : null,
            fontWeight: isSelected ? FontWeight.bold : null,
            fontSize: 15,
          ),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        dense: true,
        onTap: onTap,
        selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
    );
  }
}