import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/note_repository.dart';
import '../../data/course_repository.dart';
import '../../models/note.dart';
import '../../models/course.dart';

class CreateNoteScreen extends StatefulWidget {
  final String? courseId;
  final Note? note; // ADDED: If this is passed in, we are in "Edit Mode"

  const CreateNoteScreen({Key? key, this.courseId, this.note})
    : super(key: key);

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
  String _selectedCourseName = 'All notes';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate the fields if we are editing an existing note
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    // Use the existing note's date, or current time if it's new
    _noteDateTime = widget.note?.createdAt ?? DateTime.now();

    // Priority: 1. Existing Note's Course -> 2. Filter's Course -> 3. Null (All Notes)
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
            _selectedCourseColor = course.colorCode; // GET THE COLOR
          });
        }
      } catch (e) {
        // Silently fail
      }
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both a title and content.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.note == null) {
        // CREATE: No note was passed in
        await _noteRepository.addNote(
          title: title,
          content: content,
          courseId: _selectedCourseId,
          colorCode: _selectedCourseColor,
        );
      } else {
        // UPDATE: Overwrite the existing note
        final updatedNote = Note(
          id: widget.note!.id,
          userId: widget.note!.userId,
          courseId:
              _selectedCourseId, // Allows moving a note to a different course
          title: title,
          content: content,
          createdAt: widget.note!.createdAt,
          colorCode: _selectedCourseColor, // Keep original color
        );
        await _noteRepository.updateNote(updatedNote);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  // Bonus: Allow deleting a note if we are in Edit Mode
  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Delete Note?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
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
        if (mounted) Navigator.pop(context); // Go back to list after deleting
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCourseSelection() {
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
                      'Select Course',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text(
                      'All notes',
                      style: TextStyle(color: Colors.white),
                    ),
                    leading: Icon(
                      Icons.clear,
                      color: _selectedCourseId == null
                          ? const Color(0xFF6C63FF)
                          : Colors.white54,
                    ),
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
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white54,
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCourseId = course.id;
                                    _selectedCourseName = course.name;
                                    _selectedCourseColor = course.colorCode; // GET THE COLOR
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
      return DateFormat('MMMM d, h:mm a').format(_noteDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // If we are editing, show the Trash Can icon
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
                    hintText: 'Title',
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
                          color: const Color(0xFF1E1E1E),
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
                    hintText: 'Enter note',
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
