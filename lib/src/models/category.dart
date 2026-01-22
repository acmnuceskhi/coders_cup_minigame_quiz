class QuizCategory {
  final String id;
  final String name;
  final String description;
  final String? iconPath;

  QuizCategory({
    required this.id,
    required this.name,
    required this.description,
    this.iconPath,
  });

  factory QuizCategory.fromMap(Map<String, dynamic> map, String id) {
    return QuizCategory(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconPath: map['iconPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      if (iconPath != null) 'iconPath': iconPath,
    };
  }
}
