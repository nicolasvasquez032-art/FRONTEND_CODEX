# Sprint F-3 — TalentMatch Frontend (Completado)

> **Fecha de implementación:** 2026-09-28  
> **Estado:** ✅ Completo — `flutter analyze` pasa con 0 errores, 0 warnings  
> **Sprint anterior:** F-5 (Perfil completo: editar + subir CV)  
> **Sprint siguiente:** F-6 (Notificaciones FCM + Mapa OpenStreetMap)

---

## Objetivo del Sprint

Integrar el motor semántico ML en el HomeScreen para mostrar recomendaciones personalizadas con % de compatibilidad, con fallback automático al listado general si el ML no está disponible.

---

## Archivos creados

### Capa de Dominio — `lib/domain/`

#### `entities/recomendacion.dart`
- Entidad pura `Recomendacion` con campos del backend
- Helper `scorePercent` → `(scoreSimilitud * 100).round()` (0–100)
- Helper `badgeText` → `"✦ 87% compatible contigo"`

#### `repositories/recomendacion_repository.dart`
- Contrato abstracto `RecomendacionRepository`
- Método: `getRecomendaciones(candidatoId)` → `Future<List<Recomendacion>>`

---

### Capa de Datos — `lib/data/`

#### `models/recomendacion_model.dart`
- DTO `RecomendacionModel` con `fromJson` que mapea exactamente la respuesta del backend:
  - `vacante_id`, `titulo`, `empresa_id`, `score_similitud`, `explicacion`

#### `repositories/recomendacion_repository_impl.dart`
- Implementa `RecomendacionRepository`
- `getRecomendaciones()` → `GET /recomendaciones/candidato/{id}` con JWT

---

### Capa de Presentación — `lib/presentation/`

#### `shared/providers/recomendaciones_provider.dart`
Estado global con lógica de fallback:
- `RecomendacionesStatus` (initial, loading, loaded, error, **fallback**)
- `fallback`: se activa cuando el ML no responde (timeout, 500, 404, sin red)
  - El HomeScreen detecta este estado y muestra las vacantes generales
- `top4` → getter que retorna las 4 mejores recomendaciones
- `hasData` → true si loaded y lista no vacía
- `isFallback` → true si el ML no está disponible

#### `shared/widgets/match_badge.dart` ← **Nuevo**
Badge verde reutilizable:
- Prop `percent` (int 0–100)
- Prop `compact` (bool) → modo compacto "✦ 87%" vs completo "✦ 87% compatible contigo"
- Colores oficiales: `kMatchBg` (fondo) + `kMatchText` (texto)

#### `shared/widgets/ai_explanation_tile.dart` ← **Nuevo**
Tarjeta de recomendación IA:
- Avatar de empresa (letra inicial en cuadro azul)
- Título + `MatchBadge` con el score
- Divider
- Explicación del ML con ícono `auto_awesome` verde
- `onTap` callback para navegar al detalle
- `AnimatedContainer` para micro-interacción

---

### Pantallas modificadas

#### `presentation/home/home_screen.dart` ← **Reescrito**
Nueva lógica de carga tripartita en `initState`:
1. Carga vacantes generales (siempre, para tener fallback)
2. Carga postulaciones del candidato
3. **Intenta** cargar recomendaciones IA → si falla → `isFallback = true`

Lógica de render:
```
loading (ML o vacantes) → CircularProgressIndicator

rProvider.hasData → AiExplanationTile con badge de score
                    + chip "Motor IA activo"
                    + Banner con badge "ACTIVO" verde

rProvider.isFallback → _JobCard estándar (vacantes generales)
                       + Banner sin badge ACTIVO

vProvider.error → _ErrorCard con reintentar
```

Helper privado `_recomendacionToVacanteMin(r)`:
- Si la vacante de la recomendación no está en el caché de `VacantesProvider`,
  construye un `Vacante` mínimo con los datos disponibles para navegar al `JobDetailScreen`.

---

### Modificaciones de infraestructura

#### `main.dart`
```dart
final recomendacionRepo = RecomendacionRepositoryImpl(apiClient);
// ...
ChangeNotifierProvider(create: (_) => RecomendacionesProvider(recomendacionRepo)),
```

---

## Flujos implementados

### Flujo 1: Recomendaciones IA activas
```
HomeScreen.initState()
  → VacantesProvider.cargar()           // background, para fallback
  → RecomendacionesProvider.cargar(profileId)
  → GET /recomendaciones/candidato/{id}
  → status: loaded, recomendaciones: [...]
  → Render: AiExplanationTile × 4 con MatchBadge
  → Banner: "ACTIVO" verde
```

### Flujo 2: Fallback (ML no disponible)
```
HomeScreen.initState()
  → VacantesProvider.cargar() ← ya cargado
  → RecomendacionesProvider.cargar(profileId)
  → TIMEOUT / 500 / 404
  → status: fallback
  → Render: _JobCard × 4 (vacantes generales sin score)
  → Banner: sin badge ACTIVO
```

### Flujo 3: Tap en recomendación → detalle
```
AiExplanationTile.onTap()
  → _navigateToDetail(recomendacion)
  → Busca vacante.id == recomendacion.vacanteId en VacantesProvider.vacantes
  → Si existe: push JobDetailScreen(vacante: match)
  → Si no: push JobDetailScreen(vacante: _recomendacionToVacanteMin(r))
```

---

## Verificación de calidad

```bash
flutter analyze lib/ --no-fatal-infos
# Resultado: 0 errors, 0 warnings, 5 infos (pre-existentes)
```

---

## Estructura de archivos al finalizar el Sprint F-3

```
lib/
├── domain/
│   ├── entities/
│   │   ├── recomendacion.dart           [NUEVO]
│   │   └── (otros sin cambios)
│   └── repositories/
│       ├── recomendacion_repository.dart [NUEVO]
│       └── (otros sin cambios)
├── data/
│   ├── models/
│   │   ├── recomendacion_model.dart      [NUEVO]
│   │   └── (otros sin cambios)
│   └── repositories/
│       ├── recomendacion_repository_impl.dart [NUEVO]
│       └── (otros sin cambios)
└── presentation/
    ├── shared/
    │   ├── providers/
    │   │   ├── recomendaciones_provider.dart [NUEVO]
    │   │   └── (otros sin cambios)
    │   └── widgets/
    │       ├── match_badge.dart              [NUEVO]
    │       ├── ai_explanation_tile.dart      [NUEVO]
    │       └── (otros sin cambios)
    └── home/
        └── home_screen.dart                  [REESCRITO — IA + fallback]
```

---

## Cómo retomar (Sprint F-6)

El nuevo agente debe leer:
1. `CONTEXT/Plan_Desarrollo_Frontend.md`
2. `CONTEXT/Sprint_F2_Implementado.md`
3. `CONTEXT/Sprint_F5_Implementado.md`
4. `CONTEXT/Sprint_F3_Implementado.md` (este archivo)

### Siguiente objetivo — Sprint F-6: Notificaciones FCM + Mapa

Archivos a crear:
- `core/notifications/fcm_service.dart` — inicializar Firebase Messaging, obtener token FCM, llamar `POST /notificaciones/token-dispositivo`
- `presentation/profile/notifications_screen.dart` — lista de notificaciones (`GET /notificaciones/usuario/{id}`) con estados leída/no leída, PATCH para marcar leída
- `presentation/explore/map_screen.dart` — mapa OpenStreetMap con `flutter_map` y marcadores de vacantes con `latitud/longitud`

Dependencias ya en `pubspec.yaml`:
- `firebase_core: ^3.4.0`
- `firebase_messaging: ^15.0.4`
- `flutter_map: ^7.0.1`
- `latlong2: ^0.9.1`

⚠️ Sprint F-6 requiere configurar `google-services.json` en `android/app/` para Firebase.
