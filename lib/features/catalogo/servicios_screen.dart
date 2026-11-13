import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../../core/theme.dart';
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
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: categoria.servicios.length,
              itemBuilder: (context, i) {
                final servicio = categoria.servicios[i];
                final detalle = [
                  if (servicio.precioReferencia != null)
                    'Desde ${formatoPesos(servicio.precioReferencia!)}',
                  formatoDuracion(servicio.duracionMinutos),
                ].join(' · ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Marca.bordeSuave, width: 0.8),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfesionalesScreen(servicio: servicio),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Marca.doradoClaro,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Marca.doradoOscuro,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  servicio.nombre,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                    color: Marca.textoPrincipal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  detalle,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Marca.textoSecundario,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Marca.azulMarino,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
