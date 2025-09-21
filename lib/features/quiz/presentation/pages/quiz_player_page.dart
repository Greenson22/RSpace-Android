// lib/features/quiz/presentation/pages/quiz_player_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_player_provider.dart';
import '../../domain/models/quiz_model.dart';

class QuizPlayerPage extends StatelessWidget {
  final QuizTopic topic;
  const QuizPlayerPage({super.key, required this.topic});

  Future<bool> _onWillPop(BuildContext context) async {
    final provider = Provider.of<QuizPlayerProvider>(context, listen: false);

    if (provider.state != QuizState.playing) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Kuis?'),
        content: const Text('Progres kuis Anda saat ini akan hilang.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizPlayerProvider(topic: topic),
      child: Consumer<QuizPlayerProvider>(
        builder: (context, provider, child) {
          return WillPopScope(
            onWillPop: () => _onWillPop(context),
            child: Scaffold(
              appBar: AppBar(
                title: Text('Kuis: ${topic.name}'),
                actions: [
                  if (provider.state == QuizState.playing &&
                      provider.topic.isTimerEnabled)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Chip(
                        avatar: Icon(
                          Icons.timer_outlined,
                          color: provider.remainingTime <= 10
                              ? Colors.red
                              : null,
                        ),
                        label: Text(
                          provider.remainingTime.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: provider.remainingTime <= 10
                                ? Colors.red
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              body: _buildBody(context, provider),
            ),
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
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Tidak ada pertanyaan untuk dimainkan. Coba periksa pengaturan kuis di halaman "Kelola Kuis".',
                textAlign: TextAlign.center,
              ),
            ),
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
    final isRevealed = provider.isAnswerRevealed(question.id);

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
            Color? cardColor;
            if (isRevealed) {
              if (option.isCorrect) {
                cardColor = Colors.green.withOpacity(0.3);
              } else if (isSelected && !option.isCorrect) {
                cardColor = Colors.red.withOpacity(0.3);
              }
            } else if (isSelected) {
              cardColor = Theme.of(context).primaryColor.withOpacity(0.3);
            }

            return Card(
              color: cardColor,
              child: ListTile(
                title: Text(option.text),
                onTap: isRevealed
                    ? null
                    : () {
                        provider.answerQuestion(question, option);
                      },
              ),
            );
          }).toList(),
          const Spacer(),
          if (!provider.topic.autoAdvanceNextQuestion)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (provider.currentIndex > 0)
                  OutlinedButton(
                    onPressed: provider.previousQuestion,
                    child: const Text('Sebelumnya'),
                  ),
                if (provider.currentIndex == 0 && provider.questions.length > 1)
                  const Spacer(),
                if (provider.currentIndex < provider.questions.length - 1)
                  ElevatedButton(
                    onPressed: provider.nextQuestion,
                    child: const Text('Berikutnya'),
                  ),
                if (provider.currentIndex == provider.questions.length - 1)
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
