class Sede {
  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final int radioPermitido; // Radio en metros para marcar asistencia
  final bool activa;
  final DateTime fechaCreacion;
  final DateTime? fechaModificacion;

  Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.radioPermitido,
    required this.activa,
    required this.fechaCreacion,
    this.fechaModificacion,
  });

  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      radioPermitido: json['radioPermitido'] ?? 100,
      activa: json['activa'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'radioPermitido': radioPermitido,
      'activa': activa,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  Sede copyWith({
    String? id,
    String? nombre,
    String? direccion,
    double? latitud,
    double? longitud,
    int? radioPermitido,
    bool? activa,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Sede(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      radioPermitido: radioPermitido ?? this.radioPermitido,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? DateTime.now(),
    );
  }
}