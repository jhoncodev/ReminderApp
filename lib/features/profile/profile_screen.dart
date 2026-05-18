import 'package:flutter/material.dart';
import 'package:reminder_app/core/widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0F),
      bottomNavigationBar: BottomNavBar(currentRoute: '/profile'),
      body: Center(child: Text('Profile', style: TextStyle(color: Colors.white))),
    );
  }
}