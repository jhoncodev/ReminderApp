import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/data/teacher_repository.dart';
import 'package:reminder_app/models/teacher.dart';

class CreateTeacherScreen extends StatefulWidget {
  final Teacher? teacher;
  const CreateTeacherScreen({super.key, this.teacher});

  bool get isEditing => teacher != null;

  @override
  State<CreateTeacherScreen> createState() => _CreateTeacherScreenState();
}

class _CreateTeacherScreenState extends State<CreateTeacherScreen> {
  final _repo = TeacherRepository();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.teacher;
    if (existing == null) return;

    nameController.text = existing.name;
    emailController.text = existing.email ?? '';
    phoneController.text = existing.phone ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveTeacher() async {
    if (_isSaving) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      showErrorSnack(context, "El nombre es obligatorio");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showErrorSnack(context, "No hay usuario autenticado");
      return;
    }

    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    setState(() => _isSaving = true);

    final now = DateTime.now();
    if (widget.isEditing) {
      final original = widget.teacher!;
      final updated = Teacher(
        id: original.id,
        userId: original.userId,
        name: name,
        email: email.isEmpty ? null : email,
        phone: phone.isEmpty ? null : phone,
        createdAt: original.createdAt,
        updatedAt: now,
      );
      _repo
          .update(updated)
          .catchError((e) => debugPrint("Error al sincronizar el profesor: $e"));
    } else {
      final newTeacher = Teacher(
        userId: user.uid,
        name: name,
        email: email.isEmpty ? null : email,
        phone: phone.isEmpty ? null : phone,
        createdAt: now,
        updatedAt: now,
      );
      _repo
          .create(newTeacher)
          .catchError((e) => debugPrint("Error al sincronizar el profesor: $e"));
    }

    if (!mounted) return;
    widget.isEditing
        ? showSuccessSnack(context, "Profesor actualizado correctamente")
        : showSuccessSnack(context, "Profesor creado correctamente");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? "Editar Profesor" : "Crear Profesor";
    final buttonText = widget.isEditing ? "Guardar Cambios" : "Crear Profesor";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DarkAppBar(title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLabel(text: "Nombre del Profesor"),
              const SizedBox(height: 8),
              AppTextField(
                controller: nameController,
                hint: "Ej. Dra. García",
              ),
              const SizedBox(height: 20),

              const AppLabel(text: "Correo (Opcional)"),
              const SizedBox(height: 8),
              AppTextField(
                controller: emailController,
                hint: "profesor@universidad.edu",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              const AppLabel(text: "Teléfono (Opcional)"),
              const SizedBox(height: 8),
              AppTextField(
                controller: phoneController,
                hint: "Ej. 999 888 777",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),

              PrimaryGradientButton(
                text: _isSaving ? "Guardando..." : buttonText,
                onPressed: _isSaving ? null : _saveTeacher,
                glow: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
