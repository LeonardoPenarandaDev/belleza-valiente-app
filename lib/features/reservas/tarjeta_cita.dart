import 'package:flutter/material.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import 'reserva.dart';

/// Una cita en la lista. La clienta ve a la profesional y viceversa.
class TarjetaCita extends StatelessWidget {
  const TarjetaCita({
    super.key,
    required this.reserva,
    required this.paraProfesional,
    required this.onAccion,
    this.ocupada = false,
  });

  final Reserva reserva;
  final bool paraProfesional;
  final void Function(AccionReserva accion) onAccion;

  /// Hay una acción en curso sobre esta cita: se desactivan los botones.
  final bool ocupada;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final r = reserva;
    final contraparte = paraProfesional ? r.clienteNombre : r.profesionalNombre;
    final telefono = paraProfesional
        ? r.clienteTelefono
        : r.profesionalTelefono;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _EtiquetaEstado(r),
                const Spacer(),
                Text(
                  formatoPesos(r.precio),
                  style: textos.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(r.servicio, style: textos.titleMedium),
            Text(contraparte),
            const SizedBox(height: 8),
            _Dato(
              Icons.event,
              '${formatoFechaHora(r.fechaHora)} · '
              '${formatoDuracion(r.duracionMinutos)}',
            ),
            _Dato(
              Icons.place_outlined,
              r.direccion == null ? r.zona : '${r.direccion} (${r.zona})',
            ),
            if (telefono != null)
              _Dato(Icons.phone_outlined, _formatoCelular(telefono)),
            if (r.notas != null && r.notas!.isNotEmpty)
              _Dato(Icons.notes, r.notas!),
            if (paraProfesional &&
                r.estado == EstadoReserva.solicitada &&
                !r.vencida)
              const _Dato(
                Icons.lock_outline,
                'Verás la dirección y el celular cuando aceptes la cita.',
              ),
            if (_textoMotivo() case final texto?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(texto, style: textos.bodySmall),
              ),
            if (r.acciones.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Botones(
                acciones: r.acciones,
                ocupada: ocupada,
                onAccion: onAccion,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _textoMotivo() {
    final r = reserva;
    final motivo = (r.motivo == null || r.motivo!.isEmpty)
        ? ''
        : ': ${r.motivo}';

    return switch (r.estado) {
      EstadoReserva.rechazada => 'Rechazada$motivo',
      EstadoReserva.cancelada => switch (r.canceladaPor) {
        'cliente' =>
          paraProfesional
              ? 'La clienta canceló la cita$motivo'
              : 'Cancelaste esta cita$motivo',
        'profesional' =>
          paraProfesional
              ? 'Cancelaste esta cita$motivo'
              : 'La profesional canceló la cita$motivo',
        _ => 'Cita cancelada$motivo',
      },
      EstadoReserva.solicitada when r.vencida =>
        paraProfesional ? 'La fecha ya pasó: ya no se puede aceptar.' : 'La profesional no respondió a tiempo. Puedes pedir una nueva cita.',
      EstadoReserva.solicitada when !paraProfesional =>
        'Esperando que la profesional acepte.',
      _ => null,
    };
  }
}

/// "573001234567" → "300 123 4567".
String _formatoCelular(String telefono) {
  final d = telefono.startsWith('57') ? telefono.substring(2) : telefono;
  if (d.length != 10) return d;
  return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
}

class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado(this.reserva);

  final Reserva reserva;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final estado = reserva.estado;
    final vencida = reserva.vencida;

    final (fondo, texto) = switch (estado) {
      _ when vencida => (
        colores.surfaceContainerHighest,
        colores.onSurfaceVariant,
      ),
      EstadoReserva.solicitada => (
        colores.secondaryContainer,
        colores.onSecondaryContainer,
      ),
      EstadoReserva.aceptada => (
        const Color(0xFFD7F2DC),
        const Color(0xFF1B5E20),
      ),
      EstadoReserva.completada => (
        colores.primaryContainer,
        colores.onPrimaryContainer,
      ),
      _ => (colores.surfaceContainerHighest, colores.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(vencida ? Icons.history : estado.icono, size: 16, color: texto),
          const SizedBox(width: 4),
          Text(
            vencida ? 'Vencida' : estado.etiqueta,
            style: TextStyle(color: texto, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.texto);

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _Botones extends StatelessWidget {
  const _Botones({
    required this.acciones,
    required this.ocupada,
    required this.onAccion,
  });

  final Set<AccionReserva> acciones;
  final bool ocupada;
  final void Function(AccionReserva) onAccion;

  @override
  Widget build(BuildContext context) {
    VoidCallback? al(AccionReserva a) => ocupada ? null : () => onAccion(a);

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (acciones.contains(AccionReserva.cancelar))
          OutlinedButton(
            onPressed: al(AccionReserva.cancelar),
            child: const Text('Cancelar cita'),
          ),
        if (acciones.contains(AccionReserva.rechazar))
          OutlinedButton(
            onPressed: al(AccionReserva.rechazar),
            child: const Text('Rechazar'),
          ),
        if (acciones.contains(AccionReserva.aceptar))
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: al(AccionReserva.aceptar),
            child: const Text('Aceptar'),
          ),
      ],
    );
  }
}
