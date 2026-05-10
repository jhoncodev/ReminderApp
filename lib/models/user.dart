class User{
  final String? id;
  final String email;
  final String password;
  final DateTime createdAt;
  final DateTime updatedAt;
  User({
    this.id,
    required this.email,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

}