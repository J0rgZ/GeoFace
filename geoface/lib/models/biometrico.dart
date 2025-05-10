class Biometrico {
  final String id;
  final String empleadoId;
  final String datoFacial;
  final DateTime fechaRegistro;
  final DateTime? fechaActualizacion;

  Biometrico({
    required this.id,
    required this.empleadoId,
    required this.datoFacial,
    required this.fechaRegistro,
    this.fechaActualizacion,
  });

  factory Biometrico.fromJson(Map<String, dynamic> json) {
    return Biometrico(
      id: json['id'],
      empleadoId: json['empleadoId'],
      datoFacial: json['datoFacial'],
      fechaRegistro: DateTime.parse(json['fechaRegistro']),
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empleadoId': empleadoId,
      'datoFacial': datoFacial,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }
}