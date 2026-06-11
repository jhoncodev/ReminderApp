import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/date_helpers.dart';
import 'package:reminder_app/core/widgets/status_views.dart'; 
import '../../core/widgets/dark_app_bar.dart';
import '../../data/note_repository.dart';
import '../../data/course_repository.dart';
import '../../models/note.dart';
import '../../models/course.dart';
import 'create_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteRepository _noteRepository = NoteRepository();
  final CourseRepository _courseRepository = CourseRepository();
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedCourseId; 
  String _selectedCourseName = 'Todos los apuntes'; // Texto mostrado por defecto

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Bottomsheet del filtro por curso
  void _showFilterSheet() {
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
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.white)));
            }

            final courses = snapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text('Filtrar Apuntes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    title: const Text('Todos los apuntes', style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.all_inbox, color: _selectedCourseId == null ? AppColors.purplePrimary : Colors.white54),
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
                        children: courses.map((course) => ListTile(
                          title: Text(course.name, style: const TextStyle(color: Colors.white)),
                          leading: Icon(Icons.book, color: course.id == _selectedCourseId ? AppColors.purplePrimary : Colors.white54),
                          onTap: () {
                            setState(() {
                              _selectedCourseId = course.id;
                              _selectedCourseName = course.name;
                            });
                            Navigator.pop(context);
                          },
                        )).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(
        title: 'Apuntes',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar por título...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // 2. FILTRO POR CURSO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: _showFilterSheet,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCourseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. GRID DE APUNTES (masonry)
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: _selectedCourseId == null
                  ? _noteRepository.getUserNotes()
                  : _noteRepository.getNotesForCourse(_selectedCourseId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingView();
                }
                if (snapshot.hasError) {
                  return AppErrorView(
                    message: "No se pudieron cargar los apuntes",
                    error: snapshot.error,
                  );
                }

                // Lista inicial desde Firestore
                List<Note> notes = snapshot.data ?? [];

                // Búsqueda local por título (ignora mayúsculas/minúsculas)
                if (_searchQuery.isNotEmpty) {
                  notes = notes.where((note) => 
                    note.title.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.note_alt_outlined, color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                            ? 'No hay resultados para "$_searchQuery"'
                            : 'Aún no tienes apuntes. Toca + para crear uno',
                          style: const TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Grid tipo masonry (cards de alturas variables)
                return MasonryGridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteCard(note);
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purplePrimary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateNoteScreen(courseId: _selectedCourseId),
            ),
          );
        },
      ),
    );
  }

  // Card de apunte para el grid masonry
  Widget _buildNoteCard(Note note) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateNoteScreen(note: note), // Abre en modo edición
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:  Color(note.colorCode).withAlpha(26), // Color del apunte con transparencia
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Clave para que cada card tenga su propia altura
          children: [
            Text(
              note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              maxLines: 8, // Limita apuntes muy largos para no ocupar toda la pantalla
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              formatShortDate(note.createdAt),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}