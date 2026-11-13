import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_controller.dart';
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
    setState(() {
      _categorias = futuro;
    });
    await futuro.catchError((_) => <Categoria>[]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final primerNombre = auth.usuario?.nombre.split(' ').first ?? 'Clienta';
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belleza Valiente'),
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

          final categorias = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // Banner superior moderno
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Marca.azulMarino, Color(0xFF1E3A5F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Marca.azulMarino.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Marca.dorado.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Marca.dorado, width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 14, color: Marca.dorado),
                                SizedBox(width: 4),
                                Text(
                                  'Servicios a domicilio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hola, $primerNombre',
                        style: textos.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '¿Qué servicio necesitas hoy?',
                        style: textos.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categorías',
                      style: textos.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Marca.textoPrincipal,
                      ),
                    ),
                    Text(
                      '${categorias.length} disponibles',
                      style: textos.bodySmall?.copyWith(color: Marca.textoSecundario),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.28,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final categoria in categorias)
                      _TarjetaCategoria(categoria),
                  ],
                ),
                const SizedBox(height: 16),
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

  static const _coloresGradiente = {
    'cabello': [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
    'unas': [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
    'barberia': [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
    'rostro': [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
    'maquillaje': [Color(0xFFFFEDD5), Color(0xFFFED7AA)],
  };

  @override
  Widget build(BuildContext context) {
    final slug = categoria.slug;
    final colores = _coloresGradiente[slug] ?? const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)];

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Marca.bordeSuave, width: 0.8),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiciosScreen(categoria: categoria),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, colores[0].withValues(alpha: 0.35)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colores,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconos[slug] ?? Icons.spa,
                  size: 24,
                  color: Marca.azulMarino,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                categoria.nombre,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: Marca.textoPrincipal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
