import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import 'direct_chat_screen.dart';
import 'friend_service.dart';
import 'groups_screen.dart'
    show
        friendlyError,
        BusyMixin,
        StateView,
        InputSheet,
        GroupAvatar,
        DottedTicket,
        FadeSlideIn,
        PulseDot,
        softOf,
        mutedOf,
        inkOf,
        isDark,
        surfaceOf,
        lineOf,
        scaffoldOf;

/// زر «الأصدقاء» في هيدر رفقتي، مع نقطة حمراء عند وجود طلبات جديدة.
class FriendsEntryButton extends StatelessWidget {
  const FriendsEntryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FriendService.instance.incoming(),
      builder: (context, snap) {
        final n = snap.data?.docs.length ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text('الأصدقاء',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              if (n > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: AppColors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text('$n',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

enum _FriendsTab { all, requests }

class _FriendsScreenState extends State<FriendsScreen> with BusyMixin<FriendsScreen> {
  final svc = FriendService.instance;
  final _searchController = TextEditingController();
  late Future<String> _code = svc.myCode();
  _FriendsTab _tab = _FriendsTab.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> addFriend() => run(() async {
        final code = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const InputSheet(
            title: 'إضافة صديق بالكود',
            subtitle: 'اطلب من صديقك كود الصداقة الخاص به (8 خانات) وأدخله هنا.',
            hint: 'كود الصديق',
            action: 'إرسال الطلب',
            icon: Icons.person_add_alt_1_outlined,
            isCode: true,
            maxLength: 8,
          ),
        );
        if (code == null || code.trim().isEmpty) return;
        toast(await svc.addByCode(code));
      });

  Future<bool> confirm(String title, String body, String ok) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ok)),
        ],
      ),
    );
    return r == true;
  }

  // ---------------------------------------------------------------- header
  Widget codeCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFC29B40), Color(0xFF9A7A2E)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: const Color(0xFFC29B40).withValues(alpha: .32), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: FutureBuilder<String>(
        future: _code,
        builder: (context, s) {
          Widget inner;
          if (s.hasError) {
            inner = Column(children: [
              Text(friendlyError(s.error!),
                  style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => setState(() => _code = svc.myCode()),
                child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
              ),
            ]);
          } else if (!s.hasData) {
            inner = const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          } else {
            final code = s.data!;
            inner = Column(children: [
              DottedTicket(code: code, colors: const [Color(0xFFD4AE55), Color(0xFF8F701F)]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        toast('تم نسخ كودك');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('نسخ'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Share.share('كود الصداقة الخاص بي في رِفقة: $code'),
                          child: const Center(
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.ios_share_rounded, size: 18, color: Color(0xFF9A7A2E)),
                              SizedBox(width: 8),
                              Text('مشاركة',
                                  style: TextStyle(color: Color(0xFF9A7A2E), fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ]);
          }
          return Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.badge_outlined, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('كود الصداقة الخاص بك',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ]),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('شاركه مع من تحب ليضيفك صديقًا',
                  style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 12.5)),
            ),
            const SizedBox(height: 14),
            inner,
          ]);
        },
      ),
    );
  }

  Widget _tabs() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.incoming(),
      builder: (context, snap) {
        final n = snap.data?.docs.length ?? 0;
        Widget chip(String label, _FriendsTab t, {int? badge}) {
          final selected = _tab == t;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _tab = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: selected ? Colors.white : mutedOf(context))),
                  if (badge != null && badge > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : AppColors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$badge',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: selected ? AppColors.green : Colors.white)),
                    ),
                  ],
                ]),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark(context) ? Colors.white10 : const Color(0xFFF0F3F1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            chip('كل الأصدقاء', _FriendsTab.all),
            chip('الطلبات', _FriendsTab.requests, badge: n),
          ]),
        );
      },
    );
  }

  Widget sectionTitle(String text, int count, {IconData? icon}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 17, color: mutedOf(context)), const SizedBox(width: 6)],
          Text(text,
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: inkOf(context))),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: softOf(context, AppColors.green, AppColors.softGreen),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: const TextStyle(
                      color: AppColors.green, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
        ]),
      );

  // ---------------------------------------------------------------- cards
  Widget _requestCard({
    required String id,
    required String name,
    required Widget trailing,
    required String subtitle,
    Color? subtitleColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark(context) ? Colors.black.withValues(alpha: .22) : Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        GroupAvatar(name, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: inkOf(context))),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12.5, color: subtitleColor ?? mutedOf(context))),
          ]),
        ),
        trailing,
      ]),
    );
  }

  Widget incomingSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.incoming(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: StateView(
              icon: Icons.mark_email_read_outlined,
              title: 'لا توجد طلبات جديدة',
              message: 'هتظهر هنا طلبات الصداقة اللي حد يبعتها لك.',
            ),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionTitle('طلبات صداقة جديدة', docs.length, icon: Icons.inbox_outlined),
          ...docs.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final m = d.data();
            final name = m['fromName']?.toString() ?? 'عضو';
            final fromUid = m['fromUid']?.toString() ?? '';
            return FadeSlideIn(
              index: i,
              child: _requestCard(
                id: d.id,
                name: name,
                subtitle: 'يريد أن يصبح صديقك',
                subtitleColor: const Color(0xFF8A6B1E),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Material(
                    color: softOf(context, AppColors.red, AppColors.softRed),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: busy ? null : () => run(() => svc.deleteRequest(d.id)),
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(Icons.close_rounded, color: AppColors.red, size: 19),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [AppColors.green, AppColors.greenDark]),
                      boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: busy
                            ? null
                            : () => run(() async {
                                  await svc.accept(d.id, fromUid, name);
                                  toast('أصبحت صديقًا لـ $name 🎉');
                                }),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 19),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            );
          }),
        ]);
      },
    );
  }

  Widget outgoingSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.outgoing(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionTitle('طلبات أرسلتها', docs.length, icon: Icons.schedule_send_outlined),
          ...docs.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final name = d.data()['toName']?.toString() ?? 'عضو';
            return FadeSlideIn(
              index: i,
              child: _requestCard(
                id: d.id,
                name: name,
                subtitle: 'بانتظار القبول',
                trailing: TextButton(
                  onPressed: busy ? null : () => run(() => svc.deleteRequest(d.id)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
        ]);
      },
    );
  }

  Widget _searchField() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lineOf(context)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحثي عن صديقة',
              hintStyle: TextStyle(color: mutedOf(context), fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: mutedOf(context)),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded, size: 18, color: mutedOf(context)),
                      onPressed: () => setState(_searchController.clear),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      );

  Widget friendsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.friends(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(friendlyError(snap.error!), textAlign: TextAlign.center),
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: AppColors.green)),
          );
        }
        final docs = snap.data!.docs;
        final query = _searchController.text.trim().toLowerCase();
        final filteredDocs = docs.where((doc) {
          final name = doc.data()['name']?.toString().toLowerCase() ?? '';
          return name.contains(query);
        }).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionTitle('أصدقائي', docs.length, icon: Icons.diversity_1_rounded),
          if (docs.length >= 4) _searchField(),
          if (docs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: StateView(
                icon: Icons.diversity_1_rounded,
                title: 'لسه مفيش أصدقاء',
                message: 'شارك كودك مع من تحب، أو أدخل كود صديق لإرسال طلب صداقة.',
              ),
            )
          else if (filteredDocs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(child: Text('مفيش صديقة بالاسم ده')),
            )
          else
            ...filteredDocs.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final name = d.data()['name']?.toString() ?? 'صديق';
              return FadeSlideIn(
                index: i,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: surfaceOf(context),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: isDark(context) ? Colors.black.withValues(alpha: .22) : Colors.black.withValues(alpha: .05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => DirectChatScreen(friendUid: d.id, friendName: name),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          Stack(children: [
                            GroupAvatar(name, size: 48),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: surfaceOf(context), shape: BoxShape.circle),
                                child: const PulseDot(color: AppColors.green, size: 10),
                              ),
                            ),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: inkOf(context))),
                              const SizedBox(height: 2),
                              Text('صديق', style: TextStyle(color: mutedOf(context), fontSize: 12.5)),
                            ]),
                          ),
                          Material(
                            color: softOf(context, AppColors.green, AppColors.softGreen),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => DirectChatScreen(friendUid: d.id, friendName: name),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.green, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          PopupMenuButton<String>(
                            enabled: !busy,
                            icon: Icon(Icons.more_vert_rounded, color: mutedOf(context)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (v) async {
                              if (v == 'remove' &&
                                  await confirm('إزالة الصديق؟',
                                      'سيتم إزالتك من قائمة $name وإزالته من قائمتك.', 'إزالة')) {
                                await run(() => svc.removeFriend(d.id));
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'remove',
                                  child: ListTile(
                                      leading: Icon(Icons.person_remove_outlined, color: AppColors.red),
                                      title: Text('إزالة من الأصدقاء', style: TextStyle(color: AppColors.red)),
                                      contentPadding: EdgeInsets.zero)),
                            ],
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('الأصدقاء', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: [AppColors.green, AppColors.greenDark]),
          boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: .4), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: busy ? null : addFriend,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('إضافة بالكود', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          codeCard(),
          _tabs(),
          if (_tab == _FriendsTab.requests) ...[
            incomingSection(),
            outgoingSection(),
          ] else
            friendsSection(),
        ],
      ),
    );
  }
}