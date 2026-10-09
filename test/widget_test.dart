import 'package:belleza_valiente_app/core/api_client.dart';
import 'package:belleza_valiente_app/core/widgets.dart';
import 'package:belleza_valiente_app/features/auth/auth_controller.dart';
import 'package:belleza_valiente_app/features/auth/auth_repository.dart';
import 'package:belleza_valiente_app/features/auth/usuario.dart';
import 'package:belleza_valiente_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _ana = Usuario(
  id: 1,
  nombre: 'Ana Pérez',
  email: 'ana@ejemplo.com',
  rol: Rol.cliente,
);

/// Repositorio falso: responde sin llamar a la API.
class _RepoFalso implements AuthRepository {
  Usuario? guardado;
  ApiException? errorLogin;
  ApiException? errorRegistro;
  Map<String, Object?>? datosRegistro;

  @override
  Future<Usuario?> usuarioGuardado() async => guardado;

  @override
  Future<Usuario> login({required String email, required String password}) async {
    if (errorLogin != null) throw errorLogin!;
    return _ana;
  }

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required bool aceptaTerminos,
  }) async {
    datosRegistro = {
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'acepta_terminos': aceptaTerminos,
    };
    if (errorRegistro != null) throw errorRegistro!;
    return _ana;
  }

  @override
  Future<void> logout() async {}
}

Future<_RepoFalso> _abrirApp(WidgetTester tester, {Usuario? guardado}) async {
  final repo = _RepoFalso()..guardado = guardado;
  final auth = AuthController(repo);
  await auth.iniciar();
  await tester.pumpWidget(BellezaValienteApp(auth: auth));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('sin sesión muestra el login', (tester) async {
    await _abrirApp(tester);

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('con sesión guardada entra directo al inicio', (tester) async {
    await _abrirApp(tester, guardado: _ana);

    expect(find.text('Hola, Ana Pérez'), findsOneWidget);
  });

  testWidgets('login correcto lleva al inicio y cerrar sesión vuelve al login', (
    tester,
  ) async {
    await _abrirApp(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), 'ana@ejemplo.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'secreta123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Ana Pérez'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('login incorrecto muestra el mensaje de la API', (tester) async {
    final repo = await _abrirApp(tester);
    repo.errorLogin = ApiException(
      'Correo o contraseña incorrectos.',
      errores: {
        'email': ['Correo o contraseña incorrectos.'],
      },
      status: 422,
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), 'ana@ejemplo.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'otra');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Hola, Ana Pérez'), findsNothing);
  });

  testWidgets('registro exige aceptar términos y muestra errores del servidor', (
    tester,
  ) async {
    final repo = await _abrirApp(tester);
    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'Ana Pérez');
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), 'ana@ejemplo.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Celular (WhatsApp)'), '300 123 4567');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'secreta123');

    final crearCuenta = find.widgetWithText(FilledButton, 'Crear cuenta');
    await tester.ensureVisible(crearCuenta);
    await tester.ensureVisible(crearCuenta);
    await tester.tap(crearCuenta);
    await tester.pumpAndSettle();

    expect(find.text('Debes aceptar los términos y la política de datos.'), findsOneWidget);
    expect(repo.datosRegistro, isNull);

    repo.errorRegistro = ApiException(
      'Ya existe una cuenta con ese correo.',
      errores: {
        'email': ['Ya existe una cuenta con ese correo.'],
      },
      status: 422,
    );
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(crearCuenta);
    await tester.tap(crearCuenta);
    await tester.pumpAndSettle();

    expect(repo.datosRegistro?['acepta_terminos'], isTrue);
    expect(find.text('Ya existe una cuenta con ese correo.'), findsOneWidget);

    // Corregido el error, la cuenta se crea y se cierra la pantalla de registro.
    repo.errorRegistro = null;
    await tester.ensureVisible(crearCuenta);
    await tester.tap(crearCuenta);
    await tester.pumpAndSettle();

    expect(find.text('Hola, Ana Pérez'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsNothing);
  });

  group('validarCelular', () {
    test('acepta celulares colombianos con o sin indicativo', () {
      expect(validarCelular('300 123 4567'), isNull);
      expect(validarCelular('+57 300-123-4567'), isNull);
    });

    test('rechaza números que no son celulares de 10 dígitos', () {
      expect(validarCelular('12345'), isNotNull);
      expect(validarCelular('6075712345'), isNotNull);
    });
  });

  test('Usuario.fromJson lee la respuesta de la API', () {
    final usuario = Usuario.fromJson({
      'id': 7,
      'name': 'Luz',
      'email': 'luz@ejemplo.com',
      'telefono': '573001234567',
      'rol': 'profesional',
      'profesional_id': 3,
    });

    expect(usuario.esProfesional, isTrue);
    expect(usuario.profesionalId, 3);
  });
}
