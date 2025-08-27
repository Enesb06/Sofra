// YENİ DOSYA: lib/screens/journal_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/tasted_food_model.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'add_memory_page.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late Future<List<TastedFood>> _tastedFuture;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadTastedFoods();
    journalUpdatedNotifier.addListener(_onJournalUpdate);
  }

  @override
  void dispose() {
    _pageController.dispose();
    journalUpdatedNotifier.removeListener(_onJournalUpdate);
    super.dispose();
  }

  void _onJournalUpdate() {
    if (mounted) {
      _loadTastedFoods();
    }
  }

  void _loadTastedFoods() {
    setState(() {
      _tastedFuture = DatabaseHelper.instance.getAllTastedFoods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Flavor Journal'),
        backgroundColor: Colors.teal.shade300,
      ),
      body: FutureBuilder<List<TastedFood>>(
        future: _tastedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          
          final memories = snapshot.data;
          if (memories == null || memories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Your journal is empty.\nStart by adding a new memory!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: memories.length,
                onPageChanged: (index) {
                  setState(() { _currentPage = index; });
                },
                itemBuilder: (context, index) {
                  return _JournalEntryPage(memory: memories[index]);
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    '${_currentPage + 1} / ${memories.length}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16, backgroundColor: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMemoryPage()),
          );
        },
        label: const Text('Add Memory'),
        icon: const Icon(Icons.add_a_photo_outlined),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _JournalEntryPage extends StatelessWidget {
  final TastedFood memory;
  const _JournalEntryPage({required this.memory});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMMM yyyy').format(DateTime.parse(memory.tastedDate));

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: memory.imagePath != null
                  ? Image.file(
                      File(memory.imagePath!),
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      color: Colors.white,
                      child: const Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            memory.foodName,
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'in ${memory.cityName}, on $date',
            style: GoogleFonts.patrickHand(
              fontSize: 20,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}