import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
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
    final enviar = await _pedirDatos(reserva, accion);
    if (enviar == null || !mounted) return;

    setState(() => _ocupadas.add(reserva.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await enviar();
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
    AccionReserva.completar => 'Cita completada.',
    AccionReserva.calificar => '¡Gracias por tu calificación!',
  };

  /// Pide confirmación y los datos de la acción (motivo, pago o calificación).
  /// Devuelve la llamada a la API, o null si la usuaria se arrepiente.
  Future<Future<Reserva> Function()?> _pedirDatos(
    Reserva r,
    AccionReserva accion,
  ) async {
    switch (accion) {
      case AccionReserva.completar:
        final pago = await showDialog<_Pago>(
          context: context,
          builder: (_) => _DialogoCompletar(reserva: r),
        );
        if (pago == null) return null;
        return () =>
            _repo.completar(r.id, metodo: pago.metodo, valor: pago.valor);

      case AccionReserva.calificar:
        final calificacion = await showDialog<CalificacionCita>(
          context: context,
          builder: (_) => _DialogoCalificar(reserva: r),
        );
        if (calificacion == null) return null;
        return () => _repo.calificar(
          r.id,
          estrellas: calificacion.estrellas,
          comentario: calificacion.comentario,
        );

      case AccionReserva.aceptar:
      case AccionReserva.rechazar:
      case AccionReserva.cancelar:
        final confirmacion = await _confirmar(r, accion);
        if (confirmacion == null) return null;
        return () => _repo.ejecutar(accion, r.id, motivo: confirmacion.motivo);
    }
  }

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
        _ => _DialogoConfirmar(
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

class _Pago {
  const _Pago(this.metodo, this.valor);

  final MetodoPago metodo;
  final int valor;
}

/// La profesional registra cómo y cuánto le pagaron (el pago es por fuera de
/// la app). La comisión la calcula el servidor.
class _DialogoCompletar extends StatefulWidget {
  const _DialogoCompletar({required this.reserva});

  final Reserva reserva;

  @override
  State<_DialogoCompletar> createState() => _DialogoCompletarState();
}

class _DialogoCompletarState extends State<_DialogoCompletar> {
  late final _valor = TextEditingController(text: '${widget.reserva.precio}');
  MetodoPago? _metodo;
  String? _errorMetodo;
  String? _errorValor;

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  void _aceptar() {
    final valor = int.tryParse(_valor.text);
    setState(() {
      _errorMetodo = _metodo == null ? 'Elige cómo te pagaron.' : null;
      _errorValor = (valor == null || valor < 1)
          ? 'Escribe el valor que te pagaron.'
          : null;
    });
    if (_errorMetodo != null || _errorValor != null) return;
    Navigator.of(context).pop(_Pago(_metodo!, valor!));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final colores = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('¿Cómo te pagaron?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r.servicio} con ${r.clienteNombre}. '
              'Precio acordado: ${formatoPesos(r.precio)}.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in MetodoPago.values)
                  ChoiceChip(
                    label: Text(m.etiqueta),
                    selected: _metodo == m,
                    onSelected: (_) => setState(() {
                      _metodo = m;
                      _errorMetodo = null;
                    }),
                  ),
              ],
            ),
            if (_errorMetodo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMetodo!,
                  style: TextStyle(color: colores.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _valor,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: InputDecoration(
                labelText: 'Valor pagado',
                prefixText: r'$ ',
                helperText: 'En pesos, sin puntos.',
                errorText: _errorValor,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: _aceptar,
          child: const Text('Completar'),
        ),
      ],
    );
  }
}

/// La clienta califica con estrellas y un comentario opcional.
class _DialogoCalificar extends StatefulWidget {
  const _DialogoCalificar({required this.reserva});

  final Reserva reserva;

  @override
  State<_DialogoCalificar> createState() => _DialogoCalificarState();
}

class _DialogoCalificarState extends State<_DialogoCalificar> {
  final _comentario = TextEditingController();
  int _estrellas = 0;
  String? _error;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (_estrellas == 0) {
      setState(() => _error = 'Elige de 1 a 5 estrellas.');
      return;
    }
    final comentario = _comentario.text.trim();
    Navigator.of(context).pop(
      CalificacionCita(
        estrellas: _estrellas,
        comentario: comentario.isEmpty ? null : comentario,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;

    return AlertDialog(
      title: Text('¿Cómo te fue con ${r.profesionalNombre}?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.servicio),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: i == 1 ? '1 estrella' : '$i estrellas',
                    onPressed: () => setState(() {
                      _estrellas = i;
                      _error = null;
                    }),
                    icon: Icon(
                      i <= _estrellas ? Icons.star : Icons.star_border,
                      size: 32,
                      color: Marca.dorado,
                    ),
                  ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentario,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                helperText: 'Aparecerá en el perfil de la profesional.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: _aceptar,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
