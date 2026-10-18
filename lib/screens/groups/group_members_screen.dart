import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/groups/group_service.dart';
import 'groups_screen.dart' show friendlyError, BusyMixin;
import 'rifqa_chat_theme.dart';

class GroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  const GroupMembersScreen(
      {super.key, required this.groupId, required this.groupName});
  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen>
    with BusyMixin<GroupMembersScreen> {
  final service = GroupService.instance;
  String get myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<bool> confirm(String title, String body, String ok) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RifqaChat.ivory,
      appBar: AppBar(
          backgroundColor: RifqaChat.deep,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text('أعضاء ${widget.groupName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.group(widget.groupId),
        builder: (context, gs) {
          if (gs.hasError) return Center(child: Text(friendlyError(gs.error!)));
          if (!gs.hasData)
            return const Center(child: CircularProgressIndicator());
          final g = gs.data!.data();
          if (g == null) return const Center(child: Text('المجموعة غير متاحة'));
          final memberIds = List<String>.from(g['memberIds'] ?? []);
          final adminIds = List<String>.from(g['adminIds'] ?? []);
          final ownerId = g['ownerId']?.toString() ?? '';
          final iAmAdmin = adminIds.contains(myUid);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.members(widget.groupId),
            builder: (context, ms) {
              final names = <String, String>{};
              for (final d in ms.data?.docs ?? const []) {
                names[d.id] = d.data()['userName']?.toString() ?? 'عضو';
              }
              // المشرف الأساسي ثم المشرفون ثم الأعضاء
              int rank(String id) =>
                  id == ownerId ? 0 : (adminIds.contains(id) ? 1 : 2);
              final sorted = [...memberIds]
                ..sort((a, b) => rank(a).compareTo(rank(b)));

              return Column(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('${memberIds.length} عضو',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final id = sorted[i];
                      final isOwner = id == ownerId;
                      final isAdmin = adminIds.contains(id);
                      final name = names[id] ?? 'عضو';
                      final role = isOwner
                          ? 'المشرف الأساسي'
                          : (isAdmin ? 'مشرف' : 'عضو');
                      final canManage = iAmAdmin && !isAdmin && id != myUid;
                      return Card(
                          color: RifqaChat.paper,
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: RifqaChat.border)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            leading: RifqaPhotoAvatar(
                                size: 45,
                                variant:
                                    name.runes.fold<int>(0, (a, b) => a + b) %
                                        5),
                            title: Text(id == myUid ? '$name (أنا)' : name),
                            subtitle: Text(role),
                            trailing: canManage
                                ? PopupMenuButton<String>(
                                    enabled: !busy,
                                    onSelected: (v) async {
                                      if (v == 'promote') {
                                        if (await confirm(
                                            'ترقية إلى مشرف؟',
                                            '$name هيقدر ينشئ دعوات ويوافق على الطلبات ويغلق الاستغاثات.',
                                            'ترقية')) {
                                          await run(() =>
                                              service.promoteToAdmin(
                                                  widget.groupId, id));
                                        }
                                      } else if (v == 'remove') {
                                        if (await confirm(
                                            'إزالة العضو؟',
                                            '$name هيخرج من المجموعة ولن يرى أي محتوى فيها.',
                                            'إزالة')) {
                                          await run(() => service.removeMember(
                                              widget.groupId, id));
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'promote',
                                          child: Text('ترقية إلى مشرف')),
                                      PopupMenuItem(
                                          value: 'remove',
                                          child: Text('إزالة من المجموعة')),
                                    ],
                                  )
                                : null,
                          ));
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: iAmAdmin
                        ? const Text(
                            'المشرف لا يستطيع مغادرة المجموعة في هذه النسخة.',
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center)
                        : SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red),
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      if (!await confirm(
                                          'مغادرة المجموعة؟',
                                          'هتحتاجي كود دعوة جديد وموافقة المشرف عشان ترجعي.',
                                          'مغادرة')) {
                                        return;
                                      }
                                      await run(() async {
                                        await service
                                            .leaveGroup(widget.groupId);
                                        if (!mounted) return;
                                        navigator.popUntil((r) => r.isFirst);
                                      });
                                    },
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text('مغادرة المجموعة'),
                            ),
                          ),
                  ),
                ),
              ]);
            },
          );
        },
      ),
    );
  }
}
