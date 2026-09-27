# TalentMatch — Plan de Desarrollo Frontend (Flutter)

> **Documento de contexto para el agente de IA.**
> Léelo completo antes de generar cualquier código. Es la fuente de verdad del frontend.

---

## 1. Estado actual del proyecto

### Repositorios

| Repositorio | Ruta local | Propósito |
|---|---|---|
| `FRONTEND_CODEX` | `/home/nicolas-vasquez/Escritorio/FRONTEND_CODEX` | App móvil Flutter (TalentMatch) |
| `BACKEND_CODEX` | `/home/nicolas-vasquez/Escritorio/BACKEND_CODEX` | Backend FastAPI + microservicio ML |

### Lo que ya existe en el frontend

- Un único archivo `lib/main.dart` con **112 líneas** que implementa fielmente el wireframe visual:
  - Navegación de 4 tabs (Inicio, Explorar, Postulaciones, Perfil)
  - `JobCard`, `AiBanner`, `Feature`, `Brand`, `Detail`
  - Colores, fuentes y layout idénticos al wireframe HTML
  - **Todos los datos son hardcodeados** (sin conexión al backend)
  - **Sin autenticación** (sin login/registro)
  - **Sin arquitectura limpia** (todo en un solo archivo)

### Lo que existe en el wireframe

Archivo: `BACKEND_CODEX/CONTEXT/WIREFRAMES/talentmatch_wireframe_movil.html`

- 4 pantallas funcionales: Inicio, Explorar, Postulaciones, Perfil
- Paleta de colores y componentes definidos

---

## 2. Paleta de colores y tema (del wireframe — no cambiar)

```dart
// Colores base
const blue   = Color(0xFF1558D6);   // --blue:   #1558D6
const navy   = Color(0xFF10265F);   // --navy:   #10265F
const cyan   = Color(0xFF08C8DF);   // --cyan:   #08C8DF
const green  = Color(0xFF18A477);   // --green:  #18A477
const purple = Color(0xFF6546C7);   // --purple: #6546C7
const bg     = Color(0xFFF5F7FB);   // --bg:     #F5F7FB
const text   = Color(0xFF14213D);   // --text:   #14213D
const muted  = Color(0xFF758095);   // --muted:  #758095
const line   = Color(0xFFE7EBF2);   // --line:   #E7EBF2

// Logo: gradient de cyan a blue (LinearGradient(colors: [cyan, blue]))
// AI Banner: gradient de navy a blue
// Match badge: fondo #E8F8EF, texto #15804D
```

---

## 3. Backend — API completamente implementada

> **El backend está 100% terminado.** No generar ni modificar código del backend.

### URL base

```
http://localhost:8000   <- backend principal (FastAPI)
http://localhost:8001   <- microservicio ML (interno, no llamado directamente desde el app)
```

### Endpoints disponibles

#### Auth (/auth)

| Método | Ruta | Auth | Body / Respuesta |
|---|---|---|---|
| POST | /auth/registro/candidato | No | {email, password, full_name, skills[], experience_years, location?, education?} -> {id, user_id, full_name, skills[], experience_years, location, education} |
| POST | /auth/registro/empresa | No | {email, password} -> {id, email, role, created_at} |
| POST | /auth/login | No | {email, password} -> {access_token, token_type} |
| POST | /auth/recuperar-password | No | {email} -> 202 Accepted |
| POST | /auth/confirmar-reset | No | {token, new_password} -> 200 OK |

#### Perfiles (/perfiles)

| Método | Ruta | Auth | Body / Respuesta |
|---|---|---|---|
| GET | /perfiles/{profile_id} | JWT | -> {id, user_id, full_name, skills[], experience_years, location, education, cv_text} |
| PUT | /perfiles/{profile_id} | JWT candidato dueño | {full_name, skills[], experience_years, location?, education?} -> ProfileResponse |
| POST | /perfiles/{profile_id}/cv | JWT candidato dueño | multipart/form-data campo 'file' (PDF, JPG, PNG, WEBP) -> {profile_id, message, cv_preview} |

#### Vacantes (/vacantes)

| Método | Ruta | Auth | Notas |
|---|---|---|---|
| GET | /vacantes | público | Query params: ubicacion?, categoria?, offset=0, limit=20 |
| POST | /vacantes | JWT empresa | {titulo, descripcion, requisitos[], ubicacion, categoria?, salario_min?, salario_max?, latitud?, longitud?} |
| PUT | /vacantes/{id} | JWT empresa dueña | mismos campos que POST |
| PATCH | /vacantes/{id}/estado | JWT empresa dueña | {estado: "activa" o "pausada" o "cerrada"} |

**VacanteResponse:**
```json
{
  "id": "uuid",
  "empresa_id": "uuid",
  "titulo": "string",
  "descripcion": "string",
  "requisitos": ["string"],
  "ubicacion": "string",
  "estado": "activa | pausada | cerrada",
  "categoria": "string | null",
  "salario_min": 0,
  "salario_max": 0,
  "latitud": 0.0,
  "longitud": 0.0,
  "creado_en": "datetime"
}
```

#### Postulaciones (/postulaciones)

| Método | Ruta | Auth | Body / Respuesta |
|---|---|---|---|
| POST | /postulaciones | JWT | {candidato_id, vacante_id} -> PostulacionResponse |
| GET | /postulaciones/candidato/{candidato_id} | JWT | -> [PostulacionResponse] |
| GET | /postulaciones/vacante/{vacante_id} | JWT empresa | -> [PostulacionResponse] |
| PATCH | /postulaciones/{id}/estado | JWT empresa | {estado: "postulado" o "entrevista" o "rechazado" o "contratado"} |

**PostulacionResponse:**
```json
{
  "id": "uuid",
  "candidato_id": "uuid",
  "vacante_id": "uuid",
  "estado": "postulado | entrevista | rechazado | contratado",
  "fecha": "datetime",
  "score_match": 0.0
}
```

#### Recomendaciones (/recomendaciones)

| Método | Ruta | Auth | Respuesta |
|---|---|---|---|
| GET | /recomendaciones/candidato/{candidato_id} | JWT candidato | [{vacante_id, titulo, empresa_id, score_similitud, explicacion}] |

- El `score_similitud` es un float entre 0 y 1. Multiplicar x100 para mostrar el % en la UI.
- La `explicacion` es texto plano: "Habilidades coincidentes: Python, análisis de datos".

#### Notificaciones (/notificaciones)

| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | /notificaciones/token-dispositivo | JWT | {token, dispositivo_info?} — registra el FCM token |
| GET | /notificaciones/usuario/{usuario_id} | JWT | Query: limit=50, offset=0 -> [{id, tipo, mensaje, leido, creado_en}] |
| PATCH | /notificaciones/{id}/leida | JWT | Marca una notificación como leída |

#### Autenticación JWT

- El token se recibe en POST /auth/login como `access_token`.
- Incluirlo en todas las peticiones autenticadas: `Authorization: Bearer <token>`.
- Persistir en SharedPreferences con clave `auth_token`.
- También persistir `profile_id` y `user_id` del candidato tras el login/registro.

---

## 4. Arquitectura del frontend (Clean Architecture para Flutter)

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart        <- paleta del wireframe
│   │   └── app_strings.dart       <- textos en español
│   ├── theme/
│   │   └── app_theme.dart         <- ThemeData completo
│   ├── network/
│   │   └── api_client.dart        <- http client con interceptor JWT
│   └── storage/
│       └── secure_storage.dart    <- SharedPreferences para token/IDs
│
├── domain/
│   ├── entities/
│   │   ├── job.dart               <- Vacante (id, titulo, descripcion, score?, explicacion?)
│   │   ├── profile.dart           <- Perfil candidato
│   │   ├── postulacion.dart       <- Postulación con estado
│   │   └── notificacion.dart      <- Notificación push
│   └── repositories/              <- abstract classes (contratos)
│       ├── auth_repository.dart
│       ├── vacante_repository.dart
│       ├── postulacion_repository.dart
│       ├── perfil_repository.dart
│       └── recomendacion_repository.dart
│
├── data/
│   ├── models/                    <- DTOs con fromJson/toJson
│   │   ├── job_model.dart
│   │   ├── profile_model.dart
│   │   ├── postulacion_model.dart
│   │   └── recomendacion_model.dart
│   └── repositories/              <- implementaciones HTTP
│       ├── auth_repository_impl.dart
│       ├── vacante_repository_impl.dart
│       ├── postulacion_repository_impl.dart
│       ├── perfil_repository_impl.dart
│       └── recomendacion_repository_impl.dart
│
└── presentation/
    ├── auth/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   └── forgot_password_screen.dart
    ├── shell/
    │   └── candidate_shell.dart   <- NavigationBar de 4 tabs
    ├── home/
    │   └── home_screen.dart       <- Inicio con recomendadas IA
    ├── explore/
    │   └── explore_screen.dart    <- Explorar con filtros
    ├── applications/
    │   └── applications_screen.dart
    ├── profile/
    │   ├── profile_screen.dart
    │   └── edit_profile_screen.dart
    ├── job_detail/
    │   └── job_detail_screen.dart
    └── shared/
        ├── widgets/
        │   ├── job_card.dart
        │   ├── ai_banner.dart
        │   ├── brand_logo.dart
        │   ├── match_badge.dart
        │   └── loading_overlay.dart
        └── providers/             <- ChangeNotifier
            ├── auth_provider.dart
            ├── vacantes_provider.dart
            ├── recomendaciones_provider.dart
            └── postulaciones_provider.dart
```

> Regla de dependencia: `presentation` nunca importa `data` directamente.
> Solo usa `domain` (entidades + contratos). La inyección se hace en `main.dart`.

---

## 5. Dependencias Flutter a añadir (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # HTTP
  http: ^1.2.0

  # Persistencia de sesión
  shared_preferences: ^2.3.0

  # Gestión de estado
  provider: ^6.1.2

  # Manejo de archivos (subir CV)
  file_picker: ^8.0.0

  # Mapas (RF-05.3 — Sprint F-6)
  flutter_map: ^7.0.1
  latlong2: ^0.9.1

  # Notificaciones push FCM (Sprint F-6)
  firebase_core: ^3.4.0
  firebase_messaging: ^15.0.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

---

## 6. Sprints del frontend

### Sprint F-1 — Core + Autenticación (PRIMER OBJETIVO)

**Objetivo**: el candidato puede registrarse e iniciar sesión. El token JWT se persiste.

**Archivos a crear:**

| Archivo | Descripción |
|---|---|
| `core/constants/app_colors.dart` | Paleta completa del wireframe |
| `core/theme/app_theme.dart` | ThemeData con colores, fuentes Inter |
| `core/network/api_client.dart` | Wrapper de http que agrega Authorization: Bearer token |
| `core/storage/secure_storage.dart` | SharedPreferences: guardar/leer/borrar auth_token, user_id, profile_id, user_role |
| `domain/entities/profile.dart` | Entidad Profile |
| `domain/repositories/auth_repository.dart` | Contrato login(), registerCandidate(), logout() |
| `data/models/profile_model.dart` | DTO con fromJson |
| `data/repositories/auth_repository_impl.dart` | Llama a POST /auth/login y POST /auth/registro/candidato |
| `presentation/auth/login_screen.dart` | Pantalla login (email + password + botón) |
| `presentation/auth/register_screen.dart` | Registro candidato (nombre, email, contraseña, habilidades, ubicación) |
| `presentation/auth/forgot_password_screen.dart` | Solo campo email, llama POST /auth/recuperar-password |
| `presentation/shared/providers/auth_provider.dart` | ChangeNotifier con estado: loading, error, currentUser |
| `main.dart` | Composición: si hay token -> CandidateShell, si no -> LoginScreen |

**Flujo de autenticación:**
1. App inicia -> SecureStorage.getToken() -> si existe ir a Shell, si no ir a Login.
2. Login exitoso -> guardar access_token + user_id + profile_id + user_role.
3. Logout -> borrar todo y redirigir a Login.

---

### Sprint F-2 — Vacantes (Explorar + Home)

**Objetivo**: mostrar vacantes reales del backend en lugar de datos hardcodeados.

| Archivo | Descripción |
|---|---|
| `domain/entities/job.dart` | Entidad Job con todos los campos del backend + match? + explicacion? |
| `domain/repositories/vacante_repository.dart` | Contrato listar({ubicacion, categoria, offset, limit}) |
| `data/models/job_model.dart` | DTO VacanteModel con fromJson |
| `data/repositories/vacante_repository_impl.dart` | GET /vacantes con query params |
| `presentation/shared/providers/vacantes_provider.dart` | ChangeNotifier: List<Job>, loading, error, filtrar() |
| `presentation/explore/explore_screen.dart` | Búsqueda + filtros -> lista de JobCard reales |
| `presentation/home/home_screen.dart` | Sección "Recomendadas" (top 3) + AiBanner |
| `presentation/job_detail/job_detail_screen.dart` | Detalle de vacante + botón "Postularme" |
| `presentation/shared/widgets/job_card.dart` | Componente reutilizable extraído de main.dart |

---

### Sprint F-3 — Recomendaciones IA

**Objetivo**: mostrar en Inicio las vacantes recomendadas por el motor semántico, con % de compatibilidad y explicación.

| Archivo | Descripción |
|---|---|
| `domain/entities/recomendacion.dart` | {vacanteId, titulo, empresaId, scoreSimilitud, explicacion} |
| `domain/repositories/recomendacion_repository.dart` | Contrato getRecomendaciones(candidatoId) |
| `data/models/recomendacion_model.dart` | DTO con fromJson |
| `data/repositories/recomendacion_repository_impl.dart` | GET /recomendaciones/candidato/{id} |
| `presentation/shared/providers/recomendaciones_provider.dart` | Carga recomendaciones al entrar al Home |
| `presentation/home/home_screen.dart` | Modificar para mostrar badge "✦ XX% compatible" y texto de explicación |
| `presentation/shared/widgets/match_badge.dart` | Badge verde con score |
| `presentation/shared/widgets/ai_explanation_tile.dart` | Card que muestra la explicacion del ML |

**Lógica del badge:**
```dart
// scoreSimilitud viene como float 0.0-1.0
final pct = (recomendacion.scoreSimilitud * 100).round();
// Mostrar: "✦ 94% compatible contigo"
```

**Fallback**: si el microservicio ML no responde, cargar el listado general de vacantes (Sprint F-2).

---

### Sprint F-4 — Postulaciones

**Objetivo**: el candidato puede postularse con un toque y ver el historial con estados.

| Archivo | Descripción |
|---|---|
| `domain/entities/postulacion.dart` | {id, candidatoId, vacanteId, estado, fecha, scoreMatch} |
| `domain/repositories/postulacion_repository.dart` | Contrato postularse(), listarPorCandidato() |
| `data/models/postulacion_model.dart` | DTO con fromJson |
| `data/repositories/postulacion_repository_impl.dart` | POST /postulaciones + GET /postulaciones/candidato/{id} |
| `presentation/shared/providers/postulaciones_provider.dart` | Estado de postulaciones |
| `presentation/applications/applications_screen.dart` | Reemplazar datos hardcodeados por los reales del provider |
| `presentation/job_detail/job_detail_screen.dart` | Botón "Postularme" llama al repositorio y actualiza estado |

**Estados de postulación a mostrar en la UI:**

| Estado backend | Label UI | Color |
|---|---|---|
| postulado | En revisión | #245bc8 (azul) |
| entrevista | En entrevista | #6546C7 (purple) |
| rechazado | No seleccionado | #9099A8 (gris) |
| contratado | ¡Contratado! | #15804D (verde) |

---

### Sprint F-5 — Perfil completo

**Objetivo**: el candidato puede ver, editar su perfil y subir su CV.

| Archivo | Descripción |
|---|---|
| `domain/repositories/perfil_repository.dart` | getPerfil(), updatePerfil(), uploadCv() |
| `data/repositories/perfil_repository_impl.dart` | GET/PUT /perfiles/{id} + POST /perfiles/{id}/cv multipart |
| `presentation/shared/providers/perfil_provider.dart` | Estado del perfil del candidato autenticado |
| `presentation/profile/profile_screen.dart` | Reemplazar datos hardcodeados por los del provider |
| `presentation/profile/edit_profile_screen.dart` | Form con campos: nombre, skills, años exp., ubicación, educación |
| `presentation/profile/cv_upload_widget.dart` | Botón "Subir CV" -> FilePicker -> POST /perfiles/{id}/cv -> muestra cv_preview |

**Subida de CV:**
```dart
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
);
// Enviar como multipart/form-data con campo 'file'
```

---

### Sprint F-6 — Notificaciones + Mapa (RF-05)

**Objetivo**: registrar token FCM y mostrar vacantes en mapa.

| Archivo | Descripción |
|---|---|
| `core/notifications/fcm_service.dart` | Inicializar Firebase Messaging, obtener token, llamar POST /notificaciones/token-dispositivo |
| `presentation/profile/notifications_screen.dart` | Lista de notificaciones del usuario (leídas/no leídas) |
| `presentation/explore/map_screen.dart` | Mapa con flutter_map + marcadores de vacantes con latitud/longitud |

---

## 7. Gestión de estado (patrón a usar)

Se usa **Provider** (ChangeNotifier) por simplicidad y alineación con la arquitectura del proyecto.

```dart
// main.dart — composición de dependencias
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepositoryImpl(apiClient))),
    ChangeNotifierProvider(create: (_) => VacantesProvider(VacanteRepositoryImpl(apiClient))),
    ChangeNotifierProvider(create: (_) => RecomendacionesProvider(RecomendacionRepositoryImpl(apiClient))),
    ChangeNotifierProvider(create: (_) => PostulacionesProvider(PostulacionRepositoryImpl(apiClient))),
    ChangeNotifierProvider(create: (_) => PerfilProvider(PerfilRepositoryImpl(apiClient))),
  ],
  child: const MyApp(),
)
```

---

## 8. Manejo de errores HTTP

Todos los repositorios deben manejar estos códigos:

| Código | Acción en UI |
|---|---|
| 401 Unauthorized | Borrar token y redirigir a Login |
| 403 Forbidden | SnackBar "No tienes permisos" |
| 404 Not Found | Mostrar estado vacío en la lista |
| 409 Conflict | Para postulaciones: "Ya te postulaste a esta vacante" |
| 422 Unprocessable | Mostrar error de validación del campo |
| 500 Server Error | SnackBar "Error del servidor, intenta más tarde" |
| timeout / sin red | Banner "Sin conexión a internet" |

---

## 9. Cómo reanudar el trabajo en un nuevo chat

1. Leer este archivo completo: `FRONTEND_CODEX/CONTEXT/Plan_Desarrollo_Frontend.md`.
2. Leer el wireframe: `BACKEND_CODEX/CONTEXT/WIREFRAMES/talentmatch_wireframe_movil.html`.
3. Leer la especificación: `BACKEND_CODEX/CONTEXT/TalentMatch_Especificacion_Agente_IA (1).md`.
4. Revisar el estado actual de `lib/main.dart` y la estructura de `lib/`.
5. Continuar con el sprint que corresponda según los archivos ya creados.

### Checklist de sprints completados

- [ ] Sprint F-1 — Core + Auth (Login, Registro, JWT persistente)
- [ ] Sprint F-2 — Vacantes reales desde API (Explorar + Home)
- [ ] Sprint F-3 — Recomendaciones IA (score % + explicación)
- [ ] Sprint F-4 — Postulaciones (postularse + historial + estados)
- [ ] Sprint F-5 — Perfil completo (ver + editar + subir CV)
- [ ] Sprint F-6 — Notificaciones FCM + Mapa OpenStreetMap

---

## 10. Reglas para el agente de IA

- **No modificar el backend.** Está 100% completo.
- **Respetar la paleta de colores** exacta del wireframe (sección 2). No usar otros colores.
- **Respetar la arquitectura Clean** definida en la sección 4. Nunca llamar a http directamente desde un widget o provider; siempre a través del repositorio.
- **El main.dart actual es el punto de partida visual.** Extraer sus widgets a archivos separados; no reescribir desde cero el estilo visual.
- **Idioma de la UI**: español (textos, labels, mensajes de error).
- **Idioma del código**: inglés para nombres de clases, métodos y variables internas.
- **Animaciones y micro-interacciones**: mantener el estándar premium del wireframe. No hacer diseños planos ni mínimos.
- Todos los providers deben tener estado `loading: bool` y `error: String?` para mostrar indicadores y mensajes en la UI.
- La pantalla de **Inicio** siempre intenta cargar las recomendaciones del ML primero (Sprint F-3). Si el ML no responde, cae al listado general de vacantes.
