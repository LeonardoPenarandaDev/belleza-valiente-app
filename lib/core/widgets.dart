import 'package:flutter/material.dart';

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
