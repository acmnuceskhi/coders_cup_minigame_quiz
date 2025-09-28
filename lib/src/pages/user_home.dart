import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'quiz_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final _codeCtrl = TextEditingController();
  bool _checking = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _checking = true);
    try {
      // Find a game marked as Quiz that contains this code in responses
      final games = await FirebaseFirestore.instance
          .collection('games')
          .where('name', isEqualTo: 'Quiz')
          .get();
      String? gameId;
      String? responseId;
      for (final g in games.docs) {
        final r = await g.reference.collection('responses').doc(code).get();
        if (r.exists) {
          // If a score already exists, user already played.
          final data = r.data();
          if (data != null && data.containsKey('score') && data['score'] != null) {
            if (mounted) {
              setState(() => _checking = false);
              await showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Already played'),
                  content: Text('You have already played this quiz. Your score: ${data['score']}'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                  ],
                ),
              );
            }
            return;
          }

          gameId = g.id;
          responseId = r.id;
          break;
        }
      }
      if (gameId == null) {
          if (mounted) ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid code')));
        return;
      }
      // Load 20 random questions
      final qSnap = await FirebaseFirestore.instance
          .collection('quiz')
          .doc('meta')
          .collection('questions')
          .get();
      final all = qSnap.docs;
      if (all.isEmpty) {
          if (mounted) ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No questions available')));
        return;
      }
      final rand = Random();
      final chosen = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final indices = <int>{};
      while (indices.length < 20 && indices.length < all.length) {
        indices.add(rand.nextInt(all.length));
      }
      for (final i in indices) {
        chosen.add(all[i]);
      }

      // navigate to quiz page with chosen questions
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizPage(
            gameId: gameId!,
            responseId: responseId!,
            questions: chosen,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz'),
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () async {
            Navigator.of(context).pushNamed('/admin');
          },
        ),
      ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Enter your registration code to start the quiz'),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _checking ? null : _submit,
              child: _checking
                  ? const CircularProgressIndicator()
                  : const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
