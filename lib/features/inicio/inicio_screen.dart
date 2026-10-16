import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../catalogo/categorias_screen.dart';
import '../cuenta/cuenta_screen.dart';
import '../perfil/mi_perfil_screen.dart';
import '../reservas/citas_screen.dart';
import '../reservas/reservas_repository.dart';

/// Pantalla de inicio según el rol: la clienta navega entre el catálogo, sus
/// citas y su cuenta; la profesional, entre sus citas, su perfil y su cuenta.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.of(context).usuario!;

    return usuario.esProfesional
        ? const _Pestanas(
            pantallas: [
              CitasScreen(paraProfesional: true),
              MiPerfilScreen(),
              CuentaScreen(),
            ],
            destinos: [
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: 'Citas',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Mi perfil',
              ),
              _destinoCuenta,
            ],
          )
        : const _Pestanas(
            irAMisCitas: 1,
            pantallas: [
              CategoriasScreen(),
              CitasScreen(paraProfesional: false),
              CuentaScreen(),
            ],
            destinos: [
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
              _destinoCuenta,
            ],
          );
  }
}

const _destinoCuenta = NavigationDestination(
  icon: Icon(Icons.person_outline),
  selectedIcon: Icon(Icons.person),
  label: 'Mi cuenta',
);

class _Pestanas extends StatefulWidget {
  const _Pestanas({
    required this.pantallas,
    required this.destinos,
    this.irAMisCitas,
  });

  final List<Widget> pantallas;
  final List<NavigationDestination> destinos;

  /// Pestaña a la que se va tras pedir una cita (solo la clienta).
  final int? irAMisCitas;

  @override
  State<_Pestanas> createState() => _PestanasState();
}

class _PestanasState extends State<_Pestanas> {
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
  void _irAMisCitas() {
    if (widget.irAMisCitas case final i?) setState(() => _pestana = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _pestana, children: widget.pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: widget.destinos,
      ),
    );
  }
}
