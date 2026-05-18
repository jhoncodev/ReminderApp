// lib/data/schedule_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/models/schedule_item.dart';

class ScheduleRepository {
  final _db = FirebaseFirestore.instance;

  // Flutter weekday: Mon=1 … Sun=7  →  your schema: Mon=0 … Sun=6
  int get _todayDow => DateTime.now().weekday - 1;

  // Days remaining this week after today (for "Upcoming")
  List<int> get _remainingDow {
    final today = _todayDow;
    return List.generate(6 - today, (i) => today + 1 + i);
  }

  // ── TODAY ──────────────────────────────────────────────────────────────
  Future<List<ScheduleItem>> getTodaySchedule(String userId) async {
    final results = await Future.wait([
      _getCoursesForDays(userId, [_todayDow]),
      _getActivitiesForDays(userId, [_todayDow]),
    ]);
    final items = [...results[0], ...results[1]];
    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  // ── UPCOMING (rest of the week) ────────────────────────────────────────
  Future<List<ScheduleItem>> getUpcomingSchedule(String userId) async {
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
    final List<ScheduleItem> items = [];

    // Activities tipo "Una vez" con fecha futura
    final activitiesSnap = await _db
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .where('frequency', isEqualTo: 'Una vez')
        .get();

    for (final doc in activitiesSnap.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp?)?.toDate();
      if (date != null && date.isAfter(startOfTomorrow)) {
        items.add(
          ScheduleItem(
            id: doc.id,
            title: data['name'] ?? '',
            subtitle: _activitySubtitle(data),
            time: data['startTime'] ?? '00:00',
            accentColor: const Color(0xFF4EE6D3),
            icon: Icons.self_improvement,
            type: ScheduleItemType.activity,
          ),
        );
      }
    }

    // Cursos con sesiones en los días restantes de la semana
    final courseItems = await _getCoursesForDays(userId, _remainingDow);
    items.addAll(courseItems);

    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────

  Future<List<ScheduleItem>> _getActivitiesForDays(
    String userId,
    List<int> days,
  ) async {
    final activitiesSnap = await _db
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .get();

    final List<ScheduleItem> items = [];

    for (final doc in activitiesSnap.docs) {
      final data = doc.data();
      final frequency = data['frequency'] ?? 'Una vez';

      // scheduleDays is an array inside the document, not a subcollection
      final scheduleDays = List<int>.from(data['scheduleDays'] ?? []);

      bool matches = false;

      if (frequency == 'Diario') {
        matches = true;
      } else if (frequency == 'Semanal') {
        matches = scheduleDays.any((d) => days.contains(d));
      } else if (frequency == 'Una vez') {
        // Match by date field instead of day_of_week
        final date = (data['date'] as Timestamp?)?.toDate();
        if (date != null) {
          final now = DateTime.now();
          // For today: check if date is today
          matches =
              days.contains(_todayDow) &&
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }
      }

      if (matches) {
        items.add(
          ScheduleItem(
            id: doc.id,
            title: data['name'] ?? '',
            subtitle: _activitySubtitle(data),
            time: data['startTime'] ?? '00:00', // camelCase
            accentColor: const Color(0xFF4EE6D3),
            icon: Icons.self_improvement,
            type: ScheduleItemType.activity,
          ),
        );
      }
    }

    return items;
  }

  Future<List<ScheduleItem>> _getCoursesForDays(
    String userId,
    List<int> days,
  ) async {
    final coursesSnap = await _db
        .collection('courses')
        .where('userId', isEqualTo: userId)
        .get();

    final List<ScheduleItem> items = [];

    for (final doc in coursesSnap.docs) {
      final data = doc.data();
      final name = data['name'] as String? ?? '';

      // Leer el array de sesiones embebido
      final sessionsRaw = (data['sessions'] as List<dynamic>?) ?? [];

      // Por cada sesión, si su día coincide con los buscados, agregamos un item
      for (final raw in sessionsRaw) {
        final session = raw as Map<String, dynamic>;
        final dayOfWeek = session['dayOfWeek'] as int;

        if (!days.contains(dayOfWeek)) continue;

        final startTime = session['startTime'] as String? ?? '00:00';
        final roomName = session['roomName'] as String?;

        items.add(
          ScheduleItem(
            // ID único por curso+día para no colisionar cuando hay varias sesiones
            id: '${doc.id}_$dayOfWeek',
            title: name,
            subtitle: roomName != null ? 'Curso • $roomName' : 'Curso',
            time: startTime,
            accentColor: const Color(0xFFB483FF),
            icon: Icons.school_outlined,
            type: ScheduleItemType.course,
          ),
        );
      }
    }

    return items;
  }

  String _activitySubtitle(Map<String, dynamic> data) {
    final freq = data['frequency'] ?? '';
    final budget = data['budget_amount'];
    return budget != null ? 'Finanza • $freq' : 'Recordatorio • $freq';
  }
}
