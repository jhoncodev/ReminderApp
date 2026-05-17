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

    // Courses with a future end date (or start date if you prefer)
    final coursesSnap = await _db
        .collection('courses')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in coursesSnap.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp?)?.toDate();
      if (date != null && date.isAfter(startOfTomorrow)) {
        items.add(
          ScheduleItem(
            id: doc.id,
            title: data['name'] ?? '',
            subtitle: 'Course',
            time: data['startTime'] ?? '00:00',
            accentColor: const Color(0xFFB483FF),
            icon: Icons.school_outlined,
            type: ScheduleItemType.course,
          ),
        );
      }
    }

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
        .where('userId', isEqualTo: userId) // camelCase
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
        .where('userId', isEqualTo: userId) // camelCase
        .get();

    final List<ScheduleItem> items = [];

    for (final doc in coursesSnap.docs) {
      final data = doc.data();
      final scheduleDays = List<int>.from(data['scheduleDays'] ?? []);

      final matches = scheduleDays.any((d) => days.contains(d));

      if (matches) {
        items.add(
          ScheduleItem(
            id: doc.id,
            title: data['name'] ?? '',
            subtitle: 'Course',
            time: data['startTime'] ?? '00:00',
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
    return budget != null ? 'Finance • $freq' : 'Activity • $freq';
  }
}
