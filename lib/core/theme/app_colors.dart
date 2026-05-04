import 'package:flutter/material.dart';

// Centralized palette of the app
class AppColors {

  // Private constructor: prevents someone from instantiating AppColors().
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0A0A0A);
  static const Color backgroundDeep = Color(0xFF050505);
  static const Color card = Color(0xFF1C1C1E);
  static const Color surface = Color(0xFF1E1E1E);

  // Inputs
  static const Color inputFill = Color(0xFF232329);
  static const Color hint = Color(0xFF5A5A62);
  
  // Purple (Palette Main)
  static const Color purpleLight = Color(0xFFB483FF);
  static const Color purpleDark = Color(0xFF7A4BFF);
  static const Color purplePrimary = Color(0xFF9D65FF);
  static const Color purpleAccent = Color(0xFFEEDDFF);
  static const Color purpleSoft = Color(0xFFDAB6FF);

  //  Accents for cards/categories
  static const Color cyan = Color(0xFF4EE6D3);
  static const Color organe = Color(0xFFFFB054);

  // Button main gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purpleLight, purpleDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight, 
  );
}