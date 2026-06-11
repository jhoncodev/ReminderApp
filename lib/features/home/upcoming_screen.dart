import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/schedule_item_card.dart';
import 'package:reminder_app/core/widgets/status_views.dart';
import 'package:reminder_app/data/course_repository.dart';
import 'package:reminder_app/data/period_repository.dart';
import 'package:reminder_app/data/reminder_repository.dart';
import 'package:reminder_app/data/schedule_repository.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/period.dart';
import 'package:reminder_app/models/reminder.dart';

// Pantalla "Ver Todo": pendientes de los próximos 30 días agrupados por día
class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  static const _daysAhead = 30;

  late final Stream<List<Course>> _coursesStream = CourseRepository().watchAll();
  late final Stream<List<Reminder>> _remindersStream =
      ReminderRepository().watchAll();
  late final Stream<List<Period>> _periodsStream = PeriodRepository().watchAll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Pendientes Futuros"),
      body: StreamBuilder<List<Course>>(
        stream: _coursesStream,
        builder: (context, coursesSnap) => StreamBuilder<List<Reminder>>(
          stream: _remindersStream,
          builder: (context, remindersSnap) => StreamBuilder<List<Period>>(
            stream: _periodsStream,
            builder: (context, periodsSnap) {
              if (coursesSnap.hasError ||
                  remindersSnap.hasError ||
                  periodsSnap.hasError) {
                return AppErrorView(
                  message: "No se pudieron cargar los pendientes",
                  error: coursesSnap.error ??
                      remindersSnap.error ??
                      periodsSnap.error,
                );
              }

              final isLoading =
                  coursesSnap.connectionState == ConnectionState.waiting ||
                      remindersSnap.connectionState == ConnectionState.waiting ||
                      periodsSnap.connectionState == ConnectionState.waiting;
              if (isLoading) return const AppLoadingView();

              final days = ScheduleRepository.buildUpcomingDays(
                courses: coursesSnap.data ?? [],
                reminders: remindersSnap.data ?? [],
                periods: periodsSnap.data ?? [],
                daysAhead: _daysAhead,
              );

              if (days.isEmpty) {
                return const Center(
                  child: Text(
                    "Nada pendiente en los próximos 30 días",
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  for (final day in days) DaySection(day: day),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
