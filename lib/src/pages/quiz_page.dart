import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
// removed unused imports

class QuizPage extends StatefulWidget {
  final String code;
  final String gameId;
  final String responseId;
  final String categoryId;
  final String categoryName;

  const QuizPage({
    super.key,
    required this.code,
    required this.gameId,
    required this.responseId,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  // raw number of correct answers
  int _rawCorrect = 0;
  final List<int> _answers = [];
  bool _submitting = false;
  late final AnimationController _bgController;
  late final Animation<double> _bgScale;
  // timing
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  // Questions loaded from Firestore
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _questions = [];
  bool _loadingQuestions = true;
  String _userName = '';

  // scoring weights / settings
  // scoring constants removed; using provided formula instead

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadQuestions();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _bgScale = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _bgController.repeat(reverse: true);
  }

  Future<void> _loadUserData() async {
    try {
      final responseDoc = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .collection('responses')
          .doc(widget.responseId)
          .get();

      if (responseDoc.exists) {
        final data = responseDoc.data();
        setState(() {
          _userName = data?['userName'] ?? widget.code;
        });
      }
    } catch (e) {
      // If error, fallback to code
      setState(() {
        _userName = widget.code;
      });
    }
  }

  Future<void> _loadQuestions() async {
    try {
      // Load questions from category-specific collection
      final qSnap = await FirebaseFirestore.instance
          .collection('quiz')
          .doc('meta')
          .collection('questions_${widget.categoryId}')
          .get();

      final all = qSnap.docs;

      if (all.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No questions available')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Select random questions (up to 10, or all if less)
      final rand = Random();
      final chosen = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final indices = <int>{};
      final numQuestions = all.length < 10 ? all.length : 10;

      while (indices.length < numQuestions) {
        indices.add(rand.nextInt(all.length));
      }

      for (final i in indices) {
        chosen.add(all[i]);
      }

      setState(() {
        _questions = chosen;
        _loadingQuestions = false;
      });

      // Start timing after questions are loaded
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _select(int choice) {
    setState(() {
      _answers.add(choice);
      final q = _questions[_index].data();
      if ((q['correctIndex'] ?? 0) == choice) _rawCorrect++;
      _index++;
    });
    if (_index >= _questions.length) _submitScore();
  }

  Future<void> _submitScore() async {
    setState(() => _submitting = true);
    try {
      // stop timing
      _stopwatch.stop();
      _timer?.cancel();

      final timeTakenSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
      final total = _questions.length;
      final correct = _rawCorrect;
      final accuracy = total > 0 ? (correct / total) : 0.0;

      // final scoring per user's formula: totalSolved*10 + 1/timetaken(in seconds)
      // guard division by zero with a tiny epsilon
      final eps = 0.001;
      final safeTime = (timeTakenSeconds <= 0) ? eps : timeTakenSeconds;
      final finalScore = correct * 10 + (10.0 / safeTime);

      final ref = FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .collection('responses')
          .doc(widget.responseId);

      await ref.update({
        'score': finalScore,
        'timeTakenSeconds': timeTakenSeconds,
        'correctRate': accuracy,
        'rawCorrect': correct,
        'category': widget.categoryId,
        'categoryName': widget.categoryName,
      });

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Done'),
          content: Text(
            'Your score: ${finalScore.toStringAsFixed(3)}\nCorrect: $correct/$total\nTime: ${timeTakenSeconds.toStringAsFixed(1)}s',
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit score: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while questions are being loaded
    if (_loadingQuestions) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryName),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Defensive: ensure we have questions loaded
    if (_questions.isEmpty || _index >= _questions.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // proceed to render the quiz UI with a dimmed background image
    final q = _questions[_index].data();
    final options = List<String>.from(q['options'] ?? []);

    String _formatElapsed() {
      final ms = _stopwatch.elapsedMilliseconds;
      final s = ms ~/ 1000;
      final m = s ~/ 60;
      final sec = s % 60;
      final tenths = ((ms % 1000) ~/ 100);
      return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}.${tenths}';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Quit quiz'),
                  content: const Text(
                    'Are you sure you want to quit? Your progress will be lost.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // background image (network) with a subtle dark overlay to dim it
          Positioned.fill(
            child: ScaleTransition(
              scale: _bgScale,
              child: Image.asset(
                'assets/tech-trivia-bg.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.5),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          // quiz content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isShortScreen = constraints.maxHeight < 700;
                final screenWidth = constraints.maxWidth;
                // Use more screen width - less padding on larger screens
                final horizontalPadding = screenWidth > 1200 
                    ? screenWidth * 0.15 
                    : (screenWidth > 800 ? screenWidth * 0.08 : screenWidth * 0.05);
                
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isShortScreen ? 12 : 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // User name display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    _userName.isNotEmpty ? _userName : widget.code,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isShortScreen ? 12 : 24),
                          // Question counter and timer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Question ${_index + 1}/${_questions.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isShortScreen ? 22 : 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              // visible timer
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _formatElapsed(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isShortScreen ? 16 : 24),
                          // Question box
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              constraints: BoxConstraints(
                                maxHeight: isShortScreen 
                                    ? constraints.maxHeight * 0.25
                                    : constraints.maxHeight * 0.32,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(isShortScreen ? 20 : 28),
                                child: _renderPossibleMath(
                                  q['question'] ?? '',
                                  isShortScreen ? 20 : 24,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isShortScreen ? 20 : 36),
                          // Options
                          ...List.generate(
                            options.length,
                            (i) => Padding(
                              padding: EdgeInsets.only(
                                bottom: isShortScreen ? 10.0 : 14.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () => _select(i),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: isShortScreen ? 16 : 22,
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: _renderPossibleMath(
                                  options[i],
                                  isShortScreen ? 16 : 18,
                                ),
                              ),
                            ),
                          ),
                          if (_submitting) ...[
                            const SizedBox(height: 20),
                            const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderPossibleMath(String text, double fontSize) {
    final trimmed = text.trim();
    // simple heuristic: contains $...$ or \(...\) or \\[...\\]
    final hasMath =
        trimmed.contains(r'\(') ||
        trimmed.contains(r'\[') ||
        (trimmed.contains(r'$') && trimmed.split(r'$').length > 2);
    if (!hasMath) {
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      );
    }

    // Remove surrounding single $ markers for Math.tex
    var latex = text;
    if (latex.startsWith(r'$') && latex.endsWith(r'$')) {
      latex = latex.substring(1, latex.length - 1);
    }

    return Math.tex(
      latex,
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      mathStyle: MathStyle.text,
    );
  }
}
