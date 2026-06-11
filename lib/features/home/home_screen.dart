import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/bottom_nav_bar.dart';
import 'package:reminder_app/core/widgets/create_options_sheet.dart';
import 'package:reminder_app/core/widgets/schedule_item_card.dart';
import 'package:reminder_app/features/home/upcoming_screen.dart';
import 'package:reminder_app/data/course_repository.dart';
import 'package:reminder_app/data/period_repository.dart';
import 'package:reminder_app/data/reminder_repository.dart';
import 'package:reminder_app/data/schedule_repository.dart';
import 'package:reminder_app/data/user_repository.dart';
import 'package:reminder_app/features/auth/login_screen.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/reminder.dart';
import 'package:reminder_app/models/schedule_item.dart';
  import 'package:reminder_app/models/period.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  final _userRepository = UserRepository();
  final _courseRepository = CourseRepository();
  final _reminderRepository = ReminderRepository();
  final _periodRepository = PeriodRepository();

  late final Stream<List<Course>> _coursesStream;
  late final Stream<List<Reminder>> _remindersStream;
  late final Stream<List<Period>> _periodsStream;
  late final Stream<int> _reminderCount;
  late final Stream<int> _courseCount;
  late final Stream<int> _periodCount;

  String _displayName = 'Usuario';
  String _avatarIcon = 'anonimo';


  @override
  void initState() {
    super.initState();
    _loadCurrentUser();

    _coursesStream = _courseRepository.watchAll();
    _remindersStream = _reminderRepository.watchAll();
    _periodsStream = _periodRepository.watchAll();
    
    _reminderCount = _reminderRepository.watchAll().map((list) => list.length);
    _courseCount = _courseRepository.watchAll().map((list) => list.length);
    _periodCount = _periodRepository.watchAll().map((list) => list.length);
  }

  Future<void> _loadCurrentUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final user = await _userRepository.getCurrentUser(userId);
    setState(() {
      _displayName = user?.name ?? 'Usuario';
      _avatarIcon = user?.avatarIcon ?? 'anonimo';
    });
  }

  Future<void> _showAvatarMenu(Offset position) async {
    final selected = await showMenu(
      context: context,
      color: AppColors.card,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 12),
              Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
    if (selected == 'logout') {
      await _logout();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: SafeArea(
        child: StreamBuilder<List<Course>>(
          stream: _coursesStream,
          builder: (context, coursesSnap) {
            return StreamBuilder<List<Reminder>>(
              stream: _remindersStream,
              builder: (context, remindersSnap) {
                return StreamBuilder<List<Period>>(
                  stream: _periodsStream,
                  builder: (context, periodsSnap) {
                    final courses = coursesSnap.data ?? [];
                    final reminders = remindersSnap.data ?? [];
                    final periods = periodsSnap.data ?? [];

                    // isLoading verdadero si cualquiera de los 3 aún no entrega data
                    final isLoading = coursesSnap.connectionState == ConnectionState.waiting ||
                        remindersSnap.connectionState == ConnectionState.waiting ||
                        periodsSnap.connectionState == ConnectionState.waiting;

                    final today = ScheduleRepository.buildToday(
                      courses: courses,
                      reminders: reminders,
                      periods: periods,
                    );
                    final upcomingDays = ScheduleRepository.buildUpcomingDays(
                      courses: courses,
                      reminders: reminders,
                      periods: periods,
                      daysAhead: 7,
                    );

                    return _buildContent(today, upcomingDays, isLoading);
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purplePrimary,
        foregroundColor: Colors.white,
        onPressed: () => CreateOptionsSheet.show(context),
        child: const Icon(Icons.apps),
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/home'),
    );
  }

  Widget _buildContent(List<ScheduleItem> today, List<DaySchedule> upcomingDays, bool isLoading){
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),

          _buildStatsRow(),
          const SizedBox(height: 40),

          const Text(
            "Pendientes Hoy",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),

          if(isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.purplePrimary))
          else if (today.isEmpty)
            const Text(
              "Nada pendiente para hoy",
              style: TextStyle(color: Colors.white54),
            )
          else
            ...today.map((item) => ScheduleItemCard(item: item)),
          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Próximos",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpcomingScreen()),
                  );
                },
                child: const Text(
                  "Ver Todo",
                  style: TextStyle(
                    color: AppColors.purpleAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.purplePrimary),
            )
          else if (upcomingDays.isEmpty)
            const Text(
              "Nada próximo en los siguientes 7 días",
              style: TextStyle(color: Colors.white54),
            )
          else
            ...upcomingDays.map((day) => DaySection(day: day)),
        ],
      ),
    );
  }

  // --- Builders de componentes ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTapDown: (details) => _showAvatarMenu(details.globalPosition),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.inputFill,
                backgroundImage: AssetImage('assets/avatars/$_avatarIcon.png'),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '$_displayName!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications, color: AppColors.purpleLight),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(
          stream: _reminderCount, 
          label: 'Recordatorios', 
          color: AppColors.orange,
        ),
        
        _buildStatCard(
          stream: _courseCount, 
          label: 'Cursos', 
          color: AppColors.purpleLight,
        ),
        
        _buildStatCard(
          stream: _periodCount, 
          label: 'Periodos', 
          color: AppColors.cyan
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Stream<int> stream,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            StreamBuilder<int>(
              stream: stream, 
              builder: (context, snapshot){
                final count = snapshot.data ?? 0;
                return Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                );
              },
            ),            
            const SizedBox(height: 4),
            
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
