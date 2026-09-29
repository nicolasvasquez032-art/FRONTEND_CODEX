import '../entities/profile.dart';

/// Contrato abstracto para operaciones del perfil del candidato.
abstract class PerfilRepository {
  /// Obtiene el perfil completo desde GET /perfiles/{profileId}.
  Future<Profile> getPerfil(String profileId);

  /// Actualiza nombre, habilidades, experiencia, ubicación y educación
  /// via PUT /perfiles/{profileId}.
  Future<Profile> updatePerfil({
    required String profileId,
    required String fullName,
    required List<String> skills,
    required int experienceYears,
    String? location,
    String? education,
  });

  /// Sube el CV (PDF / JPG / PNG / WEBP) via POST /perfiles/{profileId}/cv
  /// como multipart/form-data con el campo 'file'.
  /// Devuelve el texto extraído del CV (cv_preview).
  Future<String> uploadCv({
    required String profileId,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  });
}
