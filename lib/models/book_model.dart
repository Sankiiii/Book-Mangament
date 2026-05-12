class BookModel {
  final String id;
  final String title;
  final String author;
  final String genre;
  final String description;
  bool isAvailable;
  String? borrowedBy; 
  DateTime? borrowedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.description,
    this.isAvailable = true,
    this.borrowedBy,
    this.borrowedAt,
  });

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? genre,
    String? description,
    bool? isAvailable,
    String? borrowedBy,
    DateTime? borrowedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      borrowedBy: borrowedBy ?? this.borrowedBy,
      borrowedAt: borrowedAt ?? this.borrowedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'genre': genre,
        'description': description,
        'isAvailable': isAvailable,
        'borrowedBy': borrowedBy,
        'borrowedAt': borrowedAt?.toIso8601String(),
      };

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        genre: json['genre'],
        description: json['description'],
        isAvailable: json['isAvailable'] ?? true,
        borrowedBy: json['borrowedBy'],
        borrowedAt: json['borrowedAt'] != null
            ? DateTime.parse(json['borrowedAt'])
            : null,
      );
}
