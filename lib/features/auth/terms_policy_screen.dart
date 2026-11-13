import 'package:flutter/material.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Términos y Condiciones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bienvenido a Belleza Valiente. Esta plataforma conecta a clientas con profesionales de belleza independientes a domicilio en la ciudad de Cúcuta. Los acuerdos de horarios, servicios y métodos de pago se confirman conforme a las reglas operativas de la plataforma.',
            ),
            const Divider(height: 32),
            Text(
              'Política de Tratamiento de Datos (Ley 1581)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'En cumplimiento de la legislación colombiana (Ley 1581 de 2012), los datos personales recolectados (nombre, teléfono, dirección y datos de contacto) son utilizados exclusivamente para la coordinación y prestación de los servicios solicitados.\n\nEl número de teléfono y la dirección de la clienta solo se comparten con la profesional una vez la cita ha sido debidamente aceptada. Las usuarias pueden solicitar la eliminación o anonimización de su cuenta en cualquier momento desde su perfil.',
            ),
          ],
        ),
      ),
    );
  }
}