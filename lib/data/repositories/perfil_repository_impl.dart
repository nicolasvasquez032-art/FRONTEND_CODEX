import '../../core/network/api_client.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../models/profile_model.dart';

class PerfilRepositoryImpl implements PerfilRepository {
  final ApiClient _api;

  PerfilRepositoryImpl(this._api);

  // ──────────────────────────────────────────────
  // GET /perfiles/{profileId}
  // ──────────────────────────────────────────────

  @override
  Future<Profile> getPerfil(String profileId) async {
    final raw = await _api.get('/perfiles/$profileId', auth: true);
    return ProfileModel.fromJson(raw);
  }

  // ──────────────────────────────────────────────
  // PUT /perfiles/{profileId}
  // ──────────────────────────────────────────────

  @override
  Future<Profile> updatePerfil({
    required String profileId,
    required String fullName,
    required List<String> skills,
    required int experienceYears,
    String? location,
    String? education,
    String? phone,
    String? portfolioUrl,
    String? aboutMe,
    String? jobTitle,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName,
      'skills': skills,
      'experience_years': experienceYears,
      if (location != null && location.isNotEmpty) 'location': location,
      if (education != null && education.isNotEmpty) 'education': education,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (portfolioUrl != null && portfolioUrl.isNotEmpty) 'portfolio_url': portfolioUrl,
      if (aboutMe != null && aboutMe.isNotEmpty) 'about_me': aboutMe,
      if (jobTitle != null && jobTitle.isNotEmpty) 'job_title': jobTitle,
    };
    final raw = await _api.put('/perfiles/$profileId', body);
    return ProfileModel.fromJson(raw);
  }

  // ──────────────────────────────────────────────
  // POST /perfiles/{profileId}/cv — multipart
  // ──────────────────────────────────────────────

  @override
  Future<String> uploadCv({
    required String profileId,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final raw = await _api.postMultipart(
      '/perfiles/$profileId/cv',
      fileBytes,
      fileName,
      mimeType,
    );
    // El backend devuelve { profile_id, message, cv_preview }
    return (raw['cv_preview'] as String?) ?? '';
  }
}
