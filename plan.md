# Plan de desarrollo — Belleza Valiente

> Basado en *Proyecto_Belleza_Valiente2.0.pdf* (propuesta institucional) y *Belleza Valiente — Plan técnico.pdf*.
>
> **Meta inmediata: un MVP que funcione en 6 semanas (del 5 de octubre al 15 de noviembre de 2026)**, con profesionales reales recibiendo reservas reales en Cúcuta.
> Todo lo demás (pagos en línea, mapa, notificaciones push, cupones, membresías, iOS) queda para después.
>
> **Stack:** app en **Flutter** (Android) + backend propio en **Laravel**.
> Esto reemplaza a Supabase del plan técnico original.
>
> **Servidor:** las pruebas empiezan **en local** (el PC de desarrollo). El **VPS se alquila después**, antes de las pruebas con usuarias reales (ver sección 1.8).

## Dónde está cada cosa

| Qué | Ruta en el PC |
|---|---|
| **Backend Laravel** | `C:\laragon\www\belleza-valiente-api` — GitHub: https://github.com/LeonardoPenarandaDev/belleza-valiente-api |
| **App Flutter** | `C:\laragon\www\belleza_valiente_app` — GitHub: https://github.com/LeonardoPenarandaDev/belleza-valiente-app |
| **Este plan (versión oficial)** | `C:\laragon\www\belleza_valiente_app\plan.md` |
| App de práctica (login de prueba, ya no se usa) | `C:\Users\Public\mi_primera_app` |
| PHP 8.3 (Laragon) | `C:\laragon\bin\php\php-8.3.30-nts-Win32-vs16-x64` |
| MySQL 8.0 (Laragon) | `C:\laragon\bin\mysql\mysql-8.0.30-winx64` |
| Flutter SDK | `C:\flutter` |

Bases de datos MySQL (usuario `root`, sin contraseña): `belleza_valiente` (desarrollo) y `belleza_valiente_test` (pruebas automáticas).

Accesos al backend en local:
- Desde el PC: `http://belleza-valiente-api.test` (dominio que crea Laragon).
- Desde el emulador o el teléfono: abrir la terminal de Laragon en `C:\laragon\www\belleza-valiente-api` y ejecutar `php artisan serve --host=0.0.0.0` (ver sección 1.8).

Archivos clave del backend:

| Archivo o carpeta | Contenido |
|---|---|
| `.env` | Configuración local (base de datos, comisión). No se sube a Git |
| `app\Models\` | Modelos: `User`, `Zona`, `Categoria`, `Servicio`, `Profesional`, `FotoPortafolio`, `Reserva`, `Calificacion` |
| `app\Enums\` | `Rol`, `EstadoReserva`, `MetodoPago` |
| `config\belleza.php` | Porcentaje de comisión |
| `lang\es\` | Mensajes de validación en español (y nombres legibles de los campos en `validation.php`) |
| `bootstrap\app.php` | Mensajes en español de los errores 401, 403, 404 y 429 de la API |
| `app\Providers\Filament\AdminPanelProvider.php` | Panel de administración en `/admin` (solo rol `admin`) |
| `database\migrations\` | Definición de las tablas |
| `database\seeders\` | Zonas, catálogo y usuarios de prueba |
| `routes\api.php` | Rutas de la API |

Archivos clave de la app:

| Archivo | Contenido |
|---|---|
| `lib\config.dart` | URL de la API, se pasa con `--dart-define=API_URL=...` |
| `lib\core\api_client.dart` | Cliente HTTP (`dio`): agrega el token y convierte los errores de la API en `ApiException` |
| `lib\core\token_storage.dart` | Token guardado cifrado (`flutter_secure_storage`) |
| `lib\core\theme.dart` | Colores de marca (azul marino y dorado) |
| `lib\features\auth\` | Sesión (`AuthController`, accesible con `AuthScope.of(context)`), login y registro |
| `lib\features\inicio\` | Inicio provisional tras iniciar sesión (se reemplaza en la semana 2) |
| `android\app\src\debug\AndroidManifest.xml` | Permite HTTP solo en depuración (API local) |

---

## 0. Estado actual y próximo paso

**Hecho**

- ✅ Entorno local: Laragon (PHP 8.3, MySQL 8) y Flutter en `C:\flutter`.
- ✅ Proyecto Laravel 13 creado, con Sanctum instalado.
- ✅ Tablas y modelos del MVP (sección 1.4).
- ✅ Datos iniciales: 9 zonas y 25 servicios en 5 categorías (**provisionales**, por confirmar con la fundación) y usuarios de prueba solo en local.
- ✅ Pruebas automáticas sobre la base MySQL `belleza_valiente_test`.
- ✅ Proyecto Flutter `belleza_valiente_app` creado: URL de la API configurable (`lib/config.dart`) y HTTP permitido solo en depuración.
- ✅ Backend: zona horaria `America/Bogota`.
- ✅ Backend: autenticación (`/auth/register`, `/auth/login`, `/auth/logout`, `GET /me`, `DELETE /me`) con pruebas automáticas. Eliminar la cuenta anonimiza a la usuaria (columna `users.eliminada_at`).
- ✅ Backend: mensajes de validación y de error de la API en español (`lang/es`, `bootstrap/app.php`).
- ✅ Backend: **Filament 5.10 instalado y compatible con Laravel 13**. Panel en `/admin`, solo para el rol `admin` (en local: `admin@belleza.test`). Aún sin recursos (semana 3).
- ✅ App: paquetes agregados, tema de marca, cliente HTTP con token cifrado, login, registro de clienta (con aceptación de términos), sesión guardada al reabrir la app y cierre de sesión. Pruebas de widgets en `test/`. Contrato verificado contra la API local.

**Siguiente (en este orden)**

1. App: probar login y registro en un emulador o teléfono contra la API local (en este PC aún no hay emulador creado: crearlo en Android Studio → Device Manager).
2. Backend (semana 2): endpoints de catálogo (`/categorias`, `/zonas`), profesionales (`/profesionales`, `/profesionales/{id}`), perfil profesional y fotos, con Policies y pruebas.
3. App (semana 2): inicio con categorías, servicios por categoría, lista de profesionales con filtro por zona y perfil público.
4. Cerrar los pendientes de la sección 1.10 (días 1–3), sobre todo el VPS y la cuenta de Google Play. Falta también el enlace a los términos y la política de datos en el registro (lo entrega la fundación).

---

## 1. El MVP de 6 semanas

### 1.1 Qué tiene que funcionar

Un solo flujo, de principio a fin y sin huecos:

1. La clienta se registra e inicia sesión.
2. Elige una categoría y un servicio.
3. Ve las profesionales que lo ofrecen en su zona, con precio, fotos y calificación.
4. Pide una cita: fecha, hora, dirección y notas.
5. La profesional ve la solicitud y la **acepta o rechaza**.
6. Se presta el servicio; la profesional lo marca como **completado** y registra cómo le pagaron.
7. La clienta califica.

Y del lado de la fundación: un **panel de administración web** para crear y verificar profesionales, ver las citas y consultar los indicadores.

### 1.2 Qué se simplifica (y cómo se reemplaza por ahora)

| Funcionalidad del plan completo | En el MVP | Por qué |
|---|---|---|
| Pagos con Wompi y comisión automática | **Pago por fuera de la app** (efectivo, Nequi, transferencia). La profesional registra método y valor; Laravel calcula la comisión para los reportes | Integrar pagos bien toma ~5 semanas-persona y exige cuentas aprobadas |
| Mapa y búsqueda por cercanía | **Lista de profesionales filtrada por zona/barrio** (lista fija de zonas de Cúcuta) | El mapa se añade después sin rehacer nada |
| Calendario con horas libres y control de cruces | La clienta propone fecha y hora; **la profesional acepta o rechaza**. Al aceptar, el servidor rechaza si el horario se cruza con otra cita aceptada | Evita construir el motor de disponibilidad |
| Notificaciones push (Firebase) | La app **refresca las citas** al abrir, al deslizar hacia abajo y cada 30 s en pantalla + **WhatsApp** entre clienta y profesional una vez aceptada la cita | Push y tiempo real (Laravel Reverb) se añaden después |
| Registro y verificación de profesionales dentro de la app | **La fundación crea las cuentas de profesional desde el panel** tras verificarlas en persona. El registro público de la app es solo para clientas | Las 30 profesionales ya las selecciona la fundación; evita cuentas falsas |
| Panel administrativo completo | **Panel con Filament** (sobre Laravel): usuarios, profesionales, citas e indicadores básicos | Filament genera el panel casi solo a partir de los modelos |
| Botón de emergencia con ubicación | **Botón de ayuda** que abre WhatsApp con el equipo de soporte | Cubre lo esencial con poco código |
| 10 estados de reserva | **5 estados**: solicitada, aceptada, rechazada, completada, cancelada | Menos casos que probar |
| Expiración automática de solicitudes | Las solicitudes con fecha pasada **no se pueden aceptar** y la app las muestra como vencidas | La expiración con el Scheduler queda para la Fase 2 |
| Android + iOS | **Solo Android** | iOS añade costo (USD 99/año) y revisión de Apple |
| Favoritos, cupones, membresías, puntos, reportes avanzados | Fuera | Fase 2 |

### 1.3 Pantallas del MVP

**App móvil (Flutter) — 10 pantallas**

| # | Pantalla | Rol |
|---|---|---|
| 1 | Login / registro de clienta (con aceptación de términos y política de datos) | Todos |
| 2 | Inicio: categorías | Clienta |
| 3 | Servicios de una categoría | Clienta |
| 4 | Lista de profesionales (filtro por zona) | Clienta |
| 5 | Perfil de la profesional: servicios, precios, fotos, calificación | Clienta |
| 6 | Pedir cita: fecha, hora, dirección, notas | Clienta |
| 7 | Mis citas (próximas e historial) + cancelar + calificar + WhatsApp con la profesional | Clienta |
| 8 | Solicitudes y agenda: aceptar, rechazar, cancelar, completar + WhatsApp con la clienta | Profesional |
| 9 | Mi perfil profesional: datos, zonas, servicios y precios, fotos | Profesional |
| 10 | Mi perfil / cerrar sesión / **eliminar mi cuenta** / ayuda por WhatsApp | Todos |

**Panel web (Laravel + Filament)**

- Usuarios y profesionales: **crear profesional**, marcar verificada, activar/desactivar
- Categorías, servicios y zonas
- Citas con filtro por estado
- Tablero con indicadores: profesionales activas, citas por estado, valor total, comisión, calificación promedio

**Página web pública (fuera de la app)**

- Términos y condiciones, política de tratamiento de datos e **instrucciones para eliminar la cuenta**. Google Play pide estas URL en la ficha de la app.

### 1.4 Base de datos del MVP (10 tablas + las de Laravel)

Ya creadas en `database\migrations\`:

| Tabla | Contenido |
|---|---|
| `users` | Nombre, correo, teléfono, contraseña, rol (`cliente`, `profesional`, `admin`), fecha de aceptación de términos |
| `zonas` | Zonas o barrios de Cúcuta que se cubren |
| `categorias` | Cabello, Uñas, Barbería, Rostro, Maquillaje |
| `servicios` | Catálogo base por categoría, con duración y precio de referencia |
| `profesionales` | `user_id`, bio, años de experiencia, verificada (sí/no), calificación promedio y total de calificaciones |
| `profesional_zona` | Qué zonas atiende cada profesional |
| `servicio_profesional` | Qué servicios ofrece cada profesional y a qué precio |
| `fotos_portafolio` | Ruta de cada foto de la profesional |
| `reservas` | Clienta, profesional, servicio, zona, fecha/hora, **duración y precio copiados al pedir la cita**, dirección, notas, estado, motivo, método de pago, valor, comisión |
| `calificaciones` | Una por reserva completada: estrellas y comentario |

Más las tablas propias de Laravel (`personal_access_tokens` de Sanctum, `sessions`, `jobs`, etc.).

Base de datos: **MySQL 8**, igual en local y en el VPS.

**Fechas y horas:** la zona horaria de la aplicación es `America/Bogota`. La API envía y recibe fechas en ISO 8601 con desfase (`2026-10-20T15:00:00-05:00`) para que la app, el panel y el control de cruces coincidan.

### 1.5 Reglas de seguridad y de negocio (desde el primer día)

**Acceso**

- **Autenticación con Laravel Sanctum:** la app recibe un token al iniciar sesión y lo guarda cifrado en el teléfono (`flutter_secure_storage`).
- **Policies de Laravel** en cada recurso: la clienta solo ve sus citas; la profesional solo las suyas; solo el admin entra al panel.
- El registro público crea **solo clientas**. Las profesionales las crea el admin en el panel.
- Solo se listan profesionales con `verificada = true` y activas.
- Límite de intentos en login (`throttle`) y validación con Form Requests en todos los endpoints.

**Citas: todos los cambios de estado pasan por una sola clase (`ReservaService`)**

| Acción | Quién | Desde qué estado |
|---|---|---|
| Aceptar | Profesional | `solicitada`, y solo si la fecha no ha pasado |
| Rechazar | Profesional | `solicitada` |
| Cancelar | Clienta | `solicitada` o `aceptada` |
| Cancelar (con motivo obligatorio) | Profesional | `aceptada` |
| Completar (con método y valor de pago) | Profesional | `aceptada` |
| Calificar | Clienta | `completada`, una sola vez |

- Aceptar se hace en una transacción con bloqueo. El cruce se valida **por intervalo** (inicio + `duracion_minutos`), no solo por la hora exacta.
- La app nunca envía la comisión, el precio ni el estado final: los calcula el servidor.

**Privacidad (Ley 1581)**

- El teléfono y la dirección de la clienta solo los ve la profesional **después de aceptar** la cita. El teléfono de la profesional lo ve la clienta solo con la cita aceptada.
- **Eliminar cuenta** (`DELETE /me`): se borran o anonimizan los datos personales (nombre, correo, teléfono, direcciones) y las citas se conservan sin datos personales para los indicadores. Como `reservas.cliente_id` no permite borrar al usuario, se anonimiza en lugar de borrar la fila.
- **HTTPS obligatorio en el VPS** (Android bloquea HTTP sin cifrar por defecto). En local se permite HTTP solo en la versión de depuración de la app (ver sección 1.8).
- Copia de seguridad diaria de la base de datos y de las fotos, guardada **fuera del VPS**, con una restauración de prueba antes del piloto.

**Fotos**

- La app las reduce antes de subir (`image_picker` con `maxWidth` e `imageQuality`).
- El servidor solo acepta imágenes (jpg, png, webp) de hasta 5 MB y como máximo 10 fotos por profesional.

### 1.6 API del MVP

Todas bajo `/api/v1`, en JSON, con token Sanctum salvo registro y login.

| Método | Ruta | Quién | Qué hace |
|---|---|---|---|
| POST | `/auth/register` | Pública | Crear cuenta de clienta aceptando términos |
| POST | `/auth/login` | Pública | Devuelve token |
| POST | `/auth/logout` | Todos | Revoca el token |
| GET | `/me` | Todos | Datos del usuario y su rol |
| DELETE | `/me` | Todos | Eliminar la cuenta (anonimiza datos y revoca tokens) |
| GET | `/categorias` | Todos | Categorías con sus servicios |
| GET | `/zonas` | Todos | Lista de zonas de Cúcuta |
| GET | `/profesionales?servicio_id=&zona=` | Clienta | Profesionales verificadas que ofrecen el servicio en esa zona |
| GET | `/profesionales/{id}` | Clienta | Perfil, servicios, precios, fotos, calificaciones |
| GET / PUT | `/mi-perfil-profesional` | Profesional | Ver y editar bio, zonas, servicios y precios |
| POST / DELETE | `/mi-perfil-profesional/fotos` | Profesional | Subir o borrar foto del portafolio |
| GET | `/reservas` | Clienta / Profesional | Mis citas (cada una ve solo las suyas) |
| POST | `/reservas` | Clienta | Pedir cita (queda `solicitada`; el servidor copia precio y duración) |
| POST | `/reservas/{id}/aceptar` | Profesional | Aceptar (valida fecha futura y cruce de horario) |
| POST | `/reservas/{id}/rechazar` | Profesional | Rechazar con motivo opcional |
| POST | `/reservas/{id}/completar` | Profesional | Completar con método y valor de pago |
| POST | `/reservas/{id}/cancelar` | Clienta / Profesional | Cancelar según las reglas de 1.5 |
| POST | `/reservas/{id}/calificar` | Clienta | Estrellas y comentario |

Acordar este contrato en la semana 1 permite que la app y el backend avancen en paralelo. Mientras un endpoint no existe, la app usa datos de prueba.

### 1.7 Tecnología del MVP

**Backend (`belleza-valiente-api`)**
- **Laravel 13** con PHP 8.3.
- **Sanctum** (tokens para la app), **Filament** (panel admin), almacenamiento de fotos en `storage/app/public` (en el VPS requiere `php artisan storage:link`).
- Pruebas con **Pest** o PHPUnit para los permisos y los cambios de estado.

**App (`belleza_valiente_app`)**
- **Flutter**, solo Android, carpetas por funcionalidad: `lib/features/auth`, `catalog`, `booking`, `pro`, `reviews`.
- Paquetes: `dio` (llamadas a la API), `flutter_secure_storage` (token), `url_launcher` (WhatsApp), `image_picker` (fotos), `intl` (fechas y pesos).
- URL de la API con `--dart-define=API_URL=...` (`lib/config.dart`).
- **Llave de firma del APK:** se genera una sola vez, se guarda fuera del repositorio con copia en un lugar seguro de la fundación, y se anota quién la tiene. Si se pierde, no se puede actualizar la app en Google Play.

Dos repositorios en GitHub: `belleza-valiente-api` y `belleza-valiente-app`.

### 1.8 Servidor: primero local, después VPS

#### Etapa A — Pruebas en local (semanas 1–4)

Todo corre en el PC de desarrollo, sin costo:

| Pieza | Herramienta |
|---|---|
| PHP 8.3, Composer, MySQL 8 | Laragon |
| API | `php artisan serve --host=0.0.0.0 --port=8000` |
| App | Emulador Android o teléfono físico con depuración USB |

Cómo se conecta la app con la API local:

| Dónde corre la app | URL de la API |
|---|---|
| Emulador Android | `http://10.0.2.2:8000/api/v1` (10.0.2.2 es el PC visto desde el emulador; es el valor por defecto) |
| Teléfono físico en la misma red Wi-Fi | `http://<IP-del-PC>:8000/api/v1` (p. ej. `192.168.1.50`); abrir el puerto 8000 en el firewall de Windows |

- La URL nunca se escribe en el código: va en `--dart-define=API_URL=...`.
- HTTP sin cifrar está permitido **solo en la versión de depuración** (`android/app/src/debug/AndroidManifest.xml`). La versión de producción sigue exigiendo HTTPS.
- Si hace falta mostrar la app a alguien fuera de la red local antes de tener el VPS, se puede exponer la API con un túnel HTTPS temporal (Cloudflare Tunnel o ngrok). Solo para demos: el PC tiene que estar encendido.

#### Etapa B — VPS (alquilar a más tardar en la semana 4, antes del 1 de noviembre)

Las pruebas con profesionales y clientas reales (semanas 5–6) **necesitan el VPS**: la app tiene que funcionar desde cualquier teléfono, con datos móviles y a cualquier hora.

| Requisito | Para qué |
|---|---|
| VPS con Ubuntu LTS, 1–2 GB de RAM (suficiente para el piloto) | Servidor propio |
| PHP 8.3, Composer, Nginx, MySQL 8 | Ejecutar Laravel |
| Dominio o subdominio con **HTTPS** (Let's Encrypt) | La app Android lo exige |
| Cron cada minuto (`schedule:run`) | Tareas programadas |
| Copias de seguridad diarias (base de datos y fotos) fuera del VPS | Protección de datos (Ley 1581) |
| Páginas públicas de términos, privacidad y eliminación de cuenta | Requisito de Google Play |

El VPS también sirve para la Fase 2 (colas de trabajo, tiempo real con Reverb, webhooks de Wompi).

Para que el paso de local al VPS no dé sorpresas:
- Usar **MySQL en local**, igual que en el VPS (no SQLite).
- Guardar la configuración solo en `.env` (nunca contraseñas en el código ni en Git).
- Escribir el manual de despliegue en `docs/` del backend mientras se prepara el VPS.

### 1.9 Semana a semana

Supone **2 ayudantes a tiempo completo** con apoyo del mentor: uno en Flutter y otro en Laravel. **Con una sola persona, el plazo realista es de 10 a 12 semanas** o hay que recortar más; si es el caso, ajustar esta tabla desde ya.

| Semana | Ayudante 1 — App Flutter | Ayudante 2 — Laravel | Al final de la semana se puede… |
|---|---|---|---|
| **1** (5–11 oct) | ✅ Tema y colores, navegación, cliente HTTP con token, pantallas de login y registro. Pendiente: probar en emulador o teléfono | ✅ Migraciones, modelos, Sanctum, seeders, zona horaria, endpoints de auth (incluido `DELETE /me`), mensajes en español, Filament instalado | …registrarse e iniciar sesión desde el emulador o el teléfono contra la API local |
| **2** (12–18 oct) | Inicio, servicios por categoría, lista de profesionales con filtro por zona, perfil público | Endpoints de catálogo y profesionales, edición del perfil profesional, subida de fotos, Policies | …ver profesionales reales en la app |
| **3** (19–25 oct) | Pedir cita, Mis citas, pantalla de solicitudes de la profesional (aceptar/rechazar) | Endpoints de reservas, `ReservaService` con estados y control de cruces; Filament: usuarios, creación y verificación de profesionales | …pedir una cita y que la profesional la acepte |
| **4** (26 oct–1 nov) | Mi perfil profesional (servicios, precios, fotos), completar, cancelar, calificar, eliminar cuenta | Completar con pago y comisión, calificaciones y promedio; Filament: citas y tablero. **Alquilar y preparar el VPS** (Nginx, PHP, MySQL, HTTPS) y desplegar | …hacer el flujo completo de punta a punta, ya en el VPS |
| **5** (2–8 nov) | Términos y política de datos, botones de WhatsApp, refresco automático, pulir pantallas; compilar apuntando al VPS | Pruebas automáticas de permisos y estados, cargar perfiles reales del piloto, copias de seguridad y restauración de prueba, páginas públicas | …probar con 3–5 profesionales y clientas reales |
| **6** (9–15 nov) | Corrección de errores, APK firmado, prueba interna de Google Play | Corrección de errores, ajustes en producción, manual de despliegue en `docs/` | **…entregar el MVP** |

**El VPS no puede pasar de la semana 4.** Si se alquila más tarde, las pruebas con usuarias reales se corren y la entrega también.

**Regla para cumplir:** nada nuevo entra después de la semana 1. Las ideas que surjan se anotan en la sección 2.

### 1.10 Antes de empezar (días 1–3)

**Para el equipo técnico**
- [x] Preparar el entorno local (sección 1.8, etapa A).
- [ ] Definir quién alquila el VPS y con qué presupuesto (debe estar listo en la semana 4).
- [ ] Registrar el dominio o subdominio para la API, el panel y las páginas públicas (p. ej. `api.bellezavaliente.co`); puede esperar hasta la semana 4.
- [ ] Cuenta de Google Play Console (USD 25):
  - **Cuenta de organización (la fundación):** no exige prueba cerrada, pero pide número **D-U-N-S**, que puede tardar semanas. **Iniciar el trámite ya.**
  - **Cuenta personal:** exige una prueba cerrada con al menos 12 testers durante 14 días antes de publicar abiertamente.
  - Mientras tanto, el APK se puede instalar directamente.

**Para la fundación**
- [ ] Decidir: ¿se cobra comisión durante el piloto o se registra solo para los reportes?
- [ ] Lista de zonas o barrios de Cúcuta que se van a cubrir (hoy hay 9 provisionales).
- [ ] Catálogo inicial de servicios con duración y precio de referencia (hoy hay 25 provisionales).
- [ ] Texto de términos y condiciones y política de tratamiento de datos (Ley 1581).
- [ ] Número de WhatsApp de soporte.
- [ ] Datos y fotos de las primeras profesionales del piloto.

### 1.11 Criterio de "terminado"

El MVP se entrega cuando:
- [ ] Una clienta nueva puede registrarse, pedir una cita y calificarla sin ayuda.
- [ ] Una profesional puede editar su perfil, aceptar, rechazar, cancelar y completar citas.
- [ ] Una clienta no puede ver datos de otra clienta (probado con pruebas automáticas).
- [ ] Cualquier usuaria puede eliminar su cuenta desde la app.
- [ ] La API funciona en el VPS con HTTPS, tiene copia de seguridad diaria y se probó restaurarla.
- [ ] El admin puede crear y verificar profesionales y ver los indicadores en el panel.
- [ ] Al menos 10 citas reales completadas en la prueba de las semanas 5–6.

---

## 2. Después del MVP

Una vez entregado el MVP, se retoma el plan técnico original por bloques, adaptado a Laravel:

| Orden | Bloque | Cómo se hace en Laravel | Esfuerzo aprox. (semanas-persona) |
|---|---|---|---|
| 1 | Notificaciones push | Firebase Cloud Messaging desde Laravel (colas de trabajo) | 2 |
| 2 | Pagos con Wompi | Controlador de webhook con verificación de firma, comisión y liquidación en el servidor | 5–6 |
| 3 | Citas en tiempo real | Laravel Reverb (WebSockets); requiere VPS | 1–2 |
| 4 | Disponibilidad y calendario con horas libres | Tabla de horarios y bloqueos, cálculo de franjas en el servidor | 3–4 |
| 5 | Mapa y búsqueda por cercanía | Google Maps en la app; funciones espaciales de MySQL | 3 |
| 6 | Verificación de cédula en la app, registro de profesionales desde la app y botón de emergencia con ubicación | Disco privado de Laravel, solo accesible al admin | 3 |
| 7 | Estados completos de reserva (pagada, en camino, en servicio, expirada) | Ampliar `ReservaService`; expiración con el Scheduler | 2 |
| 8 | Favoritos, cupones, paquetes y membresías | Nuevas tablas y recursos de Filament | 6 |
| 9 | Reportes de impacto para financiadores | Widgets y exportación a Excel en Filament | 3 |
| 10 | Versión iOS | Misma app Flutter | 2 |

Nada del MVP se descarta: las tablas del MVP son un subconjunto de las 16 del plan técnico.

---

## 3. Decisiones pendientes

1. **¿Cuándo se paga?** La propuesta cobra después del servicio y el plan técnico antes. En el MVP se paga por fuera de la app al terminar. Para la integración con Wompi, recomiendo cobrar al aceptar y entregar el dinero a la profesional al completar.
2. **Porcentaje de comisión** definitivo y quién asume la comisión de la pasarela.
3. **Política de cancelación:** plazo mínimo para cancelar sin penalidad, y qué pasa si la profesional cancela una cita aceptada (en el MVP solo se registra el motivo).
4. **"Puntos"** y **"términos y condiciones"** aparecen en la propuesta como indicadores, pero son funcionalidades. Los términos entran al MVP; los puntos, a la Fase 2.
5. **Paleta de marca:** la maqueta usa azul marino y dorado; el plan técnico, ciruela y rosa. Para el MVP se usa la de la maqueta salvo que se decida otra.
6. **Registro de profesionales:** en el MVP las crea el admin (sección 1.2). Confirmar con la fundación que así funciona para ellas.

---

## 4. Riesgos del MVP

| Riesgo | Cómo lo reducimos |
|---|---|
| El alcance crece y no se llega a la semana 6 | Alcance congelado tras la semana 1; todo lo nuevo va a la sección 2 |
| Hay menos personas de las previstas en 1.9 | Ajustar el plazo a 10–12 semanas o recortar alcance desde la semana 1, no al final |
| El VPS se alquila tarde y no hay dónde probar con usuarias reales | Fecha límite: semana 4 (1 de noviembre); definir responsable y presupuesto en los días 1–3 |
| Algo funciona en local y falla en el VPS | Mismo motor de base de datos (MySQL) en ambos, configuración solo en `.env`, manual de despliegue en `docs/` |
| Citas con la hora corrida | Zona horaria `America/Bogota` y fechas ISO 8601 con desfase en la API |
| Filament no es compatible con Laravel 13 | ✅ Descartado: Filament 5.10 instalado y probado en la semana 1 |
| Hay más trabajo de backend que con Supabase (auth, API, despliegue) | Usar lo que Laravel ya trae: Sanctum, Policies, Form Requests, Filament |
| Datos personales expuestos (Ley 1581) | Policies en todos los recursos, pruebas automáticas de acceso cruzado, datos de contacto visibles solo con la cita aceptada, eliminación de cuenta, HTTPS y copias de seguridad |
| Se pierden datos del VPS | Copias diarias fuera del VPS y restauración probada antes del piloto |
| No hay profesionales cargadas para probar | La fundación entrega datos y fotos en los días 1–3 |
| Retraso en Google Play (D-U-N-S, prueba cerrada, eliminación de cuenta) | Iniciar el trámite ya, cumplir los requisitos desde el MVP y distribuir el APK directamente durante el piloto |
| Se pierde la llave de firma del APK | Guardarla fuera del repositorio con copia en la fundación |
