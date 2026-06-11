import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/utils/date_helpers.dart';
import 'package:reminder_app/core/utils/picker_theme.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/core/widgets/days_selector.dart';
import 'package:reminder_app/data/reminder_repository.dart';
import 'package:reminder_app/models/reminder.dart';

class CreateReminderScreen extends StatefulWidget {
  final Reminder? reminder;
  const CreateReminderScreen({super.key, this.reminder});

  bool get isEditing => reminder != null;

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _reminderRepo = ReminderRepository();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  DateTime? _selectedDate;

  String frequency = "Una vez";
  List<String> days = ["L", "M", "M", "J", "V", "S", "D"];
  List<bool> selectedDays = List.generate(7, (_) => false);
  bool _hasBudget = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.reminder;
    if (existing == null) return;

    nameController.text = existing.name;
    notesController.text = existing.notes ?? '';
    amountController.text = existing.budgetAmount?.toString() ?? '';
    _hasBudget = existing.budgetAmount != null;
    frequency = existing.frequency;
    startTimeController.text = existing.startTime ?? '';
    _selectedDate = existing.date;

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

  Future<void> _saveReminder() async {
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

    // Se extrae los índices de los días seleccionados
    final scheduleDays = <int>[];
    for (var i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) scheduleDays.add(i);
    }

    // Validaciones según la frecuencia elegida
    if (frequency == 'Una vez' && _selectedDate == null) {
      showErrorSnack(context, "Selecciona la fecha del recordatorio");
      return;
    }
    if (frequency == 'Semanal' && scheduleDays.isEmpty) {
      showErrorSnack(context, "Selecciona al menos un día de la semana");
      return;
    }
    if (frequency == 'Mensual' && _selectedDate == null) {
      showErrorSnack(context, "Selecciona la primera fecha del recordatorio");
      return;
    }
    if (_hasBudget && amountController.text.trim().isEmpty) {
      showErrorSnack(context, "Ingresa el monto del presupuesto");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      double? budgetAmount;

      if (_hasBudget && amountController.text.isNotEmpty) {
        budgetAmount = double.tryParse(amountController.text);
      }

      if (widget.isEditing) {
        final original = widget.reminder!;
        final updated = Reminder(
          id: original.id,
          userId: original.userId,
          name: name,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          budgetAmount: budgetAmount,
          frequency: frequency,
          // Cada frecuencia guarda SOLO sus campos: días para Semanal,
          // fecha para Una vez (exacta) y Mensual (se repite ese día del mes)
          scheduleDays: frequency == 'Semanal' ? scheduleDays : const [],
          startTime: startTimeController.text.isEmpty
              ? null
              : startTimeController.text,
          date: (frequency == 'Una vez' || frequency == 'Mensual')
              ? _selectedDate
              : null,
          createdAt: original.createdAt,
          updatedAt: now,
        );
        _reminderRepo.update(updated).catchError((e) => debugPrint("Error al sincronizar recordatorio: $e"));
      } else {
        final newReminder = Reminder(
          userId: user.uid,
          name: name,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          budgetAmount: budgetAmount,
          frequency: frequency,
          scheduleDays: frequency == 'Semanal' ? scheduleDays : const [],
          createdAt: now,
          updatedAt: now,
          startTime: startTimeController.text.isEmpty
              ? null
              : startTimeController.text,
          date: (frequency == 'Una vez' || frequency == 'Mensual')
              ? _selectedDate
              : null,
        );
        _reminderRepo.create(newReminder).catchError((e) => debugPrint("Error al sincronizar recordatorio: $e"));
      }

      if (mounted){
          widget.isEditing ? showSuccessSnack(context, "Recordatorio actualizado correctamente") : showSuccessSnack(context, "Recordatorio creado correctamente");
          Navigator.pop(context);
        }
    } catch (e) {
      if (!mounted) return;
        showErrorSnack(context, "Error al guardar el recordatorio");
        debugPrint("Error al guardar el recordatorio: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? "Editar Recordatorio" : "Crear Recordatorio";
    final buttonText = widget.isEditing ? "Guardar Cambios" : "Crear Recordatorio";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DarkAppBar(title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del recordatorio
              const AppLabel(text: "Nombre del Recordatorio"),
              const SizedBox(height: 8),
              AppTextField(
                controller: nameController,
                hint: "Ej. Examen la próxima semana",
              ),
              const SizedBox(height: 20),

              // Notas
              const AppLabel(text: "Notas / Detalles"),
              const SizedBox(height: 8),
              AppTextField(
                controller: notesController,
                hint: "Detalles adicionales ...",
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Frecuencia: cada una muestra SOLO los campos que usa
              const AppLabel(text: "Frecuencia"),
              const SizedBox(height: 8),
              _frequencySelector(),
              const SizedBox(height: 20),

              // Una vez: fecha exacta
              if (frequency == "Una vez") ...[
                const AppLabel(text: "Fecha"),
                const SizedBox(height: 8),
                _datePickerField(hint: "Seleccionar fecha"),
                const SizedBox(height: 20),
              ],

              // Semanal: días de la semana
              if (frequency == "Semanal") ...[
                const AppLabel(text: "Días de la Semana"),
                const SizedBox(height: 8),
                DaysSelector(
                  selectedDays: selectedDays,
                  onSelectionChanged: (updatedDays) {
                    setState(() {
                      selectedDays = updatedDays;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Mensual: primera fecha; se repite ese día cada mes
              if (frequency == "Mensual") ...[
                const AppLabel(text: "Primera Fecha"),
                const SizedBox(height: 8),
                _datePickerField(hint: "Seleccionar fecha"),
                if (_selectedDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Se repetirá el día ${_selectedDate!.day} de cada mes",
                    style: const TextStyle(color: AppColors.hint, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              const AppLabel(text: "Hora de Inicio"),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: buildDarkPicker,
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
              const SizedBox(height: 20),

              // Presupuesto: toggle, solo para recordatorios de pagos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppLabel(text: "Presupuesto"),
                      SizedBox(height: 2),
                      Text(
                        "Actívalo si este recordatorio es un pago",
                        style: TextStyle(color: AppColors.hint, fontSize: 12),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _hasBudget,
                      onChanged: (value) {
                        setState(() {
                          _hasBudget = value;
                          if (!value) amountController.clear();
                        });
                      },
                      activeThumbColor: AppColors.purplePrimary,
                    ),
                  ),
                ],
              ),
              if (_hasBudget) ...[
                const SizedBox(height: 8),
                AppTextField(
                  controller: amountController,
                  hint: "Monto",
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 32),

              // Botón crear/guardar
              PrimaryGradientButton(
                text: buttonText,
                onPressed: _isSaving ? null : _saveReminder,
                glow: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Campo de fecha con el mismo estilo de los AppTextField
  Widget _datePickerField({required String hint}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          builder: buildDarkPicker,
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate != null ? formatShortDate(_selectedDate!) : hint,
              style: TextStyle(
                color: _selectedDate != null ? Colors.white : AppColors.hint,
              ),
            ),
            const Icon(
              Icons.calendar_today,
              color: AppColors.purplePrimary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Selector de frecuencia
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
