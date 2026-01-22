import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'category_selection_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final _codeCtrl = TextEditingController();
  bool _checking = false;
  int _currentGradient = 0;

  // Generate gradient variations from primary color
  List<List<Color>> _getGradients(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    return [
      [hsl.withLightness(0.25).toColor(), hsl.withLightness(0.35).toColor()],
      [hsl.withLightness(0.30).toColor(), hsl.withLightness(0.50).toColor()],
      [hsl.withLightness(0.20).toColor(), hsl.withLightness(0.45).toColor()],
      [hsl.withLightness(0.28).toColor(), hsl.withLightness(0.48).toColor()],
    ];
  }

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
        _currentGradient = (_currentGradient + 1) % 4;
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
          .where('name', isEqualTo: 'Tech Trivia')
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

      // Navigate to category selection page
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategorySelectionPage(
            code: code,
            gameId: gameId!,
            responseId: responseId!,
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final gradients = _getGradients(primaryColor);

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
                colors: gradients[_currentGradient],
              ),
            ),
            onEnd: () {
              if (!mounted) return;
              setState(() {
                _currentGradient = (_currentGradient + 1) % gradients.length;
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
