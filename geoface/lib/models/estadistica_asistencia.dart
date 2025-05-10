class EstadisticaAsistencia {
  final String sedeId;
  final String? empleadoId;
  final DateTime fecha;
  final int totalEmpleados;
  final int totalAsistencias;
  final int totalAusencias;
  final int totalTardanzas;
  final double porcentajeAsistencia;

  EstadisticaAsistencia({
    required this.sedeId,
    this.empleadoId,
    required this.fecha,
    required this.totalEmpleados,
    required this.totalAsistencias,
    required this.totalAusencias,
    required this.totalTardanzas,
    required this.porcentajeAsistencia,
  });

  factory EstadisticaAsistencia.fromJson(Map<String, dynamic> json) {
    return EstadisticaAsistencia(
      sedeId: json['sedeId'],
      empleadoId: json['empleadoId'],
      fecha: DateTime.parse(json['fecha']),
      totalEmpleados: json['totalEmpleados'],
      totalAsistencias: json['totalAsistencias'],
      totalAusencias: json['totalAusencias'],
      totalTardanzas: json['totalTardanzas'],
      porcentajeAsistencia: json['porcentajeAsistencia'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sedeId': sedeId,
      'empleadoId': empleadoId,
      'fecha': fecha.toIso8601String(),
      'totalEmpleados': totalEmpleados,
      'totalAsistencias': totalAsistencias,
      'totalAusencias': totalAusencias,
      'totalTardanzas': totalTardanzas,
      'porcentajeAsistencia': porcentajeAsistencia,
    };
  }
}