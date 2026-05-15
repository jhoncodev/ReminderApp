// lib/data/models/schedule_item.dart
import 'package:flutter/material.dart';

enum ScheduleItemType { course, activity }

class ScheduleItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final Color accentColor;
  final IconData icon;
  final ScheduleItemType type;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.accentColor,
    required this.icon,
    required this.type,
  });
}