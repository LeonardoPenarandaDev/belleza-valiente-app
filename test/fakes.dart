import 'package:belleza_valiente_app/core/api_client.dart';
import 'package:belleza_valiente_app/features/catalogo/catalogo_repository.dart';
import 'package:belleza_valiente_app/features/catalogo/modelos.dart';
import 'package:belleza_valiente_app/features/perfil/mi_perfil_repository.dart';
import 'package:belleza_valiente_app/features/perfil/perfil_propio.dart';
import 'package:belleza_valiente_app/features/reservas/reserva.dart';
import 'package:belleza_valiente_app/features/reservas/reservas_repository.dart';
import 'package:flutter/foundation.dart';

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

Reserva reservaDePrueba({
  int id = 1,
  EstadoReserva estado = EstadoReserva.solicitada,
  bool vencida = false,
  Set<AccionReserva> acciones = const {},
  String? direccion,
  String? clienteTelefono,
  String? motivo,
  String? canceladaPor,
  DateTime? fechaHora,
  MetodoPago? metodoPago,
  int? valorPagado,
  int? comision,
  CalificacionCita? calificacion,
}) => Reserva(
  id: id,
  estado: estado,
  vencida: vencida,
  // 15 de octubre de 2026, 3:00 p. m. en Colombia.
  fechaHora: fechaHora ?? DateTime.utc(2026, 10, 15, 20),
  duracionMinutos: 45,
  precio: 26000,
  servicio: 'Manicura tradicional',
  zona: 'Centro',
  profesionalId: 10,
  profesionalNombre: 'Laura Gómez',
  clienteNombre: 'Ana Pérez',
  acciones: acciones,
  direccion: direccion,
  clienteTelefono: clienteTelefono,
  motivo: motivo,
  canceladaPor: canceladaPor,
  metodoPago: metodoPago,
  valorPagado: valorPagado,
  comision: comision,
  calificacion: calificacion,
);

/// Reservas falsas: guardan lo que la app envía y responden sin la API.
class ReservasFalso implements ReservasRepository {
  List<Reserva> lista = [];
  ApiException? errorAccion;

  Map<String, Object?>? pedida;
  final ejecutadas = <(AccionReserva, int, String?)>[];
  final pagos = <(int, MetodoPago, int)>[];
  final calificaciones = <(int, int, String?)>[];

  /// Respuesta de una acción (por defecto, la cita con el nuevo estado).
  Reserva Function(AccionReserva, Reserva)? resultado;

  @override
  final cambios = ValueNotifier<int>(0);

  @override
  final citasPedidas = ValueNotifier<int>(0);

  @override
  Future<List<Reserva>> listar() async => List.of(lista);

  @override
  Future<Reserva> pedir({
    required int profesionalId,
    required int servicioId,
    required int zonaId,
    required String fechaHora,
    required String direccion,
    String? notas,
  }) async {
    pedida = {
      'profesional_id': profesionalId,
      'servicio_id': servicioId,
      'zona_id': zonaId,
      'fecha_hora': fechaHora,
      'direccion': direccion,
      'notas': notas,
    };
    final nueva = reservaDePrueba(id: 99, acciones: {AccionReserva.cancelar});
    lista = [...lista, nueva];
    cambios.value++;
    citasPedidas.value++;
    return nueva;
  }

  @override
  Future<Reserva> ejecutar(
    AccionReserva accion,
    int reservaId, {
    String? motivo,
  }) async {
    ejecutadas.add((accion, reservaId, motivo));
    if (errorAccion != null) throw errorAccion!;

    final actual = lista.firstWhere((r) => r.id == reservaId);
    final nueva =
        resultado?.call(accion, actual) ??
        reservaDePrueba(
          id: reservaId,
          estado: switch (accion) {
            AccionReserva.aceptar => EstadoReserva.aceptada,
            AccionReserva.rechazar => EstadoReserva.rechazada,
            AccionReserva.cancelar => EstadoReserva.cancelada,
            AccionReserva.completar ||
            AccionReserva.calificar => throw UnsupportedError('$accion'),
          },
          acciones: accion == AccionReserva.aceptar
              ? {AccionReserva.cancelar}
              : const {},
          direccion: accion == AccionReserva.aceptar ? 'Calle 10 # 5-20' : null,
          clienteTelefono: accion == AccionReserva.aceptar
              ? '573001234567'
              : null,
          motivo: motivo,
          canceladaPor: accion == AccionReserva.cancelar ? 'profesional' : null,
        );
    lista = [for (final r in lista) r.id == reservaId ? nueva : r];
    cambios.value++;
    return nueva;
  }

  @override
  Future<Reserva> completar(
    int reservaId, {
    required MetodoPago metodo,
    required int valor,
  }) async {
    pagos.add((reservaId, metodo, valor));
    if (errorAccion != null) throw errorAccion!;
    return _reemplazar(
      reservaDePrueba(
        id: reservaId,
        estado: EstadoReserva.completada,
        metodoPago: metodo,
        valorPagado: valor,
        comision: (valor * 0.15).round(),
      ),
    );
  }

  @override
  Future<Reserva> calificar(
    int reservaId, {
    required int estrellas,
    String? comentario,
  }) async {
    calificaciones.add((reservaId, estrellas, comentario));
    if (errorAccion != null) throw errorAccion!;
    return _reemplazar(
      reservaDePrueba(
        id: reservaId,
        estado: EstadoReserva.completada,
        calificacion: CalificacionCita(
          estrellas: estrellas,
          comentario: comentario,
        ),
      ),
    );
  }

  Reserva _reemplazar(Reserva nueva) {
    lista = [for (final r in lista) r.id == nueva.id ? nueva : r];
    cambios.value++;
    return nueva;
  }
}

PerfilPropio perfilPropioDePrueba({
  bool verificada = true,
  bool activa = true,
  List<Foto> fotos = const [],
}) => PerfilPropio(
  id: 10,
  nombre: 'Laura Gómez',
  bio: 'Manicurista con 5 años de experiencia.',
  aniosExperiencia: 5,
  verificada: verificada,
  activa: activa,
  calificacionPromedio: 4.8,
  totalCalificaciones: 12,
  zonas: const [centro],
  servicios: const [
    ServicioPropio(
      servicioId: 7,
      nombre: 'Manicura tradicional',
      precio: 26000,
      activo: true,
    ),
  ],
  fotos: fotos,
);

/// Perfil propio falso: guarda lo que la app envía y responde sin la API.
class MiPerfilFalso implements MiPerfilRepository {
  MiPerfilFalso([PerfilPropio? perfil])
    : perfil = perfil ?? perfilPropioDePrueba();

  PerfilPropio perfil;
  ApiException? errorGuardar;

  Map<String, Object?>? datos;
  List<int>? zonas;
  List<ServicioPropio>? servicios;
  final subidas = <String>[];
  final borradas = <int>[];

  @override
  Future<PerfilPropio> ver() async => perfil;

  @override
  Future<PerfilPropio> guardarDatos({
    String? bio,
    int? aniosExperiencia,
  }) async {
    datos = {'bio': bio, 'anios_experiencia': aniosExperiencia};
    if (errorGuardar != null) throw errorGuardar!;
    return perfil = PerfilPropio(
      id: perfil.id,
      nombre: perfil.nombre,
      bio: bio,
      aniosExperiencia: aniosExperiencia,
      verificada: perfil.verificada,
      activa: perfil.activa,
      calificacionPromedio: perfil.calificacionPromedio,
      totalCalificaciones: perfil.totalCalificaciones,
      zonas: perfil.zonas,
      servicios: perfil.servicios,
      fotos: perfil.fotos,
    );
  }

  @override
  Future<PerfilPropio> guardarZonas(List<int> zonaIds) async {
    zonas = zonaIds;
    if (errorGuardar != null) throw errorGuardar!;
    return perfil;
  }

  @override
  Future<PerfilPropio> guardarServicios(List<ServicioPropio> servicios) async {
    this.servicios = servicios;
    if (errorGuardar != null) throw errorGuardar!;
    return perfil;
  }

  @override
  Future<Foto> subirFoto(String ruta) async {
    subidas.add(ruta);
    return Foto(id: 50 + subidas.length, url: 'http://fotos.test/$ruta');
  }

  @override
  Future<void> borrarFoto(int fotoId) async => borradas.add(fotoId);
}
