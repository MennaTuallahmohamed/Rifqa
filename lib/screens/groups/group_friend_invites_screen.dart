import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/groups/group_friend_invite_service.dart';

const _deepGreen = Color(0xFF0A4838);
const _warmCream = Color(0xFFFAF6EE);
const _gold = Color(0xFFCBAB66);

/// Admin-facing screen: invite a friend with their existing 8-digit friend code.
class GroupInviteFriendScreen extends StatefulWidget {
  const GroupInviteFriendScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  State<GroupInviteFriendScreen> createState() => _GroupInviteFriendScreenState();
}

class _GroupInviteFriendScreenState extends State<GroupInviteFriendScreen> {
  final _code = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final message = await GroupFriendInviteService.instance.inviteByFriendCode(
        widget.groupId,
        _code.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      _code.clear();
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError
          ? e.message
          : e is FirebaseException && e.code == 'permission-denied'
              ? 'الدعوة مرفوضة من Firebase. تأكد من نشر قواعد الجروبات الجديدة.'
              : 'تعذر إرسال الدعوة: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _warmCream,
          appBar: AppBar(
            title: const Text('دعوة صديق للجروب'),
            backgroundColor: _deepGreen,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded,
                          color: _deepGreen, size: 42),
                      const SizedBox(height: 12),
                      Text(widget.groupName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('أنت مشرف هذه المجموعة، ويمكنك دعوة أصدقائك باستخدام كود الصداقة الخاص بهم.'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _code,
                        maxLength: 8,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'كود الصديق (8 خانات)',
                          hintText: 'ABCD2345',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key_rounded),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _sending ? null : _send,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(_sending ? 'جاري الإرسال...' : 'إرسال الدعوة'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _deepGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'الدعوة ستظهر عند صديقك في طلبات الجروبات. لن يدخل المجموعة إلا بعد موافقته، وسيبقى عضوًا عاديًا بدون صلاحيات المشرف.',
                        style: TextStyle(height: 1.6, color: Color(0xFF63716A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Invitee-facing screen: explicitly accept or reject group invitations.
class GroupFriendInvitesScreen extends StatelessWidget {
  const GroupFriendInvitesScreen({super.key});

  Future<void> _change(BuildContext context, String id, bool accept) async {
    try {
      if (accept) {
        await GroupFriendInviteService.instance.accept(id);
      } else {
        await GroupFriendInviteService.instance.reject(id);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(accept ? 'تم الانضمام إلى المجموعة' : 'تم رفض الدعوة'),
      ));
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is StateError ? e.message : 'لم تكتمل العملية: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _warmCream,
          appBar: AppBar(
            title: const Text('دعوات الجروبات'),
            backgroundColor: _deepGreen,
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: GroupFriendInviteService.instance.myInvitations(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(child: Text('تعذر تحميل الدعوات. تحققي من اتصال Firebase.'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final invites = snap.data!.docs.where((doc) {
                final d = doc.data();
                final expiry = d['expiresAt'];
                return d['status'] == 'pending' &&
                    expiry is Timestamp &&
                    expiry.toDate().isAfter(DateTime.now());
              }).toList();
              if (invites.isEmpty) {
                return const Center(child: Text('لا توجد دعوات جديدة حاليًا'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: invites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 11),
                itemBuilder: (context, i) {
                  final doc = invites[i];
                  final data = doc.data();
                  return _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.groups_rounded, color: _deepGreen),
                          SizedBox(width: 8),
                          Text('دعوة للانضمام',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ]),
                        const SizedBox(height: 10),
                        Text('${data['groupName'] ?? 'مجموعة'}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('من: ${data['fromName'] ?? 'مشرف المجموعة'}'),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: _deepGreen),
                            onPressed: () => _change(context, doc.id, true),
                            child: const Text('قبول'),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: OutlinedButton(
                            onPressed: () => _change(context, doc.id, false),
                            child: const Text('رفض'),
                          )),
                        ]),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withValues(alpha: .26)),
        ),
        child: child,
      );
}
