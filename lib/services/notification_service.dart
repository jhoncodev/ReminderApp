import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:reminder_app/core/utils/time_helpers.dart';
import 'package:reminder_app/data/course_repository.dart';
import 'package:reminder_app/data/period_repository.dart';
import 'package:reminder_app/data/reminder_repository.dart';
import 'package:reminder_app/data/schedule_repository.dart';
import 'package:reminder_app/data/shared_item_repository.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/period.dart';
import 'package:reminder_app/models/reminder.dart';
import 'package:reminder_app/models/schedule_item.dart';
import 'package:reminder_app/models/shared_item.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Notificaciones locales: avisos N minutos antes de cada curso o
// recordatorio con hora, según la config del usuario (campana del Home).
//
// Cómo funciona:
// - La config (lista de minutos, ej. [15, 5]) vive en users/{uid}.notificationLeadTimes.
// - El servicio se suscribe a cursos/recordatorios/periodos/config; ante
//   cualquier cambio espera 2s (debounce) y reprograma todo desde cero.
// - Reutiliza buildToday/buildUpcomingDays: las notificaciones siempre
//   coinciden con lo que muestra el Home.
// - Horizonte: hoy + 7 días (se renueva con cada uso de la app).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  StreamSubscription? _coursesSub;
  StreamSubscription? _remindersSub;
  StreamSubscription? _periodsSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _inboxSub;
  List<Course> _courses = [];
  List<Reminder> _reminders = [];
  List<Period> _periods = [];
  List<int> _leadTimes = [];
  Timer? _debounce;
  String? _activeUid;

  // Avisos programados usan ids 0..N (se cancelan al reprogramar);
  // los instantáneos usan ids desde 800000 y los de compartidos desde 900000
  int _lastScheduledCount = 0;
  int _instantNotificationId = 800000;
  int _inboxNotificationId = 900000;
  final Set<String> _knownSharedIds = {};
  bool _inboxPrimed = false;
  // Ocurrencias ya avisadas de inmediato: evita re-notificar lo mismo
  // cada vez que un cambio de datos dispara la reprogramación
  final Set<String> _instantNotified = {};

  static const _daysAhead = 7;

  Future<void> init() async {
    if (_initialized) return;

    // El plugin agenda en hora local: hay que decirle la zona horaria del equipo
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint("No se pudo detectar la zona horaria: $e");
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  // Permiso de Android 13+ (en versiones anteriores devuelve concedido)
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  // Arranca las suscripciones del usuario actual (idempotente por uid)
  void start() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == _activeUid) return;
    stop();
    _activeUid = uid;

    _coursesSub = CourseRepository().watchAll().listen(
      (courses) {
        _courses = courses;
        _scheduleSoon();
      },
      onError: (e) => debugPrint("Notificaciones, error en cursos: $e"),
    );
    _remindersSub = ReminderRepository().watchAll().listen(
      (reminders) {
        _reminders = reminders;
        _scheduleSoon();
      },
      onError: (e) => debugPrint("Notificaciones, error en recordatorios: $e"),
    );
    _periodsSub = PeriodRepository().watchAll().listen(
      (periods) {
        _periods = periods;
        _scheduleSoon();
      },
      onError: (e) => debugPrint("Notificaciones, error en periodos: $e"),
    );
    _settingsSub = watchLeadTimes().listen(
      (leadTimes) {
        _leadTimes = leadTimes;
        _scheduleSoon();
      },
      onError: (e) => debugPrint("Notificaciones, error en config: $e"),
    );
    // Compartidos: aviso instantáneo cuando llega algo nuevo a la bandeja.
    // (Funciona con la app abierta o en segundo plano; push real requeriría
    // FCM + Cloud Functions, fuera del alcance del proyecto.)
    _inboxSub = SharedItemRepository().watchInbox().listen(
      _onInboxChanged,
      onError: (e) => debugPrint("Notificaciones, error en compartidos: $e"),
    );
  }

  void _onInboxChanged(List<SharedItem> items) {
    // La primera emisión trae lo que YA estaba en la bandeja: no se notifica
    if (!_inboxPrimed) {
      _knownSharedIds.addAll(items.map((i) => i.id ?? ''));
      _inboxPrimed = true;
      return;
    }

    for (final item in items) {
      final id = item.id ?? '';
      if (_knownSharedIds.contains(id)) continue;
      _knownSharedIds.add(id);

      _plugin.show(
        _inboxNotificationId++,
        "Nuevo compartido",
        "${item.fromUserName} te compartió un ${item.typeLabel.toLowerCase()}: ${item.displayTitle}",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'compartidos_channel',
            'Compartidos recibidos',
            channelDescription:
                'Avisos cuando un compañero te comparte un recurso',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  // Detiene las suscripciones y borra lo programado (ej. al cerrar sesión)
  void stop() {
    _coursesSub?.cancel();
    _remindersSub?.cancel();
    _periodsSub?.cancel();
    _settingsSub?.cancel();
    _inboxSub?.cancel();
    _debounce?.cancel();
    _activeUid = null;
    _knownSharedIds.clear();
    _inboxPrimed = false;
    _instantNotified.clear();
    _lastScheduledCount = 0;
    if (_initialized) {
      _plugin
          .cancelAll()
          .catchError((e) => debugPrint("Error al limpiar notificaciones: $e"));
    }
  }

  // Debounce: los 4 streams disparan casi juntos al abrir la app;
  // así reprogramamos UNA sola vez en lugar de 4
  void _scheduleSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _rescheduleAll);
  }

  Future<void> _rescheduleAll() async {
    if (!_initialized || _activeUid == null) return;

    // Cancela SOLO los avisos programados anteriores (ids 0..N);
    // cancelAll() borraría también las notificaciones de compartidos visibles
    for (var i = 0; i < _lastScheduledCount; i++) {
      await _plugin.cancel(i);
    }
    _lastScheduledCount = 0;
    if (_leadTimes.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var notificationId = 0;

    // Las mismas ocurrencias que muestra el Home: hoy + próximos 7 días
    final occurrences = <({DateTime date, ScheduleItem item})>[
      for (final item in ScheduleRepository.buildToday(
        courses: _courses,
        reminders: _reminders,
        periods: _periods,
      ))
        (date: today, item: item),
      for (final day in ScheduleRepository.buildUpcomingDays(
        courses: _courses,
        reminders: _reminders,
        periods: _periods,
        daysAhead: _daysAhead,
      ))
        for (final item in day.items) (date: day.date, item: item),
    ];

    for (final occ in occurrences) {
      // '00:00' es el default de recordatorios sin hora: no se les avisa
      if (occ.item.time == '00:00' &&
          occ.item.type == ScheduleItemType.activity) {
        continue;
      }

      final parts = occ.item.time.split(':');
      final start = DateTime(
        occ.date.year,
        occ.date.month,
        occ.date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      final isCourse = occ.item.type == ScheduleItemType.course;

      // Caso límite: el evento aún no empieza pero TODOS los avisos ya
      // quedaron en el pasado (ej. lo creaste faltando 3 min con avisos
      // de 15 y 5) -> un único aviso inmediato, sin repetirlo en
      // reprogramaciones posteriores
      final allLeadsMissed = start.isAfter(now) &&
          _leadTimes.every(
            (lead) => !start.subtract(Duration(minutes: lead)).isAfter(now),
          );
      if (allLeadsMissed) {
        final key = occ.item.id;
        if (!_instantNotified.contains(key)) {
          _instantNotified.add(key);
          final minutesLeft = start.difference(now).inMinutes;
          final timeText = minutesLeft < 1
              ? "en menos de un minuto"
              : "en $minutesLeft min";
          await _plugin.show(
            _instantNotificationId++,
            occ.item.title,
            isCourse
                ? "Tu curso empieza $timeText (${formatTo12h(occ.item.time)})"
                : "Tu recordatorio es $timeText (${formatTo12h(occ.item.time)})",
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'avisos_channel',
                'Avisos de cursos y recordatorios',
                channelDescription:
                    'Notificaciones antes de cada curso o recordatorio con hora',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
          );
        }
        continue;
      }

      for (final lead in _leadTimes) {
        final fireAt = start.subtract(Duration(minutes: lead));
        if (!fireAt.isAfter(now)) continue;

        await _plugin.zonedSchedule(
          notificationId++,
          occ.item.title,
          isCourse
              ? "Tu curso empieza en $lead min (${formatTo12h(occ.item.time)})"
              : "Tu recordatorio es en $lead min (${formatTo12h(occ.item.time)})",
          tz.TZDateTime.from(fireAt, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'avisos_channel',
              'Avisos de cursos y recordatorios',
              channelDescription:
                  'Notificaciones antes de cada curso o recordatorio con hora',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          // Modo inexacto: puede variar ~1 min pero no requiere el permiso
          // especial de alarmas exactas de Android 12+
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }

    _lastScheduledCount = notificationId;
    debugPrint("Notificaciones programadas: $notificationId");
  }

  // Config de avisos: users/{uid}.notificationLeadTimes

  Stream<List<int>> watchLeadTimes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          final raw = doc.data()?['notificationLeadTimes'] as List<dynamic>?;
          final leads = raw?.map((e) => e as int).toList() ?? <int>[];
          leads.sort((a, b) => b.compareTo(a)); // de mayor a menor: 15, 10, 5
          return leads;
        });
  }

  void saveLeadTimes(List<int> leadTimes) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
          'notificationLeadTimes': leadTimes,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .catchError((e) => debugPrint("Error al sincronizar config de avisos: $e"));
  }
}
