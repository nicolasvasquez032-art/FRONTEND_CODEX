import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/repositories/perfil_repository.dart';

enum PerfilStatus { initial, loading, loaded, error }

enum CvUploadStatus { idle, uploading, success, error }

class PerfilProvider extends ChangeNotifier {
  final PerfilRepository _repo;

  PerfilProvider(this._repo);

  // ── Estado del perfil ──
  PerfilStatus status = PerfilStatus.initial;
  Profile? profile;
  String? error;

  // ── Estado de subida de CV ──
  CvUploadStatus cvStatus = CvUploadStatus.idle;
  String? cvError;
  String? cvPreview;

  // ── Estado de guardado de edición ──
  bool saving = false;
  String? saveError;

  // ──────────────────────────────────────────────
  // Cargar perfil
  // ──────────────────────────────────────────────

  Future<void> cargar(String profileId) async {
    if (status == PerfilStatus.loading) return;
    status = PerfilStatus.loading;
    error = null;
    notifyListeners();

    try {
      profile = await _repo.getPerfil(profileId);
      status = PerfilStatus.loaded;
    } on ApiException catch (e) {
      error = _mapError(e);
      status = PerfilStatus.error;
    } catch (_) {
      error = 'Sin conexión. Verifica tu red.';
      status = PerfilStatus.error;
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Guardar cambios del perfil
  // ──────────────────────────────────────────────

  Future<bool> guardar({
    required String profileId,
    required String fullName,
    required List<String> skills,
    required int experienceYears,
    String? location,
    String? education,
  }) async {
    saving = true;
    saveError = null;
    notifyListeners();

    try {
      profile = await _repo.updatePerfil(
        profileId: profileId,
        fullName: fullName,
        skills: skills,
        experienceYears: experienceYears,
        location: location,
        education: education,
      );
      saving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      saveError = _mapError(e);
      saving = false;
      notifyListeners();
      return false;
    } catch (_) {
      saveError = 'Sin conexión. Verifica tu red.';
      saving = false;
      notifyListeners();
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Subir CV
  // ──────────────────────────────────────────────

  Future<bool> subirCv({
    required String profileId,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    cvStatus = CvUploadStatus.uploading;
    cvError = null;
    notifyListeners();

    try {
      cvPreview = await _repo.uploadCv(
        profileId: profileId,
        fileBytes: fileBytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      // Recargar perfil para reflejar cv_text actualizado
      await cargar(profileId);
      cvStatus = CvUploadStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      cvError = _mapError(e);
      cvStatus = CvUploadStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      cvError = 'Sin conexión. Verifica tu red.';
      cvStatus = CvUploadStatus.error;
      notifyListeners();
      return false;
    }
  }

  void resetCvStatus() {
    cvStatus = CvUploadStatus.idle;
    cvError = null;
    notifyListeners();
  }

  void clearSaveError() {
    saveError = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  String _mapError(ApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Sesión expirada. Inicia sesión nuevamente.';
      case 403:
        return 'No tienes permisos para editar este perfil.';
      case 404:
        return 'Perfil no encontrado.';
      case 422:
        return 'Datos inválidos. Revisa los campos.';
      case 500:
        return 'Error del servidor. Intenta más tarde.';
      default:
        return e.message;
    }
  }
}
