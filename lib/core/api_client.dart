import 'package:dio/dio.dart';

import '../config.dart';
import 'token_storage.dart';

/// Error de la API listo para mostrar: la API ya responde en español.
class ApiException implements Exception {
  ApiException(this.mensaje, {this.errores = const {}, this.status});

  final String mensaje;

  /// Errores de validación por campo (respuestas 422).
  final Map<String, List<String>> errores;

  /// Código HTTP, o null si no hubo respuesta (sin conexión).
  final int? status;

  bool get sinConexion => status == null;

  String? errorDe(String campo) => errores[campo]?.first;

  @override
  String toString() => mensaje;
}

/// Cliente HTTP de la API: agrega el token y convierte los errores en [ApiException].
class ApiClient {
  ApiClient(this._tokens, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Config.apiUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opciones, handler) async {
          final token = await _tokens.leer();
          if (token != null) {
            opciones.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(opciones);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokens;

  /// Se llama cuando la API responde 401 (token vencido o revocado).
  void Function()? alExpirarSesion;

  Future<dynamic> get(String ruta, {Map<String, dynamic>? parametros}) =>
      _enviar(() => _dio.get(ruta, queryParameters: parametros));

  Future<dynamic> post(String ruta, {Object? datos}) =>
      _enviar(() => _dio.post(ruta, data: datos));

  Future<dynamic> put(String ruta, {Object? datos}) =>
      _enviar(() => _dio.put(ruta, data: datos));

  Future<dynamic> delete(String ruta, {Object? datos}) =>
      _enviar(() => _dio.delete(ruta, data: datos));

  Future<dynamic> _enviar(Future<Response<dynamic>> Function() peticion) async {
    try {
      final respuesta = await peticion();
      return respuesta.data;
    } on DioException catch (e) {
      throw await _traducir(e);
    }
  }

  Future<ApiException> _traducir(DioException e) async {
    final respuesta = e.response;
    if (respuesta == null) {
      return ApiException(
        'No se pudo conectar con el servidor. Revisa tu conexión a internet.',
      );
    }

    final status = respuesta.statusCode ?? 0;
    if (status == 401) {
      await _tokens.borrar();
      alExpirarSesion?.call();
    }

    var mensaje = 'Ocurrió un error. Intenta de nuevo.';
    final errores = <String, List<String>>{};
    final datos = respuesta.data;

    if (status < 500 && datos is Map) {
      final texto = datos['message'];
      if (texto is String && texto.isNotEmpty) mensaje = texto;

      final porCampo = datos['errors'];
      if (porCampo is Map) {
        porCampo.forEach((campo, lista) {
          if (lista is List) errores['$campo'] = [for (final m in lista) '$m'];
        });
      }
    } else if (status >= 500) {
      mensaje = 'El servidor tuvo un problema. Intenta de nuevo en un momento.';
    }

    return ApiException(mensaje, errores: errores, status: status);
  }
}
