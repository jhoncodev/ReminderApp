
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/date_helpers.dart';
import 'package:reminder_app/core/utils/time_helpers.dart';
import 'package:reminder_app/core/widgets/bottom_nav_bar.dart';
import 'package:reminder_app/data/course_repository.dart';
import 'package:reminder_app/data/period_repository.dart';
import 'package:reminder_app/data/teacher_repository.dart';
import 'package:reminder_app/models/teacher.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/course_session.dart';
import 'package:reminder_app/models/period.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // ── constantes ──────────────────────────────────────────────────────────────
  static const _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _dayNames = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  static const _startHour = 0;
  static const _endHour = 24;
  static const _totalHours = _endHour - _startHour;

  static const double _hourHeight = 80.0; // Alto de cada hora en el grid
  static const double _timeColWidth = 46.0;
  static const double _gridHPadding = 8.0;

  // Ancho de columna calculado para que los 7 días entren al ancho de pantalla
  late double _dayColWidth;

  // ── estado ──────────────────────────────────────────────────────────────────
  List<Course> _courses = [];
  bool _loading = true;
  late DateTime _startOfWeek;
  final _courseRepository = CourseRepository();
  final _periodRepository = PeriodRepository();
  StreamSubscription<List<Course>>? _coursesSub;
  StreamSubscription<List<Period>>? _periodsSub;
  // Zoom y desplazamiento del grid (pinch para acercar/alejar).
  // Arranca posicionado en las 7 am; doble tap restaura tamaño y posición.
  final _gridTransform = TransformationController(_initialGridTransform());

  static Matrix4 _initialGridTransform() =>
      Matrix4.identity()..setTranslationRaw(0.0, -7 * _hourHeight, 0.0);
  List<Period> _periods = [];
  String? _selectedPeriodId;

  // ── ciclo de vida ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _calculateCurrentWeek();
    _watchCourses();
    _watchPeriods();
  }

  @override
  void dispose() {
    _coursesSub?.cancel();
    _periodsSub?.cancel();
    _gridTransform.dispose();
    super.dispose();
  }

  void _calculateCurrentWeek() {
    final now = DateTime.now();
    // Solo fecha (sin hora) para comparar rangos de periodos sin sorpresas
    _startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  void _changeWeek(int deltaWeeks) {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: 7 * deltaWeeks));
    });
  }

  void _goToCurrentWeek() {
    setState(_calculateCurrentWeek);
  }

  // Streams: entregan el cache local al instante (offline) y mantienen el grid reactivo
  void _watchCourses() {
    _coursesSub = _courseRepository.getUserCourses().listen(
      (courses) {
        if (!mounted) return;
        setState(() {
          _courses = courses;
          _loading = false;
        });
      },
      onError: (e) {
        debugPrint("Error al cargar los cursos del horario: $e");
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  void _watchPeriods() {
    _periodsSub = _periodRepository.watchAll().listen(
      (periods) {
        if (!mounted) return;
        setState(() {
          _periods = periods;
          // Si el periodo filtrado fue archivado o eliminado, volver a "Todos"
          if (_selectedPeriodId != null &&
              periods.every((p) => p.id != _selectedPeriodId)) {
            _selectedPeriodId = null;
          }
        });
      },
      onError: (e) => debugPrint("Error al cargar los periodos del horario: $e"),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  double _topOffset(String time) {
    final minutes = _toMinutes(time) - _startHour * 60;
    return (minutes / 60) * _hourHeight;
  }

  double _blockHeight(String start, String end) {
    final diff = _toMinutes(end) - _toMinutes(start);
    return (diff / 60) * _hourHeight;
  }

  // Cursos visibles en una FECHA concreta del grid:
  // - respetan el filtro manual del selector de periodo
  // - cursos sin periodo: siempre visibles
  // - cursos de periodos archivados o eliminados: ocultos
  // - cursos con periodo: solo en los días dentro del rango del periodo
  //   (un periodo 7-13 jun NO muestra el curso el día 3 aunque la semana lo toque)
  List<Course> _coursesActiveOn(DateTime date) {
    return _courses.where((course) {
      if (_selectedPeriodId != null &&
          course.academicPeriodId != _selectedPeriodId) {
        return false;
      }
      final periodId = course.academicPeriodId;
      if (periodId == null) return true;
      final period = _periodById(periodId);
      if (period == null) return false;
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
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  Period? _periodById(String id) {
    for (final period in _periods) {
      if (period.id == id) return period;
    }
    return null;
  }

  String get _selectedPeriodLabel {
    if (_selectedPeriodId == null) return 'Todos los periodos';
    final period = _periods.firstWhere(
      (p) => p.id == _selectedPeriodId,
      orElse: () => Period(
        userId: '', 
        name: 'Todos los periodos', 
        startDate: DateTime.now(), 
        endDate: DateTime.now(), 
        createdAt: DateTime.now(), 
        updatedAt: DateTime.now(),
      ),
    );
    return period.name;
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // La semana completa se adapta al ancho de la pantalla
    _dayColWidth = (MediaQuery.of(context).size.width -
            _timeColWidth -
            _gridHPadding * 2) /
        7;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F), // Fondo oscuro (hardcoded, deuda técnica)
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF9D65FF)),
                ),
              )
            else
              Expanded(child: _buildGrid()),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/schedule'),
    );
  }

  Widget _buildTopBar() {
    final endOfWeek = _startOfWeek.add(const Duration(days: 6));
    final monthFormat = DateFormat('MMMM', 'es');
    final title = '${capitalize(monthFormat.format(_startOfWeek))} ${_startOfWeek.day} - ${endOfWeek.day}, ${endOfWeek.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeWeek(-1),
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
            tooltip: 'Semana anterior',
          ),
          Expanded(
            child: GestureDetector(
              onTap: _goToCurrentWeek, // Tocar el título vuelve a la semana actual
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeWeek(1),
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            tooltip: 'Semana siguiente',
          ),
          GestureDetector(
            onTap: _openPeriodSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      _selectedPeriodLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GestureDetector(
      // Doble tap: volver al tamaño y posición normales
      onDoubleTap: () => _gridTransform.value = _initialGridTransform(),
      child: InteractiveViewer(
        transformationController: _gridTransform,
        // El grid entra al ancho de pantalla; se desliza vertical y
        // el pinch solo ACERCA (el mínimo ya es la semana completa)
        constrained: false,
        minScale: 1.0,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.only(bottom: 80),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _gridHPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDayHeader(),
              const SizedBox(height: 16),
              SizedBox(
                height: _totalHours * _hourHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeColumn(),
                    for (int dayIndex = 0; dayIndex < 7; dayIndex++)
                      _buildDayColumn(dayIndex),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayHeader() {
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.only(left: _timeColWidth),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // Card un poco más clara para el header
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final currentDate = _startOfWeek.add(Duration(days: index));
          final isToday = currentDate.day == today.day && currentDate.month == today.month;
          
          return Container(
            width: _dayColWidth,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  currentDate.day.toString(),
                  style: TextStyle(
                    color: isToday ? const Color(0xFF9D65FF) : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _days[index],
                  style: TextStyle(
                    color: isToday ? const Color(0xFF9D65FF) : Colors.white38,
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeColumn() {
    return SizedBox(
      width: _timeColWidth,
      child: Stack(
        // Sin clip: la etiqueta final "12 am" sobresale unos píxeles del alto del grid
        clipBehavior: Clip.none,
        children: [
          // <= para incluir la etiqueta de cierre del día ("12 am" final)
          for (int h = 0; h <= _totalHours; h++)
            Positioned(
              // La primera etiqueta no se desplaza hacia arriba para que no se corte
              top: h == 0 ? 0 : h * _hourHeight - 8,
              left: 0,
              right: 6,
              child: Text(
                _formatHour(_startHour + h),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(int dayIndex) {
    final date = _startOfWeek.add(Duration(days: dayIndex));
    final daySessions = <_SessionEntry>[];
    for (final course in _coursesActiveOn(date)) {
      for (final session in course.sessions) {
        if (session.dayOfWeek == dayIndex) {
          daySessions.add(_SessionEntry(course: course, session: session));
        }
      }
    }

    return SizedBox(
      width: _dayColWidth,
      height: _totalHours * _hourHeight,
      child: Stack(
        children: [
          // Líneas horizontales sutiles del grid
          for (int h = 0; h <= _totalHours; h++)
            Positioned(
              top: h * _hourHeight,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha:0.05), 
              ),
            ),
          
          for (final entry in daySessions) _buildSessionBlock(entry),
        ],
      ),
    );
  }

  Widget _buildSessionBlock(_SessionEntry entry) {
    final top = _topOffset(entry.session.startTime);
    final height = _blockHeight(entry.session.startTime, entry.session.endTime).clamp(40.0, double.infinity);
    final color = Color(entry.course.colorCode); // El color elegido al crear el curso

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height,
      child: GestureDetector(
        onTap: () => _showSessionDetail(entry, color),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.18), // Fondo translúcido del color del curso
            border: Border(left: BorderSide(color: color, width: 3)), // Borde izquierdo del color del curso
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.session.roomName != null && height > 50)
                Text(
                  entry.session.roomName!,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (height > 50) const SizedBox(height: 4),
              Text(
                entry.course.name,
                maxLines: height > 80 ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (height > 70)
                FittedBox(
                  // Encoge el texto si "11:30 PM - 11:59 PM" no entra en la columna
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${formatTo12h(entry.session.startTime)} - ${formatTo12h(entry.session.endTime)}',
                    style: TextStyle(
                      color: color.withValues(alpha:0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPeriodSelector() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrar por periodo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPeriodOption(
                sheetContext: sheetContext,
                label: 'Todos los periodos',
                periodId: null,
              ),
              for (final period in _periods)
                _buildPeriodOption(
                  sheetContext: sheetContext,
                  label: period.name,
                  periodId: period.id,
                ),
            ],
          ),
        )
      )
    );
  }

  Widget _buildPeriodOption({
    required BuildContext sheetContext,
    required String label,
    required String? periodId,
  }) {
    final isSelected = _selectedPeriodId == periodId;
    return InkWell(
      onTap: () {
        setState(() => _selectedPeriodId = periodId);
        Navigator.pop(sheetContext);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.purplePrimary : AppColors.hint,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDetail(_SessionEntry entry, Color color) {
    // Día de la semana + fecha de la semana mostrada (el grid se desliza,
    // así el usuario no pierde de vista qué día está viendo)
    final date = _startOfWeek.add(Duration(days: entry.session.dayOfWeek));
    final dayLabel = '${_dayNames[entry.session.dayOfWeek]} ${date.day}';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E), // Modal oscuro
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  entry.course.name,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.today_rounded, dayLabel),
            _detailRow(Icons.access_time_rounded, '${formatTo12h(entry.session.startTime)} – ${formatTo12h(entry.session.endTime)}'),
            if (entry.session.roomName != null) _detailRow(Icons.room_rounded, entry.session.roomName!),
            // Profesor vinculado: se consulta por id al abrir el detalle (cache offline)
            if (entry.course.teacherId != null)
              FutureBuilder<Teacher?>(
                future: TeacherRepository().getById(entry.course.teacherId!),
                builder: (context, snapshot) {
                  final teacher = snapshot.data;
                  if (teacher == null) return const SizedBox.shrink();
                  return _detailRow(Icons.person_outline, teacher.name);
                },
              ),
            if (entry.course.note != null && entry.course.note!.isNotEmpty)
              _detailRow(Icons.notes_rounded, entry.course.note!),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 am';
    if (hour == 12) return '12 pm';
    return hour < 12 ? '$hour am' : '${hour - 12} pm';
  }
}

class _SessionEntry {
  final Course course;
  final CourseSession session;
  const _SessionEntry({required this.course, required this.session});
}