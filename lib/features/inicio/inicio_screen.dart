import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../catalogo/categorias_screen.dart';

/// Pantalla de inicio según el rol: la clienta ve las categorías y la
/// profesional, por ahora, un inicio provisional (sus solicitudes llegan en la semana 3).
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.of(context).usuario!;

    return usuario.esProfesional
        ? const _InicioProfesional()
        : const CategoriasScreen();
  }
}

class _InicioProfesional extends StatelessWidget {
  const _InicioProfesional();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

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
              'Hola, ${auth.usuario!.nombre}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Aquí verás las solicitudes de tus clientas.'),
          ],
        ),
      ),
    );
  }
}
