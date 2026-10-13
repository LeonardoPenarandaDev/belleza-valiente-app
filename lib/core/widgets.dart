import 'package:flutter/material.dart';

import 'theme.dart';

/// Nombre de la app en las pantallas de acceso.
class EncabezadoMarca extends StatelessWidget {
  const EncabezadoMarca({super.key});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(Icons.spa, size: 64, color: colores.secondary),
        const SizedBox(height: 12),
        Text(
          'Belleza Valiente',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colores.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Servicios de belleza a domicilio en Cúcuta',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class MensajeError extends StatelessWidget {
  const MensajeError(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colores.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(mensaje, style: TextStyle(color: colores.onErrorContainer)),
    );
  }
}

/// Pantalla de error al cargar datos, con botón para reintentar.
class ErrorAlCargar extends StatelessWidget {
  const ErrorAlCargar({
    super.key,
    required this.error,
    required this.onReintentar,
  });

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 16),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje centrado cuando una lista no tiene resultados.
class SinResultados extends StatelessWidget {
  const SinResultados(this.mensaje, {super.key, this.icono = Icons.search_off});

  final String mensaje;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Foto de la profesional, o sus iniciales si no tiene fotos.
class AvatarProfesional extends StatelessWidget {
  const AvatarProfesional({
    super.key,
    required this.nombre,
    this.foto,
    this.radio = 28,
  });

  final String nombre;
  final String? foto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final iniciales = nombre
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: radio,
      backgroundColor: colores.secondaryContainer,
      foregroundImage: foto == null ? null : NetworkImage(foto!),
      onForegroundImageError: foto == null ? null : (_, _) {},
      child: Text(
        iniciales,
        style: TextStyle(color: colores.onSecondaryContainer),
      ),
    );
  }
}

/// "★ 4,8 (12)" o "Nueva" si aún no tiene calificaciones.
class CalificacionResumen extends StatelessWidget {
  const CalificacionResumen({
    super.key,
    required this.promedio,
    required this.total,
  });

  final double promedio;
  final int total;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium;
    if (total == 0) return Text('Nueva', style: estilo);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 18, color: Marca.dorado),
        const SizedBox(width: 2),
        Text(
          '${promedio.toStringAsFixed(1).replaceAll('.', ',')} ($total)',
          style: estilo,
        ),
      ],
    );
  }
}

class CargandoEnBoton extends StatelessWidget {
  const CargandoEnBoton({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

String? validarCorreo(String? valor) {
  final correo = valor?.trim() ?? '';
  if (correo.isEmpty) return 'Escribe tu correo.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
    return 'Escribe un correo válido.';
  }
  return null;
}

/// Acepta "300 123 4567", "3001234567" o "+57 300 123 4567". El servidor lo normaliza.
String? validarCelular(String? valor) {
  var digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
  if (digitos.length == 12 && digitos.startsWith('57')) {
    digitos = digitos.substring(2);
  }
  if (digitos.isEmpty) return 'Escribe tu celular.';
  if (digitos.length != 10 || !digitos.startsWith('3')) {
    return 'Escribe un celular colombiano de 10 dígitos.';
  }
  return null;
}
