import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import '../auth/auth_controller.dart';
import '../auth/usuario.dart';

/// Mi cuenta (todos los roles): datos, cerrar sesión y eliminar la cuenta.
class CuentaScreen extends StatelessWidget {
  const CuentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final usuario = auth.usuario;
    if (usuario == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(usuario.nombre),
            subtitle: Text(switch (usuario.rol) {
              Rol.profesional => 'Profesional',
              Rol.admin => 'Administradora',
              Rol.cliente => 'Clienta',
            }),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(usuario.email),
          ),
          if (usuario.telefono case final telefono?)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(telefono),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: auth.logout,
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Eliminar mi cuenta',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _DialogoEliminarCuenta(auth: auth),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pide la contraseña antes de eliminar, para evitar borrados por error.
class _DialogoEliminarCuenta extends StatefulWidget {
  const _DialogoEliminarCuenta({required this.auth});

  final AuthController auth;

  @override
  State<_DialogoEliminarCuenta> createState() => _DialogoEliminarCuentaState();
}

class _DialogoEliminarCuentaState extends State<_DialogoEliminarCuenta> {
  final _password = TextEditingController();
  bool _eliminando = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña.');
      return;
    }

    setState(() {
      _eliminando = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.auth.eliminarCuenta(_password.text);
      // Al cerrarse la sesión la app vuelve al login y este diálogo se cierra.
      messenger.showSnackBar(
        const SnackBar(content: Text('Tu cuenta fue eliminada.')),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _eliminando = false;
          _error = e.errorDe('password') ?? e.mensaje;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Eliminar tu cuenta?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se borrarán tu nombre, correo, celular y direcciones. '
              'Tus citas se conservan sin datos personales. '
              'Esta acción no se puede deshacer.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_eliminando,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _eliminando ? null : () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _eliminando ? null : _eliminar,
          child: _eliminando ? const CargandoEnBoton() : const Text('Eliminar'),
        ),
      ],
    );
  }
}
