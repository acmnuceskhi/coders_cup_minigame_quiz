import 'package:flutter/material.dart';
import 'admin_questions_page.dart';

/// Password gate for admin questions page
/// Requires hardcoded password to access question management
class AdminPasswordGate extends StatefulWidget {
  const AdminPasswordGate({super.key});

  @override
  State<AdminPasswordGate> createState() => _AdminPasswordGateState();
}

class _AdminPasswordGateState extends State<AdminPasswordGate> {
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  static const String _correctPassword = 'reallygoodpassword';

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordCtrl.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter password')));
      return;
    }

    setState(() => _loading = true);

    // Simulate a small delay for UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    if (password == _correctPassword) {
      // Password correct - navigate to admin questions page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminQuestionsPage()),
      );
    } else {
      // Password incorrect
      setState(() => _loading = false);
      _passwordCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access'),
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.white70),
              const SizedBox(height: 24),
              const Text(
                'Enter Password to Access\nQuestion Management',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.key),
                ),
                obscureText: true,
                enabled: !_loading,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
