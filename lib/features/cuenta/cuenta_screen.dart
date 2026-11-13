import 'package:belleza_valiente_app/core/launcher_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_controller.dart';
import '../auth/usuario.dart';

enum _OpcionFoto { camara, galeria, borrar }

/// Mi cuenta (todos los roles): datos, foto de perfil, cerrar sesión y eliminar la cuenta.
class CuentaScreen extends StatelessWidget {
  const CuentaScreen({super.key, this.elegirFoto});

  final Future<String?> Function()? elegirFoto;

  Future<void> _cambiarFotoPerfil(
    BuildContext context,
    AuthController auth,
    Usuario usuario,
  ) async {
    if (elegirFoto != null) {
      final ruta = await elegirFoto!();
      if (ruta != null && context.mounted) {
        await auth.subirFotoPerfil(ruta);
      }
      return;
    }

    final seleccion = await showModalBottomSheet<_OpcionFoto>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Foto de perfil',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Marca.azulMarino,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Permite que te reconozcan fácilmente en cada cita',
              style: TextStyle(color: Marca.textoSecundario, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Marca.azulMarino),
              ),
              title: const Text('Tomar foto con la cámara', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, _OpcionFoto.camara),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Marca.doradoClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Marca.doradoOscuro),
              ),
              title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, _OpcionFoto.galeria),
            ),
            if (usuario.fotoPerfil != null) ...[
              const Divider(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete_outline, color: Colors.red.shade400),
                ),
                title: Text(
                  'Eliminar foto actual',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, _OpcionFoto.borrar),
              ),
            ],
          ],
        ),
      ),
    );

    if (seleccion == null || !context.mounted) return;

    if (seleccion == _OpcionFoto.borrar) {
      try {
        await auth.borrarFotoPerfil();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto de perfil eliminada.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.mensaje),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
      return;
    }

    final source = seleccion == _OpcionFoto.camara ? ImageSource.camera : ImageSource.gallery;
    final archivo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (archivo == null || !context.mounted) return;

    try {
      await auth.subirFotoPerfil(archivo.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto de perfil actualizada.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.mensaje),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final usuario = auth.usuario;
    if (usuario == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          LauncherService.abrirWhatsApp(
            telefono: "573000000000",
            mensaje: "Hola, necesito soporte con la app Belleza Valiente.",
          );
        },
        backgroundColor: const Color(0xFF25D366),
        icon: const Icon(Icons.support_agent, color: Colors.white),
        label: const Text('Ayuda', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                AvatarProfesional(
                  nombre: usuario.nombre,
                  foto: usuario.fotoPerfil,
                  radio: 26,
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Marca.azulMarino,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                ),
              ],
            ),
            title: Text(usuario.nombre),
            subtitle: Text(switch (usuario.rol) {
              Rol.profesional => 'Profesional',
              Rol.admin => 'Administradora',
              Rol.cliente => 'Clienta',
            }),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: () => _cambiarFotoPerfil(context, auth, usuario),
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
