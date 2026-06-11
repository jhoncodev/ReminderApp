import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/time_helpers.dart';
import 'package:reminder_app/models/schedule_item.dart';

// Card de un pendiente (curso o recordatorio) con su hora a la izquierda.
// Usada en Home (Pendientes Hoy / Próximos) y en Pendientes Futuros.
class ScheduleItemCard extends StatelessWidget {
  final ScheduleItem item;

  const ScheduleItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna de hora: inicio arriba y, si hay (cursos), fin debajo más tenue
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatTo12h(item.time),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.endTime != null)
                  Text(
                    formatTo12h(item.endTime!),
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Card del evento
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                // Borde izquierdo del color del curso/recordatorio
                border: Border(
                  left: BorderSide(color: item.accentColor, width: 4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(item.icon, color: Colors.white24, size: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sección colapsable de un día: encabezado ("Mañana", "Viernes 13", ...)
// con contador de items y chevron para expandir/colapsar sus cards.
class DaySection extends StatefulWidget {
  final DaySchedule day;

  const DaySection({super.key, required this.day});

  @override
  State<DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<DaySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 4),
            child: Row(
              children: [
                Text(
                  day.label,
                  style: const TextStyle(
                    color: AppColors.purpleSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${day.items.length})',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...day.items.map((item) => ScheduleItemCard(item: item)),
        const SizedBox(height: 8),
      ],
    );
  }
}
