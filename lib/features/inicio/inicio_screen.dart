import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../catalogo/categorias_screen.dart';
import '../reservas/citas_screen.dart';
import '../reservas/reservas_repository.dart';

/// Pantalla de inicio según el rol: la clienta navega entre el catálogo y sus
/// citas; la profesional ve directamente sus solicitudes y su agenda.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.of(context).usuario!;

    return usuario.esProfesional
        ? const CitasScreen(paraProfesional: true)
        : const _InicioClienta();
  }
}

class _InicioClienta extends StatefulWidget {
  const _InicioClienta();

  @override
  State<_InicioClienta> createState() => _InicioClientaState();
}

class _InicioClientaState extends State<_InicioClienta> {
  late final ReservasRepository _reservas;
  int _pestana = 0;

  @override
  void initState() {
    super.initState();
    _reservas = ReservasScope.of(context);
    _reservas.citasPedidas.addListener(_irAMisCitas);
  }

  @override
  void dispose() {
    _reservas.citasPedidas.removeListener(_irAMisCitas);
    super.dispose();
  }

  /// Tras pedir una cita, la clienta llega a "Mis citas" para verla.
  void _irAMisCitas() => setState(() => _pestana = 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pestana,
        children: const [
          CategoriasScreen(),
          CitasScreen(paraProfesional: false),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Mis citas',
          ),
        ],
      ),
    );
  }
}
