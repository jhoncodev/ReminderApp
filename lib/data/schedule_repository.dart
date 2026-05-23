import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/period.dart';
import 'package:reminder_app/models/reminder.dart';
import 'package:reminder_app/models/schedule_item.dart';

class ScheduleRepository {
  ScheduleRepository._();

  // Decide si un curso debe mostrarse el dia que se abre la aplicacion, considerando el perdiodo
  // - Curso sin periodo asociado: siempre visible
  // - Curso con periodo: solo si la fecha actual cae dentro del rango.
  // - Curso con periodo que ya no existe (borrado): descartar.
  static bool _isCourseInActivePeriod(
    Course course,
    List<Period> periods,
    DateTime now,
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
    final today = DateTime(now.year, now.month, now.day);
    
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

    return !today.isBefore(start) && !today.isAfter(end);
  }

  // Aplicamos el filtro de periodo dentro de la fecha que se usa la app para no  mostrar cursos de periodos que ya pasaron
  static List<Course> _filterCoursesByActivePeriod(List<Course> courses, List<Period> periods){
    final now = DateTime.now();
    return courses.where((c) => _isCourseInActivePeriod(c, periods, now)).toList();
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

  static List<ScheduleItem> buildUpcoming({
    required List<Course> courses,
    required List<Reminder> reminders,
    required List<Period> periods,
  }){
    final now = DateTime.now();
    final today = now.weekday - 1;
    final remainingDow = List.generate(6 - today, (i) => today + 1 + i);
    
    final activeCourses = _filterCoursesByActivePeriod(courses, periods);

    final items = <ScheduleItem>[
      ..._courseItemsForDays(activeCourses, remainingDow),
      ..._reminderItemsForUpComing(reminders, remainingDow, now),
    ];

    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
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
            accentColor: AppColors.purpleLight, 
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
      }
      if (matches) items.add(_reminderToItem(r));
    }
    return items;
  }

  // Genera items para cada día restante de la semana
  // - Reminders "Diario": una card por cada día restante
  // - Reminders "Semana": una card por cad día restante que coincida
  // - Reminders "Una vez": una sola card si la fecha cae dentro de la seman actual
  static List<ScheduleItem> _reminderItemsForUpComing(
    List<Reminder> reminders,
    List<int> remainingDow,
    DateTime now,
  ){
    final items = <ScheduleItem>[];
    final today = now.weekday - 1;

    // Límites de la semana actual restante: desde el siguiente dia hasta el últumo día de la seman domingo
    final daysUntilSunday = 6 - today;
    final endOfWeek = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSunday,
      23,
      59,
      59,
    );
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);

    for (final r in reminders){
      if (r.frequency == 'Diario'){
        for (final dow in remainingDow){
          items.add(_reminderToItemForDay(r, dow));
        }
      }else if (r.frequency == 'Semanal'){
        for (final dow in remainingDow){
          if (r.scheduleDays.contains(dow)){
            items.add(_reminderToItemForDay(r, dow));
          }
        }
      }else if (r.frequency == 'Una vez' && r.date != null){
        if (r.date!.isAfter(startOfTomorrow) && r.date!.isBefore(endOfWeek)){
          items.add(_reminderToItem(r));
        }
      }
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
      icon: Icons.self_improvement, 
      type: ScheduleItemType.activity,
    );
  }

  // Igual que _reminderToItem pero con id único por día,
  // para que Flutter no se queje de keys duplicadas cuando un
  // reminder Diario genera múltiples cards (una por cada día restante).
  static ScheduleItem _reminderToItemForDay(Reminder r, int dayOfWeek) {
    return ScheduleItem(
      id: '${r.id ?? ''}_$dayOfWeek',
      title: r.name,
      subtitle: r.budgetAmount != null
          ? 'Finanza • ${r.frequency}'
          : 'Recordatorio • ${r.frequency}',
      time: r.startTime ?? '00:00',
      accentColor: AppColors.cyan,
      icon: Icons.self_improvement,
      type: ScheduleItemType.activity,
    );
  }

}
