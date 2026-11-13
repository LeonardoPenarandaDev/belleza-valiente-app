enum Rol { cliente, profesional, admin }

/// Usuario autenticado, tal como lo devuelve `UserResource` de la API.
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
    this.fotoPerfil,
    this.profesionalId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int,
    nombre: json['name'] as String,
    email: json['email'] as String,
    telefono: json['telefono'] as String?,
    fotoPerfil: json['foto_perfil'] as String?,
    rol: Rol.values.asNameMap()[json['rol']] ?? Rol.cliente,
    profesionalId: json['profesional_id'] as int?,
  );

  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? fotoPerfil;
  final Rol rol;
  final int? profesionalId;

  Usuario copyWith({
    int? id,
    String? nombre,
    String? email,
    String? telefono,
    String? fotoPerfil,
    bool borrarFoto = false,
    Rol? rol,
    int? profesionalId,
  }) => Usuario(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    email: email ?? this.email,
    telefono: telefono ?? this.telefono,
    fotoPerfil: borrarFoto ? null : (fotoPerfil ?? this.fotoPerfil),
    rol: rol ?? this.rol,
    profesionalId: profesionalId ?? this.profesionalId,
  );

  bool get esProfesional => rol == Rol.profesional;
}
