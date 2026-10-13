import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../../core/widgets.dart';
import 'modelos.dart';
import 'profesionales_screen.dart';

/// Servicios de una categoría.
class ServiciosScreen extends StatelessWidget {
  const ServiciosScreen({super.key, required this.categoria});

  final Categoria categoria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoria.nombre)),
      body: categoria.servicios.isEmpty
          ? const SinResultados('Por ahora no hay servicios en esta categoría.')
          : ListView.separated(
              itemCount: categoria.servicios.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final servicio = categoria.servicios[i];
                final detalle = [
                  if (servicio.precioReferencia != null)
                    'Desde ${formatoPesos(servicio.precioReferencia!)}',
                  formatoDuracion(servicio.duracionMinutos),
                ].join(' · ');

                return ListTile(
                  title: Text(servicio.nombre),
                  subtitle: Text(detalle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfesionalesScreen(servicio: servicio),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
