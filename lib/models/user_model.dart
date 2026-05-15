class UserModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final List<String> borrowedBookIds;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    List<String>? borrowedBookIds,
    DateTime? createdAt,
  }) : borrowedBookIds = borrowedBookIds ?? [],
       createdAt = createdAt ?? DateTime.now();

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    List<String>? borrowedBookIds,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      borrowedBookIds: borrowedBookIds ?? List.from(this.borrowedBookIds),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'role': role,
    'borrowedBookIds': borrowedBookIds,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    username: json['username'],
    email: json['email'],
    role: json['role'],
    borrowedBookIds: List<String>.from(json['borrowedBookIds'] ?? []),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );
}
