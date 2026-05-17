import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/create_options_sheet.dart';
import 'package:reminder_app/data/schedule_repository.dart';
import 'package:reminder_app/data/user_repository.dart';
import 'package:reminder_app/models/schedule_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  final _userRepository = UserRepository();
  String _displayName = 'Usuario';
  final _scheduleRepository = ScheduleRepository();
  List<ScheduleItem> _todayList = [];
  List<ScheduleItem> _upcomingList = [];
  bool _isLoading = true;
  String _avatarIcon = 'anonimo';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadSchedule();
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

  Future<void> _loadSchedule() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    print('DEBUG userId: $userId'); // check user is logged in

    if (userId == null) return;

    final results = await Future.wait([
      _scheduleRepository.getTodaySchedule(userId),
      _scheduleRepository.getUpcomingSchedule(userId),
    ]);

    print('DEBUG today: ${results[0].length} items'); // how many found
    print('DEBUG upcoming: ${results[1].length} items'); // how many found

    setState(() {
      _todayList = results[0];
      _upcomingList = results[1];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Deepest black background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatsRow(),
              const SizedBox(height: 40),

              const Text(
                "Today's Schedule",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // _buildScheduleCard(
              //   time: '09:00',
              //   title: 'Morning Meditation',
              //   subtitle: 'Mental Health Activities',
              //   accentColor: const Color(0xFF4EE6D3), // Cyan
              // ),
              // _buildScheduleCard(
              //   time: '11:30',
              //   title: 'Modern Architecture 101',
              //   subtitle: 'Design Course • Zoom',
              //   accentColor: const Color(0xFFB483FF), // Purple
              //   icon: Icons.school_outlined,
              // ),
              // _buildScheduleCard(
              //   time: '14:00',
              //   title: 'Renew Subscription',
              //   subtitle: 'Finance Reminder',
              //   accentColor: const Color(0xFFFFB054), // Orange
              // ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_todayList.isEmpty)
                const Text(
                  'No schedule for today',
                  style: TextStyle(color: Colors.white54),
                )
              else
                ..._todayList.map(
                  (item) => _buildScheduleCard(
                    time: item.time,
                    title: item.title,
                    subtitle: item.subtitle,
                    accentColor: item.accentColor,
                    icon: item.icon,
                  ),
                ),

              const SizedBox(height: 40),

              // Upcoming Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Upcoming",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "SEE ALL",
                    style: TextStyle(
                      color: const Color(0xFFEEDDFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Upcoming Horizontal List
              SizedBox(
                height: 140,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _upcomingList.isEmpty
                    ? const Center(
                        child: Text(
                          'Nothing upcoming',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _upcomingList.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (_, i) {
                          final item = _upcomingList[i];
                          return _buildUpcomingCard(
                            title: item.title,
                            subtitle: item.subtitle,
                            icon: item.icon,
                            accentColor: item.accentColor,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purplePrimary,
        foregroundColor: Colors.white,
        onPressed: () => CreateOptionsSheet.show(context),
        child: const Icon(Icons.add),
      ),
      // Custom Bottom Navigation
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Component Builders ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.inputFill,
              backgroundImage: AssetImage('assets/avatars/$_avatarIcon.png'),
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
          icon: const Icon(Icons.notifications, color: Color(0xFFB483FF)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('12', 'REMINDERS', const Color(0xFFFFB054)),
        _buildStatCard('4', 'COURSES', const Color(0xFFB483FF)),
        _buildStatCard('08', 'ACTIVITIES', const Color(0xFF4EE6D3)),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E), // Dark card background
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
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

  Widget _buildScheduleCard({
    required String time,
    required String title,
    required String subtitle,
    required Color accentColor,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Event Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
                // The colored left border effect
                border: Border(left: BorderSide(color: accentColor, width: 4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (icon != null) Icon(icon, color: Colors.white24, size: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accentColor, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(Icons.home, 'HOME', isActive: true),
          _buildNavItem(Icons.calendar_today, 'SCHEDULE'),
          _buildNavItem(Icons.share, 'SHARE'),
          _buildNavItem(Icons.person, 'PROFILE'),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: isActive
              ? const BoxDecoration(
                  color: Color(0xFF9D65FF),
                  shape: BoxShape.circle,
                )
              : null,
          child: Icon(icon, color: isActive ? Colors.white : Colors.white24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
