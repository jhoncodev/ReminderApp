import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/features/auth/auth_gate.dart';
import 'package:reminder_app/features/auth/login_screen.dart';
import 'package:reminder_app/features/home/home_screen.dart';
import 'package:reminder_app/features/profile/profile_screen.dart';
import 'package:reminder_app/features/schedule/schedule_screen.dart';
import 'package:reminder_app/features/share/share_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';



class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const[Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      title: 'Reminder App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.purplePrimary),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
      '/login': (context) => const LoginScreen(),
      '/home': (context) => const HomeScreen(),
      '/schedule': (context) => const ScheduleScreen(),
      '/profile': (context) => const ProfileScreen(),
      '/share': (context) => const ShareScreen(),
    },
    );
  }
}