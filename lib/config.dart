/// Configuración que se pasa al compilar con `--dart-define`.
///
/// Ejemplos:
///   flutter run --dart-define=API_URL=http://10.0.2.2:8000/api/v1        (emulador)
///   flutter run --dart-define=API_URL=http://192.168.1.50:8000/api/v1    (teléfono en la misma Wi-Fi)
///   flutter build apk --dart-define=API_URL=https://api.ejemplo.co/api/v1 (producción)
class Config {
  /// Por defecto apunta a la API local vista desde el emulador de Android.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
}
