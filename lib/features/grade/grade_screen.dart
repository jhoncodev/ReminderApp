import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/widgets/status_views.dart';
import 'package:reminder_app/data/grade_repository.dart';
import 'package:reminder_app/models/grade.dart';
import 'package:reminder_app/features/grade/create_grade_screen.dart';

class GradeScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const GradeScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  final _gradeRepository = GradeRepository();

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
          widget.courseName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Grade>>(
        stream: _gradeRepository.watchByCourse(widget.courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }

          if (snapshot.hasError) {
           return AppErrorView(
            message: "No se pudieron cargar las calificaciones",
            error: snapshot.error,
            );
          }

          final grades = snapshot.data ?? [];

          return Column(
            children: [
              _buildHeader(grades),
              Expanded(
                child: grades.isEmpty
                    ? _buildEmptyState()
                    : _buildGradesList(grades),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purplePrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGradeScreen(courseId: widget.courseId),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(List<Grade> grades) {
    final totalWeight = _gradeRepository.calculateTotalWeight(grades);
    final averageGrade = _gradeRepository.calculateWeightedAverage(grades);
    final remainingWeight = _gradeRepository.getRemainingWeight(grades);
    final isValid = _gradeRepository.isWeightValid(grades);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha:0.1), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promedio Ponderado',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            averageGrade.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peso total: ${totalWeight.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (remainingWeight > 0)
                      Text(
                        'Falta asignar: ${remainingWeight.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isValid
                      ? Colors.green.withValues(alpha:0.2)
                      : Colors.red.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isValid ? 'Válido' : 'Inválido',
                  style: TextStyle(
                    color: isValid ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grade_outlined,
            size: 64,
            color: Colors.white.withValues(alpha:0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin calificaciones',
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera calificación',
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesList(List<Grade> grades) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: grades.map((grade) => _buildGradeCard(grade)).toList(),
      ),
    );
  }

  Widget _buildGradeCard(Grade grade) {
    final percentage = (grade.value / grade.maxValue * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha:0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  grade.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.card,
                onSelected: (value) {
                  if (value == 'edit') {
                    _editGrade(grade);
                  } else if (value == 'delete') {
                    _deleteGrade(grade.id!);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(
                      'Editar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calificación',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${grade.value} / ${grade.maxValue}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Porcentaje',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: AppColors.purplePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purplePrimary.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Peso: ${grade.weight.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.purplePrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editGrade(Grade grade) {
    // Implementar navegación a pantalla de edición
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateGradeScreen(courseId: widget.courseId, gradeToEdit: grade),
      ),
    );
  }

  Future<void> _deleteGrade(String gradeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Eliminar calificación',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta calificación?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _gradeRepository.delete(gradeId);
        if (mounted) {
          showSuccessSnack(context, "Calificación eliminada");
        }
      } catch (e) {
        if (mounted) {
          showErrorSnack(context, "Error al eliminar la calificación");
          debugPrint("No se pudo elimianr la calificación: $e");
        }
      }
    }
  }
}
