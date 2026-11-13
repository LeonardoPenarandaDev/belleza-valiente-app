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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Marca.doradoClaro,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Marca.dorado.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.spa, size: 52, color: Marca.doradoOscuro),
        ),
        const SizedBox(height: 16),
        Text(
          'Belleza Valiente',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colores.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Servicios de belleza a domicilio en Cúcuta',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Marca.textoSecundario,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colores.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colores.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: colores.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: colores.onErrorContainer, fontSize: 13.5),
            ),
          ),
        ],
      ),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Marca.textoPrincipal),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reintentar'),
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 44, color: Marca.textoSecundario),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Marca.textoSecundario,
                height: 1.3,
              ),
            ),
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
    final iniciales = nombre
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Marca.dorado, Marca.azulMarino],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        radius: radio,
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundImage: foto == null ? null : NetworkImage(foto!),
        onForegroundImageError: foto == null ? null : (_, _) {},
        child: Text(
          iniciales,
          style: TextStyle(
            color: Marca.azulMarino,
            fontWeight: FontWeight.bold,
            fontSize: radio * 0.75,
          ),
        ),
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
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
