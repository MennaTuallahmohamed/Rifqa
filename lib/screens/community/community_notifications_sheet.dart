import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/community/community_service.dart';

// Community V8: real Firestore inbox, not placeholder content.
// Names and activities are taken only from authenticated activity documents.
class CommunityNotificationsSheet extends StatefulWidget {
  const CommunityNotificationsSheet({
    super.key,
    required this.onOpenPost,
    required this.onOpenFriends,
  });

  final void Function(String postId) onOpenPost;
  final VoidCallback onOpenFriends;

  @override
  State<CommunityNotificationsSheet> createState() =>
      _CommunityNotificationsSheetState();
}

class _CommunityNotificationsSheetState
    extends State<CommunityNotificationsSheet> {
  static const Color green = Color(0xFF075246);
  static const Color teal = Color(0xFF008B79);
  static const Color gold = Color(0xFFCB9C3F);
  static const Color cream = Color(0xFFFBF9F2);
  static const Color ink = Color(0xFF1D3934);
  static const Color muted = Color(0xFF778882);
  static const Color mint = Color(0xFFE8F5EE);
  static const Color red = Color(0xFFE05268);

  final CommunityService _service = CommunityService.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      _service.myReplyNotifications();
  String _filter = 'الكل';
  bool _marking = false;

  static const _filters = <String>[
    'الكل', 'غير المقروء', 'التعليقات', 'الإعجابات', 'الصداقات',
  ];

  bool _matches(Map<String, dynamic> data) {
    final kind = data['kind']?.toString() ?? '';
    switch (_filter) {
      case 'غير المقروء':
        return data['read'] != true;
      case 'التعليقات':
        return kind == 'comment' || kind == 'reply';
      case 'الإعجابات':
        return kind == 'post_like' || kind == 'comment_like' ||
            kind == 'post_dislike';
      case 'الصداقات':
        return kind == 'friend_request';
      default:
        return true;
    }
  }

  String _title(Map<String, dynamic> data) {
    switch (data['kind']) {
      case 'post_like':
        return 'أعجب بمنشورك';
      case 'post_dislike':
        return 'تفاعل مع منشورك';
      case 'comment_like':
        return 'أعجب بتعليقك';
      case 'reply':
        return 'ردّ على تعليقك';
      case 'friend_request':
        return 'أرسل لك طلب صداقة';
      default:
        return 'علّق على منشورك';
    }
  }

  String _preview(Map<String, dynamic> data) {
    final body = data['body']?.toString().trim() ?? '';
    if (body.isNotEmpty) return '«$body»';
    switch (data['kind']) {
      case 'friend_request':
        return 'اضغطي لعرض طلب الصداقة';
      case 'post_like':
        return 'تفاعل جديد مع منشورك';
      case 'comment_like':
        return 'تفاعل جديد مع تعليقك';
      default:
        return 'تفاعل جديد في مجتمع رفقة';
    }
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'reply':
        return Icons.reply_rounded;
      case 'post_like':
      case 'comment_like':
        return Icons.favorite_rounded;
      case 'friend_request':
        return Icons.person_add_alt_1_rounded;
      case 'post_dislike':
        return Icons.thumb_down_alt_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Color _iconColor(String kind) =>
      kind == 'post_like' || kind == 'comment_like' ? red : green;

  DateTime? _createdAt(Map<String, dynamic> data) {
    final stamp = data['createdAt'];
    return stamp is Timestamp ? stamp.toDate().toLocal() : null;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _groupFor(Map<String, dynamic> data) {
    final date = _createdAt(data);
    if (date == null) return 'اليوم';
    final today = DateTime.now();
    if (_sameDate(date, today)) return 'اليوم';
    if (_sameDate(date, today.subtract(const Duration(days: 1)))) {
      return 'أمس';
    }
    final todayStart = DateTime(today.year, today.month, today.day);
    if (date.isAfter(todayStart.subtract(const Duration(days: 7)))) {
      return 'هذا الأسبوع';
    }
    return 'الأقدم';
  }

  String _time(Map<String, dynamic> data) {
    final date = _createdAt(data);
    if (date == null) return 'الآن';
    final diff = DateTime.now().difference(date);
    if (diff.isNegative || diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24 && _sameDate(date, DateTime.now())) {
      return 'منذ ${diff.inHours} ساعة';
    }
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'م' : 'ص';
    final formattedTime = '$hour:$minute $amPm';
    if (_groupFor(data) == 'أمس') return 'أمس · $formattedTime';
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} · $formattedTime';
  }

  Future<void> _markAllRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final unread = docs.where((d) => d.data()['read'] != true).toList();
    if (unread.isEmpty || _marking) return;
    setState(() => _marking = true);
    try {
      // 100 notifications max. Use one atomic write batch, allowed by V7 rules.
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      _error('تعذر تحديد الإشعارات كمقروءة: $e');
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _open(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    if (data['read'] != true) {
      try {
        await _service.markReplyRead(doc.id);
      } catch (e) {
        _error('تعذر تحديث حالة الإشعار: $e');
      }
    }
    if (!mounted) return;
    final friend = data['kind'] == 'friend_request';
    final postId = data['postId']?.toString() ?? '';
    Navigator.of(context).pop();
    if (friend) {
      widget.onOpenFriends();
    } else if (postId.isNotEmpty) {
      widget.onOpenPost(postId);
    }
  }

  Widget _notification(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final unread = data['read'] != true;
    final kind = data['kind']?.toString() ?? 'comment';
    final who = (data['senderName'] ?? 'عضو رفقة').toString().trim();
    final initials = who.isEmpty ? 'ر' : who.substring(0, 1).toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: unread ? mint : Colors.white,
        borderRadius: BorderRadius.circular(19),
        elevation: unread ? 0 : .5,
        child: InkWell(
          onTap: () => _open(doc),
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 14),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFD4E9DD),
                  child: Text(initials,
                    style: const TextStyle(color: green,
                      fontSize: 19, fontWeight: FontWeight.w800)),
                ),
                Positioned(bottom: -2, left: -2,
                  child: CircleAvatar(radius: 10,
                    backgroundColor: Colors.white,
                    child: Icon(_icon(kind), size: 14,
                      color: _iconColor(kind))),
                ),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '$who ',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                      TextSpan(text: _title(data),
                        style: TextStyle(fontWeight: unread
                          ? FontWeight.w600 : FontWeight.w400)),
                    ]),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ink, fontSize: 13.2,
                      height: 1.45),
                  ),
                  const SizedBox(height: 3),
                  Text(_preview(data),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 12,
                      height: 1.35)),
                  const SizedBox(height: 5),
                  Text(_time(data),
                    style: TextStyle(color: unread ? teal : muted,
                      fontSize: 11, fontWeight: unread
                        ? FontWeight.w700 : FontWeight.w400)),
                ],
              )),
              const SizedBox(width: 6),
              Icon(_icon(kind), size: 22, color: _iconColor(kind)),
              const SizedBox(width: 5),
              const Icon(Icons.chevron_left_rounded, size: 21, color: muted),
              if (unread) ...[
                const SizedBox(width: 4),
                const CircleAvatar(radius: 4.2, backgroundColor: gold),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _filtersRow() => SizedBox(height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: _filters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 7),
      itemBuilder: (context, i) {
        final current = _filters[i];
        final selected = current == _filter;
        return ChoiceChip(
          label: Text(current),
          showCheckmark: false,
          selected: selected,
          selectedColor: green,
          backgroundColor: const Color(0xFFF0F0EA),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          labelStyle: TextStyle(
            color: selected ? Colors.white : ink,
            fontSize: 12.2,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500),
          onSelected: (_) => setState(() => _filter = current),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FractionallySizedBox(
        heightFactor: .91,
        child: Container(
          decoration: const BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: SafeArea(top: false,
            child: Column(children: [
              const SizedBox(height: 13),
              Container(width: 44, height: 5,
                decoration: BoxDecoration(color: const Color(0xFF8F9591),
                  borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 20),
              const Text('إشعارات المجتمع',
                style: TextStyle(fontSize: 23,
                  fontWeight: FontWeight.w900, color: green)),
              const SizedBox(height: 16),
              Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text('تعذر عرض الإشعارات. تأكدي من نشر قواعد Firestore.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ink))));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: teal));
                  }
                  final all = snapshot.data!.docs;
                  final unreadCount = all.where((d) => d.data()['read'] != true).length;
                  final visible = all.where((d) => _matches(d.data())).toList();
                  final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
                  for (final name in const ['اليوم', 'أمس', 'هذا الأسبوع', 'الأقدم']) {
                    grouped[name] = [];
                  }
                  for (final doc in visible) {
                    grouped[_groupFor(doc.data())]!.add(doc);
                  }
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: _filtersRow(),
                    ),
                    const SizedBox(height: 7),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: Row(children: [
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: mint,
                              borderRadius: BorderRadius.circular(15)),
                            child: Text('$unreadCount غير مقروء',
                              style: const TextStyle(fontSize: 11,
                                color: green, fontWeight: FontWeight.w700))),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: unreadCount == 0 || _marking
                              ? null : () => _markAllRead(all),
                          icon: const Icon(Icons.done_all_rounded, size: 17),
                          label: Text(_marking ? 'جاري التحديث...'
                            : 'تحديد الكل كمقروء'),
                          style: TextButton.styleFrom(
                            foregroundColor: green,
                            textStyle: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                    Expanded(child: visible.isEmpty
                      ? Center(child: Column(
                          mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.notifications_none_rounded,
                            size: 64, color: teal),
                          const SizedBox(height: 14),
                          Text(all.isEmpty ? 'مفيش إشعارات لسه'
                            : 'مفيش إشعارات في القسم ده',
                            style: const TextStyle(color: muted,
                              fontSize: 15)),
                        ]))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(15, 9, 15, 30),
                          children: [
                            for (final entry in grouped.entries)
                              if (entry.value.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
                                  child: Text(entry.key,
                                    style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w900,
                                      color: ink))),
                                for (final doc in entry.value) _notification(doc),
                              ],
                          ],
                        )),
                  ]);
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
