# Sprint F-5 — TalentMatch Frontend (Completado)

> **Fecha de implementación:** 2026-09-28  
> **Estado:** ✅ Completo — `flutter analyze` pasa con 0 errores, 0 warnings  
> **Sprint anterior:** F-2 (Vacantes + Postulaciones)  
> **Sprint siguiente:** F-3 (Recomendaciones IA — motor semántico ML)

---

## Objetivo del Sprint

Conectar la pantalla de Perfil con el backend real y habilitar la subida de CV:

1. Cargar datos reales del candidato desde `GET /perfiles/{profile_id}`
2. Editar nombre, habilidades, experiencia, ubicación y educación via `PUT /perfiles/{profile_id}`
3. Subir CV (PDF, JPG, PNG, WEBP) via `POST /perfiles/{profile_id}/cv` (multipart)
4. Mostrar el texto extraído del CV en la UI (`cv_preview`)

---

## Archivos creados

### Capa de Dominio — `lib/domain/`

#### `repositories/perfil_repository.dart`
- Contrato abstracto `PerfilRepository`
- Métodos:
  - `getPerfil(profileId)` → `Future<Profile>`
  - `updatePerfil({profileId, fullName, skills, experienceYears, location?, education?})` → `Future<Profile>`
  - `uploadCv({profileId, fileBytes, fileName, mimeType})` → `Future<String>` (devuelve cv_preview)

---

### Capa de Datos — `lib/data/`

#### `repositories/perfil_repository_impl.dart`
- Implementa `PerfilRepository`
- `getPerfil()` → `GET /perfiles/{id}` con JWT
- `updatePerfil()` → `PUT /perfiles/{id}` — body con `full_name`, `skills`, `experience_years`, `location?`, `education?`
- `uploadCv()` → usa `apiClient.postMultipart()` a `POST /perfiles/{id}/cv` — extrae `cv_preview` de la respuesta

---

### Capa de Presentación — `lib/presentation/`

#### `shared/providers/perfil_provider.dart`
Estado global del perfil. Maneja:
- `PerfilStatus` (initial, loading, loaded, error) con `profile` y `error`
- `CvUploadStatus` (idle, uploading, success, error) con `cvError` y `cvPreview`
- `saving: bool` + `saveError: String?` para el estado de guardado
- Métodos: `cargar(profileId)`, `guardar({...})` → `Future<bool>`, `subirCv({...})` → `Future<bool>`
- Después de `subirCv()` exitoso: recarga el perfil automáticamente para reflejar el nuevo `cvText`

#### `profile/edit_profile_screen.dart` ← **Nuevo**
Formulario premium de edición de perfil:
- AppBar con botón atrás y título centrado
- Avatar circular con gradiente y inicial del nombre
- Secciones organizadas con `_SectionHeader` (icono + label)
- Campos: Nombre completo, Educación, Ubicación (Colombia picker), Años de experiencia, Habilidades
- Preview en tiempo real de skills como chips (`ValueListenableBuilder`)
- Validación de formulario con `Form` + `_formKey`
- Botón "Guardar cambios" con `CircularProgressIndicator` al guardar
- SnackBar verde en éxito, rojo en error
- Navega de vuelta con `Navigator.pop` al guardar exitosamente

#### `profile/cv_upload_widget.dart` ← **Nuevo**
Widget embebible (no pantalla completa) de subida de CV:
- Usa `file_picker: 13.1.0` con la nueva API:
  - `FilePicker.pickFile(type: FileType.custom, allowedExtensions: [...])` → `PlatformFile?`
  - `file.readAsBytes()` para obtener los bytes del archivo
- Estado visual:
  - Sin CV: icono de subida + botón "Seleccionar archivo"
  - Con CV: badge verde "✓ Activo" + preview del texto extraído (max 300 chars) + botón "Reemplazar CV"
  - Subiendo: indicador de progreso con texto "Subiendo CV..."
- Snackbars de confirmación/error

#### `profile/profile_screen.dart` ← **Reescrito completamente**
Reemplaza la pantalla estática con datos reales:
- `initState` → carga el perfil si `PerfilStatus.initial`
- Pull-to-refresh
- Estados: `CircularProgressIndicator` (loading), `_ErrorCard` con reintentar (error)
- `_ProfileCard` — avatar con gradiente, nombre real, años de experiencia, botón "Editar perfil"
- `CvUploadWidget` — widget de CV embebido
- `_SkillsCard` — chips con skills reales del backend
- `_DetailsCard` — ubicación y educación si existen
- `_LogoutButton` — diálogo de confirmación con botón rojo

---

### Modificaciones de infraestructura

#### `main.dart`
- Importados `PerfilRepositoryImpl`, `PerfilProvider`
- Registrado en `MultiProvider`:
  ```dart
  ChangeNotifierProvider(create: (_) => PerfilProvider(perfilRepo)),
  ```

---

## Flujos implementados

### Flujo 1: Ver perfil
```
CandidateShell (Profile tab)
  → ProfileScreen.initState()
  → PerfilProvider.cargar(profileId)
  → GET /perfiles/{profileId}
  → _ProfileCard + _SkillsCard + _DetailsCard + CvUploadWidget
```

### Flujo 2: Editar perfil
```
ProfileScreen
  → botón "Editar perfil"
  → push EditProfileScreen(profile: pp.profile!)
  → FormKey.validate()
  → PerfilProvider.guardar(...)
  → PUT /perfiles/{profileId}
  → SnackBar verde + Navigator.pop
  → ProfileScreen muestra datos actualizados (profile reactive)
```

### Flujo 3: Subir CV
```
CvUploadWidget
  → botón "Seleccionar archivo"
  → FilePicker.pickFile() → PlatformFile
  → file.readAsBytes() → bytes
  → PerfilProvider.subirCv(...)
  → POST /perfiles/{id}/cv (multipart)
  → PerfilProvider.cargar() para refrescar cvText
  → Vista actualizada con preview + badge "✓ Activo"
```

---

## Nota sobre file_picker v13

La versión `13.1.0` cambió completamente la API:

| Característica | v8.x (antigua) | v13.x (actual) |
|---|---|---|
| Instancia | `FilePicker.platform.pickFiles()` | `FilePicker.pickFiles()` / `FilePicker.pickFile()` |
| Resultado | `FilePickerResult?` | `List<PlatformFile>` / `PlatformFile?` |
| Leer bytes | `.bytes` (Uint8List?) sincrónico | `.readAsBytes()` (Future<Uint8List>) async |
| Leer como stream | `.readStream` | `.readAsByteStream()` |

---

## Verificación de calidad

```bash
flutter analyze lib/ --no-fatal-infos
# Resultado: 0 errors, 0 warnings, 5 infos (pre-existentes del proyecto)
```

Los 5 `info` pre-existentes (sin cambios vs Sprint F-2):
1. `edit_profile_screen.dart` — underscores innecesarios en `_` parámetros (cosmético)
2. `edit_profile_screen.dart` — mismo
3. `brand_logo.dart` — `withOpacity` deprecated
4. `colombia_location_picker.dart` — underscores innecesarios
5. `candidate_shell.dart` — BuildContext en gap async

---

## Estructura de archivos al finalizar el Sprint F-5

```
lib/
├── domain/
│   └── repositories/
│       ├── auth_repository.dart         [sin cambios]
│       ├── vacante_repository.dart      [sin cambios]
│       ├── postulacion_repository.dart  [sin cambios]
│       └── perfil_repository.dart       [NUEVO]
├── data/
│   └── repositories/
│       ├── auth_repository_impl.dart    [sin cambios]
│       ├── vacante_repository_impl.dart [sin cambios]
│       ├── postulacion_repository_impl.dart [sin cambios]
│       └── perfil_repository_impl.dart  [NUEVO]
└── presentation/
    ├── shared/
    │   └── providers/
    │       ├── auth_provider.dart       [sin cambios]
    │       ├── vacantes_provider.dart   [sin cambios]
    │       ├── postulaciones_provider.dart [sin cambios]
    │       └── perfil_provider.dart     [NUEVO]
    └── profile/
        ├── profile_screen.dart          [REESCRITO — datos reales]
        ├── edit_profile_screen.dart     [NUEVO]
        └── cv_upload_widget.dart        [NUEVO]
```

---

## Cómo retomar (Sprint F-3)

El nuevo agente debe leer:
1. `CONTEXT/Plan_Desarrollo_Frontend.md`
2. `CONTEXT/Sprint_F2_Implementado.md`
3. `CONTEXT/Sprint_F5_Implementado.md` (este archivo)

### Siguiente objetivo — Sprint F-3: Recomendaciones IA

Archivos a crear:
- `domain/entities/recomendacion.dart` — `{vacanteId, titulo, empresaId, scoreSimilitud, explicacion}`
- `domain/repositories/recomendacion_repository.dart` — contrato `getRecomendaciones(candidatoId)`
- `data/models/recomendacion_model.dart` — DTO con `fromJson`
- `data/repositories/recomendacion_repository_impl.dart` — `GET /recomendaciones/candidato/{id}`
- `presentation/shared/providers/recomendaciones_provider.dart` — carga en initState del HomeScreen
- `presentation/shared/widgets/match_badge.dart` — badge verde "✦ XX% compatible"
- `presentation/shared/widgets/ai_explanation_tile.dart` — card con la explicación del ML
- Modificar `presentation/home/home_screen.dart` — usar recomendaciones con score en lugar de vacantes generales

Endpoint backend:
- `GET /recomendaciones/candidato/{candidato_id}` (JWT requerido)
- Respuesta: `[{vacante_id, titulo, empresa_id, score_similitud, explicacion}]`
- `score_similitud` es float 0.0–1.0 → multiplicar x100 para mostrar como %
- Fallback: si el ML no responde, cargar `GET /vacantes` normal (ya implementado)
