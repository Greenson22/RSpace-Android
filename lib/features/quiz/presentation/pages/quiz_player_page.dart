// lib/features/quiz/presentation/pages/quiz_player_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_player_provider.dart';
import '../../domain/models/quiz_model.dart';

class QuizPlayerPage extends StatelessWidget {
  final String topicName;
  const QuizPlayerPage({super.key, required this.topicName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizPlayerProvider(topicName: topicName),
      child: Consumer<QuizPlayerProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(title: Text('Kuis: $topicName')),
            body: _buildBody(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuizPlayerProvider provider) {
    switch (provider.state) {
      case QuizState.loading:
        return const Center(child: CircularProgressIndicator());
      case QuizState.playing:
        if (provider.questions.isEmpty) {
          return const Center(
            child: Text('Tidak ada pertanyaan dalam kuis ini.'),
          );
        }
        return _buildQuestionView(context, provider);
      case QuizState.finished:
        return _buildResultView(context, provider);
    }
  }

  Widget _buildQuestionView(BuildContext context, QuizPlayerProvider provider) {
    final question = provider.questions[provider.currentIndex];
    final userAnswer = provider.userAnswers[question.id];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pertanyaan ${provider.currentIndex + 1} dari ${provider.questions.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (provider.currentIndex + 1) / provider.questions.length,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                question.questionText,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...question.options.map((option) {
            bool isSelected = userAnswer == option;
            return Card(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : null,
              child: ListTile(
                title: Text(option.text),
                onTap: () {
                  provider.answerQuestion(question, option);
                },
              ),
            );
          }).toList(),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: provider.currentIndex > 0
                    ? provider.previousQuestion
                    : null,
                child: const Text('Sebelumnya'),
              ),
              if (provider.currentIndex < provider.questions.length - 1)
                ElevatedButton(
                  onPressed: provider.nextQuestion,
                  child: const Text('Berikutnya'),
                )
              else
                ElevatedButton(
                  onPressed: provider.finishQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Selesai'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context, QuizPlayerProvider provider) {
    final totalQuestions = provider.questions.length;
    final score = provider.score;
    final percentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Kuis Selesai!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text('Skor Anda:', style: Theme.of(context).textTheme.titleLarge),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$score dari $totalQuestions benar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Ulangi Kuis'),
            onPressed: provider.restartQuiz,
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali ke Daftar Topik'),
          ),
        ],
      ),
    );
  }
}
