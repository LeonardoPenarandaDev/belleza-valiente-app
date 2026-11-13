/// Modelos del catálogo y de las profesionales, tal como los devuelve la API.
library;

class Zona {
  const Zona({required this.id, required this.nombre});

  factory Zona.fromJson(Map<String, dynamic> json) =>
      Zona(id: json['id'] as int, nombre: json['nombre'] as String);

  final int id;
  final String nombre;
}

class Servicio {
  const Servicio({
    required this.id,
    required this.categoriaId,
    required this.nombre,
    required this.duracionMinutos,
    this.descripcion,
    this.precioReferencia,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
    id: json['id'] as int,
    categoriaId: json['categoria_id'] as int,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    duracionMinutos: json['duracion_minutos'] as int,
    precioReferencia: json['precio_referencia'] as int?,
  );

  final int id;
  final int categoriaId;
  final String nombre;
  final String? descripcion;
  final int duracionMinutos;
  final int? precioReferencia;
}

class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.servicios,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    slug: json['slug'] as String,
    servicios: _lista(json['servicios'], Servicio.fromJson),
  );

  final int id;
  final String nombre;
  final String slug;
  final List<Servicio> servicios;
}

/// Profesional en la lista de resultados.
class ProfesionalResumen {
  const ProfesionalResumen({
    required this.id,
    required this.nombre,
    required this.calificacionPromedio,
    required this.totalCalificaciones,
    required this.zonas,
    this.bio,
    this.aniosExperiencia,
    this.fotoPrincipal,
    this.precio,
  });

  factory ProfesionalResumen.fromJson(Map<String, dynamic> json) =>
      ProfesionalResumen(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        bio: json['bio'] as String?,
        aniosExperiencia: json['anios_experiencia'] as int?,
        calificacionPromedio: (json['calificacion_promedio'] as num).toDouble(),
        totalCalificaciones: json['total_calificaciones'] as int,
        fotoPrincipal: json['foto_principal'] as String?,
        precio: json['precio'] as int?,
        zonas: _lista(json['zonas'], Zona.fromJson),
      );

  final int id;
  final String nombre;
  final String? bio;
  final int? aniosExperiencia;
  final double calificacionPromedio;
  final int totalCalificaciones;
  final String? fotoPrincipal;

  /// Precio del servicio buscado.
  final int? precio;
  final List<Zona> zonas;
}

/// Una página de resultados de `/profesionales`.
class PaginaProfesionales {
  const PaginaProfesionales({
    required this.profesionales,
    required this.pagina,
    required this.ultimaPagina,
  });

  factory PaginaProfesionales.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return PaginaProfesionales(
      profesionales: _lista(json['data'], ProfesionalResumen.fromJson),
      pagina: meta['current_page'] as int,
      ultimaPagina: meta['last_page'] as int,
    );
  }

  final List<ProfesionalResumen> profesionales;
  final int pagina;
  final int ultimaPagina;

  bool get hayMas => pagina < ultimaPagina;
}

/// Servicio que ofrece una profesional, con su precio.
class ServicioOfrecido {
  const ServicioOfrecido({
    required this.servicioId,
    required this.categoriaId,
    required this.nombre,
    required this.duracionMinutos,
    required this.precio,
  });

  factory ServicioOfrecido.fromJson(Map<String, dynamic> json) =>
      ServicioOfrecido(
        servicioId: json['servicio_id'] as int,
        categoriaId: json['categoria_id'] as int,
        nombre: json['nombre'] as String,
        duracionMinutos: json['duracion_minutos'] as int,
        precio: json['precio'] as int,
      );

  final int servicioId;
  final int categoriaId;
  final String nombre;
  final int duracionMinutos;
  final int precio;
}

class Foto {
  const Foto({required this.id, required this.url});

  factory Foto.fromJson(Map<String, dynamic> json) =>
      Foto(id: json['id'] as int, url: json['url'] as String);

  final int id;
  final String url;
}

class Calificacion {
  const Calificacion({
    required this.estrellas,
    required this.fecha,
    this.comentario,
  });

  factory Calificacion.fromJson(Map<String, dynamic> json) => Calificacion(
    estrellas: json['estrellas'] as int,
    comentario: json['comentario'] as String?,
    fecha: DateTime.parse(json['fecha'] as String),
  );

  final int estrellas;
  final String? comentario;
  final DateTime fecha;
}

/// Perfil público de una profesional (`/profesionales/{id}`).
class PerfilProfesional {
  const PerfilProfesional({
    required this.id,
    required this.nombre,
    required this.calificacionPromedio,
    required this.totalCalificaciones,
    required this.zonas,
    required this.servicios,
    required this.fotos,
    required this.calificaciones,
    this.fotoPerfil,
    this.bio,
    this.aniosExperiencia,
  });

  factory PerfilProfesional.fromJson(Map<String, dynamic> json) =>
      PerfilProfesional(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        fotoPerfil: json['foto_perfil'] as String?,
        bio: json['bio'] as String?,
        aniosExperiencia: json['anios_experiencia'] as int?,
        calificacionPromedio: (json['calificacion_promedio'] as num).toDouble(),
        totalCalificaciones: json['total_calificaciones'] as int,
        zonas: _lista(json['zonas'], Zona.fromJson),
        servicios: _lista(json['servicios'], ServicioOfrecido.fromJson),
        fotos: _lista(json['fotos'], Foto.fromJson),
        calificaciones: _lista(json['calificaciones'], Calificacion.fromJson),
      );

  final int id;
  final String nombre;
  final String? fotoPerfil;
  final String? bio;
  final int? aniosExperiencia;
  final double calificacionPromedio;
  final int totalCalificaciones;
  final List<Zona> zonas;
  final List<ServicioOfrecido> servicios;
  final List<Foto> fotos;
  final List<Calificacion> calificaciones;
}

List<T> _lista<T>(Object? json, T Function(Map<String, dynamic>) desde) => [
  for (final item in (json as List?) ?? const [])
    desde(item as Map<String, dynamic>),
];
