import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import 'auth_controller.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _enviando = false;
  bool _verPassword = false;
  ApiException? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).login(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EncabezadoMarca(),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: validarCorreo,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        tooltip: _verPassword ? 'Ocultar' : 'Mostrar',
                        icon: Icon(
                          _verPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _verPassword = !_verPassword),
                      ),
                    ),
                    obscureText: !_verPassword,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _entrar(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Escribe tu contraseña.' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    MensajeError(_error!.errorDe('email') ?? _error!.mensaje),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _enviando ? null : _entrar,
                    child: _enviando
                        ? const CargandoEnBoton()
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _enviando
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegistroScreen(),
                            ),
                          ),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
