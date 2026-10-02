import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/notificacion_repository.dart';

class FcmService {
  final NotificacionRepository _notificacionRepo;

  FcmService(this._notificacionRepo);

  Future<void> initialize() async {
    if (kIsWeb) {
      if (kDebugMode) print('FCM saltado en Web (requiere FirebaseOptions explícitos).');
      return;
    }

    try {
      // Graceful degradation si Firebase no está configurado (ej. sin google-services.json)
      await Firebase.initializeApp();
      
      final messaging = FirebaseMessaging.instance;
      
      // Solicitar permisos en iOS
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          if (kDebugMode) {
            print('FCM Token: $token');
          }
          await _notificacionRepo.registrarToken(token);
        }

        // Refrescar token si cambia
        messaging.onTokenRefresh.listen((newToken) async {
          await _notificacionRepo.registrarToken(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM no pudo ser inicializado (probablemente falte google-services.json): $e');
      }
    }
  }
}
