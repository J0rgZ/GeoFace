class Biometrico {
  final String id;
  final String empleadoId;
  final String datoFacial; // URL de la imagen en Firebase Storage
  final String fechaRegistro; // Almacenado como string ISO8601
  final String? fechaActualizacion; // Almacenado como string ISO8601

  Biometrico({
    required this.id,
    required this.empleadoId,
    required this.datoFacial,
    required this.fechaRegistro,
    this.fechaActualizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empleadoId': empleadoId,
      'datoFacial': datoFacial,
      'fechaRegistro': fechaRegistro,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  factory Biometrico.fromMap(Map<String, dynamic> map) {
    return Biometrico(
      id: map['id'],
      empleadoId: map['empleadoId'],
      datoFacial: map['datoFacial'],
      fechaRegistro: map['fechaRegistro'],
      fechaActualizacion: map['fechaActualizacion'],
    );
  }
}