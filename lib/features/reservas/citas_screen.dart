import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../../core/widgets.dart';
import '../auth/boton_cerrar_sesion.dart';
import 'reserva.dart';
import 'reservas_repository.dart';
import 'tarjeta_cita.dart';

/// Mis citas (clienta) o Solicitudes y agenda (profesional).
///
/// Sin notificaciones push en el MVP, la lista se refresca al abrirla, al
/// deslizar hacia abajo y cada 30 segundos (plan, sección 1.2).
class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key, required this.paraProfesional});

  final bool paraProfesional;

  static const intervaloRefresco = Duration(seconds: 30);

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _Pestana {
  const _Pestana(
    this.titulo,
    this.vacia,
    this.filtro, {
    this.ascendente = false,
  });

  final String titulo;
  final String vacia;
  final bool Function(Reserva) filtro;

  /// Las próximas van de la más cercana a la más lejana; el historial, al revés.
  final bool ascendente;
}

class _CitasScreenState extends State<CitasScreen> {
  late final ReservasRepository _repo;
  Timer? _temporizador;

  List<Reserva>? _reservas;
  Object? _error;

  /// Citas con una acción en curso.
  final _ocupadas = <int>{};

  List<_Pestana> get _pestanas => widget.paraProfesional
      ? [
          _Pestana(
            'Solicitudes',
            'No tienes solicitudes nuevas.',
            (r) => r.estado == EstadoReserva.solicitada,
            ascendente: true,
          ),
          _Pestana(
            'Agenda',
            'No tienes citas aceptadas.',
            (r) => r.estado == EstadoReserva.aceptada,
            ascendente: true,
          ),
          _Pestana(
            'Historial',
            'Aún no hay citas en tu historial.',
            (r) => !r.proxima,
          ),
        ]
      : [
          _Pestana(
            'Próximas',
            'No tienes citas próximas. Elige un servicio en Inicio para pedir una.',
            (r) => r.proxima,
            ascendente: true,
          ),
          _Pestana(
            'Historial',
            'Aún no hay citas en tu historial.',
            (r) => !r.proxima,
          ),
        ];

  @override
  void initState() {
    super.initState();
    _repo = ReservasScope.of(context);
    _repo.cambios.addListener(_cargar);
    _cargar();
    _temporizador = Timer.periodic(
      CitasScreen.intervaloRefresco,
      (_) => _cargar(),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _repo.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final reservas = await _repo.listar();
      if (mounted) {
        setState(() {
          _reservas = reservas;
          _error = null;
        });
      }
    } catch (e) {
      // Si ya hay una lista, se conserva: un refresco fallido no la borra.
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _ejecutar(Reserva reserva, AccionReserva accion) async {
    final confirmacion = await _confirmar(reserva, accion);
    if (confirmacion == null || !mounted) return;

    setState(() => _ocupadas.add(reserva.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.ejecutar(accion, reserva.id, motivo: confirmacion.motivo);
      messenger.showSnackBar(SnackBar(content: Text(_exito(accion))));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
      await _cargar();
    } finally {
      if (mounted) setState(() => _ocupadas.remove(reserva.id));
    }
  }

  String _exito(AccionReserva accion) => switch (accion) {
    AccionReserva.aceptar =>
      'Cita aceptada. Ya puedes ver la dirección y el celular.',
    AccionReserva.rechazar => 'Solicitud rechazada.',
    AccionReserva.cancelar => 'Cita cancelada.',
  };

  /// Pide confirmación y, si aplica, el motivo. Devuelve null si se arrepiente.
  Future<_Confirmacion?> _confirmar(Reserva r, AccionReserva accion) {
    final cuando = formatoFechaHora(r.fechaHora);

    return showDialog<_Confirmacion>(
      context: context,
      builder: (_) => switch (accion) {
        AccionReserva.aceptar => _DialogoConfirmar(
          titulo: '¿Aceptar la cita?',
          mensaje: '${r.servicio} con ${r.clienteNombre}, el $cuando.',
          confirmar: 'Aceptar',
        ),
        AccionReserva.rechazar => _DialogoConfirmar(
          titulo: '¿Rechazar la solicitud?',
          mensaje: '${r.servicio} con ${r.clienteNombre}, el $cuando.',
          confirmar: 'Rechazar',
          pideMotivo: true,
          ayudaMotivo: 'Motivo (opcional). La clienta lo verá.',
        ),
        AccionReserva.cancelar when widget.paraProfesional => _DialogoConfirmar(
          titulo: '¿Cancelar la cita?',
          mensaje:
              'Ya la habías aceptado. Avísale a ${r.clienteNombre} el motivo.',
          confirmar: 'Cancelar cita',
          pideMotivo: true,
          motivoObligatorio: true,
          ayudaMotivo: 'Motivo (obligatorio). La clienta lo verá.',
        ),
        AccionReserva.cancelar => _DialogoConfirmar(
          titulo: '¿Cancelar la cita?',
          mensaje: '${r.servicio} con ${r.profesionalNombre}, el $cuando.',
          confirmar: 'Cancelar cita',
          pideMotivo: true,
          ayudaMotivo: 'Motivo (opcional). La profesional lo verá.',
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pestanas = _pestanas;

    return DefaultTabController(
      length: pestanas.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis citas'),
          actions: const [BotonCerrarSesion()],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: [for (final p in pestanas) Tab(text: _conConteo(p))],
          ),
        ),
        body: _cuerpo(pestanas),
      ),
    );
  }

  /// "Solicitudes (2)" para que la profesional vea de un vistazo las pendientes.
  String _conConteo(_Pestana p) {
    final reservas = _reservas;
    if (reservas == null || p.titulo == 'Historial') return p.titulo;
    final n = reservas.where(p.filtro).length;
    return n == 0 ? p.titulo : '${p.titulo} ($n)';
  }

  Widget _cuerpo(List<_Pestana> pestanas) {
    final reservas = _reservas;
    if (reservas == null) {
      if (_error != null) {
        return ErrorAlCargar(error: _error!, onReintentar: _cargar);
      }
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      children: [for (final p in pestanas) _lista(p, reservas)],
    );
  }

  Widget _lista(_Pestana pestana, List<Reserva> todas) {
    final reservas = todas.where(pestana.filtro).toList()
      ..sort(
        (a, b) => pestana.ascendente
            ? a.fechaHora.compareTo(b.fechaHora)
            : b.fechaHora.compareTo(a.fechaHora),
      );

    return RefreshIndicator(
      onRefresh: _cargar,
      child: reservas.isEmpty
          // Desplazable para que "deslizar hacia abajo" funcione aun vacía.
          ? ListView(
              children: [
                const SizedBox(height: 80),
                SinResultados(pestana.vacia, icono: Icons.event_available),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reservas.length,
              itemBuilder: (context, i) => TarjetaCita(
                reserva: reservas[i],
                paraProfesional: widget.paraProfesional,
                ocupada: _ocupadas.contains(reservas[i].id),
                onAccion: (accion) => _ejecutar(reservas[i], accion),
              ),
            ),
    );
  }
}

class _Confirmacion {
  const _Confirmacion(this.motivo);

  final String? motivo;
}

class _DialogoConfirmar extends StatefulWidget {
  const _DialogoConfirmar({
    required this.titulo,
    required this.mensaje,
    required this.confirmar,
    this.pideMotivo = false,
    this.motivoObligatorio = false,
    this.ayudaMotivo,
  });

  final String titulo;
  final String mensaje;
  final String confirmar;
  final bool pideMotivo;
  final bool motivoObligatorio;
  final String? ayudaMotivo;

  @override
  State<_DialogoConfirmar> createState() => _DialogoConfirmarState();
}

class _DialogoConfirmarState extends State<_DialogoConfirmar> {
  final _motivo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _aceptar() {
    final motivo = _motivo.text.trim();
    if (widget.motivoObligatorio && motivo.isEmpty) {
      setState(() => _error = 'Escribe el motivo.');
      return;
    }
    Navigator.of(context).pop(_Confirmacion(motivo.isEmpty ? null : motivo));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.mensaje),
          if (widget.pideMotivo) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _motivo,
              maxLength: 255,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: widget.ayudaMotivo,
                errorText: _error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: _aceptar,
          child: Text(widget.confirmar),
        ),
      ],
    );
  }
}
