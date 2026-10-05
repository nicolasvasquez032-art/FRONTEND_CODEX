import 'dart:async';

import 'package:flutter/material.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/domain/entities/user_session.dart';
import 'package:talentmatch/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthProvider(this._repo) {
    _init();
  }

  AuthStatus status = AuthStatus.unknown;
  UserSession? session;
  bool loading = false;
  String? error;
  bool hasSeenOnboarding = false;

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
      status = AuthStatus.authenticated;
      error = null;
    } on TimeoutException {
      error = 'El servidor tardó demasiado en responder. Verifica tu conexión e inténtalo de nuevo.';
      status = AuthStatus.unauthenticated;
    } on ApiException catch (e) {
      error = _mapError(e);
      status = AuthStatus.unauthenticated;
    } catch (_) {
      error = 'Sin conexión a internet.';
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
    } on ApiException catch (e) {
      error = _mapError(e);
      status = AuthStatus.unauthenticated;
    } catch (_) {
      error = 'Sin conexión a internet.';
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
  }) async {
    _setLoading(true);
    try {
      await _repo.registerCompany(email: email, password: password);
      error = null;
    } on ApiException catch (e) {
      error = _mapError(e);
      status = AuthStatus.unauthenticated;
    } catch (_) {
      error = 'Sin conexión a internet.';
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
    } on ApiException catch (e) {
      error = _mapError(e);
      return false;
    } catch (_) {
      error = 'Sin conexión a internet.';
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
    status = AuthStatus.unauthenticated;
    error = null;
    loading = false;
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
