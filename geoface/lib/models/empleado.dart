class Empleado {
  final String id;
  final String nombre;
  final String apellidos;
  final String correo;
  final String cargo;
  final String sedeId;
  final String dni;  // Nuevo campo DNI
  final String celular;  // Nuevo campo celular
  final bool hayDatosBiometricos;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? fechaModificacion;

  Empleado({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.cargo,
    required this.sedeId,
    required this.dni,  // Requerido y único
    required this.celular,  // Requerido
    required this.hayDatosBiometricos,
    required this.activo,
    required this.fechaCreacion,
    this.fechaModificacion,
  });

  String get nombreCompleto => '$nombre $apellidos';

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id'],
      nombre: json['nombre'],
      apellidos: json['apellidos'],
      correo: json['correo'],
      cargo: json['cargo'],
      sedeId: json['sedeId'],
      dni: json['dni'],
      celular: json['celular'],
      hayDatosBiometricos: json['hayDatosBiometricos'] ?? false,
      activo: json['activo'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : null,
    );
  }

  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado(
      id: map['id'],
      nombre: map['nombre'],
      apellidos: map['apellidos'],
      correo: map['correo'],
      cargo: map['cargo'],
      sedeId: map['sedeId'],
      dni: map['dni'],
      celular: map['celular'],
      hayDatosBiometricos: map['hayDatosBiometricos'] ?? false,
      activo: map['activo'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaModificacion: map['fechaModificacion'] != null
          ? DateTime.parse(map['fechaModificacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'correo': correo,
      'cargo': cargo,
      'sedeId': sedeId,
      'dni': dni,
      'celular': celular,
      'hayDatosBiometricos': hayDatosBiometricos,
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  Empleado copyWith({
    String? id,
    String? nombre,
    String? apellidos,
    String? correo,
    String? cargo,
    String? sedeId,
    String? dni,
    String? celular,
    bool? hayDatosBiometricos,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Empleado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      correo: correo ?? this.correo,
      cargo: cargo ?? this.cargo,
      sedeId: sedeId ?? this.sedeId,
      dni: dni ?? this.dni,
      celular: celular ?? this.celular,
      hayDatosBiometricos: hayDatosBiometricos ?? this.hayDatosBiometricos,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? DateTime.now(),
    );
  }
}