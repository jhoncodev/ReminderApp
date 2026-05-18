
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:reminder_app/core/widgets/bottom_nav_bar.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/course_session.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // ── constants ──────────────────────────────────────────────────────────────
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _startHour = 7;
  static const _endHour = 24;
  static const _totalHours = _endHour - _startHour;

  static const double _hourHeight = 80.0; // Increased for the new grid look
  static const double _timeColWidth = 65.0;
  static const double _dayColWidth = 100.0;

  // ── state ──────────────────────────────────────────────────────────────────
  List<Course> _courses = [];
  bool _loading = true;
  late DateTime _startOfWeek;

  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _calculateCurrentWeek();
    _loadCourses();
  }

  void _calculateCurrentWeek() {
    final now = DateTime.now();
    _startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  }

 Future<void> _loadCourses() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      
      // 1. Check if we actually have a logged-in user
      print("🔍 DEBUG: Current UID is: $uid");

      if (uid == null) {
        print("🚨 DEBUG: UID is null! The user is NOT logged in. Bailing out.");
        setState(() => _loading = false);
        return;
      }

      print("⏳ DEBUG: User is logged in. Fetching courses from Firestore...");

      final snap = await FirebaseFirestore.instance
          .collection('courses')
          .where('userId', isEqualTo: uid)
          .get();

      // 2. Did we get the data?
      print("✅ DEBUG: Success! Loaded ${snap.docs.length} courses for user $uid");

      setState(() {
        _courses = snap.docs.map((d) => Course.fromFirestore(d, null)).toList();
        for (var course in _courses) {
          print("📚 Course Name: ${course.name}");
          print("   Total Sessions: ${course.sessions.length}");
          for (var session in course.sessions) {
             print("   -> Day: ${session.dayOfWeek} | Start: ${session.startTime} | End: ${session.endTime}");
          }
        }
        _loading = false;
      });

    } catch (e) {
      // 3. Did Firebase throw a fit? (e.g., Security Rules, Missing Index)
      print("❌ DEBUG: Caught an error while fetching: $e");
      setState(() => _loading = false); 
    }
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

  Color _courseColor(int index) {
    const palette = [
      Color(0xFF9D65FF),
      Color(0xFF5EAEFF),
      Color(0xFFFF6B6B),
      Color(0xFF6BFFB8),
      Color(0xFFFFD166),
      Color(0xFFFF9F1C),
      Color(0xFF06D6A0),
    ];
    return palette[index % palette.length];
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F), // Original dark background
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
    final monthFormat = DateFormat('MMMM');
    final title = '${monthFormat.format(_startOfWeek)} ${_startOfWeek.day} - ${endOfWeek.day}, ${endOfWeek.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Text(
                  'Week',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(right: 20, bottom: 40),
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
        color: const Color(0xFF1C1C1E), // Slightly lighter dark card for header
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
        children: [
          for (int h = 0; h < _totalHours; h++)
            Positioned(
              top: h * _hourHeight - 8,
              left: 0,
              right: 12,
              child: Text(
                _formatHour(_startHour + h),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(int dayIndex) {
    final daySessions = <_SessionEntry>[];

    for (int ci = 0; ci < _courses.length; ci++) {
      final course = _courses[ci];
      for (final session in course.sessions) {
        if (session.dayOfWeek == dayIndex) {
          daySessions.add(_SessionEntry(course: course, session: session, colorIndex: ci));
        }
      }
    }

    return SizedBox(
      width: _dayColWidth,
      height: _totalHours * _hourHeight,
      child: Stack(
        children: [
          // Subtle horizontal grid lines adapted for dark mode
          for (int h = 0; h <= _totalHours; h++)
            Positioned(
              top: h * _hourHeight,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.05), 
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
    final color = _courseColor(entry.colorIndex);

    return Positioned(
      top: top,
      left: 6,
      right: 6,
      height: height,
      child: GestureDetector(
        onTap: () => _showSessionDetail(entry, color),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.18), // Original opacity background
            border: Border(left: BorderSide(color: color, width: 4)), // New left border style
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(8),
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (height > 70)
                Text(
                  '${entry.session.startTime} - ${entry.session.endTime}',
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetail(_SessionEntry entry, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E), // Original dark modal
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
            _detailRow(Icons.access_time_rounded, '${entry.session.startTime} – ${entry.session.endTime}'),
            if (entry.session.roomName != null) _detailRow(Icons.room_rounded, entry.session.roomName!),
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
    if (hour == 0) return '12:00 am';
    if (hour == 12) return '12:00 pm';
    return hour < 12 ? '${hour.toString().padLeft(2, '0')}:00 am' : '${(hour - 12).toString().padLeft(2, '0')}:00 pm';
  }
}

class _SessionEntry {
  final Course course;
  final CourseSession session;
  final int colorIndex;
  const _SessionEntry({required this.course, required this.session, required this.colorIndex});
}