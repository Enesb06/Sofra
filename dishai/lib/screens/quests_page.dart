// YENİ DOSYA: lib/screens/quests_page.dart

import 'package:flutter/material.dart';

import '../models/quest_model.dart';
import '../services/database_helper.dart';
import '../services/quest_service.dart';
import '../services/sync_service.dart'; // Anlık güncelleme için

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  // Tüm görevlerin ilerlemesini tutacak olan Future
  late Future<List<QuestProgress>> _questsProgressFuture;

  @override
  void initState() {
    super.initState();
    // Sayfa ilk açıldığında görev durumunu yükle
    _questsProgressFuture = _loadQuestsProgress();
    // Journal güncellendiğinde sayfayı yenilemek için dinleyici ekle
    journalUpdatedNotifier.addListener(_onJournalUpdate);
  }

  @override
  void dispose() {
    // Sayfa kapandığında dinleyiciyi kaldır
    journalUpdatedNotifier.removeListener(_onJournalUpdate);
    super.dispose();
  }
  
  void _onJournalUpdate() {
    // Sinyal geldiğinde, Future'ı yeniden tetikleyerek sayfayı yenile
    if (mounted) {
      setState(() {
        _questsProgressFuture = _loadQuestsProgress();
      });
    }
  }
  
Future<List<QuestProgress>> _loadQuestsProgress() async {
    // 1. Veritabanından hem şehir hem kategori bilgilerini içeren listeyi çek.
    final List<TastedFoodInfo> tastedInfo = await DatabaseHelper.instance.getTastedFoodInfoForQuests();
    final List<QuestProgress> progressList = [];

    // 2. Kütüphanedeki TÜM görevler için döngü başlat.
    for (final quest in QuestService.allQuests) {
      // 3. Her bir görevin ilerlemesini QuestService'in merkezi metoduyla hesapla.
      final int progressCount = QuestService.calculateProgressForQuest(quest, tastedInfo);
      
      // 4. Hesaplanan ilerlemeyi listeye ekle.
      progressList.add(QuestProgress(quest: quest, currentProgress: progressCount));
    }

    return progressList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flavor Quests'),
        backgroundColor: Colors.purple.shade300,
      ),
      body: FutureBuilder<List<QuestProgress>>(
        future: _questsProgressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load quests.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No quests available.'));
          }

          final questsProgress = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: questsProgress.length,
            itemBuilder: (context, index) {
              final progress = questsProgress[index];
              return _QuestProgressCard(progress: progress);
            },
          );
        },
      ),
    );
  }
}

// Görevleri listeleyen kart widget'ı
class _QuestProgressCard extends StatelessWidget {
  final QuestProgress progress;
  const _QuestProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final double percentage = progress.quest.totalTarget == 0
        ? 0
        : progress.currentProgress / progress.quest.totalTarget;
    final bool isCompleted = progress.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCompleted ? 1 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted ? Colors.green.shade300 : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              progress.quest.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.grey.shade700 : Colors.black87,
                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              progress.quest.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green.shade400 : Colors.purple.shade400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (isCompleted)
                  Icon(Icons.check_circle, color: Colors.green.shade500)
                else
                  Text(
                    '${progress.currentProgress} / ${progress.quest.totalTarget}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}