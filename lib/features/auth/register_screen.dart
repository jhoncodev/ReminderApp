import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';

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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Deep dark background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:[
              const SizedBox(height:20),

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
              _buildLabel('NOMBRE COMPLETO'),
              const SizedBox(height: 8),
              _buildTextField(
                hintText: 'Messi Ronaldo',
                controller: fullNameController,
              ),
              const SizedBox(height: 20),

              // Email
              _buildLabel('CORREO ELECTRÓNICO'),
              const SizedBox(height: 8),
              _buildTextField(
                hintText: 'messi@ronaldo.com',
                controller: emailController,
              ),
              const SizedBox(height: 20),

              // Password
              _buildLabel('CONTRASEÑA'),
              const SizedBox(height: 8),
              _buildTextField(
                hintText: '••••••••',
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 20),

              // Confirm Password
              _buildLabel('CONFIRMAR CONTRASEÑA'),
              const SizedBox(height: 8),
              _buildTextField(
                hintText: '••••••••',
                obscureText: true,
                controller: confirmPasswordController,
              ),
              const SizedBox(height: 32),

              // Register Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ElevatedButton(
                  onPressed: (){
                    final password = passwordController.text;
                    final confirmPassword = confirmPasswordController.text;

                    if (password != confirmPassword){
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Las contraseñas no coinciden')
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Registro exitoso')
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
  
  Widget _buildLabel(String text){
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    bool obscureText = false,
    TextEditingController? controller,
  }){
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color:  Color(0xFF5A5A62)),
        filled: true,
        fillColor: const Color(0xFF232329),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

