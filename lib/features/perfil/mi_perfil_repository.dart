import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../../core/api_client.dart';
import '../catalogo/modelos.dart';
import 'perfil_propio.dart';

/// Endpoints del perfil propio de la profesional (`/mi-perfil-profesional`).
class MiPerfilRepository {
  MiPerfilRepository(this._api);

  final ApiClient _api;

  /// Máximo de fotos del portafolio (lo valida también el servidor).
  static const maxFotos = 10;

  Future<PerfilPropio> ver() async =>
      _perfil(await _api.get('/mi-perfil-profesional'));

  Future<PerfilPropio> guardarDatos({String? bio, int? aniosExperiencia}) =>
      _actualizar({'bio': bio, 'anios_experiencia': aniosExperiencia});

  /// Reemplaza las zonas que atiende por [zonaIds].
  Future<PerfilPropio> guardarZonas(List<int> zonaIds) =>
      _actualizar({'zonas': zonaIds});

  /// Reemplaza sus servicios y precios por [servicios].
  Future<PerfilPropio> guardarServicios(List<ServicioPropio> servicios) =>
      _actualizar({
        'servicios': [for (final s in servicios) s.toJson()],
      });

  /// Sube una foto ya reducida en el teléfono (ver `image_picker`).
  Future<Foto> subirFoto(String ruta) async {
    final datos = await _api.post(
      '/mi-perfil-profesional/fotos',
      datos: FormData.fromMap({'foto': await MultipartFile.fromFile(ruta)}),
    );
    return Foto.fromJson(datos['data'] as Map<String, dynamic>);
  }

  Future<void> borrarFoto(int fotoId) =>
      _api.delete('/mi-perfil-profesional/fotos/$fotoId');

  Future<PerfilPropio> _actualizar(Map<String, Object?> cambios) async =>
      _perfil(await _api.put('/mi-perfil-profesional', datos: cambios));

  PerfilPropio _perfil(dynamic datos) =>
      PerfilPropio.fromJson(datos['data'] as Map<String, dynamic>);
}

/// Da acceso al [MiPerfilRepository]: `MiPerfilScope.of(context)`.
class MiPerfilScope extends InheritedWidget {
  const MiPerfilScope({super.key, required this.repo, required super.child});

  final MiPerfilRepository repo;

  /// El repositorio no cambia; se puede llamar desde `initState`.
  static MiPerfilRepository of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MiPerfilScope>()!.repo;

  @override
  bool updateShouldNotify(MiPerfilScope oldWidget) => false;
}
