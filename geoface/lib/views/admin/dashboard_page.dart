// views/admin/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/sede_controller.dart';
import '../../controllers/empleado_controller.dart';
import '../../controllers/asistencia_controller.dart';
import '../../models/sede.dart';
import '../../models/empleado.dart';
import '../../models/asistencia.dart';
import '../../utils/date_utils.dart' as date_utils;

class DashboardPage extends StatefulWidget {
  final void Function(int)? onNavigateToTab;

  const DashboardPage({Key? key, this.onNavigateToTab}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final sedeController = Provider.of<SedeController>(context, listen: false);
    final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    final asistenciaController = Provider.of<AsistenciaController>(context, listen: false);
    
    await sedeController.getSedes();
    await empleadoController.getEmpleados();
    await asistenciaController.getAllAsistencias(); // Nuevo método necesario para obtener todas las asistencias
  }

  // Calcula las asistencias del día actual
  int _getAsistenciasHoy(List<Asistencia> asistencias) {
    final hoy = DateTime.now();
    return asistencias.where((a) => date_utils.isSameDay(a.fechaHoraEntrada, hoy)).length;
  }

  // Calcula las asistencias por sede en el día actual
  Map<String, int> _getAsistenciasPorSedeHoy(List<Asistencia> asistencias, List<Sede> sedes) {
    final hoy = DateTime.now();
    final Map<String, int> asistenciasPorSede = {};
    
    // Inicializar el mapa con todas las sedes en 0
    for (var sede in sedes) {
      asistenciasPorSede[sede.id] = 0;
    }
    
    // Contar asistencias de hoy por sede
    for (var asistencia in asistencias) {
      if (date_utils.isSameDay(asistencia.fechaHoraEntrada, hoy)) {
        asistenciasPorSede[asistencia.sedeId] = (asistenciasPorSede[asistencia.sedeId] ?? 0) + 1;
      }
    }
    
    return asistenciasPorSede;
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si estamos en tema oscuro o claro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer3<SedeController, EmpleadoController, AsistenciaController>(
          builder: (context, sedeController, empleadoController, asistenciaController, _) {
            final sedes = sedeController.sedes;
            final empleados = empleadoController.empleados;
            final asistencias = asistenciaController.asistencias;
            
            if (sedeController.loading || empleadoController.loading || asistenciaController.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (sedeController.errorMessage != null) {
              return Center(child: Text(sedeController.errorMessage!));
            }

            if (empleadoController.errorMessage != null) {
              return Center(child: Text(empleadoController.errorMessage!));
            }
            
            if (asistenciaController.errorMessage != null) {
              return Center(child: Text(asistenciaController.errorMessage!));
            }

            final sedesActivas = sedes.where((sede) => sede.activa).length;
            final empleadosActivos = empleados.where((emp) => emp.activo).length;
            final totalSedes = sedes.length;
            final totalEmpleados = empleados.length;
            
            // Nuevas métricas para asistencias
            final asistenciasHoy = _getAsistenciasHoy(asistencias);
            final asistenciasPorSedeHoy = _getAsistenciasPorSedeHoy(asistencias, sedes);

            return LayoutBuilder(
              builder: (context, constraints) {
                // Determinar si estamos en un dispositivo móvil o tablet/desktop
                final isSmallScreen = constraints.maxWidth < 600;
                
                // Ajustar aspectRatio según el tamaño de la pantalla
                final cardAspectRatio = isSmallScreen ? 1.1 : 1.5;
      
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      _buildDashboardHeader(),
                      
                      const SizedBox(height: 16),
                      
                      // Tarjetas de estadísticas principales - VERSIÓN RESPONSIVA
                      LayoutBuilder(
                        builder: (context, cardConstraints) {
                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // Siempre 2 columnas
                              childAspectRatio: cardAspectRatio,
                              crossAxisSpacing: 0,
                              mainAxisSpacing: 0,
                            ),
                            itemCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              switch (index) {
                                case 0:
                                  return _buildStatCard(
                                    title: 'Sedes Activas',
                                    value: sedesActivas.toString(),
                                    total: totalSedes.toString(),
                                    icon: Icons.location_city,
                                    color: Colors.blue,
                                    isDarkMode: isDarkMode,
                                  );
                                case 1:
                                  return _buildStatCard(
                                    title: 'Empleados Activos',
                                    value: empleadosActivos.toString(),
                                    total: totalEmpleados.toString(),
                                    icon: Icons.people,
                                    color: Colors.green,
                                    isDarkMode: isDarkMode,
                                  );
                                case 2:
                                  return _buildStatCard(
                                    title: 'Asistencias Hoy',
                                    value: asistenciasHoy.toString(),
                                    total: empleadosActivos.toString(),
                                    icon: Icons.calendar_today,
                                    color: Colors.orange,
                                    isDarkMode: isDarkMode,
                                  );
                                case 3:
                                  return _buildStatCard(
                                    title: 'Tasa de Asistencia',
                                    value: '${empleadosActivos > 0 ? (asistenciasHoy / empleadosActivos * 100).toStringAsFixed(0) : 0}%',
                                    description: 'Hoy',
                                    icon: Icons.analytics,
                                    color: Colors.cyan,
                                    isDarkMode: isDarkMode,
                                  );
                                default:
                                  return const SizedBox();
                              }
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      
                      // Sección de asistencias por sede hoy
                      _buildSectionHeader(
                        title: 'Asistencias Hoy por Sede',
                        actionLabel: sedes.length > 5 ? 'Ver detalle' : null,
                        onAction: sedes.length > 5 ? () {
                          widget.onNavigateToTab?.call(3); // Asumo que 3 es el índice para "Asistencias"
                        } : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Gráfico de asistencias por sede
                      _buildAsistenciasSedeChart(asistenciasPorSedeHoy, sedes, isDarkMode),
                      
                      const SizedBox(height: 24),
                      
                      // Sección de sedes
                      _buildSectionHeader(
                        title: 'Sedes',
                        actionLabel: sedes.length > 5 ? 'Ver todas' : null,
                        onAction: sedes.length > 5 ? () {
                          widget.onNavigateToTab?.call(1); // 1 es el índice de "Sedes"
                        } : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Lista de sedes con asistencias de hoy
                      ...sedes.take(5).map((sede) => _buildSedeCard(
                        sede, 
                        empleados, 
                        asistenciasPorSedeHoy[sede.id] ?? 0,
                        isDarkMode,
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Resumen de datos
                      _buildSummaryCard(
                        totalSedes: totalSedes,
                        sedesActivas: sedesActivas,
                        totalEmpleados: totalEmpleados,
                        empleadosActivos: empleadosActivos,
                        asistenciasHoy: asistenciasHoy,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                );
              }
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'Estadisticas',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.visibility),
              label: Text(actionLabel),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? total,
    String? description,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    // Ajustar color según tema oscuro/claro
    final cardColor = isDarkMode 
        ? Color.alphaBlend(color.withOpacity(0.2), Colors.grey[900]!) 
        : color.withOpacity(0.1);
    
    final borderColor = isDarkMode 
        ? color.withOpacity(0.3) 
        : color.withOpacity(0.2);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reducido de 16 a 12
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24), // Reducido de 28 a 24
                if (total != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reducido
                    decoration: BoxDecoration(
                      color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total: $total',
                      style: TextStyle(
                        fontSize: 10, // Reducido de 12 a 10
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4), // Reducido de Spacer() a altura fija
            Text(
              value,
              style: TextStyle(
                fontSize: 24, // Reducido de 28 a 24
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4), // Reducido
            Text(
              title,
              style: TextStyle(
                fontSize: 13, // Reducido de 14 a 13
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (description != null)
              Text(
                description,
                style: TextStyle(
                  fontSize: 11, // Reducido de 12 a 11
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistenciasSedeChart(
    Map<String, int> asistenciasPorSede, 
    List<Sede> sedes,
    bool isDarkMode,
  ) {
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    
    // Filtrar solo sedes con asistencias
    final sedesConAsistencias = sedes
        .where((sede) => (asistenciasPorSede[sede.id] ?? 0) > 0)
        .toList();
    
    if (sedesConAsistencias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No hay asistencias registradas hoy',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ...sedesConAsistencias.take(6).map((sede) {
                final asistencias = asistenciasPorSede[sede.id] ?? 0;
                // Calcular altura máxima de la barra (160 es el espacio disponible)
                final maxHeight = 160.0;
                final height = asistencias > 0 
                    ? (asistencias / sedesConAsistencias.map((s) => asistenciasPorSede[s.id] ?? 0).reduce((a, b) => a > b ? a : b)) * maxHeight
                    : 0.0;
                
                return _buildBarChartItem(
                  label: sede.nombre.split(' ').first, // Mostrar solo la primera palabra
                  value: asistencias,
                  barWidth: constraints.maxWidth / (sedesConAsistencias.length * 2),
                  barHeight: height,
                  color: sede.activa ? activeColor : inactiveColor!,
                  isDarkMode: isDarkMode,
                );
              }),
            ],
          );
        }
      ),
    );
  }

  Widget _buildBarChartItem({
    required String label,
    required int value,
    required double barWidth,
    required double barHeight,
    required Color color,
    required bool isDarkMode,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: barWidth,
          height: barHeight > 0 ? barHeight : 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: barWidth * 1.5,
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSedeCard(
    Sede sede, 
    List<Empleado> allEmpleados, 
    int asistenciasHoy,
    bool isDarkMode,
  ) {
    final empleadosSede = allEmpleados.where((emp) => emp.sedeId == sede.id).toList();
    final empleadosActivos = empleadosSede.where((emp) => emp.activo).length;
    final porcentajeActivos = empleadosSede.isNotEmpty 
        ? (empleadosActivos / empleadosSede.length * 100).toStringAsFixed(0) 
        : '0';
    final porcentajeAsistencias = empleadosActivos > 0 
        ? (asistenciasHoy / empleadosActivos * 100).toStringAsFixed(0) 
        : '0';

    // Colores para tema oscuro/claro
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final activeColor = sede.activa ? Colors.green : Colors.red;
    final activeBgColor = activeColor.withOpacity(isDarkMode ? 0.2 : 0.1);
    final activeTextColor = isDarkMode ? activeColor.withOpacity(0.9) : activeColor.withOpacity(0.8);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      color: cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Indicador de estado
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Nombre de la sede
                Expanded(
                  child: Text(
                    sede.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Estado de la sede
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    sede.activa ? 'Activa' : 'Inactiva',
                    style: TextStyle(
                      color: activeTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dirección de la sede
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined, 
                  size: 16, 
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sede.direccion,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Datos de empleados y asistencias
            Row(
              children: [
                Expanded(
                  child: _buildSedeDataItem(
                    title: 'Empleados',
                    value: '${empleadosSede.length} totales',
                    isDarkMode: isDarkMode,
                  ),
                ),
                Expanded(
                  child: _buildSedeDataItem(
                    title: 'Activos',
                    value: '$empleadosActivos ($porcentajeActivos%)',
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Nueva fila para asistencias
            Row(
              children: [
                Expanded(
                  child: _buildSedeDataItem(
                    title: 'Asistencias Hoy',
                    value: '$asistenciasHoy',
                    isDarkMode: isDarkMode,
                  ),
                ),
                Expanded(
                  child: _buildSedeDataItem(
                    title: 'Tasa Asistencia',
                    value: '$porcentajeAsistencias%',
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSedeDataItem({
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required int totalSedes,
    required int sedesActivas,
    required int totalEmpleados,
    required int empleadosActivos,
    required int asistenciasHoy,
    required bool isDarkMode,
  }) {
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.grey[100];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final _ = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              label: 'Total de sedes:',
              value: totalSedes.toString(),
              isDarkMode: isDarkMode,
            ),
            _buildSummaryRow(
              label: 'Sedes activas:',
              value: sedesActivas.toString(),
              isDarkMode: isDarkMode,
            ),
            _buildSummaryRow(
              label: 'Total de empleados:',
              value: totalEmpleados.toString(),
              isDarkMode: isDarkMode,
            ),
            _buildSummaryRow(
              label: 'Empleados activos:',
              value: empleadosActivos.toString(),
              isDarkMode: isDarkMode,
            ),
            _buildSummaryRow(
              label: 'Asistencias registradas hoy:',
              value: asistenciasHoy.toString(),
              isDarkMode: isDarkMode,
            ),
            _buildSummaryRow(
              label: 'Porcentaje de asistencia hoy:',
              value: empleadosActivos > 0 
                  ? '${(asistenciasHoy / empleadosActivos * 100).toStringAsFixed(1)}%' 
                  : '0%',
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}