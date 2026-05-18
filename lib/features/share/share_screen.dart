import 'package:flutter/material.dart';
import 'package:reminder_app/core/widgets/bottom_nav_bar.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0F),
      bottomNavigationBar: BottomNavBar(currentRoute: '/share'),
      body: Center(child: Text('Share', style: TextStyle(color: Colors.white))),
    );
  }
}