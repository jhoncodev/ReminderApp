import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
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
  void initState(){
    super.initState();
    final existing = widget.period;
    if(existing != null){
      nameController.text = existing.name;
      startDateController.text = _formatDate(existing.startDate);
      endDateController.text = _formatDate(existing.endDate);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String input){
    final parts = input.split('/');
    if(parts.length != 3) return null;
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if(month == null || day == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date){
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2,'0');
    return "$m/$d/${date.year}";
  }

  void _showSnack(String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _savePeriod() async {
    if(_isSaving) return;

    final name = nameController.text.trim();
    final startText = startDateController.text;
    final endText = endDateController.text;

    if(name.isEmpty){
      _showSnack("El nombre es obligatorio");
      return;
    }
    if(startText.isEmpty || endText.isEmpty){
      _showSnack("Selecciona las fechas de inicio y fin");
      return;
    }

    final startDate = _parseDate(startText);
    final endDate = _parseDate(endText);

    if(startDate == null || endDate == null){
      _showSnack("Formato de fecha invalido");
      return;
    }
    if(endDate.isBefore(startDate)){
      _showSnack("La fecha de fin debe ser posterior a la de inicio");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if(user == null){
      _showSnack("No hay usuario autenticado");
      return;
    }

    setState(() => _isSaving = true);

    try{
      final now = DateTime.now();
      if(widget.isEditing){
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
        
        await _repo.update(updated);
      }else{
        // Creando un periodo
        final newPeriod = Period(
          userId: user.uid, 
          name: name, 
          startDate: startDate, 
          endDate: endDate, 
          createdAt: now, 
          updatedAt: now
        );

        await _repo.create(newPeriod);
      }

      if(!mounted) return;
      _showSnack(
        widget.isEditing ? "Periodo actualizado correctamente" : "Periodo creado correctamente"
      );
      Navigator.pop(context);

    }catch (e){
      if(!mounted) return;
      _showSnack("Error al guardar: $e");
    
    } finally {
      if(mounted) setState(() => _isSaving = false);
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
                  // Period name
                  const AppLabel(text:"NOMBRE DEL PERIODO"),
                  
                  const SizedBox(height: 8),

                  AppTextField(
                    controller: nameController, 
                    hint: "Ej. Ciclo 2024"
                  ),

                  const SizedBox(height: 24),

                  // Start date
                  const AppLabel(text:"INICIO"),
                  const SizedBox(height: 8),
                  AppDatePickerField(controller: startDateController),

                  const SizedBox(height: 20),

                  // End date
                  const AppLabel(text:"FIN"),
                  const SizedBox(height: 8),
                  AppDatePickerField(controller: endDateController),

                  // Button
                  const SizedBox(height: 50),
                  PrimaryGradientButton(
                    text: _isSaving ? "Guardando..." : buttonText, 
                    onPressed: _isSaving ? null : _savePeriod,
                    glow: true,
                  )
                ],
              ),
            ),
        ),
      );
  }
}
