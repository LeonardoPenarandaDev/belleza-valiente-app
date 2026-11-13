import 'package:flutter/widgets.dart';

import '../../core/api_client.dart';
import 'modelos.dart';

/// Endpoints del catálogo y de las profesionales.
class CatalogoRepository {
  CatalogoRepository(this._api);

  final ApiClient _api;

  // Categorías y zonas cambian muy poco: se guardan mientras la app está abierta.
  List<Categoria>? _categorias;
  List<Zona>? _zonas;

  Future<List<Categoria>> categorias({bool recargar = false}) async {
    if (_categorias != null && !recargar) return _categorias!;
    final datos = await _api.get('/categorias');
    return _categorias = [
      for (final c in datos['data'] as List)
                Categoria.fromJson(c as Map<String, dynamic>),
    ];
  }

  Future<List<Zona>> zonas() async {
    if (_zonas != null) return _zonas!;
    final datos = await _api.get('/zonas');
    return _zonas = [
      for (final z in datos['data'] as List)
        Zona.fromJson(z as Map<String, dynamic>),
    ];
  }

  Future<PaginaProfesionales> profesionales({
    int? servicioId,
    int? zonaId,
    int pagina = 1,
  }) async {
    final datos = await _api.get(
      '/profesionales',
      parametros: {
        'servicio_id': ?servicioId,
        'zona_id': ?zonaId,
        'page': pagina,
      },
    );
    return PaginaProfesionales.fromJson(datos as Map<String, dynamic>);
  }

  Future<PerfilProfesional> perfil(int id) async {
    final datos = await _api.get('/profesionales/$id');
    return PerfilProfesional.fromJson(datos['data'] as Map<String, dynamic>);
  }
}

/// Da acceso al [CatalogoRepository] desde cualquier pantalla: `CatalogoScope.of(context)`.
class CatalogoScope extends InheritedWidget {
  const CatalogoScope({super.key, required this.repo, required super.child});

  final CatalogoRepository repo;

  /// El repositorio no cambia en toda la vida de la app, así que no hace falta
  /// registrar dependencia y se puede llamar desde `initState`.
  static CatalogoRepository of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CatalogoScope>()!.repo;

  @override
  bool updateShouldNotify(CatalogoScope oldWidget) => false;
}
