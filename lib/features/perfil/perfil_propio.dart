import '../catalogo/modelos.dart';

/// Servicio que ofrece la profesional. Si no está activo, lo tiene pausado:
/// conserva el precio pero las clientas no lo ven.
class ServicioPropio {
  const ServicioPropio({
    required this.servicioId,
    required this.nombre,
    required this.precio,
    required this.activo,
  });

  factory ServicioPropio.fromJson(Map<String, dynamic> json) => ServicioPropio(
    servicioId: json['servicio_id'] as int,
    nombre: json['nombre'] as String,
    precio: json['precio'] as int,
    activo: json['activo'] as bool? ?? true,
  );

  final int servicioId;
  final String nombre;
  final int precio;
  final bool activo;

  Map<String, Object> toJson() => {
    'servicio_id': servicioId,
    'precio': precio,
    'activo': activo,
  };
}

/// Perfil de la profesional autenticada (`/mi-perfil-profesional`).
class PerfilPropio {
  const PerfilPropio({
    required this.id,
    required this.nombre,
    required this.verificada,
    required this.activa,
    required this.calificacionPromedio,
    required this.totalCalificaciones,
    required this.zonas,
    required this.servicios,
    required this.fotos,
    this.fotoPerfil,
    this.bio,
    this.aniosExperiencia,
  });

  factory PerfilPropio.fromJson(Map<String, dynamic> json) => PerfilPropio(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    fotoPerfil: json['foto_perfil'] as String?,
    bio: json['bio'] as String?,
    aniosExperiencia: json['anios_experiencia'] as int?,
    verificada: json['verificada'] as bool? ?? false,
    activa: json['activa'] as bool? ?? false,
    calificacionPromedio: (json['calificacion_promedio'] as num).toDouble(),
    totalCalificaciones: json['total_calificaciones'] as int,
    zonas: [
      for (final z in json['zonas'] as List)
        Zona.fromJson(z as Map<String, dynamic>),
    ],
    servicios: [
      for (final s in json['servicios'] as List)
        ServicioPropio.fromJson(s as Map<String, dynamic>),
    ],
    fotos: [
      for (final f in json['fotos'] as List)
        Foto.fromJson(f as Map<String, dynamic>),
    ],
  );

  final int id;
  final String nombre;
  final String? fotoPerfil;
  final String? bio;
  final int? aniosExperiencia;

  /// Las clientas solo la ven si la fundación la verificó y no la ha pausado.
  final bool verificada;
  final bool activa;
  final double calificacionPromedio;
  final int totalCalificaciones;
  final List<Zona> zonas;
  final List<ServicioPropio> servicios;
  final List<Foto> fotos;

  PerfilPropio conFotos(List<Foto> fotos) => PerfilPropio(
    id: id,
    nombre: nombre,
    fotoPerfil: fotoPerfil,
    bio: bio,
    aniosExperiencia: aniosExperiencia,
    verificada: verificada,
    activa: activa,
    calificacionPromedio: calificacionPromedio,
    totalCalificaciones: totalCalificaciones,
    zonas: zonas,
    servicios: servicios,
    fotos: fotos,
  );
}
