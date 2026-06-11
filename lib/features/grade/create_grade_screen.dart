import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/data/grade_repository.dart';
import 'package:reminder_app/models/grade.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateGradeScreen extends StatefulWidget {
  final String courseId;
  final Grade? gradeToEdit;

  const CreateGradeScreen({
    super.key,
    required this.courseId,
    this.gradeToEdit,
  });

  @override
  State<CreateGradeScreen> createState() => _CreateGradeScreenState();
}

class _CreateGradeScreenState extends State<CreateGradeScreen> {
  final _gradeRepository = GradeRepository();
  late TextEditingController titleController;
  late TextEditingController valueController;
  late TextEditingController maxValueController;
  late TextEditingController weightController;

  bool _isLoading = false;
  String _validationMessage = '';
  bool _isValidWeight = true;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.gradeToEdit?.title ?? '',
    );
    valueController = TextEditingController(
      text: widget.gradeToEdit?.value.toString() ?? '',
    );
    maxValueController = TextEditingController(
      text: widget.gradeToEdit?.maxValue.toString() ?? '20',
    );
    weightController = TextEditingController(
      text: widget.gradeToEdit?.weight.toString() ?? '',
    );

    _checkWeightValidation();
  }

  @override
  void dispose() {
    titleController.dispose();
    valueController.dispose();
    maxValueController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> _checkWeightValidation() async {
    if (weightController.text.isEmpty) {
      setState(() {
        _validationMessage = '';
        _isValidWeight = true;
      });
      return;
    }

    try {
      final grades = await _gradeRepository.getByCourse(widget.courseId);
      double totalWeight = _gradeRepository.calculateTotalWeight(grades);

      // Restar el peso actual si estamos editando
      if (widget.gradeToEdit != null) {
        totalWeight -= widget.gradeToEdit!.weight;
      }

      final newWeight = double.parse(weightController.text);
      final newTotal = totalWeight + newWeight;

      setState(() {
        if (newTotal > 100) {
          _isValidWeight = false;
          _validationMessage =
              'Peso total excede 100% (actual: ${newTotal.toStringAsFixed(1)}%)';
        } else if (newTotal == 100) {
          _isValidWeight = true;
          _validationMessage = 'Peso completado correctamente';
        } else {
          _isValidWeight = true;
          _validationMessage =
              'Falta asignar: ${(100 - newTotal).toStringAsFixed(1)}%';
        }
      });
    } catch (e) {
      setState(() {
        _validationMessage = '';
        _isValidWeight = true;
      });
    }
  }

  Future<void> _saveGrade() async {
    // Validar campos
    if (titleController.text.isEmpty) {
      _showError('El título es requerido');
      return;
    }

    if (valueController.text.isEmpty ||
        maxValueController.text.isEmpty ||
        weightController.text.isEmpty) {
      _showError('Todos los campos son requeridos');
      return;
    }

    try {
      final value = double.parse(valueController.text);
      final maxValue = double.parse(maxValueController.text);
      final weight = double.parse(weightController.text);

      if (value < 0 || maxValue <= 0 || weight <= 0) {
        _showError('Los valores deben ser positivos');
        return;
      }

      if (value > maxValue) {
        _showError('La calificación no puede ser mayor al máximo');
        return;
      }

      if (!_isValidWeight) {
        _showError('El peso total no es válido');
        return;
      }

      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final grade = Grade(
        id: widget.gradeToEdit?.id,
        userId: userId,
        courseId: widget.courseId,
        title: titleController.text.trim(),
        value: value,
        maxValue: maxValue,
        weight: weight,
        createdAt: widget.gradeToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.gradeToEdit == null) {
        await _gradeRepository.create(grade);
      } else {
        await _gradeRepository.update(grade);
      }

      if (mounted) {
        widget.gradeToEdit == null ? showSuccessSnack(context, "Calificación creada") : showSuccessSnack(context, "Calificación actualizada");
        Navigator.pop(context);
      }
    } catch (e) {
      if(!mounted) return;
        showErrorSnack(context, "No se pudo guardar la calificacion");
        debugPrint("Error al guardar la calificación: $e");
      
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    showErrorSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.gradeToEdit == null
              ? 'Nueva Calificación'
              : 'Editar Calificación',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Título',
              hint: 'ej. Parcial 1, Tarea 3',
              controller: titleController,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Calificación Obtenida',
              hint: 'ej. 17.5',
              controller: valueController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Calificación Máxima',
              hint: 'ej. 20',
              controller: maxValueController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Peso (%)',
              hint: 'ej. 30',
              controller: weightController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _checkWeightValidation(),
            ),
            const SizedBox(height: 24),
            if (_validationMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isValidWeight
                      ? Colors.green.withValues(alpha:0.2)
                      : Colors.red.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isValidWeight ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isValidWeight ? Icons.check_circle : Icons.error,
                      color: _isValidWeight ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _validationMessage,
                        style: TextStyle(
                          color: _isValidWeight ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purplePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.purplePrimary.withValues(alpha:
                    0.5,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.gradeToEdit == null
                            ? 'Crear Calificación'
                            : 'Actualizar Calificación',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.5)),
            filled: true,
            fillColor: const Color(0xFF0F0F0F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha:0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.purplePrimary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
