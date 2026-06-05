import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; 
import '../../core/widgets/dark_app_bar.dart';
import '../../data/note_repository.dart';
import '../../data/course_repository.dart';
import '../../models/note.dart';
import '../../models/course.dart';
import 'create_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteRepository _noteRepository = NoteRepository();
  final CourseRepository _courseRepository = CourseRepository();
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedCourseId; 
  String _selectedCourseName = 'All notes'; // Default display text

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Bottom Sheet for the Dropdown Filter
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
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
                    child: Text('Filter Notes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    title: const Text('All notes', style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.all_inbox, color: _selectedCourseId == null ? const Color(0xFF6C63FF) : Colors.white54),
                    onTap: () {
                      setState(() {
                        _selectedCourseId = null;
                        _selectedCourseName = 'All notes';
                      });
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: courses.map((course) => ListTile(
                          title: Text(course.name, style: const TextStyle(color: Colors.white)),
                          leading: Icon(Icons.book, color: course.id == _selectedCourseId ? const Color(0xFF6C63FF) : Colors.white54),
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
      backgroundColor: const Color(0xFF121212),
      appBar: const DarkAppBar(
        title: 'Notes',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
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
                  hintText: 'Search title...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // 2. DROPDOWN TAB FILTER
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

          // 3. MASONRY NOTES GRID
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: _selectedCourseId == null
                  ? _noteRepository.getUserNotes()
                  : _noteRepository.getNotesForCourse(_selectedCourseId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading notes', style: const TextStyle(color: Colors.redAccent)));
                }

                // Initial list from Firebase
                List<Note> notes = snapshot.data ?? [];

                // Local Search Filter (Filters by title ignoring uppercase/lowercase)
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
                            ? 'No notes found for "$_searchQuery"'
                            : 'No notes yet. Tap + to create one!',
                          style: const TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Masonry Grid View implementation
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
        backgroundColor: const Color(0xFF6C63FF),
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

  // Card UI updated for Masonry Grid
  Widget _buildNoteCard(Note note) {
    return GestureDetector(
      onTap: () {
        // THIS IS THE ONLY CHANGE HERE:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateNoteScreen(note: note), // Pass the note!
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:  Color(note.colorCode).withAlpha(26), // Use the note's color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // This is crucial for varying container sizes
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
              maxLines: 8, // Caps extremely long notes from taking up the entire screen height
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatDate(note.createdAt),
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