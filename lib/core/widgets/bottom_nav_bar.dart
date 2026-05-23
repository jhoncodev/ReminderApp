

import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentRoute});

  final String currentRoute;

  void _onNavTap(BuildContext context, String route) {
    if (currentRoute == route) return; // already here
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
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
          _buildNavItem(context, Icons.home,          'INICIO',     '/home'),
          _buildNavItem(context, Icons.calendar_today,'HORARIO', '/schedule'),
          _buildNavItem(context, Icons.share,         'COMPARTIR',    '/share'),
          _buildNavItem(context, Icons.person,        'PERFIL',  '/profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final bool isActive = currentRoute == route;

    return GestureDetector(
      onTap: () => _onNavTap(context, route),
      child: Column(
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
      ),
    );
  }
}