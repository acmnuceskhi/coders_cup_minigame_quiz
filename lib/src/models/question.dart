class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;

  Question({required this.id, required this.question, required this.options, required this.correctIndex});

  Map<String, dynamic> toMap() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
      };

  static Question fromMap(String id, Map<String, dynamic> m) => Question(
        id: id,
        question: (m['question'] ?? '') as String,
        options: List<String>.from(m['options'] ?? []),
        correctIndex: (m['correctIndex'] ?? 0) as int,
      );
}
