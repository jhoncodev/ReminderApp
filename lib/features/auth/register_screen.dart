import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_password_field.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  @override
  void dispose(){
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void registerUser(){
    final password = passwordController.text;
    final confirmPassowrd = confirmPasswordController.text;

    if(password != confirmPassowrd){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registro exitoso")),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Regístrate"), // Deep dark background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:[
              // Title and subtitle
              const Text(
                'Recuérdalo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Empieza a capturar tus intenciones y organiza tu día con precisión',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // Full name
              const AppLabel(text:'NOMBRE COMPLETO'),
              const SizedBox(height: 8),
              AppTextField(
                controller: fullNameController, 
                hint: "Messi Ronaldo"
              ),
              const SizedBox(height: 20),

              // Email
              const AppLabel(text:"CORREO ELECTRÓNICO"),
              const SizedBox(height: 8),
              AppTextField(
                controller: emailController, 
                hint: "messiro@gmail.com"
              ),
              const SizedBox(height: 20),

              // Password
              const AppLabel(text:"CONTRASEÑA"),
              const SizedBox(height: 8),
              AppPasswordField(controller: passwordController),
              const SizedBox(height: 20),

              // Confirm Password
              const AppLabel(text:"CONFIRMAR CONTRASEÑA"),
              const SizedBox(height: 8),
              AppPasswordField(controller: confirmPasswordController),
              const SizedBox(height: 32),

              // Register Button
              PrimaryGradientButton(
                text: "Registrarse", 
                onPressed: registerUser,
                glow: true,
              ),
              const SizedBox(height: 24),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Ya tienes una cuenta? ',
                    style: TextStyle(color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () { 
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Inicia Sesión',
                      style: TextStyle(
                        color: Color(0xFFEEDDFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

