import 'package:flutter/material.dart';

// Paleta centralizada de la app
class AppColors {

  // Constructor privado: evita que alguien instancie AppColors().
  AppColors._();

  // Fondos
  static const Color background = Color(0xFF0A0A0A);
  static const Color backgroundDeep = Color(0xFF050505);
  static const Color card = Color(0xFF1C1C1E);
  static const Color surface = Color(0xFF1E1E1E);

  // Inputs
  static const Color inputFill = Color(0xFF232329);
  static const Color hint = Color(0xFF5A5A62);
  
  // Morados (paleta principal)
  static const Color purpleLight = Color(0xFFB483FF);
  static const Color purpleDark = Color(0xFF7A4BFF);
  static const Color purplePrimary = Color(0xFF9D65FF);
  static const Color purpleAccent = Color(0xFFEEDDFF);
  static const Color purpleSoft = Color(0xFFDAB6FF);

  // Acentos para cards/categorías
  static const Color cyan = Color(0xFF4EE6D3);
  static const Color orange = Color(0xFFFFB054);
  static const Color pink = Color(0xFFFF6B6B);
  static const Color green = Color(0xFF6BCB77);

  // Colores de feedback (éxito/error)
  static const Color success = Color(0xFF2E7D52);
  static const Color error = Color(0xFFB3433E);

  // Gradiente principal de botones
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purpleLight, purpleDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight, 
  );
}