import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/formato.dart';
import '../../core/widgets.dart';
import '../catalogo/catalogo_repository.dart';
import '../catalogo/modelos.dart';
import 'mi_perfil_repository.dart';
import 'perfil_propio.dart';

/// Guardado común de las pantallas de edición: muestra el error del servidor
/// y, si todo sale bien, vuelve a "Mi perfil" con el perfil actualizado.
mixin _Guardar<T extends StatefulWidget> on State<T> {
  bool guardando = false;
  String? errorGuardar;

  Future<void> guardar(
    Future<PerfilPropio> Function(MiPerfilRepository repo) cambio,
  ) async {
    setState(() {
      guardando = true;
      errorGuardar = null;
    });
    try {
      final perfil = await cambio(MiPerfilScope.of(context));
      if (mounted) Navigator.of(context).pop(perfil);
    } on ApiException catch (e) {
      final primero = e.errores.values.firstOrNull?.firstOrNull;
      if (mounted) setState(() => errorGuardar = primero ?? e.mensaje);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Widget botonGuardar(VoidCallback? onGuardar) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorGuardar != null) ...[
            MensajeError(errorGuardar!),
            const SizedBox(height: 8),
          ],
          FilledButton(
            onPressed: guardando ? null : onGuardar,
            child: guardando ? const CargandoEnBoton() : const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

// --- Datos ---

class EditarDatosScreen extends StatefulWidget {
  const EditarDatosScreen({super.key, required this.perfil});

  final PerfilPropio perfil;

  @override
  State<EditarDatosScreen> createState() => _EditarDatosScreenState();
}

class _EditarDatosScreenState extends State<EditarDatosScreen> with _Guardar {
  final _formulario = GlobalKey<FormState>();
  late final _bio = TextEditingController(text: widget.perfil.bio);
  late final _anios = TextEditingController(
    text: widget.perfil.aniosExperiencia?.toString(),
  );

  @override
  void dispose() {
    _bio.dispose();
    _anios.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_formulario.currentState!.validate()) return;
    final bio = _bio.text.trim();
    guardar(
      (repo) => repo.guardarDatos(
        bio: bio.isEmpty ? null : bio,
        aniosExperiencia: int.tryParse(_anios.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre mí')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _bio,
              maxLength: 1000,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Sobre mí',
                hintText: 'Tu experiencia, técnicas y productos que usas.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _anios,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: const InputDecoration(
                labelText: 'Años de experiencia',
              ),
              validator: (v) {
                final anios = int.tryParse(v ?? '');
                if (anios != null && anios > 60) return 'Máximo 60 años.';
                return null;
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: botonGuardar(_enviar),
    );
  }
}

// --- Zonas ---

class EditarZonasScreen extends StatefulWidget {
  const EditarZonasScreen({super.key, required this.perfil});

  final PerfilPropio perfil;

  @override
  State<EditarZonasScreen> createState() => _EditarZonasScreenState();
}

class _EditarZonasScreenState extends State<EditarZonasScreen> with _Guardar {
  late Future<List<Zona>> _zonas;
  late final _elegidas = {for (final z in widget.perfil.zonas) z.id};

  @override
  void initState() {
    super.initState();
    _zonas = CatalogoScope.of(context).zonas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zonas donde atiendo')),
      body: FutureBuilder(
        future: _zonas,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorAlCargar(
              error: snapshot.error!,
              onReintentar: () =>
                  setState(() => _zonas = CatalogoScope.of(context).zonas()),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Las clientas de estas zonas podrán pedirte citas.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final z in snapshot.data!)
                    FilterChip(
                      label: Text(z.nombre),
                      selected: _elegidas.contains(z.id),
                      onSelected: (si) => setState(
                        () => si ? _elegidas.add(z.id) : _elegidas.remove(z.id),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: botonGuardar(() {
        if (_elegidas.isEmpty) {
          setState(() => errorGuardar = 'Elige al menos una zona.');
          return;
        }
        guardar((repo) => repo.guardarZonas(_elegidas.toList()));
      }),
    );
  }
}

// --- Servicios y precios ---

/// Lo que la profesional elige para un servicio del catálogo.
class _Eleccion {
  _Eleccion({required this.ofrece, required String precio})
    : precio = TextEditingController(text: precio);

  bool ofrece;
  final TextEditingController precio;
}

class EditarServiciosScreen extends StatefulWidget {
  const EditarServiciosScreen({super.key, required this.perfil});

  final PerfilPropio perfil;

  /// Límites del servidor, en pesos.
  static const precioMinimo = 1000;
  static const precioMaximo = 5000000;

  @override
  State<EditarServiciosScreen> createState() => _EditarServiciosScreenState();
}

class _EditarServiciosScreenState extends State<EditarServiciosScreen>
    with _Guardar {
  final _formulario = GlobalKey<FormState>();
  late Future<List<Categoria>> _categorias;
  final _elecciones = <int, _Eleccion>{};

  @override
  void initState() {
    super.initState();
    _categorias = CatalogoScope.of(context).categorias();
  }

  @override
  void dispose() {
    for (final e in _elecciones.values) {
      e.precio.dispose();
    }
    super.dispose();
  }

  _Eleccion _eleccion(Servicio s) => _elecciones.putIfAbsent(s.id, () {
    final actual = widget.perfil.servicios
        .where((p) => p.servicioId == s.id)
        .firstOrNull;
    return _Eleccion(
      ofrece: actual?.activo ?? false,
      precio: '${actual?.precio ?? s.precioReferencia ?? ''}',
    );
  });

  /// Los marcados quedan activos. Los que ya ofrecía y desmarcó quedan
  /// pausados, con su precio, para poder reactivarlos sin volver a escribirlo.
  void _enviar(List<Categoria> categorias) {
    if (!_formulario.currentState!.validate()) return;

    final servicios = <ServicioPropio>[];
    for (final c in categorias) {
      for (final s in c.servicios) {
        final e = _eleccion(s);
        final precio = int.tryParse(e.precio.text);
        final loTenia = widget.perfil.servicios.any(
          (p) => p.servicioId == s.id,
        );
        if (precio == null || (!e.ofrece && !loTenia)) continue;
        if (!e.ofrece && !_precioValido(precio)) continue;
        servicios.add(
          ServicioPropio(
            servicioId: s.id,
            nombre: s.nombre,
            precio: precio,
            activo: e.ofrece,
          ),
        );
      }
    }

    if (!servicios.any((s) => s.activo)) {
      setState(() => errorGuardar = 'Elige al menos un servicio.');
      return;
    }
    guardar((repo) => repo.guardarServicios(servicios));
  }

  bool _precioValido(int precio) =>
      precio >= EditarServiciosScreen.precioMinimo &&
      precio <= EditarServiciosScreen.precioMaximo;

  String? _validarPrecio(String? valor) {
    final precio = int.tryParse(valor ?? '');
    if (precio == null) return 'Escribe el precio.';
    if (!_precioValido(precio)) {
      return 'Entre ${formatoPesos(EditarServiciosScreen.precioMinimo)} '
          'y ${formatoPesos(EditarServiciosScreen.precioMaximo)}.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _categorias,
      builder: (context, snapshot) {
        final categorias = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: const Text('Servicios y precios')),
          body: switch (snapshot) {
            _ when snapshot.hasError => ErrorAlCargar(
              error: snapshot.error!,
              onReintentar: () => setState(
                () =>
                    _categorias = CatalogoScope.of(context)
                        .categorias(recargar: true),
              ),
            ),
            _ when categorias == null => const Center(
              child: CircularProgressIndicator(),
            ),
            _ => Form(
              key: _formulario,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Marca los servicios que ofreces y escribe tu precio, '
                    'en pesos y sin puntos.',
                  ),
                  for (final c in categorias)
                    if (c.servicios.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        c.nombre,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final s in c.servicios) _fila(s),
                    ],
                ],
              ),
            ),
          },
          bottomNavigationBar: categorias == null
              ? null
              : botonGuardar(() => _enviar(categorias)),
        );
      },
    );
  }

  Widget _fila(Servicio s) {
    final e = _eleccion(s);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: e.ofrece,
            onChanged: (v) => setState(() => e.ofrece = v ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${s.nombre}\n${formatoDuracion(s.duracionMinutos)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: TextFormField(
              key: ValueKey('precio-${s.id}'),
              controller: e.precio,
              enabled: e.ofrece,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              decoration: const InputDecoration(
                prefixText: r'$ ',
                isDense: true,
                errorMaxLines: 2,
              ),
              validator: (v) => e.ofrece ? _validarPrecio(v) : null,
            ),
          ),
        ],
      ),
    );
  }
}
