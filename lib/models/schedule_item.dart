// lib/data/models/schedule_item.dart
import 'package:flutter/material.dart';

enum ScheduleItemType { course, activity }

class ScheduleItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String? endTime; // Solo cursos: hora de fin de la sesión
  final Color accentColor;
  final IconData icon;
  final ScheduleItemType type;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    this.endTime,
    required this.accentColor,
    required this.icon,
    required this.type,
  });
}

// Items de un día concreto, con etiqueta para el encabezado
// de la lista ("Mañana", "Viernes 13", ...)
class DaySchedule {
  final DateTime date;
  final String label;
  final List<ScheduleItem> items;

  DaySchedule({
    required this.date,
    required this.label,
    required this.items,
  });
}