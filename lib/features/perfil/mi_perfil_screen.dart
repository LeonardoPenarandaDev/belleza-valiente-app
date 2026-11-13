import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/formato.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../catalogo/modelos.dart';
import 'editar_perfil_screens.dart';
import 'mi_perfil_repository.dart';
import 'perfil_propio.dart';

/// Elige una foto de la galería o cámara, reducida para no gastar datos.
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

Future<String?> _elegirFotoConOpciones(BuildContext context) async {
  final origen = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Agregar foto de tu trabajo',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Marca.azulMarino,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Muestra el resultado real de tus servicios a las clientas',
              textAlign: TextAlign.center,
              style: TextStyle(color: Marca.textoSecundario, fontSize: 13.5),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Marca.azulMarino),
              ),
              title: const Text('Tomar foto con la cámara', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Toma una foto al instante de tu trabajo terminado'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const Divider(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Marca.doradoClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Marca.doradoOscuro),
              ),
              title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Selecciona una imagen guardada en tu teléfono'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );

  if (origen == null) return null;

  final foto = await ImagePicker().pickImage(
    source: origen,
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

  Future<void> _editar(Widget pantalla) async {
    final actualizado = await Navigator.of(context)
        .push<PerfilPropio>(MaterialPageRoute(builder: (_) => pantalla));
    if (actualizado != null && mounted) {
      setState(() => _perfil = actualizado);
      _avisar('Cambios guardados.');
    }
  }

  Future<void> _subirFoto() async {
    final ruta = widget.elegirFoto == elegirFotoDeGaleria
        ? await _elegirFotoConOpciones(context)
        : await widget.elegirFoto();

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('¿Borrar esta foto?'),
        content: const Text('Las clientas ya no la verán en tu perfil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size(0, 42),
            ),
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
        .showSnackBar(SnackBar(
          content: Text(mensaje),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          if (_avisoVisibilidad(perfil) case final aviso?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                  style: TextStyle(
                    color: (bio == null || bio.isEmpty) ? Marca.textoSecundario : Marca.textoPrincipal,
                    fontSize: 14.5,
                  ),
                ),
                if (perfil.aniosExperiencia case final anios?) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      anios == 1
                          ? '1 año de experiencia'
                          : '$anios años de experiencia',
                      style: textos.bodySmall?.copyWith(
                        color: Marca.textoSecundario,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
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
                ? const Text(
                    'Elige al menos una zona para recibir citas.',
                    style: TextStyle(color: Marca.textoSecundario),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final z in perfil.zonas)
                        Chip(
                          avatar: const Icon(Icons.place_outlined, size: 16, color: Marca.azulMarino),
                          label: Text(z.nombre),
                        ),
                    ],
                  ),
          ),
          _Seccion(
            titulo: 'Servicios y precios',
            onEditar: () => _editar(EditarServiciosScreen(perfil: perfil)),
            child: perfil.servicios.isEmpty
                ? const Text(
                    'Elige los servicios que ofreces y su precio.',
                    style: TextStyle(color: Marca.textoSecundario),
                  )
                : Column(
                    children: [
                      for (final s in perfil.servicios)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.activo ? s.nombre : '${s.nombre} (pausado)',
                                  style: s.activo
                                      ? const TextStyle(fontWeight: FontWeight.w500)
                                      : TextStyle(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Marca.doradoClaro,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  formatoPesos(s.precio),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7A5E00),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
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
        // Mensaje de ayuda / recomendación para la profesional
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, size: 20, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sube fotos nítidas de tus peinados, uñas, cortes o maquillaje. '
                  'Las clientas revisan estas fotos antes de agendar su cita.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.green.shade900,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (perfil.fotos.isNotEmpty)
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
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
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: BorderSide(color: lleno ? Colors.grey : Marca.azulMarino, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: lleno || _subiendo ? null : _subirFoto,
          icon: _subiendo
              ? const CargandoEnBoton()
              : const Icon(Icons.add_a_photo_outlined, size: 20),
          label: Text(
            lleno ? 'Llegaste al máximo de fotos' : 'Agregar foto',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Marca.bordeSuave, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Marca.textoPrincipal,
                    ),
                  ),
                ),
                if (onEditar != null)
                  IconButton(
                    tooltip: 'Editar $titulo'.toLowerCase(),
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Marca.azulMarino),
                    onPressed: onEditar,
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
            Padding(padding: const EdgeInsets.only(right: 6), child: child),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              foto.url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFFE2E8F0),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, color: Marca.textoSecundario),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: borrando
                ? Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
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
      ),
    );
  }
}
