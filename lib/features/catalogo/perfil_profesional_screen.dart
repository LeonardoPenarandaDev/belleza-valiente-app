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
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: FilledButton.icon(
                        icon: const Icon(Icons.event_available_rounded, size: 20),
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Tarjeta de cabecera de la profesional
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Marca.bordeSuave),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AvatarProfesional(
                    nombre: perfil.nombre,
                    foto: perfil.fotoPerfil ?? perfil.fotos.firstOrNull?.url,
                    radio: 42,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfil.nombre,
                          style: textos.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CalificacionResumen(
                          promedio: perfil.calificacionPromedio,
                          total: perfil.totalCalificaciones,
                        ),
                        if (perfil.aniosExperiencia != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              perfil.aniosExperiencia == 1
                                  ? '1 año de experiencia'
                                  : '${perfil.aniosExperiencia} años de experiencia',
                              style: textos.bodySmall?.copyWith(
                                color: Marca.textoSecundario,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (perfil.bio != null && perfil.bio!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    perfil.bio!,
                    style: textos.bodyMedium?.copyWith(
                      color: Marca.textoPrincipal,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Zonas que atiende
        if (perfil.zonas.isNotEmpty) ...[
          const _Titulo('Zonas que atiende'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final zona in perfil.zonas)
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 16, color: Marca.azulMarino),
                  label: Text(zona.nombre),
                ),
            ],
          ),
        ],

        // Servicios ofrecidos
        const _Titulo('Servicios'),
        for (final servicio in perfil.servicios)
          Card(
            elevation: servicio.servicioId == servicioId ? 2 : 1,
            color: servicio.servicioId == servicioId
                ? Marca.doradoClaro
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: servicio.servicioId == servicioId
                    ? Marca.dorado
                    : Marca.bordeSuave,
                width: servicio.servicioId == servicioId ? 1.5 : 0.8,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servicio.nombre,
                          style: textos.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Marca.textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: Marca.textoSecundario),
                            const SizedBox(width: 4),
                            Text(
                              formatoDuracion(servicio.duracionMinutos),
                              style: textos.bodySmall?.copyWith(color: Marca.textoSecundario),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatoPesos(servicio.precio),
                    style: textos.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: servicio.servicioId == servicioId
                          ? const Color(0xFF7A5E00)
                          : Marca.azulMarino,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Trabajos / Portafolio visual
        if (perfil.fotos.isNotEmpty) ...[
          const _Titulo('Trabajos'),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: perfil.fotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  _Miniatura(fotos: perfil.fotos, indice: i),
            ),
          ),
        ],

        // Opiniones
        const _Titulo('Opiniones'),
        if (perfil.calificaciones.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Marca.bordeSuave),
            ),
            child: const Text('Todavía no tiene opiniones.'),
          )
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
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: Marca.textoPrincipal,
      ),
    ),
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
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                fotos[indice].url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, color: Marca.textoSecundario),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: inicial),
        itemCount: fotos.length,
        itemBuilder: (context, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                fotos[i].url,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Marca.bordeSuave, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= calificacion.estrellas ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18,
                    color: Marca.doradoOscuro,
                  ),
                const SizedBox(width: 8),
                Text(
                  _fecha.format(calificacion.fecha.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Marca.textoSecundario,
                  ),
                ),
              ],
            ),
            if (calificacion.comentario != null &&
                calificacion.comentario!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  calificacion.comentario!,
                  style: const TextStyle(fontSize: 14, color: Marca.textoPrincipal),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
