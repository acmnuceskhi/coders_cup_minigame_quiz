import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import '../models/category.dart';

class AdminQuestionsPage extends StatefulWidget {
  const AdminQuestionsPage({super.key});

  @override
  State<AdminQuestionsPage> createState() => _AdminQuestionsPageState();
}

class _AdminQuestionsPageState extends State<AdminQuestionsPage> {
  bool _isUploading = false;
  String? _selectedCategoryId;
  List<QuizCategory> _categories = [];
  bool _loadingCategories = true;

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
        _loadingCategories = false;
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
      });
    } catch (e) {
      setState(() => _loadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUpload() async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first')),
      );
      return;
    }

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (res == null) return;

    final fileBytes = res.files.single.bytes;
    if (fileBytes == null) return;

    final content = utf8.decode(fileBytes);
    final rows = const CsvToListConverter().convert(content, eol: '\n');

    setState(() => _isUploading = true);

    int uploadedCount = 0;
    int skippedCount = 0;
    final List<String> skippedReasons = [];

    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance
        .collection('quiz')
        .doc('meta')
        .collection('questions_$_selectedCategoryId');

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];

      // Skip empty rows
      if (row.isEmpty) {
        skippedCount++;
        skippedReasons.add('Row ${i + 1}: Empty row');
        continue;
      }

      // Validate minimum columns (question + 4 options + correctIndex = 6)
      if (row.length < 6) {
        skippedCount++;
        skippedReasons.add(
          'Row ${i + 1}: Missing columns (need 6, got ${row.length})',
        );
        continue;
      }

      final q = row[0].toString().trim();

      // Validate question is not empty
      if (q.isEmpty) {
        skippedCount++;
        skippedReasons.add('Row ${i + 1}: Empty question');
        continue;
      }

      // Extract options
      final opts = <String>[];
      bool hasEmptyOption = false;
      for (var j = 1; j <= 4 && j < row.length; j++) {
        final opt = row[j].toString().trim();
        if (opt.isEmpty) {
          hasEmptyOption = true;
          break;
        }
        opts.add(opt);
      }

      // Validate all 4 options are present
      if (hasEmptyOption || opts.length < 4) {
        skippedCount++;
        skippedReasons.add('Row ${i + 1}: Missing or empty options (need 4)');
        continue;
      }

      // Parse and validate correctIndex
      final correctStr = row[5].toString().trim();
      final correct = int.tryParse(correctStr);

      if (correct == null) {
        skippedCount++;
        skippedReasons.add(
          'Row ${i + 1}: Invalid correctIndex "$correctStr" (must be 0-3)',
        );
        continue;
      }

      if (correct < 0 || correct > 3) {
        skippedCount++;
        skippedReasons.add(
          'Row ${i + 1}: correctIndex $correct out of range (must be 0-3)',
        );
        continue;
      }

      // Valid question - add to batch
      final doc = col.doc();
      batch.set(doc, {'question': q, 'options': opts, 'correctIndex': correct});
      uploadedCount++;
    }

    try {
      await batch.commit();
      if (!mounted) return;

      // Show detailed results
      String message = 'Upload complete: $uploadedCount uploaded';
      if (skippedCount > 0) {
        message += ', $skippedCount skipped';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );

      // Show detailed skipped reasons if any
      if (skippedReasons.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Skipped Questions ($skippedCount)'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: skippedReasons.length > 20
                    ? 20
                    : skippedReasons.length,
                itemBuilder: (context, idx) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    skippedReasons[idx],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            actions: [
              if (skippedReasons.length > 20)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '...and ${skippedReasons.length - 20} more',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _clearAll() async {
    if (_selectedCategoryId == null) return;

    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(
          'Clear all questions in category "${_categories.firstWhere((c) => c.id == _selectedCategoryId).name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final col = FirebaseFirestore.instance
        .collection('quiz')
        .doc('meta')
        .collection('questions_$_selectedCategoryId');
    final snap = await col.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All questions removed')));
    }
  }

  Future<void> _manageCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManagementPage()),
    );
    // Reload categories after returning
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Quiz Questions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _manageCategories,
            tooltip: 'Manage Categories',
          ),
        ],
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No categories found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _manageCategories,
                    child: const Text('Create Categories'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Question Category',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategoryId,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _pickAndUpload,
                    child: const Text('Import CSV for Selected Category'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'CSV format: question, option1, option2, option3, option4, correctIndex (0-based).',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Example: "What is 2+2?", "1", "2", "3", "4", 3',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: Invalid rows (missing data, invalid format) will be skipped automatically.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _clearAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear All Questions in Category'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preview (${_categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => _categories.first).name}):',
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _selectedCategoryId == null
                        ? const Center(child: Text('Select a category'))
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('quiz')
                                .doc('meta')
                                .collection('questions_$_selectedCategoryId')
                                .snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final docs = snap.data!.docs;
                              if (docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No questions in this category yet',
                                  ),
                                );
                              }
                              return ListView.builder(
                                itemCount: docs.length,
                                itemBuilder: (context, idx) {
                                  final d = docs[idx].data();
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 0,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text('${idx + 1}'),
                                      ),
                                      title: Text(d['question'] ?? ''),
                                      subtitle: Text(
                                        (d['options'] ?? []).join(' | '),
                                      ),
                                      trailing: Text(
                                        'Answer: ${d['correctIndex'] ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
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
    );
  }
}

// Category Management Page
class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _idController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (id.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID and Name are required')));
      return;
    }

    // Validate ID format (alphanumeric, underscores, hyphens only)
    if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ID must be lowercase letters, numbers, hyphens or underscores only',
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('quiz')
          .doc('meta')
          .collection('categories')
          .doc(id)
          .set({'name': name, 'description': desc});

      _nameController.clear();
      _descController.clear();
      _idController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Category added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add category: $e')));
      }
    }
  }

  Future<void> _editCategory(String id, String currentName, String currentDesc) async {
    final nameController = TextEditingController(text: currentName);
    final descController = TextEditingController(text: currentDesc);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $id (cannot be changed)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) {
      nameController.dispose();
      descController.dispose();
      return;
    }

    final newName = nameController.text.trim();
    final newDesc = descController.text.trim();

    nameController.dispose();
    descController.dispose();

    if (newName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name cannot be empty')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('quiz')
          .doc('meta')
          .collection('categories')
          .doc(id)
          .update({'name': newName, 'description': newDesc});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Delete category "$name"?\n\nThis will NOT delete the questions in this category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('quiz')
          .doc('meta')
          .collection('categories')
          .doc(id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Category deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add New Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Category ID (e.g., webdev, mobile)',
                        border: OutlineInputBorder(),
                        helperText: 'Lowercase, no spaces',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name (e.g., Web Development)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _addCategory,
                      child: const Text('Add Category'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Existing Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('quiz')
                  .doc('meta')
                  .collection('categories')
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No categories yet'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final d = docs[idx];
                    final data = d.data();
                    return ListTile(
                      title: Text(data['name'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${d.id}'),
                          if (data['description']?.isNotEmpty == true)
                            Text(data['description']),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editCategory(
                              d.id,
                              data['name'] ?? '',
                              data['description'] ?? '',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteCategory(d.id, data['name'] ?? ''),
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
    );
  }
}
