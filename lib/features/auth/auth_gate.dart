import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/features/auth/login_screen.dart';
import 'package:reminder_app/features/home/home_screen.dart';

class AuthGate extends StatelessWidget{
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), 
      builder: (context, snapshot){
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.purplePrimary),
            ),
          );
        }

        if(snapshot.hasData){
          return const HomeScreen();
        }

        return const LoginScreen();
      }
    );
  }
}