// lib/features/quiz/domain/models/quiz_model.dart

class QuizTopic {
  // Mengganti 'title' menjadi 'name' untuk konsistensi
  String name;
  String icon;
  int position;

  QuizTopic({
    required this.name,
    this.icon = '❓', // Ikon default untuk kuis
    this.position = -1,
  });

  // Fungsi baru untuk membuat JSON yang akan disimpan di file config
  Map<String, dynamic> toConfigJson() {
    return {'icon': icon, 'position': position};
  }
}
