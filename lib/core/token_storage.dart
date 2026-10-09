import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token de Sanctum cifrado en el teléfono.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? almacen])
    : _almacen = almacen ?? const FlutterSecureStorage();

  static const _clave = 'token';

  final FlutterSecureStorage _almacen;

  // Copia en memoria para no leer el almacenamiento cifrado en cada petición.
  String? _token;
  bool _leido = false;

  Future<String?> leer() async {
    if (!_leido) {
      _token = await _almacen.read(key: _clave);
      _leido = true;
    }
    return _token;
  }

  Future<void> guardar(String token) async {
    await _almacen.write(key: _clave, value: token);
    _token = token;
    _leido = true;
  }

  Future<void> borrar() async {
    await _almacen.delete(key: _clave);
    _token = null;
    _leido = true;
  }
}
