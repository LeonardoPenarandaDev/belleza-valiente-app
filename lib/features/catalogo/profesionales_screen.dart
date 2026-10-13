import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../../core/widgets.dart';
import 'catalogo_repository.dart';
import 'modelos.dart';
import 'perfil_profesional_screen.dart';

/// Profesionales que ofrecen un servicio, con filtro por zona.
class ProfesionalesScreen extends StatefulWidget {
  const ProfesionalesScreen({super.key, required this.servicio});

  final Servicio servicio;

  @override
  State<ProfesionalesScreen> createState() => _ProfesionalesScreenState();
}

class _ProfesionalesScreenState extends State<ProfesionalesScreen> {
  late final CatalogoRepository _repo;
  List<Zona> _zonas = const [];
  int? _zonaId;

  final _profesionales = <ProfesionalResumen>[];
  int _pagina = 0;
  bool _hayMas = false;
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _repo = CatalogoScope.of(context);
    _cargarZonas();
    _cargar();
  }

  Future<void> _cargarZonas() async {
    try {
      final zonas = await _repo.zonas();
      if (mounted) setState(() => _zonas = zonas);
    } catch (_) {
      // Sin zonas se puede seguir buscando en todas.
    }
  }

  /// Carga la primera página, o la siguiente si [mas] es true.
  Future<void> _cargar({bool mas = false}) async {
    final zonaId = _zonaId;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final pagina = await _repo.profesionales(
        servicioId: widget.servicio.id,
        zonaId: zonaId,
        pagina: mas ? _pagina + 1 : 1,
      );
      // Si mientras tanto cambió la zona, esta respuesta ya no sirve.
      if (!mounted || zonaId != _zonaId) return;
      setState(() {
        if (!mas) _profesionales.clear();
        _profesionales.addAll(pagina.profesionales);
        _pagina = pagina.pagina;
        _hayMas = pagina.hayMas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || zonaId != _zonaId) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  void _cambiarZona(int? zonaId) {
    setState(() => _zonaId = zonaId);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.servicio.nombre)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<int?>(
              initialValue: _zonaId,
              decoration: const InputDecoration(
                labelText: 'Zona',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todas las zonas'),
                ),
                for (final zona in _zonas)
                  DropdownMenuItem(value: zona.id, child: Text(zona.nombre)),
              ],
              onChanged: _cambiarZona,
            ),
          ),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _lista() {
    if (_profesionales.isEmpty) {
      if (_cargando) return const Center(child: CircularProgressIndicator());
      if (_error != null) {
        return ErrorAlCargar(error: _error!, onReintentar: _cargar);
      }
      return SinResultados(
        _zonaId == null
            ? 'Aún no hay profesionales para este servicio.'
            : 'No hay profesionales para este servicio en esta zona. '
                  'Prueba con otra zona.',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _profesionales.length + 1,
        itemBuilder: (context, i) {
          if (i < _profesionales.length) {
            return _TarjetaProfesional(
              profesional: _profesionales[i],
              servicio: widget.servicio,
            );
          }
          return _PieDeLista(
            cargando: _cargando,
            error: _error,
            hayMas: _hayMas,
            onVerMas: () => _cargar(mas: true),
          );
        },
      ),
    );
  }
}

class _TarjetaProfesional extends StatelessWidget {
  const _TarjetaProfesional({
    required this.profesional,
    required this.servicio,
  });

  final ProfesionalResumen profesional;
  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PerfilProfesionalScreen(
              profesionalId: profesional.id,
              servicioId: servicio.id,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AvatarProfesional(
                nombre: profesional.nombre,
                foto: profesional.fotoPrincipal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profesional.nombre, style: textos.titleMedium),
                    const SizedBox(height: 2),
                    CalificacionResumen(
                      promedio: profesional.calificacionPromedio,
                      total: profesional.totalCalificaciones,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profesional.zonas.map((z) => z.nombre).join(', '),
                      style: textos.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (profesional.precio != null)
                Text(
                  formatoPesos(profesional.precio!),
                  style: textos.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieDeLista extends StatelessWidget {
  const _PieDeLista({
    required this.cargando,
    required this.error,
    required this.hayMas,
    required this.onVerMas,
  });

  final bool cargando;
  final Object? error;
  final bool hayMas;
  final VoidCallback onVerMas;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            MensajeError('$error'),
            TextButton(onPressed: onVerMas, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (hayMas) {
      return TextButton(
        onPressed: onVerMas,
        child: const Text('Ver más profesionales'),
      );
    }
    return const SizedBox(height: 16);
  }
}
