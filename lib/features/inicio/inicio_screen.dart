import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';

/// Inicio provisional tras iniciar sesión. En la semana 2 se reemplaza por
/// las categorías (clienta) y las solicitudes (profesional).
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final usuario = auth.usuario!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belleza Valiente'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${usuario.nombre}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              usuario.esProfesional
                  ? 'Aquí verás las solicitudes de tus clientas.'
                  : 'Aquí podrás elegir un servicio y pedir tu cita.',
            ),
          ],
        ),
      ),
    );
  }
}
