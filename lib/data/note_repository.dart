import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';

class NoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Devuelve el uid del usuario con sesión iniciada (null si no hay sesión)
  String? get _currentUserId => _auth.currentUser?.uid;

  // Referencia a la colección 'notes' en Firestore
  CollectionReference get _notesCollection => _firestore.collection('notes');

  // ==========================================
  // CREAR
  // ==========================================
Future<void> addNote({
    required String title,
    required String content,
    String? courseId,
    int colorCode = 0xFF6C63FF, // Color por defecto si no se indica
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User must be logged in to create a note');

    final newNote = Note(
      id: '', 
      userId: userId,
      courseId: courseId, 
      title: title,
      content: content,
      colorCode: colorCode,
      createdAt: DateTime.now(),
    );

    await _notesCollection.add(newNote.toFirestore());
  }

  // ==========================================
  // LEER (todos los apuntes)
  // ==========================================
  Stream<List<Note>> getUserNotes() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]); // Stream vacío si no hay sesión

    return _notesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Note.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // ==========================================
  // LEER (apuntes de un curso)
  // ==========================================
  Stream<List<Note>> getNotesForCourse(String courseId) {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _notesCollection
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId) // Excluye los apuntes libres (sin curso)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Note.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // ==========================================
  // ACTUALIZAR
  // ==========================================
  Future<void> updateNote(Note note) async {
    if (_currentUserId == null || note.userId != _currentUserId) {
      throw Exception('Unauthorized to update this note');
    }

    await _notesCollection.doc(note.id).update(note.toFirestore());
  }

  // ==========================================
  // ELIMINAR
  // ==========================================
  Future<void> deleteNote(String noteId) async {
    if (_currentUserId == null) throw Exception('User must be logged in');
    
    await _notesCollection.doc(noteId).delete();
  }
}