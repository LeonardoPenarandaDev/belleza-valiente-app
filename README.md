# belleza-valiente-app

App móvil de **Belleza Valiente**: servicios de belleza a domicilio en Cúcuta.
Una sola app para clientas y profesionales. Por ahora solo Android.

Backend: [belleza-valiente-api](https://github.com/LeonardoPenarandaDev/belleza-valiente-api) (Laravel).

## Requisitos

- Flutter 3.47 o superior
- Android Studio o un teléfono Android con depuración USB
- La API corriendo en local (ver el README del backend)

## Ejecutar

Levantar la API en el PC:

```bash
php artisan serve --host=0.0.0.0
```

Correr la app indicando dónde está la API:

```bash
# Emulador Android (10.0.2.2 es el PC visto desde el emulador). Es el valor por defecto.
flutter run

# Teléfono en la misma Wi-Fi (usar la IP del PC)
flutter run --dart-define=API_URL=http://192.168.1.50:8000/api/v1
```

En depuración la app permite HTTP sin cifrar para hablar con la API local.
La versión de producción exige HTTPS.

## Estructura

```
lib/
├─ config.dart      URL de la API (se pasa con --dart-define)
└─ features/        una carpeta por funcionalidad: auth, catalog, booking, pro, reviews
```

## Antes de publicar en Google Play

- Confirmar el identificador de la app (`co.bellezavaliente.belleza_valiente_app` en
  `android/app/build.gradle.kts`). **No se puede cambiar después de la primera publicación.**
- Firmar la versión de producción y compilar con la URL HTTPS del VPS.
