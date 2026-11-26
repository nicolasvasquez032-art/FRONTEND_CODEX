import 'dart:async';

import 'package:flutter/material.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/domain/entities/user_session.dart';
import 'package:talentmatch/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  final ApiClient? apiClient;

  AuthProvider(this._repo, {this.apiClient}) {
    _init();
  }

  AuthStatus status = AuthStatus.unknown;
  UserSession? session;
  bool loading = false;
  String? error;
  bool hasSeenOnboarding = false;
  bool needsProfileCompletion = false;

  /// Callback global para limpiar estado en memoria de otros providers al cambiar de sesión.
  static VoidCallback? onSessionReset;

  void markProfileCompleted() {
    needsProfileCompletion = false;
    notifyListeners();
  }

  void setNeedsProfileCompletion(bool value) {
    needsProfileCompletion = value;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Inicialización: restaurar sesión guardada
  // ──────────────────────────────────────────────

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      final s = await _repo.restoreSession();
      if (s != null) {
        session = s;
        status = AuthStatus.authenticated;
      } else {
        status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool?> refreshCompanyPremium() async {
    final current = session;
    final api = apiClient;
    if (current == null || !current.isCompany || api == null) return null;

    try {
      final response = await api.get('/pagos/pro', auth: true);
      final isPremium = response['is_premium'];
      if (session?.userId != current.userId || isPremium is! bool) return null;
      final activeSession = session!;
      final expiresAt = DateTime.tryParse(response['premium_expires_at'] as String? ?? '');
      if (activeSession.isPremium != isPremium ||
          activeSession.premiumExpiresAt != expiresAt) {
        session = activeSession.withPremium(isPremium, expiresAt);
        notifyListeners();
      }
      return isPremium;
    } catch (_) {
      return null;
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    hasSeenOnboarding = true;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      // El repositorio hace el login y, para candidatos, obtiene el perfil.
      // Un límite global evita que el botón quede cargando indefinidamente si
      // alguna de esas dos peticiones queda retenida por la red.
      session = await _repo
          .login(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      onSessionReset?.call();
      needsProfileCompletion = false;
      status = AuthStatus.authenticated;
      error = null;
    } on TimeoutException {
      error = 'El servidor tardó demasiado en responder. Verifica tu conexión e inténtalo de nuevo.';
      status = AuthStatus.unauthenticated;
    } on ApiException catch (e) {
      error = _mapError(e);
      status = AuthStatus.unauthenticated;
    } catch (_) {
      error = 'Error de comunicación con el servidor. Por favor intenta de nuevo.';
      status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────
  // Login Social (Google, Facebook, LinkedIn)
  // ──────────────────────────────────────────────

  Future<void> loginWithSocial({
    required String provider,
    String? token,
    String? email,
    String? fullName,
  }) async {
    _setLoading(true);
    try {
      session = await _repo
          .loginWithSocial(
            provider: provider,
            token: token,
            email: email,
            fullName: fullName,
          )
          .timeout(const Duration(seconds: 20));
      onSessionReset?.call();
      if (session != null && session!.isCandidate) {
        needsProfileCompletion = session!.isNewUser;
      }
      status = AuthStatus.authenticated;
      error = null;
    } on TimeoutException {
      error = 'El servidor tardó demasiado en responder. Verifica tu conexión e inténtalo de nuevo.';
      status = AuthStatus.unauthenticated;
    } on ApiException catch (e) {
      error = _mapError(e);
      status = AuthStatus.unauthenticated;
    } catch (_) {
      error = 'Error al iniciar sesión con $provider. Inténtalo de nuevo.';
      status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────
  // Procesar token recibido de OAuth Social
  // ──────────────────────────────────────────────

  Future<void> handleSocialAuthToken({
    required String token,
    required String refreshToken,
    bool isNewUser = false,
  }) async {
    _setLoading(true);
    try {
      session = await _repo.handleSocialAuthToken(
        token: token,
        refreshToken: refreshToken,
        isNewUser: isNewUser,
      );
      onSessionReset?.call();
      if (session != null && session!.isCandidate) {
        needsProfileCompletion = true;
      }
      status = AuthStatus.authenticated;
      error = null;
    } catch (_) {
      error = 'Error al completar la autenticación con el proveedor social.';
      status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────
  // Registro candidato
  // ──────────────────────────────────────────────

  Future<void> registerCandidate({
    required String email,
    required String password,
    required String fullName,
    List<String> skills = const [],
    int experienceYears = 0,
    String? location,
    String? education,
  }) async {
    _setLoading(true);
    try {
      await _repo.registerCandidate(
        email: email,
        password: password,
        fullName: fullName,
        skills: skills,
        experienceYears: experienceYears,
        location: location,
        education: education,
      );
      error = null;
    } on TimeoutException {
      error = 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
      status = AuthStatus.unauthenticated;
    } on ApiException catch (e) {
      error = _mapError(e);
      status = AuthStatus.unauthenticated;
    } catch (_) {
      error = 'Error de comunicación con el servidor. Por favor intenta de nuevo.';
      status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────
  // Registro empresa
  // ──────────────────────────────────────────────

  Future<void> registerCompany({
    required String email,
    required String password,
    String? nombre,
  }) async {
    _setLoading(true);
    try {
      await _repo.registerCompany(email: email, password: password, nombre: nombre);
      error = null;
    } on TimeoutException {
      error = 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
      status = AuthStatus.unauthenticated;
    } on ApiException catch (e) {
      error = _mapError(e);
      status = AuthStatus.unauthenticated;
    } catch (_) {
      error = 'Error de comunicación con el servidor. Por favor intenta de nuevo.';
      status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────
  // Recuperar contraseña
  // ──────────────────────────────────────────────

  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _repo.requestPasswordReset(email);
      error = null;
      return true;
    } on TimeoutException {
      error = 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
      return false;
    } on ApiException catch (e) {
      error = _mapError(e);
      return false;
    } catch (_) {
      error = 'Error de comunicación con el servidor. Por favor intenta de nuevo.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────
  // Logout
  // ──────────────────────────────────────────────

  Future<void> logout() async {
    await _repo.logout();
    session = null;
    needsProfileCompletion = false;
    status = AuthStatus.unauthenticated;
    error = null;
    loading = false;
    onSessionReset?.call();
    notifyListeners();
  }

  /// Invocado por el interceptor global de ApiClient cuando el token expira o es revocado.
  void handleSessionExpired([String message = 'Tu sesión ha expirado. Por favor, inicia sesión de nuevo.']) {
    session = null;
    needsProfileCompletion = false;
    status = AuthStatus.unauthenticated;
    error = message;
    loading = false;
    onSessionReset?.call();
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  void _setLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  String _mapError(ApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Correo o contraseña incorrectos.';
      case 409:
        return 'Este correo ya está registrado.';
      case 422:
        return 'Datos inválidos. Revisa los campos.';
      case 500:
        return 'Error del servidor. Intenta más tarde.';
      default:
        return e.message;
    }
  }
}
