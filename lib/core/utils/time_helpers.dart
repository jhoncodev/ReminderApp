import 'package:flutter/material.dart';

// "14:30" -> "2:30 pm"
// "08:00" -> "8:00 am"
String formatTo12h(String time24h){
  final parts = time24h.split(':');
  final hour24 = int.parse(parts[0]);
  final minute = parts[1];
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
  
  return '$hour12:$minute $period';
}

// TimeOfDay (hour: 14, minute:30) -> "14:30"
// TimeOfDay (hour: 8, minute:0) -> "08:00"
String formatTo24h(TimeOfDay time){
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  
  return '$h:$m';
}

// "14:30" -> TimeOfDay(hours: 14, minute: 30)
TimeOfDay parse24h(String time24h){
  final parts = time24h.split(':');
  
  return TimeOfDay(
    hour: int.parse(parts[0]), 
    minute: int.parse(parts[1])
  );
}

