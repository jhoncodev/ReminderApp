import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';

class NoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to securely grab the current logged-in user's ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Reference to the 'notes' collection in Firestore
  CollectionReference get _notesCollection => _firestore.collection('notes');

  // ==========================================
  // CREATE
  // ==========================================
Future<void> addNote({
    required String title,
    required String content,
    String? courseId,
    int colorCode = 0xFF6C63FF, // Default color if not provided
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User must be logged in to create a note');

    final newNote = Note(
      id: '', 
      userId: userId,
      courseId: courseId, 
      title: title,
      content: content,
      colorCode: colorCode, // Save the color!
      createdAt: DateTime.now(),
    );

    await _notesCollection.add(newNote.toFirestore());
  }

  // ==========================================
  // READ (All Notes)
  // ==========================================
  Stream<List<Note>> getUserNotes() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]); // Return empty stream if logged out

    return _notesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Fetched ${snapshot.docs.length} notes for user $userId');
      return snapshot.docs
          .map((doc) => Note.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // ==========================================
  // READ (Course-Specific Notes)
  // ==========================================
  Stream<List<Note>> getNotesForCourse(String courseId) {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _notesCollection
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId) // Filters out free notes
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Note.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // ==========================================
  // UPDATE
  // ==========================================
  Future<void> updateNote(Note note) async {
    if (_currentUserId == null || note.userId != _currentUserId) {
      throw Exception('Unauthorized to update this note');
    }

    await _notesCollection.doc(note.id).update(note.toFirestore());
  }

  // ==========================================
  // DELETE
  // ==========================================
  Future<void> deleteNote(String noteId) async {
    if (_currentUserId == null) throw Exception('User must be logged in');
    
    await _notesCollection.doc(noteId).delete();
  }
}