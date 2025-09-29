import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'quiz_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final _codeCtrl = TextEditingController();
  bool _checking = false;
  // Animated blue gradients
  final List<List<Color>> _blueGradients = [
    [Color(0xFF0D47A1), Color(0xFF1976D2)], // deep -> mid
    [Color(0xFF1565C0), Color(0xFF64B5F6)], // mid -> light
    [Color(0xFF0B3D91), Color(0xFF42A5F5)], // darker -> light
    [Color(0xFF1E3A8A), Color(0xFF60A5FA)],
  ];
  int _currentGradient = 0;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Kick off the first gradient transition on next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentGradient = (_currentGradient + 1) % _blueGradients.length;
      });
    });
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
          if (data != null &&
              data.containsKey('score') &&
              data['score'] != null) {
            if (mounted) {
              setState(() => _checking = false);
              await showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Already played'),
                  content: Text(
                    'You have already played this quiz. Your score: ${data['score']}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
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
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid code')));
        }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No questions available')),
          );
        }
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
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(seconds: 4),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _blueGradients[_currentGradient],
              ),
            ),
            onEnd: () {
              if (!mounted) return;
              setState(() {
                _currentGradient =
                    (_currentGradient + 1) % _blueGradients.length;
              });
            },
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () async {
                  _codeCtrl.text = '';
                  Navigator.of(context).pushNamed('/admin');
                },
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your registration code to start the quiz',
                    style: TextStyle(fontSize: 36, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _codeCtrl,
                    style: TextStyle(color: Colors.grey[900]),
                    cursorColor: Colors.grey[900],
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 24),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _checking ? null : _submit,
                    child: _checking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
