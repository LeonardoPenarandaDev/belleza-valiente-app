import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import 'usuario.dart';

/// Endpoints de autenticación (`/auth/*` y `/me`).
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  static const _dispositivo = 'android';

  Future<Usuario> login({
    required String email,
    required String password,
  }) async {
    final datos = await _api.post(
      '/auth/login',
      datos: {
        'email': email,
        'password': password,
        'dispositivo': _dispositivo,
      },
    );
    return _guardarSesion(datos);
  }

  /// Crea una cuenta de clienta. Las profesionales las crea la fundación.
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required bool aceptaTerminos,
  }) async {
    final datos = await _api.post(
      '/auth/register',
      datos: {
        'name': nombre,
        'email': email,
        'telefono': telefono,
        'password': password,
        'acepta_terminos': aceptaTerminos,
        'dispositivo': _dispositivo,
      },
    );
    return _guardarSesion(datos);
  }

  /// Usuario de la sesión guardada, o null si no hay sesión o ya no es válida.
  Future<Usuario?> usuarioGuardado() async {
    if (await _tokens.leer() == null) return null;

    try {
      final datos = await _api.get('/me');
      return Usuario.fromJson(datos['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.status == 401) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Aunque el servidor no responda, la sesión se cierra en el teléfono.
    } finally {
      await _tokens.borrar();
    }
  }

  Future<Usuario> _guardarSesion(dynamic datos) async {
    await _tokens.guardar(datos['token'] as String);
    return Usuario.fromJson(datos['user'] as Map<String, dynamic>);
  }
}
