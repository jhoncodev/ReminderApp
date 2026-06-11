import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/utils/date_helpers.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/core/widgets/app_date_picker_field.dart';
import 'package:reminder_app/data/period_repository.dart';
import 'package:reminder_app/models/period.dart';

class CreatePeriodScreen extends StatefulWidget {
  final Period? period;
  const CreatePeriodScreen({super.key, this.period});

  bool get isEditing => period != null;

  @override
  State<CreatePeriodScreen> createState() => _CreatePeriodScreenState();
}

class _CreatePeriodScreenState extends State<CreatePeriodScreen> {
  final _repo = PeriodRepository();
  final nameController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.period;
    if (existing != null) {
      nameController.text = existing.name;
      startDateController.text = formatShortDate(existing.startDate);
      endDateController.text = formatShortDate(existing.endDate);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String input) {
    final parts = input.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) return null;
    return DateTime(year, month, day);
  }

  Future<void> _savePeriod() async {
    if (_isSaving) return;

    final name = nameController.text.trim();
    final startText = startDateController.text;
    final endText = endDateController.text;

    if (name.isEmpty) {
      showErrorSnack(context, "El nombre es obligatorio");
      return;
    }
    if (startText.isEmpty || endText.isEmpty) {
      showErrorSnack(context, "Selecciona las fechas de inicio y fin");
      return;
    }

    final startDate = _parseDate(startText);
    final endDate = _parseDate(endText);

    if (startDate == null || endDate == null) {
      showErrorSnack(context, "Formato de fecha invalido");
      return;
    }
    if (endDate.isBefore(startDate)) {
      showErrorSnack(context, "La fecha de fin debe ser posterior a la de inicio");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showErrorSnack(context, "No hay usuario autenticado");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      if (widget.isEditing) {
        // Editando un periodo
        final original = widget.period!;
        final updated = Period(
          id: original.id,
          userId: original.userId,
          name: name,
          startDate: startDate,
          endDate: endDate,
          createdAt: original.createdAt,
          updatedAt: now,
        );

        _repo.update(updated).catchError((e) => debugPrint("Error al sincronizar el periodo: $e"));
      } else {
        // Creando un periodo
        final newPeriod = Period(
          userId: user.uid,
          name: name,
          startDate: startDate,
          endDate: endDate,
          createdAt: now,
          updatedAt: now,
        );

        _repo.create(newPeriod).catchError((e) => debugPrint("Error al sincronizar el periodo: $e"));
      }

      if (!mounted) return;
        widget.isEditing ? showSuccessSnack(context, "Periodo actualizado correctamente") : showSuccessSnack(context, "Periodo creado correctamente");
        Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
        showErrorSnack(context, "Error al guardar el periodo");
        debugPrint("Error al guardar el periodo: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? "Editar Periodo" : "Crear Periodo";
    final buttonText = widget.isEditing ? "Guardar Cambios" : "Crear Periodo";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DarkAppBar(title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del periodo
              const AppLabel(text: "Nombre del Período"),

              const SizedBox(height: 8),

              AppTextField(controller: nameController, hint: "Ej. Ciclo 2024"),

              const SizedBox(height: 24),

              // Fecha de inicio
              const AppLabel(text: "Inicio"),
              const SizedBox(height: 8),
              AppDatePickerField(controller: startDateController),

              const SizedBox(height: 20),

              // Fecha de fin
              const AppLabel(text: "Fin"),
              const SizedBox(height: 8),
              AppDatePickerField(controller: endDateController),

              // Botón
              const SizedBox(height: 50),
              PrimaryGradientButton(
                text: _isSaving ? "Guardando..." : buttonText,
                onPressed: _isSaving ? null : _savePeriod,
                glow: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
