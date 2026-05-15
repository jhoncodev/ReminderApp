import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/core/widgets/days_selector.dart';
import 'package:reminder_app/data/activity_repository.dart';
import 'package:reminder_app/models/activity.dart';

class CreateActivityScreen extends StatefulWidget {
  final Activity? activity;
  const CreateActivityScreen({super.key, this.activity});

  bool get isEditing => activity != null;

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _activityRepo = ActivityRepository();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  DateTime? _selectedDate;

  String frequency = "Una vez";
  List<String> days = ["L", "M", "M", "J", "V", "S", "D"];
  List<bool> selectedDays = List.generate(7, (_) => false);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.activity;
    if (existing == null) return;

    nameController.text = existing.name;
    notesController.text = existing.notes ?? '';
    amountController.text = existing.budgetAmount?.toString() ?? '';
    frequency = existing.frequency;

    // Días prellenados
    for (final day in existing.scheduleDays) {
      if (day >= 0 && day < selectedDays.length) {
        selectedDays[day] = true;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    notesController.dispose();
    amountController.dispose();
    startTimeController.dispose();
    _selectedDate = null;
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveActivity() async {
    if (_isSaving) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnack("El nombre es obligatorio");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("No hay usuario autenticado");
      return;
    }

    // Se extrae los índices de los días seleccionados
    final scheduleDays = <int>[];
    for (var i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) scheduleDays.add(i);
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      double? budgetAmount;

      if (amountController.text.isNotEmpty) {
        budgetAmount = double.tryParse(amountController.text);
      }

      if (widget.isEditing) {
        final original = widget.activity!;
        final updated = Activity(
          id: original.id,
          userId: original.userId,
          name: name,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          budgetAmount: budgetAmount,
          frequency: frequency,
          scheduleDays: scheduleDays,
          startTime: startTimeController.text.isEmpty
              ? null
              : startTimeController.text,
          date: frequency == 'Una vez' ? _selectedDate : null,
          createdAt: original.createdAt,
          updatedAt: now,
        );
        await _activityRepo.update(updated);
      } else {
        final newActivity = Activity(
          userId: user.uid,
          name: name,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          budgetAmount: budgetAmount,
          frequency: frequency,
          scheduleDays: scheduleDays,
          createdAt: now,
          updatedAt: now,
          startTime: startTimeController.text.isEmpty
              ? null
              : startTimeController.text,
          date: frequency == 'Una vez' ? _selectedDate : null,
        );
        await _activityRepo.create(newActivity);
      }

      if (!mounted) return;
      _showSnack(
        widget.isEditing
            ? "Actividad actualizada correctamente"
            : "Actividad creada correctamente",
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error al guardar: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? "Editar Actividad" : "Crear Actividad";
    final buttonText = widget.isEditing ? "Guardar Cambios" : "Crear Actividad";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DarkAppBar(title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Acitivity name
              const AppLabel(text: "NOMBRE DE LA ACTIVIDAD"),
              const SizedBox(height: 8),
              AppTextField(
                controller: nameController,
                hint: "Ej. Sesión de Yoga",
              ),

              const SizedBox(height: 20),

              // Notes
              const AppLabel(text: "NOTAS / DETALLES"),
              const SizedBox(height: 8),
              AppTextField(
                controller: notesController,
                hint: "Detalles adicionales ...",
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Amount
              const AppLabel(text: "PRESUPUESTO"),
              const SizedBox(height: 8),
              AppTextField(
                controller: amountController,
                hint: "Monto (opcional)",
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              // Frequency
              const AppLabel(text: "FRECUENCIA"),
              const SizedBox(height: 8),
              _frequencySelector(),

              const SizedBox(height: 20),

              // Days
              const AppLabel(text: "DÍAS SELECCIONADOS"),
              const SizedBox(height: 8),
              DaysSelector(
                selectedDays: selectedDays,
                onSelectionChanged: (updatedDays) {
                  setState(() {
                    selectedDays = updatedDays;
                  });
                },
              ),
              const AppLabel(text: "HORA DE INICIO"),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      startTimeController.text =
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: startTimeController,
                    hint: "Ej. 09:00",
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (frequency == "Una vez") ...[
                const SizedBox(height: 20),
                const AppLabel(text: "FECHA"),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF232329),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Seleccionar fecha',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Create button
              PrimaryGradientButton(
                text: buttonText,
                onPressed: _isSaving ? null : _saveActivity,
                glow: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Frequency selector
  Widget _frequencySelector() {
    final options = ["Una vez", "Diario", "Semanal", "Mensual"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((e) {
        final selected = frequency == e;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => frequency = e);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF9D65FF)
                    : const Color(0xFF232329),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  e,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
