import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _quizTitleController = TextEditingController();
  final _quizDescriptionController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _quizTitleController.dispose();
    _quizDescriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showLogoutConfirmation() async {
    if (!mounted) return;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _createQuiz() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _firestore.collection('quizzes').add({
          'title': _quizTitleController.text.trim(),
          'description': _quizDescriptionController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'questions': [],
          'totalAttempts': 0,
          'averageScore': 0.0,
          'lastAttempted': null,
          'topScore': 0.0,
          'completionRate': 0.0,
          'totalTimeSpent': 0,
          'averageTimePerQuestion': 0.0,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz created successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        _quizTitleController.clear();
        _quizDescriptionController.clear();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _editQuestion(String quizId, int questionIndex, Map<String, dynamic> question) async {
    final questionController = TextEditingController(text: question['question']);
    final optionsControllers = List.generate(
      4,
      (index) => TextEditingController(text: question['options'][index]),
    );
    final correctAnswerIndex = ValueNotifier<int>(question['correctAnswer']);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: optionsControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Option ${index + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              )),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: correctAnswerIndex,
                builder: (context, value, child) => DropdownButtonFormField<int>(
                  value: value,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(4, (index) => DropdownMenuItem(
                    value: index,
                    child: Text('Option ${index + 1}'),
                  )),
                  onChanged: (value) => correctAnswerIndex.value = value!,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (questionController.text.isEmpty ||
                  optionsControllers.any((c) => c.text.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final quizRef = _firestore.collection('quizzes').doc(quizId);
                final quiz = await quizRef.get();
                final questions = List<Map<String, dynamic>>.from(quiz.data()!['questions']);
                questions[questionIndex] = {
                  'question': questionController.text,
                  'options': optionsControllers.map((c) => c.text).toList(),
                  'correctAnswer': correctAnswerIndex.value,
                };
                await quizRef.update({'questions': questions});
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question updated successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuestion(String quizId, int questionIndex) async {
    try {
      final quizRef = _firestore.collection('quizzes').doc(quizId);
      final quiz = await quizRef.get();
      final questions = List<Map<String, dynamic>>.from(quiz.data()!['questions']);
      questions.removeAt(questionIndex);
      await quizRef.update({'questions': questions});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _addQuestion(String quizId) async {
    final questionController = TextEditingController();
    final optionsControllers = List.generate(4, (_) => TextEditingController());
    final correctAnswerIndex = ValueNotifier<int>(0);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: optionsControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Option ${index + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              )),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: correctAnswerIndex,
                builder: (context, value, child) => DropdownButtonFormField<int>(
                  value: value,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(4, (index) => DropdownMenuItem(
                    value: index,
                    child: Text('Option ${index + 1}'),
                  )),
                  onChanged: (value) => correctAnswerIndex.value = value!,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (questionController.text.isEmpty ||
                  optionsControllers.any((c) => c.text.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final quizRef = _firestore.collection('quizzes').doc(quizId);
                await quizRef.update({
                  'questions': FieldValue.arrayUnion([
                    {
                      'question': questionController.text,
                      'options': optionsControllers.map((c) => c.text).toList(),
                      'correctAnswer': correctAnswerIndex.value,
                    }
                  ]),
                });
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question added successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Manage Quizzes'),
            Tab(text: 'Quiz Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Manage Quizzes Tab
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Create New Quiz',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _quizTitleController,
                              decoration: const InputDecoration(
                                labelText: 'Quiz Title',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.quiz),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _quizDescriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Quiz Description',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _createQuiz,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.add),
                              label: Text(_isLoading ? 'Creating...' : 'Create Quiz'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Existing Quizzes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('quizzes').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final quizzes = snapshot.data?.docs ?? [];

                        if (quizzes.isEmpty) {
                          return const Center(
                            child: Text('No quizzes created yet'),
                          );
                        }

                        return ListView.builder(
                          itemCount: quizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = quizzes[index].data() as Map<String, dynamic>;
                            final questions = (quiz['questions'] as List?)?.length ?? 0;
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ExpansionTile(
                                title: Text(
                                  quiz['title'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${questions} questions • ${quiz['totalAttempts']} attempts',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          quiz['description'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => _addQuestion(quizzes[index].id),
                                              icon: const Icon(Icons.add_circle),
                                              label: const Text('Add Question'),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () async {
                                                try {
                                                  await _firestore
                                                      .collection('quizzes')
                                                      .doc(quizzes[index].id)
                                                      .delete();
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Quiz deleted successfully'),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error: ${e.toString()}'),
                                                    ),
                                                  );
                                                }
                                              },
                                              tooltip: 'Delete Quiz',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (questions > 0) ...[
                                          const Text(
                                            'Questions:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: questions,
                                            itemBuilder: (context, qIndex) {
                                              final question = quiz['questions'][qIndex];
                                              return Card(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                child: ListTile(
                                                  title: Text(question['question']),
                                                  subtitle: Text(
                                                    'Correct Answer: Option ${question['correctAnswer'] + 1}',
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit),
                                                        onPressed: () => _editQuestion(
                                                          quizzes[index].id,
                                                          qIndex,
                                                          question,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete),
                                                        onPressed: () => _deleteQuestion(
                                                          quizzes[index].id,
                                                          qIndex,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Quiz Analytics Tab
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('quizzes').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final quizzes = snapshot.data?.docs ?? [];

                  if (quizzes.isEmpty) {
                    return const Center(
                      child: Text('No quizzes available for analytics'),
                    );
                  }

                  return ListView.builder(
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = quizzes[index].data() as Map<String, dynamic>;
                      final totalAttempts = quiz['totalAttempts'] ?? 0;
                      final averageScore = quiz['averageScore'] ?? 0.0;
                      final questions = (quiz['questions'] as List?)?.length ?? 0;
                      final topScore = quiz['topScore'] ?? 0.0;
                      final completionRate = quiz['completionRate'] ?? 0.0;
                      final totalTimeSpent = quiz['totalTimeSpent'] ?? 0;
                      final averageTimePerQuestion = quiz['averageTimePerQuestion'] ?? 0.0;

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quiz['title'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Attempts',
                                      totalAttempts.toString(),
                                      Icons.people,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Average Score',
                                      '${(averageScore * 100).toStringAsFixed(1)}%',
                                      Icons.analytics,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Top Score',
                                      '${(topScore * 100).toStringAsFixed(1)}%',
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Completion Rate',
                                      '${(completionRate * 100).toStringAsFixed(1)}%',
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Time Spent',
                                      '${(totalTimeSpent / 60).toStringAsFixed(1)} min',
                                      Icons.timer,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Avg Time/Question',
                                      '${averageTimePerQuestion.toStringAsFixed(1)}s',
                                      Icons.speed,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 