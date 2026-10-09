import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import 'auth_controller.dart';

/// Registro público: solo para clientas.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();

  bool _aceptaTerminos = false;
  bool _enviando = false;
  bool _verPassword = false;
  ApiException? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _telefono.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).registrar(
        nombre: _nombre.text.trim(),
        email: _email.text.trim(),
        telefono: _telefono.text.trim(),
        password: _password.text,
        aceptaTerminos: _aceptaTerminos,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    errorText: error?.errorDe('name'),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Escribe tu nombre.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    errorText: error?.errorDe('email'),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: validarCorreo,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefono,
                  decoration: InputDecoration(
                    labelText: 'Celular (WhatsApp)',
                    hintText: '300 123 4567',
                    errorText: error?.errorDe('telefono'),
                  ),
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.next,
                  validator: validarCelular,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    helperText: 'Mínimo 8 caracteres',
                    errorText: error?.errorDe('password'),
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
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => (v == null || v.length < 8)
                      ? 'La contraseña debe tener al menos 8 caracteres.'
                      : null,
                ),
                const SizedBox(height: 8),
                // TODO: enlazar los textos cuando la fundación entregue las páginas públicas (plan 1.10).
                FormField<bool>(
                  initialValue: _aceptaTerminos,
                  validator: (v) => v == true
                      ? null
                      : 'Debes aceptar los términos y la política de datos.',
                  builder: (campo) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        value: _aceptaTerminos,
                        onChanged: (v) {
                          setState(() => _aceptaTerminos = v ?? false);
                          campo.didChange(v);
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Acepto los términos y condiciones y la política de '
                          'tratamiento de datos personales.',
                        ),
                      ),
                      if ((campo.errorText ?? error?.errorDe('acepta_terminos')) case final texto?)
                        Text(
                          texto,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (error != null && error.errores.isEmpty) ...[
                  const SizedBox(height: 16),
                  MensajeError(error.mensaje),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _enviando ? null : _registrar,
                  child: _enviando
                      ? const CargandoEnBoton()
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
