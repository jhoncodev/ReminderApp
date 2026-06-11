import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import '../../data/note_repository.dart';
import '../../data/course_repository.dart';
import '../../models/note.dart';
import '../../models/course.dart';

class CreateNoteScreen extends StatefulWidget {
  final String? courseId;
  final Note? note; // Si llega un apunte, estamos en modo edición

  const CreateNoteScreen({super.key, this.courseId, this.note});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final NoteRepository _noteRepository = NoteRepository();
  final CourseRepository _courseRepository = CourseRepository();
  int _selectedCourseColor = 0xFF1E1E1E;

  late DateTime _noteDateTime;
  String? _selectedCourseId;
  String _selectedCourseName = 'Todos los apuntes';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Prellenar los campos si editamos un apunte existente
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    // Fecha del apunte existente, o la actual si es nuevo
    _noteDateTime = widget.note?.createdAt ?? DateTime.now();

    // Prioridad: 1. curso del apunte -> 2. curso del filtro -> 3. null (todos)
    _selectedCourseId = widget.note?.courseId ?? widget.courseId;

    _fetchSelectedCourseName();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchSelectedCourseName() async {
    if (_selectedCourseId != null) {
      try {
        final course = await _courseRepository.getCourseById(_selectedCourseId!);
        if (mounted && course != null) {
          setState(() {
            _selectedCourseName = course.name;
            _selectedCourseColor = course.colorCode; // Toma el color del curso
          });
        }
      } catch (e) {
        // Si falla, se mantiene el nombre y color por defecto
        debugPrint("Error al cargar el curso del apunte: $e");
      }
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      showErrorSnack(context, "Escribe un título y un contenido");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.note == null) {
        // CREAR: no llegó apunte existente
        await _noteRepository.addNote(
          title: title,
          content: content,
          courseId: _selectedCourseId,
          colorCode: _selectedCourseColor,
        );
      } else {
        // ACTUALIZAR: sobrescribe el apunte existente
        final updatedNote = Note(
          id: widget.note!.id,
          userId: widget.note!.userId,
          courseId:
              _selectedCourseId, // Permite mover el apunte a otro curso
          title: title,
          content: content,
          createdAt: widget.note!.createdAt,
          colorCode: _selectedCourseColor, // Mantiene el color original
        );
        await _noteRepository.updateNote(updatedNote);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error al guardar el apunte: $e");
      if (mounted) {
        showErrorSnack(context, "Error al guardar el apunte");
      }
    } finally {
      if (mounted){
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Eliminar apunte (solo disponible en modo edición)
  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          '¿Eliminar Apunte?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await _noteRepository.deleteNote(widget.note!.id);
        if (mounted) Navigator.pop(context); // Volver a la lista tras eliminar
      } catch (e) {
        debugPrint("Error al eliminar el apunte: $e");
        if (mounted){
          showErrorSnack(context, "Error al eliminar el apunte");
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showCourseSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StreamBuilder<List<Course>>(
          stream: _courseRepository.getUserCourses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            final courses = snapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Seleccionar Curso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text(
                      'Todos los apuntes',
                      style: TextStyle(color: Colors.white),
                    ),
                    leading: Icon(
                      Icons.clear,
                      color: _selectedCourseId == null
                          ? AppColors.purplePrimary
                          : Colors.white54,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCourseId = null;
                        _selectedCourseName = 'Todos los apuntes';
                      });
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: courses
                            .map(
                              (course) => ListTile(
                                title: Text(
                                  course.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                leading: Icon(
                                  Icons.book,
                                  color: course.id == _selectedCourseId
                                      ? AppColors.purplePrimary
                                      : Colors.white54,
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCourseId = course.id;
                                    _selectedCourseName = course.name;
                                    _selectedCourseColor = course.colorCode; // Toma el color del curso
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String get _formattedDateTime {
    final now = DateTime.now();
    if (_noteDateTime.year == now.year &&
        _noteDateTime.month == now.month &&
        _noteDateTime.day == now.day) {
      return 'Today, ${DateFormat.jm().format(_noteDateTime)}';
    } else {
      return DateFormat("d 'de' MMMM, h:mm a", 'es').format(_noteDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // En modo edición se muestra el ícono de eliminar
          if (widget.note != null && !_isLoading)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 26,
              ),
              onPressed: _deleteNote,
            ),

          _isLoading
              ? const SizedBox(
                  width: 48,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: Colors.white, size: 28),
                  onPressed: _saveNote,
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Título',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formattedDateTime,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showCourseSelection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _selectedCourseName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu apunte',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
