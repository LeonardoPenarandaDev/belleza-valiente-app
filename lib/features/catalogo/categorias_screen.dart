import 'package:flutter/material.dart';

import '../../core/widgets.dart';
import '../auth/auth_controller.dart';
import '../auth/boton_cerrar_sesion.dart';
import 'catalogo_repository.dart';
import 'modelos.dart';
import 'servicios_screen.dart';

/// Inicio de la clienta: categorías del catálogo.
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late Future<List<Categoria>> _categorias;

  @override
  void initState() {
    super.initState();
    _categorias = CatalogoScope.of(context).categorias();
  }

  Future<void> _recargar() async {
    final futuro = CatalogoScope.of(context).categorias(recargar: true);
    setState(() => _categorias = futuro);
    await futuro.catchError((_) => <Categoria>[]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final primerNombre = auth.usuario!.nombre.split(' ').first;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belleza Valiente'),
        actions: [BotonCerrarSesion()],
      ),
      body: FutureBuilder(
        future: _categorias,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorAlCargar(
              error: snapshot.error!,
              onReintentar: _recargar,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Hola, $primerNombre', style: textos.headlineSmall),
                const SizedBox(height: 4),
                Text('¿Qué servicio necesitas hoy?', style: textos.bodyLarge),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final categoria in snapshot.data!)
                      _TarjetaCategoria(categoria),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaCategoria extends StatelessWidget {
  const _TarjetaCategoria(this.categoria);

  final Categoria categoria;

  static const _iconos = {
    'cabello': Icons.face_3,
    'unas': Icons.back_hand,
    'barberia': Icons.content_cut,
    'rostro': Icons.face_retouching_natural,
    'maquillaje': Icons.brush,
  };

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiciosScreen(categoria: categoria),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _iconos[categoria.slug] ?? Icons.spa,
              size: 40,
              color: colores.secondary,
            ),
            const SizedBox(height: 8),
            Text(
              categoria.nombre,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
