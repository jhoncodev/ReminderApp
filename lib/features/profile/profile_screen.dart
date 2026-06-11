import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/avatar_selector.dart';
import 'package:reminder_app/core/widgets/bottom_nav_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/data/user_repository.dart';
import 'package:reminder_app/models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepository = UserRepository();
  final nameController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;
  String _selectedAvatar = 'anonimo';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      setState(() {
        _userEmail = currentUser.email ?? 'Sin correo';
      });

      final user = await _userRepository.getCurrentUser(currentUser.uid);

      if (user != null && mounted) {
        setState(() {
          nameController.text = user.name;
          // Cargar el avatar guardado
          _selectedAvatar =
              (user.avatarIcon != null && user.avatarIcon!.isNotEmpty)
              ? user.avatarIcon!
              : 'anonimo';
        });
      }
    } catch (e) {
      if(!mounted) return;
        showErrorSnack(context,"Error al cargar los datos del usuario");
        debugPrint("Error al cargar los datos del usuario: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUserData() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (nameController.text.trim().isEmpty) {
      showErrorSnack(context, "El nombre no puede estar vacío");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedUser = User(
        id: currentUser.uid,
        name: nameController.text.trim(),
        avatarIcon: _selectedAvatar,
      );

      await _userRepository.updateUser(updatedUser);

      if (mounted) {
        showSuccessSnack(context, "Perfil actualizado con éxito!");
      }
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, "Error al actualizar el perfil");
        debugPrint("Error al actualizar el perfil: $e");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openAvatarPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Elige tu Avatar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AvatarSelector(
                    selectedAvatar: _selectedAvatar,
                    onAvatarSelected: (avatar) {
                      setState(() => _selectedAvatar = avatar);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DarkAppBar(title: 'Mi Perfil'),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/profile'),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.purplePrimary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _openAvatarPicker,
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 56,
                                  backgroundColor: AppColors.card,
                                  backgroundImage: AssetImage(
                                    'assets/avatars/$_selectedAvatar.png',
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.purplePrimary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.background,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Toca para cambiar',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Correo (solo lectura)
                    const AppLabel(text: "Correo Electrónico"),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _userEmail,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo de nombre
                    const AppLabel(text: "Nombre de Usuario"),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: nameController,
                      hint: "Ej. Pugbardo",
                    ),
                    const SizedBox(height: 32),

                    PrimaryGradientButton(
                      text: _isSaving ? "Guardando..." : "Actualizar Perfil",
                      onPressed: _isSaving ? null : _saveUserData,
                      glow: true,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
