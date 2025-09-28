import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  final String gameId;
  final String responseId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> questions;

  const QuizPage({super.key, required this.gameId, required this.responseId, required this.questions});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _index = 0;
  int _score = 0;
  final List<int> _answers = [];
  bool _submitting = false;

  void _select(int choice) {
    setState(() {
      _answers.add(choice);
      final q = widget.questions[_index].data();
      if ((q['correctIndex'] ?? 0) == choice) _score++;
      _index++;
    });
    if (_index >= widget.questions.length) _submitScore();
  }

  Future<void> _submitScore() async {
    setState(() => _submitting = true);
    try {
      final ref = FirebaseFirestore.instance.collection('games').doc(widget.gameId).collection('responses').doc(widget.responseId);
      await ref.update({'score': _score});
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Done'),
          content: Text('Your score: $_score'),
          actions: [
            TextButton(onPressed: () {
              if (mounted) Navigator.of(context).pop();
            }, child: const Text('OK')),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit score: $e')));
    } finally {
      setState(() => _submitting = false);
    }
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
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('games').doc(widget.gameId).collection('responses').doc(widget.responseId).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final doc = snap.data;
        if (doc != null && doc.data() != null && doc.data()!.containsKey('score') && doc.data()!['score'] != null) {
          // already scored
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Already played'), content: Text('You have already played this quiz. Your score: ${doc.data()!['score']}'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))]));
            Navigator.of(context).pop();
          });
          return const Scaffold();
        }

        // proceed to render the quiz UI
        final q = widget.questions[_index].data();
        final options = List<String>.from(q['options'] ?? []);
        return Scaffold(
          appBar: AppBar(title: Text('Question ${_index + 1}/${widget.questions.length}')),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(q['question'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...List.generate(options.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ElevatedButton(onPressed: () => _select(i), child: Text(options[i])),
                )),
                const Spacer(),
                if (_submitting) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }
}
