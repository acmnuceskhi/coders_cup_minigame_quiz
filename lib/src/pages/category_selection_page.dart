import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import 'quiz_page.dart';

class CategorySelectionPage extends StatefulWidget {
  final String code;
  final String gameId;
  final String responseId;

  const CategorySelectionPage({
    super.key,
    required this.code,
    required this.gameId,
    required this.responseId,
  });

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  List<QuizCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('quiz')
          .doc('meta')
          .collection('categories')
          .get();

      setState(() {
        _categories = snap.docs
            .map((doc) => QuizCategory.fromMap(doc.data(), doc.id))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Future<void> _selectCategory(QuizCategory category) async {
    // Check if category has questions
    final questionsSnap = await FirebaseFirestore.instance
        .collection('quiz')
        .doc('meta')
        .collection('questions_${category.id}')
        .limit(1)
        .get();

    if (questionsSnap.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No questions available in ${category.name} yet'),
          ),
        );
      }
      return;
    }

    // Navigate to quiz page with selected category
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            code: widget.code,
            gameId: widget.gameId,
            responseId: widget.responseId,
            categoryId: category.id,
            categoryName: category.name,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(primaryColor);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              hsl.withLightness(0.12).toColor(),
              hsl.withLightness(0.08).toColor(),
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _categories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No quiz categories available yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Please check back later.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Header Section
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.08,
                            vertical: 24,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.quiz,
                                size: 56,
                                color: primaryColor.withOpacity(0.9),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Choose Your Category',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select a topic to begin your quiz challenge',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Categories Grid
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.08,
                            ),
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: size.width > 1200 ? 3 : (size.width > 800 ? 2 : 1),
                                childAspectRatio: size.width > 800 ? 2.5 : 3.0,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final categoryColor = _getCategoryColor(index);
                                
                                return InkWell(
                                  onTap: () => _selectCategory(category),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          categoryColor.withOpacity(0.9),
                                          categoryColor.withOpacity(0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: categoryColor.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(index),
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  category.name,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                if (category.description.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    category.description,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white.withOpacity(0.9),
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white.withOpacity(0.8),
                                            size: 28,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(primaryColor);

    // Generate vibrant color variations by rotating hue
    final hueShifts = [0.0, 50.0, 100.0, 150.0, 200.0, 250.0, 300.0, 330.0];
    final hueShift = hueShifts[index % hueShifts.length];

    return hsl
        .withHue((hsl.hue + hueShift) % 360)
        .withSaturation(0.75)
        .withLightness(0.45)
        .toColor();
  }

  IconData _getCategoryIcon(int index) {
    final icons = [
      Icons.code_rounded,
      Icons.phone_android_rounded,
      Icons.language_rounded,
      Icons.storage_rounded,
      Icons.cloud_rounded,
      Icons.security_rounded,
      Icons.computer_rounded,
      Icons.psychology_rounded,
    ];
    return icons[index % icons.length];
  }
}
