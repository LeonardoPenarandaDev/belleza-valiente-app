import 'package:belleza_valiente_app/core/api_client.dart';
import 'package:belleza_valiente_app/features/catalogo/catalogo_repository.dart';
import 'package:belleza_valiente_app/features/catalogo/modelos.dart';

const unas = Categoria(
  id: 2,
  nombre: 'Uñas',
  slug: 'unas',
  servicios: [
    Servicio(
      id: 7,
      categoriaId: 2,
      nombre: 'Manicura tradicional',
      duracionMinutos: 45,
      precioReferencia: 25000,
    ),
  ],
);

const cabello = Categoria(
  id: 1,
  nombre: 'Cabello',
  slug: 'cabello',
  servicios: [],
);

const centro = Zona(id: 1, nombre: 'Centro');
const caobos = Zona(id: 2, nombre: 'Caobos');

/// Zona sin profesionales.
const atalaya = Zona(id: 3, nombre: 'Atalaya');

const laura = ProfesionalResumen(
  id: 10,
  nombre: 'Laura Gómez',
  calificacionPromedio: 4.8,
  totalCalificaciones: 12,
  zonas: [centro, caobos],
  precio: 26000,
);

final perfilLaura = PerfilProfesional(
  id: 10,
  nombre: 'Laura Gómez',
  bio: 'Manicurista con 5 años de experiencia.',
  aniosExperiencia: 5,
  calificacionPromedio: 4.8,
  totalCalificaciones: 12,
  zonas: const [centro, caobos],
  servicios: const [
    ServicioOfrecido(
      servicioId: 7,
      categoriaId: 2,
      nombre: 'Manicura tradicional',
      duracionMinutos: 45,
      precio: 26000,
    ),
    ServicioOfrecido(
      servicioId: 8,
      categoriaId: 2,
      nombre: 'Uñas en gel',
      duracionMinutos: 90,
      precio: 45000,
    ),
  ],
  fotos: const [],
  calificaciones: [
    Calificacion(
      estrellas: 5,
      comentario: 'Muy puntual y cuidadosa.',
      fecha: DateTime(2026, 10, 1),
    ),
  ],
);

/// Catálogo falso: responde sin llamar a la API y registra las búsquedas.
class CatalogoFalso implements CatalogoRepository {
  List<Categoria> categoriasResp = const [cabello, unas];
  List<ProfesionalResumen> profesionalesResp = const [laura];
  ApiException? errorProfesionales;

  /// Zonas con las que se buscó, en orden.
  final busquedas = <int?>[];

  @override
  Future<List<Categoria>> categorias({bool recargar = false}) async =>
      categoriasResp;

  @override
  Future<List<Zona>> zonas() async => const [atalaya, caobos, centro];

  @override
  Future<PaginaProfesionales> profesionales({
    int? servicioId,
    int? zonaId,
    int pagina = 1,
  }) async {
    busquedas.add(zonaId);
    if (errorProfesionales != null) throw errorProfesionales!;
    return PaginaProfesionales(
      profesionales: zonaId == atalaya.id ? const [] : profesionalesResp,
      pagina: 1,
      ultimaPagina: 1,
    );
  }

  @override
  Future<PerfilProfesional> perfil(int id) async => perfilLaura;
}
