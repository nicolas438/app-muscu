import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';

/// Alerte de fin de repos : notification programmée qui fait vibrer le
/// téléphone (et sonne selon ses réglages) à l'heure exacte de fin du repos.
///
/// La notification est confiée au système : elle se déclenche même si
/// l'application est en arrière-plan ou l'écran verrouillé, ce qui est le
/// cas le plus courant entre deux séries.
class RestAlarmService {
  static final RestAlarmService _instance = RestAlarmService._internal();
  factory RestAlarmService() => _instance;
  RestAlarmService._internal();

  /// Identifiant unique : une seule alerte de repos peut exister à la fois.
  static const int _notificationId = 4201;
  static const String _channelId = 'rest_timer';

  /// Motif de vibration (en millisecondes) : pause, vibre, pause, vibre…
  /// Trois impulsions bien distinctes, reconnaissables même dans une poche.
  static final Int64List _vibrationPattern = Int64List.fromList([0, 450, 200, 450, 200, 700]);

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionsRequested = false;

  /// Initialise le module de notifications. À appeler au démarrage.
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Les autorisations sont demandées au premier repos, pas au lancement.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Notifications indisponibles : $e');
    }
  }

  /// Demande l'autorisation d'afficher des notifications (Android 13+ et iOS),
  /// une seule fois par lancement de l'application.
  Future<void> requestPermissions() async {
    if (!_initialized || _permissionsRequested) return;
    _permissionsRequested = true;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
    } catch (e) {
      debugPrint('Autorisation de notification refusée ou indisponible : $e');
    }
  }

  /// Programme l'alerte de fin de [rest], en remplaçant la précédente.
  Future<void> schedule(ActiveRest rest) async {
    if (!_initialized) return;
    await cancel();

    // Le système refuse les dates passées ; une marge évite les cas limites.
    if (!rest.endsAt.isAfter(DateTime.now().add(const Duration(seconds: 1)))) return;

    try {
      final android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Alarme exacte si le système l'autorise, sinon approximative
      // (quelques secondes de décalage possibles).
      final canBeExact = await android?.canScheduleExactNotifications() ?? true;

      await _plugin.zonedSchedule(
        id: _notificationId,
        title: 'Repos terminé',
        body: 'C\'est reparti : ${rest.exerciseName}',
        // Instant absolu en UTC : aucune base de fuseaux horaires n'est nécessaire.
        scheduledDate: tz.TZDateTime.from(rest.endsAt, tz.UTC),
        androidScheduleMode: canBeExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Fin du temps de repos',
            channelDescription: 'Vibre et sonne quand le temps de repos entre deux séries est écoulé.',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            enableVibration: true,
            vibrationPattern: _vibrationPattern,
            playSound: true,
            // La notification disparaît d'elle-même après une minute.
            timeoutAfter: 60000,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Impossible de programmer la fin du repos : $e');
    }
  }

  /// Annule l'alerte de repos en attente (repos passé ou séance terminée).
  Future<void> cancel() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (e) {
      debugPrint('Impossible d\'annuler l\'alerte de repos : $e');
    }
  }
}
