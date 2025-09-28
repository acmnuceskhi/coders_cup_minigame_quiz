import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

class AdminQuestionsPage extends StatefulWidget {
  const AdminQuestionsPage({super.key});

  @override
  State<AdminQuestionsPage> createState() => _AdminQuestionsPageState();
}

class _AdminQuestionsPageState extends State<AdminQuestionsPage> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (res == null) return;
    final fileBytes = res.files.single.bytes;
    final content = utf8.decode(fileBytes!);
    final rows = const CsvToListConverter().convert(content, eol: '\n');
    // Expect rows: question, option1, option2, option3, option4, correctIndex
    setState(() => _isUploading = true);
    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance.collection('quiz').doc('meta').collection('questions');
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final q = row[0].toString();
      final opts = <String>[];
      for (var j = 1; j <= 4 && j < row.length; j++) {
        opts.add(row[j].toString());
      }
      final correct = (row.length > 5) ? int.tryParse(row[5].toString()) ?? 0 : 0;
      final doc = col.doc();
      batch.set(doc, {
        'question': q,
        'options': opts,
        'correctIndex': correct,
      });
    }
    try {
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Questions uploaded')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _clearAll() async {
    final col = FirebaseFirestore.instance.collection('quiz').doc('meta').collection('questions');
    final snap = await col.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All questions removed')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Quiz Questions')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: _isUploading ? null : _pickAndUpload, child: const Text('Import CSV')),
            const SizedBox(height: 8),
            const Text(
              'CSV format: question, option1, option2, option3, option4, correctIndex (0-based).',
              style: TextStyle(fontSize: 13,),
            ),
            const SizedBox(height: 6),
            const Text(
              'Example: "What is 2+2?", "1", "2", "3", "4", 3',
              style: TextStyle(fontSize: 12,),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _clearAll, child: const Text('Clear all questions')),
            const SizedBox(height: 12),
            const Text('Preview:') ,
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('quiz').doc('meta').collection('questions').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final d = docs[idx].data();
                      return ListTile(
                        title: Text(d['question'] ?? ''),
                        subtitle: Text((d['options'] ?? []).join(' | ')),
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
