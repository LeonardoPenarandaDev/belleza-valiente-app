import 'package:belleza_valiente_app/core/api_client.dart';
import 'package:belleza_valiente_app/core/formato.dart';
import 'package:belleza_valiente_app/features/auth/auth_controller.dart';
import 'package:belleza_valiente_app/features/auth/auth_repository.dart';
import 'package:belleza_valiente_app/features/auth/usuario.dart';
import 'package:belleza_valiente_app/features/catalogo/modelos.dart';
import 'package:belleza_valiente_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Sesión ya iniciada con el rol indicado.
class _SesionFalsa implements AuthRepository {
  _SesionFalsa(this.usuario);

  final Usuario usuario;

  @override
  Future<Usuario?> usuarioGuardado() async => usuario;

  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _clienta = Usuario(
  id: 1,
  nombre: 'Ana Pérez',
  email: 'ana@ejemplo.com',
  rol: Rol.cliente,
);

Future<CatalogoFalso> _abrir(
  WidgetTester tester, {
  Usuario usuario = _clienta,
  CatalogoFalso? catalogo,
}) async {
  final repo = catalogo ?? CatalogoFalso();
  final auth = AuthController(_SesionFalsa(usuario));
  await auth.iniciar();
  await tester.pumpWidget(
    BellezaValienteApp(
      auth: auth,
      catalogo: repo,
      reservas: ReservasFalso(),
      miPerfil: MiPerfilFalso(),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('la clienta va de la categoría al perfil de la profesional', (
    tester,
  ) async {
    await _abrir(tester);

    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Cabello'), findsOneWidget);

    await tester.tap(find.text('Uñas'));
    await tester.pumpAndSettle();
    expect(find.text('Desde \$25.000 · 45 min'), findsOneWidget);

    await tester.tap(find.text('Manicura tradicional'));
    await tester.pumpAndSettle();
    expect(find.text('Laura Gómez'), findsOneWidget);
    expect(find.text('\$26.000'), findsOneWidget);
    expect(find.text('4,8 (12)'), findsOneWidget);
    expect(find.text('Centro, Caobos'), findsOneWidget);

    await tester.tap(find.text('Laura Gómez'));
    await tester.pumpAndSettle();
    expect(find.text('5 años de experiencia'), findsOneWidget);
    expect(find.text('Manicurista con 5 años de experiencia.'), findsOneWidget);
    expect(find.text('Uñas en gel'), findsOneWidget);
    expect(find.text('\$45.000'), findsOneWidget);
    expect(find.text('1 h 30 min'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Muy puntual y cuidadosa.'), 100);
    expect(find.text('Muy puntual y cuidadosa.'), findsOneWidget);
  });

  testWidgets('filtrar por zona vuelve a buscar y avisa si no hay nadie', (
    tester,
  ) async {
    final repo = await _abrir(tester);
    await tester.tap(find.text('Uñas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manicura tradicional'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Todas las zonas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atalaya').last);
    await tester.pumpAndSettle();

    expect(repo.busquedas, [null, atalaya.id]);
    expect(find.text('Laura Gómez'), findsNothing);
    expect(
      find.textContaining(
        'No hay profesionales para este servicio en esta zona',
      ),
      findsOneWidget,
    );
  });

  testWidgets('si la búsqueda falla se puede reintentar', (tester) async {
    final repo = CatalogoFalso()
      ..errorProfesionales = ApiException(
        'No se pudo conectar con el servidor.',
      );
    await _abrir(tester, catalogo: repo);
    await tester.tap(find.text('Uñas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manicura tradicional'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);

    repo.errorProfesionales = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Laura Gómez'), findsOneWidget);
  });

  testWidgets('la profesional no ve el catálogo', (tester) async {
    await _abrir(
      tester,
      usuario: const Usuario(
        id: 2,
        nombre: 'Laura Gómez',
        email: 'laura@ejemplo.com',
        rol: Rol.profesional,
      ),
    );

    expect(find.text('No tienes solicitudes nuevas.'), findsOneWidget);
    expect(find.text('Uñas'), findsNothing);
  });

  group('modelos', () {
    test('leen la lista de profesionales de la API', () {
      final pagina = PaginaProfesionales.fromJson({
        'data': [
          {
            'id': 1,
            'nombre': 'Laura Gómez',
            'bio': null,
            'anios_experiencia': 5,
            'calificacion_promedio': 0,
            'total_calificaciones': 0,
            'foto_principal': null,
            'precio': 25000,
            'zonas': [
              {'id': 1, 'nombre': 'Centro'},
            ],
          },
        ],
        'links': {},
        'meta': {'current_page': 1, 'last_page': 2, 'total': 21},
      });

      expect(pagina.hayMas, isTrue);
      expect(pagina.profesionales.single.precio, 25000);
      expect(pagina.profesionales.single.calificacionPromedio, 0.0);
      expect(pagina.profesionales.single.zonas.single.nombre, 'Centro');
    });

    test('leen el perfil público de la API', () {
      final perfil = PerfilProfesional.fromJson({
        'id': 1,
        'nombre': 'Laura Gómez',
        'bio': 'Manicurista',
        'anios_experiencia': null,
        'calificacion_promedio': 4.5,
        'total_calificaciones': 2,
        'zonas': [],
        'servicios': [
          {
            'servicio_id': 7,
            'categoria_id': 2,
            'nombre': 'Manicura',
            'duracion_minutos': 45,
            'precio': 25000,
          },
        ],
        'fotos': [
          {'id': 3, 'url': 'http://10.0.2.2:8000/storage/portafolio/1/a.jpg'},
        ],
        'calificaciones': [
          {
            'estrellas': 5,
            'comentario': null,
            'fecha': '2026-10-01T15:00:00-05:00',
          },
        ],
      });

      expect(perfil.servicios.single.precio, 25000);
      expect(perfil.fotos.single.url, endsWith('/a.jpg'));
      expect(perfil.calificaciones.single.fecha.toUtc().hour, 20);
    });
  });

  test('formatos de precio y duración', () {
    expect(formatoPesos(25000), '\$25.000');
    expect(formatoPesos(200000), '\$200.000');
    expect(formatoDuracion(45), '45 min');
    expect(formatoDuracion(60), '1 h');
    expect(formatoDuracion(90), '1 h 30 min');
  });
}
