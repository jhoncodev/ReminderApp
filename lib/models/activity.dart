class Activity {
  final int? id;
  final String userId;
  final String name;
  final String? notes; 
  final double? budgetAmount; 
  final String frequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Activity({
    this.id,
    required this.userId,
    required this.name,
    this.notes,
    this.budgetAmount,
    required this.frequency,
    required this.createdAt,
    required this.updatedAt,
  });
}