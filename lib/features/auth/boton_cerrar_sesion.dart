import 'package:flutter/material.dart';

import 'auth_controller.dart';

class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: const Icon(Icons.logout),
      onPressed: AuthScope.of(context).logout,
    );
  }
}
