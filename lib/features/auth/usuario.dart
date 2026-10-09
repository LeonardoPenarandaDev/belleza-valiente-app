enum Rol { cliente, profesional, admin }

/// Usuario autenticado, tal como lo devuelve `UserResource` de la API.
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
    this.profesionalId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int,
    nombre: json['name'] as String,
    email: json['email'] as String,
    telefono: json['telefono'] as String?,
    rol: Rol.values.asNameMap()[json['rol']] ?? Rol.cliente,
    profesionalId: json['profesional_id'] as int?,
  );

  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final Rol rol;
  final int? profesionalId;

  bool get esProfesional => rol == Rol.profesional;
}
