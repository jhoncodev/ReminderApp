import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/date_helpers.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/period.dart';
import 'package:reminder_app/models/reminder.dart';
import 'package:reminder_app/models/schedule_item.dart';

class ScheduleRepository {
  ScheduleRepository._();

  // Decide si un curso se dicta en una fecha dada, considerando su periodo
  // - Curso sin periodo asociado: siempre visible
  // - Curso con periodo: solo si la fecha cae dentro del rango.
  // - Curso con periodo que ya no existe (archivado o borrado): descartar.
  static bool _isCourseActiveOn(
    Course course,
    List<Period> periods,
    DateTime date,
  ){
    if (course.academicPeriodId == null) return true;

    // Buscamos el periodo asociado al curso
    Period? period;
    for (final p in periods){
      if (p.id == course.academicPeriodId){
        period = p;
        break;
      }
    }

    if (period == null) return false;

    // Comparar solo año/mes/día para evitar problemas con horas/timezones
    final day = DateTime(date.year, date.month, date.day);

    final start = DateTime(
      period.startDate.year,
      period.startDate.month,
      period.startDate.day,
    );

    final end = DateTime(
      period.endDate.year,
      period.endDate.month,
      period.endDate.day,
    );

    return !day.isBefore(start) && !day.isAfter(end);
  }

  // Filtro de cursos activos HOY (para la sección "Pendientes Hoy")
  static List<Course> _filterCoursesByActivePeriod(List<Course> courses, List<Period> periods){
    final now = DateTime.now();
    return courses.where((c) => _isCourseActiveOn(c, periods, now)).toList();
  }

  static List<ScheduleItem> buildToday({
    required List<Course> courses,
    required List<Reminder> reminders,
    required List<Period> periods,
  }){
    final today = DateTime.now().weekday - 1;
    final activeCourses = _filterCoursesByActivePeriod(courses, periods);

    final items = <ScheduleItem>[
      ..._courseItemsForDays(activeCourses, [today]),
      ..._reminderItemsForToday(reminders),
    ];

    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  // Próximos N días (SIN incluir hoy), agrupados por día.
  // - Cursos: sesiones de ese día de la semana, solo si su periodo cubre ESA fecha
  // - Reminders "Diario": una card por día
  // - Reminders "Semanal": en los días que coincidan con scheduleDays
  // - Reminders "Una vez": solo en su fecha exacta
  // - Reminders "Mensual": el mismo día del mes de su primera fecha, en adelante
  static List<DaySchedule> buildUpcomingDays({
    required List<Course> courses,
    required List<Reminder> reminders,
    required List<Period> periods,
    required int daysAhead,
  }){
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <DaySchedule>[];

    for (var offset = 1; offset <= daysAhead; offset++){
      final date = today.add(Duration(days: offset));
      final dow = date.weekday - 1;
      final daySuffix = '${date.year}-${date.month}-${date.day}';
      final items = <ScheduleItem>[];

      for (final c in courses){
        if (!_isCourseActiveOn(c, periods, date)) continue;
        for (final s in c.sessions){
          if (s.dayOfWeek != dow) continue;
          items.add(
            ScheduleItem(
              id: '${c.id}_${daySuffix}_${s.startTime}',
              title: c.name,
              subtitle: s.roomName != null ? 'Curso • ${s.roomName}' : 'Curso',
              time: s.startTime,
              endTime: s.endTime,
              accentColor: Color(c.colorCode),
              icon: Icons.school_outlined,
              type: ScheduleItemType.course,
            ),
          );
        }
      }

      for (final r in reminders){
        bool matches = false;
        if (r.frequency == 'Diario'){
          matches = true;
        } else if (r.frequency == 'Semanal'){
          matches = r.scheduleDays.contains(dow);
        } else if (r.frequency == 'Una vez' && r.date != null){
          matches = r.date!.year == date.year &&
              r.date!.month == date.month &&
              r.date!.day == date.day;
        } else if (r.frequency == 'Mensual' && r.date != null){
          final initial = DateTime(r.date!.year, r.date!.month, r.date!.day);
          matches = date.day == r.date!.day && !date.isBefore(initial);
        }
        if (matches) items.add(_reminderToItemForDay(r, daySuffix));
      }

      if (items.isEmpty) continue;
      items.sort((a, b) => a.time.compareTo(b.time));
      days.add(DaySchedule(date: date, label: _dayLabel(date, offset), items: items));
    }
    return days;
  }

  // "Mañana" para el primer día; el resto "Viernes 13", "Sábado 14", ...
  // Si el día cae en otro mes, se agrega el mes: "Miércoles 1 de Julio"
  static String _dayLabel(DateTime date, int offset){
    if (offset == 1) return 'Mañana';
    final now = DateTime.now();
    final dayPart = capitalize(DateFormat('EEEE d', 'es').format(date));
    if (date.month == now.month && date.year == now.year) return dayPart;
    return '$dayPart de ${capitalize(DateFormat('MMMM', 'es').format(date))}';
  }

  static List<ScheduleItem> _courseItemsForDays(List<Course> courses, List<int> days){
    final items = <ScheduleItem>[];
    for (final c in courses){
      for (final s in c.sessions){
        if (!days.contains(s.dayOfWeek)) continue;
        items.add(
          ScheduleItem(
            id: '${c.id}_${s.dayOfWeek}',
            title: c.name,
            subtitle: s.roomName != null ? 'Curso • ${s.roomName}' : 'Curso',
            time: s.startTime,
            endTime: s.endTime,
            accentColor: Color(c.colorCode),
            icon: Icons.school_outlined,
            type: ScheduleItemType.course,
          )
        );
      }
    }
    return items;
  }

  static List<ScheduleItem> _reminderItemsForToday(List<Reminder> reminders){
    final now = DateTime.now();
    final today = now.weekday - 1;
    final items = <ScheduleItem>[];

    for (final r in reminders){
      bool matches = false;
      if (r.frequency == 'Diario'){
        matches = true;
      } else if(r.frequency == 'Semanal'){
        matches = r.scheduleDays.contains(today);
      } else if (r.frequency == 'Una vez' && r.date != null){
        matches = r.date!.year == now.year && r.date!.month == now.month && r.date!.day == now.day;
      } else if (r.frequency == 'Mensual' && r.date != null){
        // Se repite el mismo día del mes, a partir de su primera fecha
        final initial = DateTime(r.date!.year, r.date!.month, r.date!.day);
        final todayDate = DateTime(now.year, now.month, now.day);
        matches = now.day == r.date!.day && !todayDate.isBefore(initial);
      }
      if (matches) items.add(_reminderToItem(r));
    }
    return items;
  }

  static ScheduleItem _reminderToItem(Reminder r){
    return ScheduleItem(
      id: r.id ?? '', 
      title: r.name, 
      subtitle: r.budgetAmount != null ? 'Finanza • ${r.frequency}' : 'Recordatorio • ${r.frequency}', 
      time: r.startTime ?? '00:00', 
      accentColor: AppColors.cyan, 
      icon: Icons.notifications_outlined, 
      type: ScheduleItemType.activity,
    );
  }

  // Igual que _reminderToItem pero con id único por fecha,
  // para que Flutter no se queje de keys duplicadas cuando un
  // reminder Diario genera múltiples cards (una por cada día).
  static ScheduleItem _reminderToItemForDay(Reminder r, String daySuffix) {
    return ScheduleItem(
      id: '${r.id ?? ''}_$daySuffix',
      title: r.name,
      subtitle: r.budgetAmount != null
          ? 'Finanza • ${r.frequency}'
          : 'Recordatorio • ${r.frequency}',
      time: r.startTime ?? '00:00',
      accentColor: AppColors.cyan,
      icon: Icons.notifications_outlined,
      type: ScheduleItemType.activity,
    );
  }

}
