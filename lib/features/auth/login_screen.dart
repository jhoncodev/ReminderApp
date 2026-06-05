import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_password_field.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/features/auth/register_screen.dart';
import 'package:reminder_app/features/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
  setState(() => _isLoading = true);
  try {
    // Call the AuthService class we created in the previous steps
    final authService = AuthService(); 
    final userCredential = await authService.signInWithGoogle();
    
    // If successful and the user didn't cancel the prompt
    if (userCredential != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión con Google exitoso')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _loginUser() async {
    setState(() => _isLoading = true);
    try {
      // 1. Authenticate the user with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase login errors
      String errorMessage =
          e.message ?? 'Ocurrió un error durante el inicio de sesión';
      if (e.code == 'user-not-found') {
        errorMessage = 'No se encontró usuario con ese correo';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El correo electrónico está mal formateado';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Deep dark background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // 1. Logo Icon
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon/ic_full.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Title & Subtitle
              const Text(
                'Reminder App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Organiza Tu Aprendizaje",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),

              // 3. Email Input
              const AppLabel(text: "Correo Electrónico"),
              const SizedBox(height: 8),
              AppTextField(
                controller: emailController,
                hint: "apellido@gmail.com",
              ),
              const SizedBox(height: 24),

              // 4. Password Input
              const AppLabel(text: "Contraseña"),
              const SizedBox(height: 8),
              AppPasswordField(controller: passwordController),
              const SizedBox(height: 12),

              // 5. Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password logic
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Color(0xFFDAB6FF), // Light purple text
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 6. Gradient Login Button
              PrimaryGradientButton(
                text: "Iniciar Sesión",
                onPressed: _isLoading ? null : _loginUser,
                glow: true,
              ),
              const SizedBox(height: 40),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "O",
                      style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                // Note: Ensure you have a Google icon in your assets, or use a standard Flutter icon
                icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 32), 
                label: const Text(
                  'Continuar con Google',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w600
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _loginWithGoogle,
              ),
              const SizedBox(height: 40),

              // 7. Register Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No tienes una cuenta? ',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(
                        color: Color(0xFFEEDDFF),
                        fontSize: 14,
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
