class Asistencia {
  final String id;
  final String empleadoId;
  final String sedeId;
  final DateTime fechaHoraEntrada;
  final DateTime? fechaHoraSalida;
  final double latitudEntrada;
  final double longitudEntrada;
  final double? latitudSalida;
  final double? longitudSalida;
  final String capturaEntrada; // Referencia a la captura facial
  final String? capturaSalida; // Referencia a la captura facial

  Asistencia({
    required this.id,
    required this.empleadoId,
    required this.sedeId,
    required this.fechaHoraEntrada,
    this.fechaHoraSalida,
    required this.latitudEntrada,
    required this.longitudEntrada,
    this.latitudSalida,
    this.longitudSalida,
    required this.capturaEntrada,
    this.capturaSalida,
  });

  bool get registroCompleto => fechaHoraSalida != null;

  Duration get tiempoTrabajado => fechaHoraSalida != null
      ? fechaHoraSalida!.difference(fechaHoraEntrada)
      : DateTime.now().difference(fechaHoraEntrada);

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'],
      empleadoId: json['empleadoId'],
      sedeId: json['sedeId'],
      fechaHoraEntrada: DateTime.parse(json['fechaHoraEntrada']),
      fechaHoraSalida: json['fechaHoraSalida'] != null
          ? DateTime.parse(json['fechaHoraSalida'])
          : null,
      latitudEntrada: json['latitudEntrada'],
      longitudEntrada: json['longitudEntrada'],
      latitudSalida: json['latitudSalida'],
      longitudSalida: json['longitudSalida'],
      capturaEntrada: json['capturaEntrada'],
      capturaSalida: json['capturaSalida'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empleadoId': empleadoId,
      'sedeId': sedeId,
      'fechaHoraEntrada': fechaHoraEntrada.toIso8601String(),
      'fechaHoraSalida': fechaHoraSalida?.toIso8601String(),
      'latitudEntrada': latitudEntrada,
      'longitudEntrada': longitudEntrada,
      'latitudSalida': latitudSalida,
      'longitudSalida': longitudSalida,
      'capturaEntrada': capturaEntrada,
      'capturaSalida': capturaSalida,
    };
  }

  Asistencia copyWith({
    String? id,
    String? empleadoId,
    String? sedeId,
    DateTime? fechaHoraEntrada,
    DateTime? fechaHoraSalida,
    double? latitudEntrada,
    double? longitudEntrada,
    double? latitudSalida,
    double? longitudSalida,
    String? capturaEntrada,
    String? capturaSalida,
  }) {
    return Asistencia(
      id: id ?? this.id,
      empleadoId: empleadoId ?? this.empleadoId,
      sedeId: sedeId ?? this.sedeId,
      fechaHoraEntrada: fechaHoraEntrada ?? this.fechaHoraEntrada,
      fechaHoraSalida: fechaHoraSalida ?? this.fechaHoraSalida,
      latitudEntrada: latitudEntrada ?? this.latitudEntrada,
      longitudEntrada: longitudEntrada ?? this.longitudEntrada,
      latitudSalida: latitudSalida ?? this.latitudSalida,
      longitudSalida: longitudSalida ?? this.longitudSalida,
      capturaEntrada: capturaEntrada ?? this.capturaEntrada,
      capturaSalida: capturaSalida ?? this.capturaSalida,  
    );
  }

  factory Asistencia.fromMap(Map<dynamic, dynamic> map) {
    return Asistencia(
      id: map['id'],
      empleadoId: map['empleadoId'],
      sedeId: map['sedeId'],
      fechaHoraEntrada: DateTime.parse(map['fechaHoraEntrada']),
      fechaHoraSalida: map['fechaHoraSalida'] != null
          ? DateTime.parse(map['fechaHoraSalida'])
          : null,
      latitudEntrada: map['latitudEntrada'],
      longitudEntrada: map['longitudEntrada'],
      latitudSalida: map['latitudSalida'],
      longitudSalida: map['longitudSalida'],
      capturaEntrada: map['capturaEntrada'],
      capturaSalida: map['capturaSalida'],
    );
  }
}