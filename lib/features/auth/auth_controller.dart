import 'package:flutter/widgets.dart';

import '../../core/api_client.dart';
import 'auth_repository.dart';
import 'usuario.dart';

enum EstadoSesion { cargando, sinSesion, conSesion, sinConexion }

/// Estado de la sesión de toda la app.
class AuthController extends ChangeNotifier {
  AuthController(this._repo);

  final AuthRepository _repo;

  EstadoSesion estado = EstadoSesion.cargando;
  Usuario? usuario;

  /// Recupera la sesión guardada al abrir la app.
  Future<void> iniciar() async {
    _cambiar(EstadoSesion.cargando);
    try {
      usuario = await _repo.usuarioGuardado();
      _cambiar(usuario == null ? EstadoSesion.sinSesion : EstadoSesion.conSesion);
    } on ApiException {
      _cambiar(EstadoSesion.sinConexion);
    }
  }

  Future<void> login({required String email, required String password}) async {
    usuario = await _repo.login(email: email, password: password);
    _cambiar(EstadoSesion.conSesion);
  }

  Future<void> registrar({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required bool aceptaTerminos,
  }) async {
    usuario = await _repo.registrar(
      nombre: nombre,
      email: email,
      telefono: telefono,
      password: password,
      aceptaTerminos: aceptaTerminos,
    );
    _cambiar(EstadoSesion.conSesion);
  }

  Future<void> logout() async {
    await _repo.logout();
    sesionExpirada();
  }

  /// La API respondió 401: el token ya no sirve.
  void sesionExpirada() {
    usuario = null;
    _cambiar(EstadoSesion.sinSesion);
  }

  void _cambiar(EstadoSesion nuevo) {
    estado = nuevo;
    notifyListeners();
  }
}

/// Da acceso al [AuthController] desde cualquier pantalla: `AuthScope.of(context)`.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}
