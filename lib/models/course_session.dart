class CourseSession {
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? roomName;

  CourseSession({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomName,
  });

  // Convierte un mapa de Firestore a un objeto CourseSession
  factory CourseSession.fromMap(Map<String, dynamic> map){
    return CourseSession(
      dayOfWeek: map['dayOfWeek'] as int,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      roomName: map['roomName'] as String?,
    );
  }

  // Convierte un objeto CourseSession a un mapa para Firestore
  Map<String, dynamic> toMap(){
    return{
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      if(roomName != null) 'roomName': roomName,
    };
  }
}