import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nombreUsuario;
  final String correo;
  final String tipoUsuario; // ADMIN, EMPLEADO
  final String? empleadoId; // Null si es ADMIN
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? fechaUltimoAcceso;

  Usuario({
    required this.id,
    required this.nombreUsuario,
    required this.correo,
    required this.tipoUsuario,
    this.empleadoId,
    required this.activo,
    required this.fechaCreacion,
    this.fechaUltimoAcceso,
  });

  bool get isAdmin => tipoUsuario == 'ADMIN';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? '',
      nombreUsuario: json['nombreUsuario'] ?? '',
      correo: json['correo'] ?? '',
      tipoUsuario: json['tipoUsuario'] ?? '',
      empleadoId: json['empleadoId'],
      activo: json['activo'] ?? false,
      // Manejo de Timestamp para fechaCreacion
      fechaCreacion: json['fechaCreacion'] is Timestamp 
          ? (json['fechaCreacion'] as Timestamp).toDate()
          : (json['fechaCreacion'] != null && json['fechaCreacion'] is String && json['fechaCreacion'] != '')
              ? DateTime.parse(json['fechaCreacion'])
              : DateTime.now(),
      // Manejo de Timestamp para fechaUltimoAcceso
      fechaUltimoAcceso: json['fechaUltimoAcceso'] is Timestamp
          ? (json['fechaUltimoAcceso'] as Timestamp).toDate()
          : (json['fechaUltimoAcceso'] != null && json['fechaUltimoAcceso'] is String && json['fechaUltimoAcceso'] != '')
              ? DateTime.parse(json['fechaUltimoAcceso'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreUsuario': nombreUsuario,
      'correo': correo,
      'tipoUsuario': tipoUsuario,
      'empleadoId': empleadoId,
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaUltimoAcceso': fechaUltimoAcceso?.toIso8601String(),
    };
  }
}