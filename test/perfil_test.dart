import 'package:belleza_valiente_app/core/api_client.dart';
import 'package:belleza_valiente_app/features/auth/auth_controller.dart';
import 'package:belleza_valiente_app/features/auth/auth_repository.dart';
import 'package:belleza_valiente_app/features/auth/usuario.dart';
import 'package:belleza_valiente_app/features/catalogo/modelos.dart';
import 'package:belleza_valiente_app/features/perfil/mi_perfil_repository.dart';
import 'package:belleza_valiente_app/features/perfil/mi_perfil_screen.dart';
import 'package:belleza_valiente_app/features/perfil/perfil_propio.dart';
import 'package:belleza_valiente_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _SesionFalsa implements AuthRepository {
  @override
  Future<Usuario?> usuarioGuardado() async => const Usuario(
    id: 2,
    nombre: 'Laura Gómez',
    email: 'laura@ejemplo.com',
    rol: Rol.profesional,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Abre la app como profesional y entra a "Mi perfil".
Future<MiPerfilFalso> _abrirMiPerfil(
  WidgetTester tester, {
  PerfilPropio? perfil,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final repo = MiPerfilFalso(perfil);
  final auth = AuthController(_SesionFalsa());
  await auth.iniciar();
  await tester.pumpWidget(
    BellezaValienteApp(
      auth: auth,
      catalogo: CatalogoFalso(),
      reservas: ReservasFalso(),
      miPerfil: repo,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mi perfil'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('la profesional ve su perfil', (tester) async {
    await _abrirMiPerfil(tester);

    expect(find.text('Manicurista con 5 años de experiencia.'), findsOneWidget);
    expect(find.text('5 años de experiencia'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Manicura tradicional'), findsOneWidget);
    expect(find.text(r'$26.000'), findsOneWidget);
    expect(find.text('Fotos (0 de 10)'), findsOneWidget);
    expect(find.textContaining('las clientas no'), findsNothing);
  });

  testWidgets('avisa si las clientas aún no ven su perfil', (tester) async {
    await _abrirMiPerfil(
      tester,
      perfil: perfilPropioDePrueba(verificada: false),
    );

    expect(
      find.text(
        'Las clientas aún no ven tu perfil: la fundación debe verificarlo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('edita la presentación y los años de experiencia', (
    tester,
  ) async {
    final repo = await _abrirMiPerfil(tester);

    await tester.tap(find.byTooltip('editar sobre mí'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sobre mí'),
      'Uñas en gel y acrílicas.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Años de experiencia'),
      '7',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.datos, {
      'bio': 'Uñas en gel y acrílicas.',
      'anios_experiencia': 7,
    });
    expect(find.text('Cambios guardados.'), findsOneWidget);
    expect(find.text('Uñas en gel y acrílicas.'), findsOneWidget);
    expect(find.text('7 años de experiencia'), findsOneWidget);
  });

  testWidgets('elige las zonas donde atiende', (tester) async {
    final repo = await _abrirMiPerfil(tester);

    await tester.tap(find.byTooltip('editar zonas donde atiendo'));
    await tester.pumpAndSettle();

    // Sin zonas no se puede guardar.
    await tester.tap(find.widgetWithText(FilterChip, 'Centro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige al menos una zona.'), findsOneWidget);
    expect(repo.zonas, isNull);

    await tester.tap(find.widgetWithText(FilterChip, 'Caobos'));
    await tester.tap(find.widgetWithText(FilterChip, 'Atalaya'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.zonas, unorderedEquals([caobos.id, atalaya.id]));
  });

  testWidgets('elige servicios y precios', (tester) async {
    final repo = await _abrirMiPerfil(tester);

    await tester.tap(find.byTooltip('editar servicios y precios'));
    await tester.pumpAndSettle();

    // Viene con el servicio que ya ofrece y su precio.
    expect(find.widgetWithText(TextFormField, '26000'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('precio-7')), '500');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.textContaining(r'Entre $1.000'), findsOneWidget);
    expect(repo.servicios, isNull);

    await tester.enterText(find.byKey(const ValueKey('precio-7')), '28000');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final enviado = repo.servicios!.single;
    expect(enviado.servicioId, 7);
    expect(enviado.precio, 28000);
    expect(enviado.activo, isTrue);
  });

  testWidgets('exige al menos un servicio activo', (tester) async {
    final repo = await _abrirMiPerfil(tester);
    await tester.tap(find.byTooltip('editar servicios y precios'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige al menos un servicio.'), findsOneWidget);
    expect(repo.servicios, isNull);
  });

  testWidgets('muestra el error del servidor al guardar', (tester) async {
    final repo = await _abrirMiPerfil(tester);
    repo.errorGuardar = ApiException(
      'Datos inválidos.',
      errores: {
        'zonas.0': ['La zona seleccionada no es válida.'],
      },
      status: 422,
    );

    await tester.tap(find.byTooltip('editar zonas donde atiendo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('La zona seleccionada no es válida.'), findsOneWidget);
  });

  testWidgets('agrega y borra fotos del portafolio', (tester) async {
    final repo = await _abrirMiPerfil(
      tester,
      perfil: perfilPropioDePrueba(
        fotos: const [Foto(id: 1, url: 'http://fotos.test/1.jpg')],
      ),
    );
    expect(find.text('Fotos (1 de 10)'), findsOneWidget);

    await tester.tap(find.byTooltip('Borrar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();
    expect(repo.borradas, [1]);
    expect(find.text('Fotos (0 de 10)'), findsOneWidget);
  });

  testWidgets('sube la foto elegida de la galería', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final repo = MiPerfilFalso();
    await tester.pumpWidget(
      MaterialApp(
        home: MiPerfilScope(
          repo: repo,
          child: MiPerfilScreen(elegirFoto: () async => 'foto.jpg'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar foto'));
    await tester.pumpAndSettle();

    expect(repo.subidas, ['foto.jpg']);
    expect(find.text('Foto agregada.'), findsOneWidget);
    expect(find.text('Fotos (1 de 10)'), findsOneWidget);
  });

  test('PerfilPropio.fromJson lee la respuesta de la API', () {
    final perfil = PerfilPropio.fromJson({
      'id': 3,
      'nombre': 'Laura Gómez',
      'bio': null,
      'anios_experiencia': null,
      'calificacion_promedio': 0,
      'total_calificaciones': 0,
      'verificada': true,
      'activa': false,
      'zonas': [
        {'id': 1, 'nombre': 'Centro'},
      ],
      'servicios': [
        {
          'servicio_id': 7,
          'categoria_id': 2,
          'nombre': 'Manicura',
          'duracion_minutos': 45,
          'precio': 25000,
          'activo': false,
        },
      ],
      'fotos': [
        {'id': 9, 'url': 'http://api.test/storage/portafolio/3/a.jpg'},
      ],
    });

    expect(perfil.activa, isFalse);
    expect(perfil.servicios.single.activo, isFalse);
    expect(perfil.servicios.single.toJson(), {
      'servicio_id': 7,
      'precio': 25000,
      'activo': false,
    });
    expect(perfil.fotos.single.id, 9);
  });
}
