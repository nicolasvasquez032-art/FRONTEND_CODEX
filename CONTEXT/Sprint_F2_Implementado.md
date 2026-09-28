# Sprint F-2 — TalentMatch Frontend (Completado)

> **Fecha de implementación:** 2026-09-27  
> **Estado:** ✅ Completo — `flutter analyze` pasa con 0 errores  
> **Sprint anterior:** F-1 (Auth: Login, Registro, Recuperar contraseña)  
> **Sprint siguiente:** F-3 (Perfil real, Editar perfil, Subir CV)

---

## Objetivo del Sprint

Conectar el frontend Flutter con los endpoints reales del backend FastAPI para:

1. Listar vacantes activas desde la BD (`GET /vacantes`)
2. Navegar al detalle de una vacante
3. Postularse a una vacante con un toque (`POST /postulaciones`)
4. Ver el historial de postulaciones del candidato (`GET /postulaciones/candidato/{id}`)

---

## Lo que existía antes (placeholders)

| Pantalla | Problema |
|---|---|
| `HomeScreen` | Datos hardcodeados (`_demoJobs`), sin llamada a API |
| `ExploreScreen` | Lista estática, filtro solo local |
| `ApplicationsScreen` | Pantalla vacía estática |
| `job_detail/` | Carpeta vacía, sin archivo |
| `main.dart` | Solo `AuthProvider` registrado |

---

## Archivos creados

### Capa de Dominio — `lib/domain/`

#### `entities/vacante.dart`
- Entidad pura `Vacante` con todos los campos del backend
- Enum `VacanteEstado` (activa, pausada, cerrada)
- Helper `salarioDisplay` → formatea rango salarial como string legible
- Helper `tiempoRelativo` → "Hace 2 h", "Ayer", "Hace 3 días"

#### `entities/postulacion.dart`
- Entidad pura `Postulacion`
- Enum `PostulacionEstado` (postulado, entrevista, rechazado, contratado)
- Extension `PostulacionEstadoX` → `.label` en español

#### `repositories/vacante_repository.dart`
- Contrato abstracto `VacanteRepository`
- Métodos: `listarVacantes({ubicacion, categoria})`, `getVacante(id)`

#### `repositories/postulacion_repository.dart`
- Contrato abstracto `PostulacionRepository`
- Métodos: `postularse({candidatoId, vacanteId})`, `listarMisPostulaciones(candidatoId)`

---

### Capa de Datos — `lib/data/`

#### `models/vacante_model.dart`
- DTO `VacanteModel` con `fromJson(Map)` → mapea exactamente `VacanteResponse` del backend
- Método `toEntity()` → convierte a entidad de dominio `Vacante`
- Parser de `VacanteEstado` desde string

#### `models/postulacion_model.dart`
- DTO `PostulacionModel` con `fromJson(Map)` → mapea exactamente `PostulacionResponse` del backend
- Método `toEntity()` → convierte a entidad de dominio `Postulacion`

#### `repositories/vacante_repository_impl.dart`
- Implementa `VacanteRepository`
- `listarVacantes()` → `GET /vacantes` con query params opcionales (`ubicacion`, `categoria`)
- `getVacante(id)` → `GET /vacantes/{id}`

#### `repositories/postulacion_repository_impl.dart`
- Implementa `PostulacionRepository`
- `postularse()` → `POST /postulaciones` con `candidato_id` y `vacante_id`
- `listarMisPostulaciones()` → `GET /postulaciones/candidato/{id}`

---

### Capa de Presentación — `lib/presentation/`

#### `shared/providers/vacantes_provider.dart`
Estado global para vacantes. Maneja:
- `VacantesStatus` (initial, loading, loaded, error)
- Lista `vacantes` desde la API
- `filtered` — getter que aplica búsqueda en tiempo real sobre la lista cargada
- Métodos: `cargar({ubicacion, categoria})`, `setQuery(q)`, `clearQuery()`

#### `shared/providers/postulaciones_provider.dart`
Estado global para postulaciones. Maneja:
- `PostulacionesStatus` (initial, loading, loaded, error)
- Lista `postulaciones` del candidato
- Mapa `_byVacante` → `vacanteId → Postulacion` (caché para saber si ya postuló)
- `yaPostulado(vacanteId)` → bool
- `postularse({candidatoId, vacanteId})` → `Future<bool>`
- `cargar(candidatoId)` → carga historial desde API

#### `job_detail/job_detail_screen.dart` ← **Archivo nuevo**
Pantalla completa de detalle de vacante:
- `SliverAppBar` expandible con gradiente y categoría
- Descripción del cargo con texto completo
- Lista de requisitos con bullet points
- Barra inferior fija con botón **"Postularme"**
  - Se deshabilita y cambia a verde ✅ cuando ya está postulado
  - Animación `AnimatedSwitcher` entre estado normal y "Ya estás postulado"
  - SnackBar verde con confirmación o rojo con error
- Chips de metadatos: ubicación, tiempo relativo, salario

---

### Pantallas modificadas

#### `presentation/home/home_screen.dart`
- Eliminados los `_demoJobs` hardcodeados
- Conectado a `VacantesProvider` vía `context.watch`
- `initState` carga vacantes y postulaciones si no están cargadas
- Muestra máximo 4 vacantes recientes
- Estados de UI: `CircularProgressIndicator` (loading), `_ErrorCard` con botón reintentar, `_EmptyCard`
- Pull-to-refresh (`RefreshIndicator`)
- Las tarjetas navegan a `JobDetailScreen`

#### `presentation/explore/explore_screen.dart`
- Eliminada la lista estática de 5 empleos
- Conectado a `VacantesProvider`
- Búsqueda en tiempo real vía `TextField` → `vp.setQuery()`
- Botón `×` para limpiar búsqueda
- Contador de resultados: "X vacantes encontradas"
- Navega a `JobDetailScreen` al tocar cualquier tarjeta
- Pull-to-refresh

#### `presentation/applications/applications_screen.dart`
- Eliminado el estado vacío estático
- Conectado a `PostulacionesProvider` y `VacantesProvider`
- Tarjeta `_PostulacionCard` con color e ícono diferente por estado:
  - 🔵 **Postulado** — azul
  - 🟡 **En entrevista** — amarillo
  - 🔴 **Rechazado** — rojo
  - 🟢 **Contratado** — verde
- Muestra `scoreMatch` si está disponible ("X% match")
- Fecha relativa de la postulación
- Pull-to-refresh

---

### Modificaciones de infraestructura

#### `core/network/api_client.dart`
- Cambio de `auth: false` a **`auth: true`** como default en el método `post()`
- Todos los endpoints de negocio (postulaciones, vacantes) ahora envían el JWT automáticamente

#### `data/repositories/auth_repository_impl.dart`
- Añadido `auth: false` explícito en los 3 posts de autenticación (login, registro, recuperar contraseña) para no enviar JWT donde no existe aún

#### `main.dart`
- Importados `VacanteRepositoryImpl`, `PostulacionRepositoryImpl`
- Importados `VacantesProvider`, `PostulacionesProvider`
- Registrados en `MultiProvider`:
  ```dart
  ChangeNotifierProvider(create: (_) => VacantesProvider(vacanteRepo)),
  ChangeNotifierProvider(create: (_) => PostulacionesProvider(postulacionRepo)),
  ```

---

## Flujos implementados

### Flujo 1: Ver vacantes
```
CandidateShell (Home tab)
  → HomeScreen.initState()
  → VacantesProvider.cargar()
  → GET /vacantes
  → Lista de _JobCard
  → tap → JobDetailScreen
```

### Flujo 2: Buscar vacantes
```
CandidateShell (Explore tab)
  → ExploreScreen
  → TextField onChanged → VacantesProvider.setQuery(q)
  → filtered getter aplica búsqueda local (sin nueva llamada API)
  → Lista filtrada actualizada en tiempo real
```

### Flujo 3: Postularse
```
JobDetailScreen
  → _PostularseBar._postularse()
  → PostulacionesProvider.postularse(candidatoId, vacanteId)
  → POST /postulaciones
  → Botón cambia a verde "Ya estás postulado"
  → SnackBar de confirmación
```

### Flujo 4: Ver mis postulaciones
```
CandidateShell (Applications tab)
  → ApplicationsScreen.initState()
  → PostulacionesProvider.cargar(profileId)
  → GET /postulaciones/candidato/{profileId}
  → Lista de _PostulacionCard con badge de color por estado
```

---

## Verificación de calidad

```bash
flutter analyze lib/ --no-fatal-infos
# Resultado: 0 errors, 3 infos (warnings pre-existentes del proyecto)
```

Los 3 `info` son:
1. `brand_logo.dart` — `withOpacity` deprecated (pre-existente)
2. `colombia_location_picker.dart` — underscores innecesarios (pre-existente)
3. `candidate_shell.dart` — BuildContext en gap async (pre-existente)

---

## Estructura de archivos al finalizar el Sprint F-2

```
lib/
├── core/
│   └── network/
│       └── api_client.dart              [MODIFICADO — auth default: true]
├── domain/
│   ├── entities/
│   │   ├── user_session.dart            [sin cambios]
│   │   ├── profile.dart                 [sin cambios]
│   │   ├── vacante.dart                 [NUEVO]
│   │   └── postulacion.dart             [NUEVO]
│   └── repositories/
│       ├── auth_repository.dart         [sin cambios]
│       ├── vacante_repository.dart      [NUEVO]
│       └── postulacion_repository.dart  [NUEVO]
├── data/
│   ├── models/
│   │   ├── profile_model.dart           [sin cambios]
│   │   ├── vacante_model.dart           [NUEVO]
│   │   └── postulacion_model.dart       [NUEVO]
│   └── repositories/
│       ├── auth_repository_impl.dart    [MODIFICADO — auth: false explícito]
│       ├── vacante_repository_impl.dart [NUEVO]
│       └── postulacion_repository_impl.dart [NUEVO]
└── presentation/
    ├── shared/
    │   └── providers/
    │       ├── auth_provider.dart       [sin cambios]
    │       ├── vacantes_provider.dart   [NUEVO]
    │       └── postulaciones_provider.dart [NUEVO]
    ├── home/
    │   └── home_screen.dart             [REESCRITO — API real]
    ├── explore/
    │   └── explore_screen.dart          [REESCRITO — API real]
    ├── applications/
    │   └── applications_screen.dart     [REESCRITO — API real]
    └── job_detail/
        └── job_detail_screen.dart       [NUEVO]
```

---

## Cómo retomar (Sprint F-3)

El nuevo agente debe leer:
1. `CONTEXT/Plan_Desarrollo_Frontend.md`
2. `CONTEXT/Sprint_F2_Implementado.md` (este archivo)

### Siguiente objetivo — Sprint F-3: Perfil real + Editar + Subir CV

Archivos a crear:
- `domain/repositories/profile_repository.dart` — contrato abstracto
- `data/repositories/profile_repository_impl.dart` — implementación `GET/PUT /perfiles/{id}` + `POST /perfiles/{id}/cv`
- `presentation/shared/providers/profile_provider.dart` — estado global del perfil
- `presentation/profile/edit_profile_screen.dart` — formulario de edición
- `presentation/profile/upload_cv_screen.dart` — selector de archivo + subida

Endpoint backend disponibles:
- `GET /perfiles/{profile_id}` → devuelve perfil completo
- `PUT /perfiles/{profile_id}` → actualiza nombre, habilidades, ubicación, educación, experiencia
- `POST /perfiles/{profile_id}/cv` → multipart/form-data con el archivo PDF o imagen

Dependencia ya instalada en `pubspec.yaml`:
- `file_picker: ^13.1.0` — selector de PDF/imagen (ya listado, no hay que añadirlo)
