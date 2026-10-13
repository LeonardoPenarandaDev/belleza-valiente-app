import 'package:flutter/material.dart';

enum EstadoReserva {
  solicitada('Solicitada', Icons.schedule),
  aceptada('Aceptada', Icons.check_circle),
  rechazada('Rechazada', Icons.block),
  completada('Completada', Icons.done_all),
  cancelada('Cancelada', Icons.cancel);

  const EstadoReserva(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;

  bool get abierta => this == solicitada || this == aceptada;
}

/// Acciones que el servidor permite sobre una cita (`acciones` en la API).
enum AccionReserva { aceptar, rechazar, cancelar }

/// Cita tal como la devuelve `ReservaResource`. El servidor ya oculta el
/// teléfono y la dirección cuando no corresponde verlos.
class Reserva {
  const Reserva({
    required this.id,
    required this.estado,
    required this.vencida,
    required this.fechaHora,
    required this.duracionMinutos,
    required this.precio,
    required this.servicio,
    required this.zona,
    required this.profesionalId,
    required this.profesionalNombre,
    required this.clienteNombre,
    required this.acciones,
    this.direccion,
    this.notas,
    this.motivo,
    this.canceladaPor,
    this.profesionalTelefono,
    this.clienteTelefono,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final profesional = json['profesional'] as Map<String, dynamic>;
    final cliente = json['cliente'] as Map<String, dynamic>;
    final acciones = AccionReserva.values.asNameMap();

    return Reserva(
      id: json['id'] as int,
      estado:
          EstadoReserva.values.asNameMap()[json['estado']] ??
          EstadoReserva.cancelada,
      vencida: json['vencida'] as bool? ?? false,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      duracionMinutos: json['duracion_minutos'] as int,
      precio: json['precio'] as int,
      direccion: json['direccion'] as String?,
      notas: json['notas'] as String?,
      motivo: json['motivo'] as String?,
      canceladaPor: json['cancelada_por'] as String?,
      servicio: (json['servicio'] as Map<String, dynamic>)['nombre'] as String,
      zona: (json['zona'] as Map<String, dynamic>)['nombre'] as String,
      profesionalId: profesional['id'] as int,
      profesionalNombre: profesional['nombre'] as String,
      profesionalTelefono: profesional['telefono'] as String?,
      clienteNombre: cliente['nombre'] as String,
      clienteTelefono: cliente['telefono'] as String?,
      acciones: {
        for (final a in (json['acciones'] as List? ?? const [])) ?acciones[a],
      },
    );
  }

  final int id;
  final EstadoReserva estado;

  /// Solicitada con la fecha ya pasada: ya no se puede aceptar.
  final bool vencida;
  final DateTime fechaHora;
  final int duracionMinutos;
  final int precio;
  final String? direccion;
  final String? notas;

  /// Motivo del rechazo o de la cancelación.
  final String? motivo;

  /// 'cliente' o 'profesional'.
  final String? canceladaPor;
  final String servicio;
  final String zona;
  final int profesionalId;
  final String profesionalNombre;
  final String? profesionalTelefono;
  final String clienteNombre;
  final String? clienteTelefono;
  final Set<AccionReserva> acciones;

  /// Pendiente de atender: solicitada (aunque esté vencida) o aceptada.
  bool get proxima => estado.abierta;
}
