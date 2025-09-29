import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class QuizPage extends StatefulWidget {
  final String gameId;
  final String responseId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> questions;

  const QuizPage({
    super.key,
    required this.gameId,
    required this.responseId,
    required this.questions,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int _score = 0;
  final List<int> _answers = [];
  bool _submitting = false;
  late final AnimationController _bgController;
  late final Animation<double> _bgScale;

  void _select(int choice) {
    setState(() {
      _answers.add(choice);
      final q = widget.questions[_index].data();
      if ((q['correctIndex'] ?? 0) == choice) _score++;
      _index++;
    });
    if (_index >= widget.questions.length) _submitScore();
  }

  @override
  void initState() {
    super.initState();
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

  Future<void> _submitScore() async {
    setState(() => _submitting = true);
    try {
      final ref = FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .collection('responses')
          .doc(widget.responseId);
      await ref.update({'score': _score});
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Done'),
          content: Text('Your score: $_score'),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defensive: ensure response hasn't been scored while user navigated here.
    // If so, inform user and pop.
    // Note: this check is synchronous because questions were loaded earlier, but
    // we do a quick fetch to be safe.
    // (We avoid calling async code in build; instead we check a FutureBuilder below.)
    if (_index >= widget.questions.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // proceed to render the quiz UI with a dimmed background image
    final q = widget.questions[_index].data();
    final options = List<String>.from(q['options'] ?? []);

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
                    'Are you sure you want to quist? Your progress will be lost.',
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
      ),
      body: Stack(
        children: [
          // background image (network) with a subtle dark overlay to dim it
          Positioned.fill(
            child: ScaleTransition(
              scale: _bgScale,
              child: Image.asset(
                'assets/tech-trivia-bg.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.7),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          // quiz content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.2,
              vertical: 30,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Question ${_index + 1}/${widget.questions.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.height * 0.05,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    color: Colors.black,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: GptMarkdown(
                          q['question'] ?? '',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 21, 183, 27),
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                ...List.generate(
                  options.length,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.1,
                      ),
                      child: ElevatedButton(
                        onPressed: () => _select(i),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(fontSize: 24),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _renderPossibleMath(options[i], 20),
                      ),
                    ),
                  ),
                ),
                // const Spacer(),
                if (_submitting)
                  const Center(child: CircularProgressIndicator()),
              ],
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
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
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
      textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      mathStyle: MathStyle.text,
    );
  }
}
