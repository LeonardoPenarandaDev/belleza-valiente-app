import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/formato.dart';
import '../../core/widgets.dart';
import '../catalogo/modelos.dart';
import 'editar_perfil_screens.dart';
import 'mi_perfil_repository.dart';
import 'perfil_propio.dart';

/// Elige una foto de la galería, ya reducida para no gastar datos (plan,
/// sección 1.5). Devuelve la ruta del archivo o null si no eligió ninguna.
typedef ElegirFoto = Future<String?> Function();

Future<String?> elegirFotoDeGaleria() async {
  final foto = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
  );
  return foto?.path;
}

/// Mi perfil profesional: datos, zonas, servicios y precios, y fotos.
class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key, this.elegirFoto = elegirFotoDeGaleria});

  final ElegirFoto elegirFoto;

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  late final MiPerfilRepository _repo;

  PerfilPropio? _perfil;
  Object? _error;
  bool _subiendo = false;

  /// Fotos que se están borrando.
  final _borrando = <int>{};

  @override
  void initState() {
    super.initState();
    _repo = MiPerfilScope.of(context);
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final perfil = await _repo.ver();
      if (mounted) {
        setState(() {
          _perfil = perfil;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Abre una pantalla de edición; al guardar, devuelve el perfil actualizado.
  Future<void> _editar(Widget pantalla) async {
    final actualizado = await Navigator.of(context)
        .push<PerfilPropio>(MaterialPageRoute(builder: (_) => pantalla));
    if (actualizado != null && mounted) {
      setState(() => _perfil = actualizado);
      _avisar('Cambios guardados.');
    }
  }

  Future<void> _subirFoto() async {
    final ruta = await widget.elegirFoto();
    if (ruta == null || !mounted) return;

    setState(() => _subiendo = true);
    try {
      final foto = await _repo.subirFoto(ruta);
      if (mounted) {
        setState(() => _perfil = _perfil!.conFotos([..._perfil!.fotos, foto]));
      }
      _avisar('Foto agregada.');
    } on ApiException catch (e) {
      _avisar(e.errorDe('foto') ?? e.mensaje);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _borrarFoto(Foto foto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar esta foto?'),
        content: const Text('Las clientas ya no la verán en tu perfil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _borrando.add(foto.id));
    try {
      await _repo.borrarFoto(foto.id);
      if (mounted) {
        setState(
          () => _perfil = _perfil!.conFotos([
            for (final f in _perfil!.fotos)
              if (f.id != foto.id) f,
          ]),
        );
      }
    } on ApiException catch (e) {
      _avisar(e.mensaje);
    } finally {
      if (mounted) setState(() => _borrando.remove(foto.id));
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    final perfil = _perfil;
    if (perfil == null) {
      if (_error != null) {
        return ErrorAlCargar(error: _error!, onReintentar: _cargar);
      }
      return const Center(child: CircularProgressIndicator());
    }

    final textos = Theme.of(context).textTheme;
    final bio = perfil.bio;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_avisoVisibilidad(perfil) case final aviso?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MensajeError(aviso),
            ),
          _Seccion(
            titulo: 'Sobre mí',
            onEditar: () => _editar(EditarDatosScreen(perfil: perfil)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bio == null || bio.isEmpty
                      ? 'Cuéntales a las clientas sobre tu experiencia.'
                      : bio,
                ),
                if (perfil.aniosExperiencia case final anios?) ...[
                  const SizedBox(height: 4),
                  Text(
                    anios == 1
                        ? '1 año de experiencia'
                        : '$anios años de experiencia',
                    style: textos.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                CalificacionResumen(
                  promedio: perfil.calificacionPromedio,
                  total: perfil.totalCalificaciones,
                ),
              ],
            ),
          ),
          _Seccion(
            titulo: 'Zonas donde atiendo',
            onEditar: () => _editar(EditarZonasScreen(perfil: perfil)),
            child: perfil.zonas.isEmpty
                ? const Text('Elige al menos una zona para recibir citas.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final z in perfil.zonas) Chip(label: Text(z.nombre)),
                    ],
                  ),
          ),
          _Seccion(
            titulo: 'Servicios y precios',
            onEditar: () => _editar(EditarServiciosScreen(perfil: perfil)),
            child: perfil.servicios.isEmpty
                ? const Text('Elige los servicios que ofreces y su precio.')
                : Column(
                    children: [
                      for (final s in perfil.servicios)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.activo ? s.nombre : '${s.nombre} (pausado)',
                                  style: s.activo
                                      ? null
                                      : TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                ),
                              ),
                              Text(formatoPesos(s.precio)),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          _Seccion(
            titulo:
                'Fotos (${perfil.fotos.length} de ${MiPerfilRepository.maxFotos})',
            child: _fotos(perfil),
          ),
        ],
      ),
    );
  }

  String? _avisoVisibilidad(PerfilPropio perfil) {
    if (!perfil.verificada) {
      return 'Las clientas aún no ven tu perfil: la fundación debe verificarlo.';
    }
    if (!perfil.activa) {
      return 'Tu perfil está pausado: las clientas no lo ven. '
          'Comunícate con la fundación para activarlo.';
    }
    return null;
  }

  Widget _fotos(PerfilPropio perfil) {
    final lleno = perfil.fotos.length >= MiPerfilRepository.maxFotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (perfil.fotos.isNotEmpty)
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final foto in perfil.fotos)
                _FotoEditable(
                  foto: foto,
                  borrando: _borrando.contains(foto.id),
                  onBorrar: () => _borrarFoto(foto),
                ),
            ],
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: lleno || _subiendo ? null : _subirFoto,
          icon: _subiendo
              ? const CargandoEnBoton()
              : const Icon(Icons.add_a_photo_outlined),
          label: Text(lleno ? 'Llegaste al máximo de fotos' : 'Agregar foto'),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child, this.onEditar});

  final String titulo;
  final Widget child;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onEditar != null)
                  IconButton(
                    tooltip: 'Editar $titulo'.toLowerCase(),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEditar,
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
            Padding(padding: const EdgeInsets.only(right: 8), child: child),
          ],
        ),
      ),
    );
  }
}

class _FotoEditable extends StatelessWidget {
  const _FotoEditable({
    required this.foto,
    required this.borrando,
    required this.onBorrar,
  });

  final Foto foto;
  final bool borrando;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            foto.url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Colors.black12,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: borrando
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CargandoEnBoton(),
                )
              : IconButton.filledTonal(
                  tooltip: 'Borrar foto',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onBorrar,
                ),
        ),
      ],
    );
  }
}
