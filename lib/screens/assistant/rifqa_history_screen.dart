// lib/features/ask_rifqa/rifqa_history_screen.dart
//
// تفتح من شاشة «اسأل رفقة». لما المستخدمة تختار محادثة بترجّع id بتاعها
// عن طريق Navigator.pop(context, id).

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'rifqa_history_service.dart';

class RifqaHistoryScreen extends StatelessWidget {
  const RifqaHistoryScreen({super.key, required this.service});
  final RifqaHistoryService service;

  static const _cream = Color(0xFFFAF7F0);
  static const _ink = Color(0xFF1F2A24);

  String _when(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    final hm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'النهاردة $hm';
    if (diff == 1) return 'إمبارح $hm';
    return '${t.day}/${t.month}/${t.year}';
  }

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Text(body, style: const TextStyle(fontSize: 16, height: 1.6)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
                minimumSize: const Size(110, 46),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('احذفي', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          title: const Text('محادثاتي السابقة',
              style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'حذف كل المحادثات',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () async {
                if (await _confirm(context, 'حذف كل المحادثات؟',
                    'هيتم حذف كل محادثاتك مع رفقة نهائيًا.')) {
                  await service.clearAll();
                }
              },
            ),
          ],
        ),
        body: !service.isAvailable
            ? const _Empty(
                icon: Icons.lock_outline_rounded,
                title: 'سجّلي دخولك لحفظ محادثاتك',
                body: 'المحادثات بتتحفظ على حسابك بس، ومحدش غيرك يشوفها.',
              )
            : StreamBuilder<List<ConversationSummary>>(
                stream: service.watch(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return const _Empty(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'لسه مفيش محادثات',
                      body: 'أول ما تسألي رفقة، محادثتك هتظهر هنا وتقدري ترجعي لها في أي وقت.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = items[i];
                      return Dismissible(
                        key: ValueKey(c.id),
                        direction: DismissDirection.horizontal,
                        background: _swipeBg(Alignment.centerRight),
                        secondaryBackground: _swipeBg(Alignment.centerLeft),
                        confirmDismiss: (_) => _confirm(
                            context, 'حذف المحادثة؟', '«${c.title}» هتتحذف نهائيًا.'),
                        onDismissed: (_) => service.delete(c.id),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.pop(context, c.id),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: AppColors.green.withOpacity(.12)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.softGreen,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.forum_rounded,
                                        color: AppColors.green, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.w800,
                                                color: _ink)),
                                        const SizedBox(height: 3),
                                        Text(c.preview,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 13.5,
                                                height: 1.5,
                                                color: Color(0xFF6B756F))),
                                        const SizedBox(height: 4),
                                        Text(_when(c.updatedAt),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF8A948E))),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_left_rounded,
                                      color: Color(0xFF8A948E)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _swipeBg(Alignment a) => Container(
        alignment: a,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFB3261E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.green.withOpacity(.5)),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, height: 1.7, color: Color(0xFF6B756F))),
          ],
        ),
      ),
    );
  }
}