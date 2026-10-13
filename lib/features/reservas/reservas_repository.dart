import 'package:flutter/widgets.dart';

import '../../core/api_client.dart';
import 'reserva.dart';

/// Endpoints de las citas (`/reservas`).
class ReservasRepository {
  ReservasRepository(this._api);

  final ApiClient _api;

  /// Aumenta cada vez que una cita cambia desde la app, para que las listas
  /// abiertas se actualicen.
  final cambios = ValueNotifier<int>(0);

  /// Aumenta cuando la clienta pide una cita, para llevarla a "Mis citas".
  final citasPedidas = ValueNotifier<int>(0);

  Future<List<Reserva>> listar() async {
    final datos = await _api.get('/reservas');
    return [
      for (final r in datos['data'] as List)
        Reserva.fromJson(r as Map<String, dynamic>),
    ];
  }

  /// [fechaHora] en el formato de la API (ver `isoColombia`).
  Future<Reserva> pedir({
    required int profesionalId,
    required int servicioId,
    required int zonaId,
    required String fechaHora,
    required String direccion,
    String? notas,
  }) async {
    final datos = await _api.post(
      '/reservas',
      datos: {
        'profesional_id': profesionalId,
        'servicio_id': servicioId,
        'zona_id': zonaId,
        'fecha_hora': fechaHora,
        'direccion': direccion,
        if (notas != null && notas.isNotEmpty) 'notas': notas,
      },
    );
    cambios.value++;
    citasPedidas.value++;
    return _reserva(datos);
  }

  Future<Reserva> ejecutar(
    AccionReserva accion,
    int reservaId, {
    String? motivo,
  }) async {
    final datos = await _api.post(
      '/reservas/$reservaId/${accion.name}',
      datos: {if (motivo != null && motivo.isNotEmpty) 'motivo': motivo},
    );
    cambios.value++;
    return _reserva(datos);
  }

  Reserva _reserva(dynamic datos) =>
      Reserva.fromJson(datos['data'] as Map<String, dynamic>);
}

/// Da acceso al [ReservasRepository]: `ReservasScope.of(context)`.
class ReservasScope extends InheritedWidget {
  const ReservasScope({super.key, required this.repo, required super.child});

  final ReservasRepository repo;

  /// El repositorio no cambia; se puede llamar desde `initState`.
  static ReservasRepository of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ReservasScope>()!.repo;

  @override
  bool updateShouldNotify(ReservasScope oldWidget) => false;
}
