import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizPlayScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizPlayScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _correctAnswers = 0;
  int _totalTimeSpent = 0;
  DateTime _startTime = DateTime.now();
  List<Map<String, dynamic>> _previousAttempts = [];
  bool _showPreviousAttempts = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
    _loadPreviousAttempts();
  }

  Future<void> _loadPreviousAttempts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // First try to get attempts without the timestamp filter
      final snapshot = await _firestore
          .collection('userAttempts')
          .where('userId', isEqualTo: user.uid)
          .where('quizId', isEqualTo: widget.quizId)
          .get();

      setState(() {
        _previousAttempts = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'score': data['score'],
            'timestamp': (data['timestamp'] as Timestamp).toDate(),
            'correctAnswers': data['correctAnswers'],
            'totalQuestions': data['totalQuestions'],
            'timeSpent': data['timeSpent'],
          };
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading previous attempts: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadQuiz() async {
    try {
      final quizDoc = await _firestore.collection('quizzes').doc(widget.quizId).get();
      if (quizDoc.exists) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(quizDoc.data()!['questions']);
          _isLoading = false;
          _startTime = DateTime.now();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading quiz: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an answer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final isCorrect = _selectedAnswerIndex == _questions[_currentQuestionIndex]['correctAnswer'];
    if (isCorrect) {
      _correctAnswers++;
    }

    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    _totalTimeSpent += timeSpent;

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _startTime = DateTime.now();
        _isSubmitting = false;
      });
    } else {
      await _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final score = _correctAnswers / _questions.length;
      final averageTimePerQuestion = _totalTimeSpent / _questions.length;

      // Update quiz statistics
      final quizRef = _firestore.collection('quizzes').doc(widget.quizId);
      final quiz = await quizRef.get();
      final currentAttempts = quiz.data()!['totalAttempts'] ?? 0;
      final currentAverageScore = quiz.data()!['averageScore'] ?? 0.0;
      final currentTopScore = quiz.data()!['topScore'] ?? 0.0;

      await quizRef.update({
        'totalAttempts': currentAttempts + 1,
        'averageScore': ((currentAverageScore * currentAttempts) + score) / (currentAttempts + 1),
        'topScore': score > currentTopScore ? score : currentTopScore,
        'lastAttempted': FieldValue.serverTimestamp(),
        'totalTimeSpent': FieldValue.increment(_totalTimeSpent),
        'averageTimePerQuestion': ((quiz.data()!['averageTimePerQuestion'] ?? 0) * currentAttempts + averageTimePerQuestion) / (currentAttempts + 1),
      });

      // Update user statistics
      final userStatsRef = _firestore.collection('userStats').doc(user.uid);
      final userStats = await userStatsRef.get();
      final currentUserStats = userStats.data() ?? {
        'quizzesTaken': 0,
        'averageScore': 0.0,
        'totalTimeSpent': 0,
        'correctAnswers': 0,
        'totalQuestions': 0,
      };

      await userStatsRef.set({
        'quizzesTaken': currentUserStats['quizzesTaken'] + 1,
        'averageScore': ((currentUserStats['averageScore'] * currentUserStats['quizzesTaken']) + score) / (currentUserStats['quizzesTaken'] + 1),
        'totalTimeSpent': currentUserStats['totalTimeSpent'] + _totalTimeSpent,
        'correctAnswers': currentUserStats['correctAnswers'] + _correctAnswers,
        'totalQuestions': currentUserStats['totalQuestions'] + _questions.length,
      }, SetOptions(merge: true));

      // Record attempt
      await _firestore.collection('userAttempts').add({
        'userId': user.uid,
        'quizId': widget.quizId,
        'quizTitle': widget.quizTitle,
        'score': score,
        'correctAnswers': _correctAnswers,
        'totalQuestions': _questions.length,
        'timeSpent': _totalTimeSpent,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Quiz Completed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Score: ${(score * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Correct Answers: $_correctAnswers/${_questions.length}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Time Spent: ${_formatTime(_totalTimeSpent)}',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting quiz: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showPreviousAttempts ? Icons.quiz : Icons.history),
            onPressed: () {
              setState(() => _showPreviousAttempts = !_showPreviousAttempts);
            },
          ),
        ],
      ),
      body: _showPreviousAttempts
          ? _buildPreviousAttempts()
          : Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentQuestion['question'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...List.generate(
                          currentQuestion['options'].length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedAnswerIndex = index;
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedAnswerIndex == index
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                                foregroundColor: _selectedAnswerIndex == index
                                    ? Colors.white
                                    : Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              child: Text(
                                currentQuestion['options'][index],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _currentQuestionIndex < _questions.length - 1
                                ? 'Next Question'
                                : 'Submit Quiz',
                            style: const TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPreviousAttempts() {
    if (_previousAttempts.isEmpty) {
      return const Center(
        child: Text(
          'No previous attempts',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _previousAttempts.length,
      itemBuilder: (context, index) {
        final attempt = _previousAttempts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attempt ${_previousAttempts.length - index}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAttemptStat(
                      'Score',
                      '${(attempt['score'] * 100).toStringAsFixed(1)}%',
                    ),
                    _buildAttemptStat(
                      'Correct',
                      '${attempt['correctAnswers']}/${attempt['totalQuestions']}',
                    ),
                    _buildAttemptStat(
                      'Time',
                      _formatTime(attempt['timeSpent']),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${attempt['timestamp'].toString().split('.')[0]}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttemptStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 