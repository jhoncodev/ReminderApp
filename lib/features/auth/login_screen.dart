import 'package:flutter/material.dart';
import 'package:reminder_app/app.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_password_field.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/avatar_selector.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/data/user_repository.dart';
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

  Future<void> _showAvatarPickerSheet() async {
    // Contexto raíz: sobrevive aunque AuthGate ya haya cambiado Login por Home
    final rootContext = rootNavigatorKey.currentContext;
    if(rootContext == null) return;

    await showModalBottomSheet(
      context: rootContext, 
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Elige tu Avatar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  "Puedes cambiarlo después en tu perfil.",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 20),
                AvatarSelector(
                  selectedAvatar: "anonimo", 
                  onAvatarSelected: (avatar) async {
                    Navigator.pop(sheetContext);
                    try{
                      await UserRepository().updateAvatarIcon(avatar);
                    } catch (e){
                      debugPrint("Error al guardar avatar: $e");
                      final ctx = rootNavigatorKey.currentContext;
                      if (ctx != null && ctx.mounted) showErrorSnack(ctx, "No se pudo guardar el avatar");
                    }
                  }
                )
              ],
            ),
          ),
        )
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Servicio de autenticación con Google
      final authService = AuthService(); 
      final userCredential = await authService.signInWithGoogle();
      
      // Si fue exitoso y el usuario no canceló el prompt
      if (userCredential != null) {
        // Primer login con la cuenta de google: ofrecer elegir avatar
        if (userCredential.additionalUserInfo?.isNewUser ?? false){
          await _showAvatarPickerSheet();
        }
        if (!mounted) return;
        showSuccessSnack(context, "Inicio de sesión con Google exitoso");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error en Google Sign-In: $e");
      if(!mounted) return;
        final message = e is FirebaseAuthException ? authErrorMessage(e) : "No se pudo iniciar sesión con Google";
        showErrorSnack(context, message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginUser() async {
    
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty){ 
      showErrorSnack(context, "Completa el correo y contraseña");
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim(),);

      final user = userCredential.user;
      if (user != null && !user.emailVerified){
        if (mounted) await _showVerificationDialog(user);
        return;
      }

      if (mounted){
        showSuccessSnack(context, "Inicio de sesión exitoso");
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomeScreen())
        );
      }

    } on FirebaseAuthException catch (e) {
      debugPrint("Error de login: ${e.code}");

      if(!mounted) return;
        showErrorSnack(context, authErrorMessage(e));
    } catch (e) {
      debugPrint("error de login: $e");
      if(!mounted) return;
      showErrorSnack(context, "Ocurrió un error, intenta de nuevo");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showVerificationDialog(User user) async {
    await showDialog(
      context: context, 
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Verifica Tu Correo",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Tu correo aún no está verificado. Revisa tu bandeja (y la carpeta de spam) y toca el enlace antes de iniciar sesión.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try{
                await user.sendEmailVerification();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                
                if (mounted) {
                  showSuccessSnack(context, "Correo de verificación reenviado");
                }
              } on FirebaseAuthException catch (e){
                debugPrint("Error al reenviar verificación: ${e.code}");
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) showErrorSnack(context, authErrorMessage(e));
              }
            }, 
            child: const Text(
              "Reenviar Correo",
              style: TextStyle(color: AppColors.purplePrimary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text("Entendido", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );

    // Sin la verificación no hay sesión: se cierra al salir del dialogo.
    // (Se cierra después porque reenviar el correo requiere la sesión viva.)
    await FirebaseAuth.instance.signOut();
  }

  void _showPasswordResetSheet() {
    // Prellenamos con lo que el usuario ya escribió en el login
    final resetController = TextEditingController(
      text: emailController.text.trim(),
    );
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            // Sube el contenido cuando aparece el teclado
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Recuperar Contraseña",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                "Te enviaremos un enlace para restablecerla.",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),

              const AppLabel(text: "Correo electrónico"),
              const SizedBox(height: 8),

              AppTextField(
                controller: resetController,
                hint: "apellido@gmail.com",
              ),

              // Error inline: visible dentro del modal (un SnackBar quedaría oculto detrás)
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),

              PrimaryGradientButton(
                text: "Enviar Enlace",
                glow: true,
                onPressed: () async {
                  final email = resetController.text.trim();
                  if (email.isEmpty) {
                    setSheetState(() => errorMessage = "Escribe tu correo electrónico");
                    return;
                  }
                  try {
                    await AuthService().sendPasswordReset(email);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (!mounted) return;
                    showSuccessSnack(
                      context,
                      "Si existe una cuenta con ese correo, te llegará un enlace",
                    );
                  } on FirebaseAuthException catch (e) {
                    debugPrint("Error en reset de contraseña: ${e.code}");
                    if (sheetContext.mounted) {
                      setSheetState(() => errorMessage = authErrorMessage(e));
                    }
                  } catch (e) {
                    debugPrint("Error en reset de contraseña: $e");
                    if (sheetContext.mounted) {
                      setSheetState(() => errorMessage = "Ocurrió un error, intenta de nuevo");
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Logo
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

              // 2. Título y subtítulo
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

              // 3. Campo de correo
              const AppLabel(text: "Correo Electrónico"),
              const SizedBox(height: 8),
              AppTextField(
                controller: emailController,
                hint: "apellido@gmail.com",
              ),
              const SizedBox(height: 24),

              // 4. Campo de contraseña
              const AppLabel(text: "Contraseña"),
              const SizedBox(height: 8),
              AppPasswordField(controller: passwordController),
              const SizedBox(height: 12),

              // 5. Link de recuperar contraseña
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _showPasswordResetSheet();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Color(0xFFDAB6FF), // Texto morado claro
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 6. Botón de iniciar sesión
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

              // 7. Footer de registro
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
