import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'core/token_storage.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/inicio/inicio_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokens = TokenStorage();
  final api = ApiClient(tokens);
  final auth = AuthController(AuthRepository(api, tokens));
  api.alExpirarSesion = auth.sesionExpirada;
  auth.iniciar();

  runApp(BellezaValienteApp(auth: auth));
}

class BellezaValienteApp extends StatefulWidget {
  const BellezaValienteApp({super.key, required this.auth});

  final AuthController auth;

  @override
  State<BellezaValienteApp> createState() => _BellezaValienteAppState();
}

class _BellezaValienteAppState extends State<BellezaValienteApp> {
  final _navegador = GlobalKey<NavigatorState>();
  late EstadoSesion _estado;

  @override
  void initState() {
    super.initState();
    _estado = widget.auth.estado;
    widget.auth.addListener(_alCambiarSesion);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_alCambiarSesion);
    super.dispose();
  }

  /// Al entrar o salir de la sesión se cierran las pantallas abiertas
  /// (p. ej. el registro) para mostrar la pantalla raíz que corresponde.
  void _alCambiarSesion() {
    if (widget.auth.estado != _estado) {
      _estado = widget.auth.estado;
      _navegador.currentState?.popUntil((ruta) => ruta.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: widget.auth,
      child: MaterialApp(
        title: 'Belleza Valiente',
        navigatorKey: _navegador,
        theme: temaBellezaValiente(),
        locale: const Locale('es', 'CO'),
        supportedLocales: const [Locale('es', 'CO'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const _PantallaRaiz(),
      ),
    );
  }
}

class _PantallaRaiz extends StatelessWidget {
  const _PantallaRaiz();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return switch (auth.estado) {
      EstadoSesion.cargando => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      EstadoSesion.sinSesion => const LoginScreen(),
      EstadoSesion.conSesion => const InicioScreen(),
      EstadoSesion.sinConexion => _SinConexion(onReintentar: auth.iniciar),
    };
  }
}

class _SinConexion extends StatelessWidget {
  const _SinConexion({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No se pudo conectar con el servidor. Revisa tu conexión a internet.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
