import 'package:belleza_valiente_app/core/api_client.dart';
import 'package:belleza_valiente_app/core/fechas.dart';
import 'package:belleza_valiente_app/features/auth/auth_controller.dart';
import 'package:belleza_valiente_app/features/auth/auth_repository.dart';
import 'package:belleza_valiente_app/features/auth/usuario.dart';
import 'package:belleza_valiente_app/features/reservas/reserva.dart';
import 'package:belleza_valiente_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

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

const _profesional = Usuario(
  id: 2,
  nombre: 'Laura Gómez',
  email: 'laura@ejemplo.com',
  rol: Rol.profesional,
);

Future<ReservasFalso> _abrir(
  WidgetTester tester,
  Usuario usuario, {
  List<Reserva> reservas = const [],
}) async {
  // Pantalla del tamaño de un teléfono (la de pruebas es de 800×600).
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final repo = ReservasFalso()..lista = List.of(reservas);
  final auth = AuthController(_SesionFalsa(usuario));
  await auth.iniciar();
  await tester.pumpWidget(
    BellezaValienteApp(auth: auth, catalogo: CatalogoFalso(), reservas: repo),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// Va del inicio al formulario de pedir cita con Laura.
Future<void> _irAPedirCita(WidgetTester tester) async {
  await tester.tap(find.text('Uñas'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Manicura tradicional'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Laura Gómez'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pedir cita'));
  await tester.pumpAndSettle();
}

/// Elige el día 15 del mes siguiente (siempre dentro de los próximos 60 días).
Future<void> _elegirFecha(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.event));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Próximo mes'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('15'));
  await tester.tap(find.text('ACEPTAR'));
  await tester.pumpAndSettle();
}

Future<void> _elegirHora(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.schedule));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ACEPTAR'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la clienta pide una cita y la ve en Mis citas', (tester) async {
    final repo = await _abrir(tester, _clienta);
    await _irAPedirCita(tester);

    // El servicio buscado queda elegido; Laura atiende dos zonas.
    expect(find.text('Manicura tradicional · \$26.000'), findsOneWidget);

    await tester.ensureVisible(find.text('Enviar solicitud'));
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('Elige la fecha y la hora de la cita.'), findsOneWidget);
    expect(repo.pedida, isNull);

    await _elegirFecha(tester);
    await _elegirHora(tester);
    await tester.tap(find.text('Zona'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caobos').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dirección'),
      'Calle 10 # 5-20',
    );
    await tester.ensureVisible(find.text('Enviar solicitud'));
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    final hoy = ahoraEnColombia();
    final mes = hoy.month == 12 ? 1 : hoy.month + 1;
    final anio = hoy.month == 12 ? hoy.year + 1 : hoy.year;
    expect(repo.pedida, {
      'profesional_id': 10,
      'servicio_id': 7,
      'zona_id': caobos.id,
      'fecha_hora': '$anio-${mes.toString().padLeft(2, '0')}-15T09:00:00-05:00',
      'direccion': 'Calle 10 # 5-20',
      'notas': '',
    });

    // Vuelve al inicio, en la pestaña Mis citas.
    expect(find.textContaining('Solicitud enviada'), findsOneWidget);
    expect(find.text('Esperando que la profesional acepte.'), findsOneWidget);
    expect(find.text('Cancelar cita'), findsOneWidget);
  });

  testWidgets('no deja pedir una cita en una hora que ya pasó', (tester) async {
    final repo = await _abrir(tester, _clienta);
    await _irAPedirCita(tester);

    // Hoy (fecha inicial del calendario) a las 00:00: siempre ya pasó.
    await tester.tap(find.byIcon(Icons.event));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();
    // Cambia al ingreso por teclado (formato de 24 horas) y escribe 00:00.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '0');
    await tester.enterText(find.byType(TextFormField).at(1), '00');
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dirección'),
      'Calle 10 # 5-20',
    );
    await tester.ensureVisible(find.text('Enviar solicitud'));
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    expect(
      find.text('Elige una fecha y hora que no hayan pasado.'),
      findsOneWidget,
    );
    expect(repo.pedida, isNull);
  });

  testWidgets('la clienta cancela una cita próxima', (tester) async {
    final repo = await _abrir(
      tester,
      _clienta,
      reservas: [
        reservaDePrueba(acciones: {AccionReserva.cancelar}),
      ],
    );
    await tester.tap(find.text('Mis citas').last);
    await tester.pumpAndSettle();

    expect(
      find.text('jueves 15 de octubre, 3:00 p. m. · 45 min'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar cita'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Me surgió un viaje');
    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar cita'));
    await tester.pumpAndSettle();

    expect(repo.ejecutadas.single, (
      AccionReserva.cancelar,
      1,
      'Me surgió un viaje',
    ));
    expect(find.text('Cita cancelada.'), findsOneWidget);
  });

  testWidgets('la profesional acepta una solicitud y ve el contacto', (
    tester,
  ) async {
    final repo = await _abrir(
      tester,
      _profesional,
      reservas: [
        reservaDePrueba(
          acciones: {AccionReserva.aceptar, AccionReserva.rechazar},
        ),
      ],
    );

    expect(find.text('Solicitudes (1)'), findsOneWidget);
    expect(
      find.text('Verás la dirección y el celular cuando aceptes la cita.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Aceptar la cita?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar').last);
    await tester.pumpAndSettle();

    expect(repo.ejecutadas.single.$1, AccionReserva.aceptar);
    expect(find.text('Solicitudes'), findsOneWidget);
    expect(find.text('Agenda (1)'), findsOneWidget);

    await tester.tap(find.text('Agenda (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Calle 10 # 5-20 (Centro)'), findsOneWidget);
    expect(find.text('300 123 4567'), findsOneWidget);
  });

  testWidgets('la profesional debe dar el motivo para cancelar', (
    tester,
  ) async {
    final repo = await _abrir(
      tester,
      _profesional,
      reservas: [
        reservaDePrueba(
          estado: EstadoReserva.aceptada,
          acciones: {AccionReserva.cancelar},
        ),
      ],
    );
    await tester.tap(find.text('Agenda (1)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar cita'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar cita'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el motivo.'), findsOneWidget);
    expect(repo.ejecutadas, isEmpty);

    await tester.enterText(find.byType(TextField), 'Tuve una calamidad');
    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar cita'));
    await tester.pumpAndSettle();
    expect(repo.ejecutadas.single, (
      AccionReserva.cancelar,
      1,
      'Tuve una calamidad',
    ));

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(
      find.text('Cancelaste esta cita: Tuve una calamidad'),
      findsOneWidget,
    );
  });

  testWidgets('si el servidor rechaza la acción se muestra su mensaje', (
    tester,
  ) async {
    final repo = await _abrir(
      tester,
      _profesional,
      reservas: [
        reservaDePrueba(
          acciones: {AccionReserva.aceptar, AccionReserva.rechazar},
        ),
      ],
    );
    repo.errorAccion = ApiException(
      'Esta cita se cruza con otra que ya aceptaste.',
      status: 409,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Esta cita se cruza con otra que ya aceptaste.'),
      findsOneWidget,
    );
  });

  testWidgets('las solicitudes vencidas solo se pueden rechazar', (
    tester,
  ) async {
    await _abrir(
      tester,
      _profesional,
      reservas: [
        reservaDePrueba(vencida: true, acciones: {AccionReserva.rechazar}),
      ],
    );

    expect(find.text('Vencida'), findsOneWidget);
    expect(
      find.text('La fecha ya pasó: ya no se puede aceptar.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Aceptar'), findsNothing);
    expect(find.text('Rechazar'), findsOneWidget);
  });

  group('Reserva.fromJson', () {
    test('lee la respuesta de la API', () {
      final r = Reserva.fromJson({
        'id': 5,
        'estado': 'aceptada',
        'vencida': false,
        'fecha_hora': '2026-10-15T15:00:00-05:00',
        'fecha_hora_fin': '2026-10-15T15:45:00-05:00',
        'duracion_minutos': 45,
        'precio': 25000,
        'direccion': 'Calle 10 # 5-20',
        'notas': null,
        'motivo': null,
        'cancelada_por': null,
        'servicio': {'id': 7, 'nombre': 'Manicura tradicional'},
        'zona': {'id': 1, 'nombre': 'Centro'},
        'profesional': {
          'id': 1,
          'nombre': 'Laura Gómez',
          'telefono': '573000000000',
        },
        'cliente': {'nombre': 'Clienta de prueba'},
        'acciones': ['cancelar', 'otra-desconocida'],
        'creada_at': '2026-10-13T17:00:00-05:00',
      });

      expect(r.estado, EstadoReserva.aceptada);
      expect(r.acciones, {AccionReserva.cancelar});
      expect(r.profesionalTelefono, '573000000000');
      expect(r.clienteTelefono, isNull);
      expect(formatoFechaHora(r.fechaHora), 'jueves 15 de octubre, 3:00 p. m.');
    });
  });

  test('isoColombia arma la fecha con el desfase de Colombia', () {
    expect(
      isoColombia(DateTime(2026, 1, 5), 7, 30),
      '2026-01-05T07:30:00-05:00',
    );
  });
}
