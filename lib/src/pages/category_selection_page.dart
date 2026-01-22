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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Quiz Category'),
        backgroundColor: primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              hsl.withLightness(0.85).toColor(),
              hsl.withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0))
                  .withLightness(0.90)
                  .toColor(),
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No quiz categories available yet.\nPlease check back later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Choose Your Quiz Topic',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select a category to start your quiz',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _selectCategory(category),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: _getCategoryColor(index),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(index),
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  category.name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (category
                                                    .description
                                                    .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4.0,
                                                        ),
                                                    child: Text(
                                                      category.description,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 18,
                                            color: Colors.black38,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(primaryColor);
    
    // Generate color variations by rotating hue and adjusting saturation/lightness
    final hueShifts = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];
    final hueShift = hueShifts[index % hueShifts.length];
    
    return hsl
        .withHue((hsl.hue + hueShift) % 360)
        .withSaturation(0.7)
        .withLightness(0.5)
        .toColor();
  }

  IconData _getCategoryIcon(int index) {
    final icons = [
      Icons.code,
      Icons.phone_android,
      Icons.web,
      Icons.storage,
      Icons.cloud,
      Icons.security,
      Icons.devices,
      Icons.language,
    ];
    return icons[index % icons.length];
  }
}
