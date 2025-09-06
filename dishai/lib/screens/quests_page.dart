// GÜNCELLENMİŞ VE TAM DOSYA: lib/screens/quests_page.dart (Tıklanabilir Rozetler ve Bilgi Diyaloğu)

import 'package:flutter/material.dart';

import '../models/badge_model.dart' as app_badge;
import '../models/quest_model.dart';
import '../services/badge_service.dart';
import '../services/database_helper.dart';
import '../services/quest_service.dart';
import '../services/sync_service.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> with TickerProviderStateMixin {
  Map<String, int>? _stats;
  List<QuestProgress> _questsProgress = [];
  Set<String> _unlockedBadgeIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    journalUpdatedNotifier.addListener(_onJournalUpdate);
  }

  @override
  void dispose() {
    journalUpdatedNotifier.removeListener(_onJournalUpdate);
    super.dispose();
  }
  
  void _onJournalUpdate() {
    if (mounted) {
      _loadAllData();
    }
  }
  
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final stats = await DatabaseHelper.instance.getTastedFoodStats();
    final tastedInfo = await DatabaseHelper.instance.getTastedFoodInfoForQuests();
    final unlockedBadges = await DatabaseHelper.instance.getUnlockedBadgeIds();

    final questsProgress = <QuestProgress>[];
    for (final quest in QuestService.allQuests) {
      final progressCount = QuestService.calculateProgressForQuest(quest, tastedInfo);
      questsProgress.add(QuestProgress(quest: quest, currentProgress: progressCount));
    }

    if (mounted) {
      setState(() {
        _stats = stats;
        _questsProgress = questsProgress;
        _unlockedBadgeIds = unlockedBadges;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Achievements'),
         
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildProfileHeader(),
                  TabBar(
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(icon: Icon(Icons.flag_outlined), text: 'Quests'),
                      Tab(icon: Icon(Icons.shield_outlined), text: 'Badges'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildQuestsList(),
                        _buildBadgesGrid(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

   Widget _buildProfileHeader() {
    return Container(
      width: double.infinity, // Genişliğin tüm alanı kaplamasını sağla
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      color: Colors.grey.shade50,
      child: Column( // Ana widget'ı Row yerine Column yapıyoruz
        crossAxisAlignment: CrossAxisAlignment.center, // İçeriği ortala
        children: [
          const Text(
            'Gastronomy Explorer',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            // İstatistikleri iki yana yaslamak için MainAxisAlignment.spaceAround kullanıyoruz
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(count: _stats?['totalDishes'] ?? 0, label: 'Dishes Tasted'),
              _StatItem(count: _stats?['citiesVisited'] ?? 0, label: 'Cities Visited'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestsList() {
    if (_questsProgress.isEmpty) {
      return const Center(child: Text('No quests available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _questsProgress.length,
      itemBuilder: (context, index) {
        final progress = _questsProgress[index];
        return _QuestProgressCard(progress: progress);
      },
    );
  }

  Widget _buildBadgesGrid() {
    final allBadges = BadgeService.allBadges;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        final isUnlocked = _unlockedBadgeIds.contains(badge.id);
        return _BadgeCard(badge: badge, isUnlocked: isUnlocked);
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  const _StatItem({required this.count, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final app_badge.Badge badge;
  final bool isUnlocked;

  const _BadgeCard({required this.badge, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => _BadgeInfoDialog(badge: badge, isUnlocked: isUnlocked),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center, // Bunu kaldırıyoruz, Expanded yönetecek
        children: [
          // Rozet görselinin kaplayacağı alanı esnek hale getiriyoruz.
          Expanded(
            flex: 3, // Görsel, metne göre 3 kat daha fazla yer kaplasın
            child: AspectRatio(
              aspectRatio: 1.0, // Görselin kendisi kare olsun
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand, // Stack'in içindekiler alanı doldursun
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0), // Kenarlardan hafif boşluk
                    child: Image.asset(
                      badge.unlockedAssetPath,
                    ),
                  ),
                  if (!isUnlocked)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white.withOpacity(0.9),
                        size: 40,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Metnin kaplayacağı alanı esnek hale getiriyoruz.
          Expanded(
            flex: 2, // Metin, görsele göre 2 kat daha fazla yer kaplasın
            child: Center(
              child: Text(
                badge.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13, // Yazı boyutu hafifçe küçültüldü
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      // --- DEĞİŞİKLİKLER BURADA ---
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 5, // Gölgeyi biraz daha belirgin yap.
      shadowColor: Colors.grey.shade100.withOpacity(0.5), // Gölge rengini yumuşat.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Kenarlık rengini görevin durumuna göre akıllıca belirliyoruz.
        side: BorderSide(
          color: isCompleted ? Colors.green.shade300 : Colors.grey.shade200,
          width: isCompleted ? 2 : 1, // Tamamlanmışsa kenarlık daha kalın olsun.
        ),
      ),
      // --- BİTTİ ---
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
                        isCompleted ? Colors.green.shade400 : Theme.of(context).colorScheme.primary,
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

// --- YENİ EKLENEN WIDGET ---
// Rozetlere tıklandığında gösterilecek olan bilgilendirme diyaloğu.
class _BadgeInfoDialog extends StatelessWidget {
  final app_badge.Badge badge;
  final bool isUnlocked;

  const _BadgeInfoDialog({required this.badge, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- DEĞİŞİKLİK BURADA ---
          // Artık 'isUnlocked' kontrolü yapmıyoruz.
          // Diyalog her zaman rozetin kilidi açılmış, renkli görselini gösterir.
          Image.asset(
            badge.unlockedAssetPath,
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 20),

          // Rozet Başlığı
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Rozet Açıklaması (Nasıl kazanıldığı)
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          
          // Durum bilgisi (Kilitli veya Açık)
          if (!isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, color: Colors.grey.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Locked",
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
           if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade800, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Unlocked!",
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        )
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}