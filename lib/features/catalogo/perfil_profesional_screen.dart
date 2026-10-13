import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/formato.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../reservas/pedir_cita_screen.dart';
import 'catalogo_repository.dart';
import 'modelos.dart';

/// Perfil público de una profesional: servicios, precios, fotos y calificaciones.
class PerfilProfesionalScreen extends StatefulWidget {
  const PerfilProfesionalScreen({
    super.key,
    required this.profesionalId,
    this.servicioId,
  });

  final int profesionalId;

  /// Servicio que la clienta estaba buscando; se resalta en la lista.
  final int? servicioId;

  @override
  State<PerfilProfesionalScreen> createState() =>
      _PerfilProfesionalScreenState();
}

class _PerfilProfesionalScreenState extends State<PerfilProfesionalScreen> {
  late Future<PerfilProfesional> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = CatalogoScope.of(context).perfil(widget.profesionalId);
  }

  void _recargar() {
    setState(
      () => _perfil = CatalogoScope.of(context).perfil(widget.profesionalId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _perfil,
      builder: (context, snapshot) {
        final perfil = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: const Text('Perfil')),
          body: snapshot.hasError
              ? ErrorAlCargar(error: snapshot.error!, onReintentar: _recargar)
              : perfil == null
              ? const Center(child: CircularProgressIndicator())
              : _Contenido(perfil: perfil, servicioId: widget.servicioId),
          bottomNavigationBar: perfil == null || perfil.servicios.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FilledButton.icon(
                      icon: const Icon(Icons.event_available),
                      label: const Text('Pedir cita'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PedirCitaScreen(
                            perfil: perfil,
                            servicioId: widget.servicioId,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.perfil, this.servicioId});

  final PerfilProfesional perfil;
  final int? servicioId;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            AvatarProfesional(
              nombre: perfil.nombre,
              foto: perfil.fotos.firstOrNull?.url,
              radio: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(perfil.nombre, style: textos.titleLarge),
                  const SizedBox(height: 4),
                  CalificacionResumen(
                    promedio: perfil.calificacionPromedio,
                    total: perfil.totalCalificaciones,
                  ),
                  if (perfil.aniosExperiencia != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      perfil.aniosExperiencia == 1
                          ? '1 año de experiencia'
                          : '${perfil.aniosExperiencia} años de experiencia',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (perfil.bio != null && perfil.bio!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(perfil.bio!),
        ],
        if (perfil.zonas.isNotEmpty) ...[
          const _Titulo('Zonas que atiende'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final zona in perfil.zonas)
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 18),
                  label: Text(zona.nombre),
                ),
            ],
          ),
        ],
        const _Titulo('Servicios'),
        for (final servicio in perfil.servicios)
          Card(
            color: servicio.servicioId == servicioId
                ? colores.secondaryContainer
                : null,
            child: ListTile(
              title: Text(servicio.nombre),
              subtitle: Text(formatoDuracion(servicio.duracionMinutos)),
              trailing: Text(
                formatoPesos(servicio.precio),
                style: textos.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (perfil.fotos.isNotEmpty) ...[
          const _Titulo('Trabajos'),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: perfil.fotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) =>
                  _Miniatura(fotos: perfil.fotos, indice: i),
            ),
          ),
        ],
        const _Titulo('Opiniones'),
        if (perfil.calificaciones.isEmpty)
          const Text('Todavía no tiene opiniones.')
        else
          for (final calificacion in perfil.calificaciones)
            _Opinion(calificacion),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.fotos, required this.indice});

  final List<Foto> fotos;
  final int indice;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _GaleriaFotos(fotos: fotos, inicial: indice),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fotos[indice].url,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 120,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

/// Fotos a pantalla completa; se pasa de una a otra deslizando.
class _GaleriaFotos extends StatelessWidget {
  const _GaleriaFotos({required this.fotos, required this.inicial});

  final List<Foto> fotos;
  final int inicial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PageView(
        controller: PageController(initialPage: inicial),
        children: [
          for (final foto in fotos)
            InteractiveViewer(child: Center(child: Image.network(foto.url))),
        ],
      ),
    );
  }
}

class _Opinion extends StatelessWidget {
  const _Opinion(this.calificacion);

  final Calificacion calificacion;

  static final _fecha = DateFormat('d MMM y', 'es');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= calificacion.estrellas ? Icons.star : Icons.star_border,
                  size: 18,
                  color: Marca.dorado,
                ),
              const SizedBox(width: 8),
              Text(
                _fecha.format(calificacion.fecha.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (calificacion.comentario != null &&
              calificacion.comentario!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(calificacion.comentario!),
            ),
        ],
      ),
    );
  }
}
