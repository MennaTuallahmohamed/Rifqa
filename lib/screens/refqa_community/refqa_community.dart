import 'package:flutter/material.dart';
import 'refqa_community_data.dart';
import 'refqa_community_widgets.dart';
import 'refqa_community_create_post.dart';
import 'refqa_community_post_details.dart';
import 'refqa_community_profile.dart';

/// Entry point: Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const RefqaCommunityScreen(),
/// ));
/// All content is UI-only demo data; no Firebase writes are performed.
class RefqaCommunityScreen extends StatefulWidget {
  const RefqaCommunityScreen({super.key});

  @override
  State<RefqaCommunityScreen> createState() => _RefqaCommunityScreenState();
}

class _RefqaCommunityScreenState extends State<RefqaCommunityScreen> {
  final store = RefqaCommunityData.instance;
  final searchCtrl = TextEditingController();
  RefqaPostType? type;
  RefqaTopic topic = RefqaTopic.all;
  bool searching = false;

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(_update);
  }

  void _update() => setState(() {});

  @override
  void dispose() {
    searchCtrl.removeListener(_update);
    searchCtrl.dispose();
    super.dispose();
  }

  List<RefqaPost> _visible() {
    final q = searchCtrl.text.trim();
    return store.posts.where((post) {
      if (store.blockedAuthors.contains(post.author)) return false;
      if (type != null && post.type != type) return false;
      if (topic != RefqaTopic.all && post.topic != topic) return false;
      return q.isEmpty || post.body.contains(q) || post.author.contains(q) || post.location.contains(q);
    }).toList();
  }

  Future<void> _openPost(RefqaPost post) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => RefqaCommunityPostDetailsScreen(post: post),
    ));
  }

  Future<void> _create() async {
    final published = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder: (_) => const RefqaCommunityCreatePostScreen(),
    ));
    if (published == true && mounted) {
      refqaNotice(context, 'تمت إضافة المنشور للمعاينة؛ سيحتاج مراجعة قبل النشر الفعلي');
    }
  }

  Future<void> _report(RefqaPost post) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('سبب الإبلاغ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          for (final item in ['معلومات مضللة', 'إساءة أو مضايقة', 'إعلانات مزعجة', 'محتوى غير مناسب'])
            ListTile(title: Text(item), leading: const Icon(Icons.flag_outlined), onTap: () => Navigator.pop(ctx, item)),
          const SizedBox(height: 12),
        ]),
      ),
    );
    if (reason == null || !mounted) return;
    store.reportPost(post);
    refqaNotice(context, 'تم تسجيل البلاغ في المعاينة فقط: $reason');
  }

  Future<void> _block(RefqaPost post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حظر المستخدم'),
        content: Text('إخفاء منشورات ${post.author} من المعاينة الحالية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حظر')),
        ],
      ),
    );
    if (ok == true && mounted) {
      store.blockAuthor(post.author);
      refqaNotice(context, 'تم إخفاء منشورات المستخدم في المعاينة');
    }
  }

  void _bottom(int i) {
    if (i == 3) return;
    if (i == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    refqaNotice(context, 'افتحي هذا القسم من القائمة الرئيسية في رفقة');
  }

  @override
  Widget build(BuildContext context) => RefqaRoot(
        child: Scaffold(
          body: Column(children: [
            RefqaTopBar(
              title: 'مجتمع رفقة',
              subtitle: 'منصة تواصل بين ضيوف الرحمن',
              showBack: false,
              leading: IconButton(
                tooltip: 'الملف والمجتمع',
                onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => const RefqaCommunityProfileScreen(),
                )),
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
              ),
              trailing: IconButton(
                tooltip: 'بحث',
                onPressed: () => setState(() => searching = !searching),
                icon: const Icon(Icons.search_rounded, color: Colors.white),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: store,
                builder: (context, _) => Stack(children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    children: [
                      const SizedBox(height: 10),
                      if (searching) ...[
                        TextField(
                          controller: searchCtrl,
                          autofocus: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'ابحثي في الأسئلة والنصائح والمعلومات',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      RefqaTypeStrip(selected: type, onSelected: (v) => setState(() => type = v)),
                      const SizedBox(height: 12),
                      RefqaWhitePanel(
                        padding: const EdgeInsets.all(10),
                        child: InkWell(
                          onTap: _create,
                          child: Row(children: [
                            const RefqaAvatar(path: '${RefqaCommunityData.assetRoot}avatar_female.jpg', radius: 18),
                            const SizedBox(width: 9),
                            const Expanded(child: Text('اكتبي سؤالك أو نصيحتك أو معلوماتك...', style: TextStyle(fontSize: 12, color: RefqaColors.muted))),
                            const Icon(Icons.image_outlined, color: RefqaColors.muted),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      RefqaTopicStrip(current: topic, onChanged: (v) => setState(() => topic = v)),
                      const SizedBox(height: 10),
                      for (final post in _visible())
                        RefqaPostCard(
                          key: ValueKey(post.id),
                          post: post,
                          onDetails: () => _openPost(post),
                          onLike: () => store.toggleLike(post),
                          onFriend: () {
                            store.requestFriend(post.author);
                            refqaNotice(context, store.requestedFriends.contains(post.author)
                                ? 'تم إرسال طلب صداقة تجريبي إلى ${post.author}'
                                : 'تم إلغاء طلب الصداقة التجريبي');
                          },
                          onReport: () => _report(post),
                          onBlock: () => _block(post),
                        ),
                      if (_visible().isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 45),
                          child: Column(children: [
                            const Icon(Icons.search_off_rounded, size: 55, color: RefqaColors.muted),
                            const SizedBox(height: 12),
                            const Text('لا توجد منشورات تطابق البحث', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextButton(onPressed: () => setState(() {
                              type = null;
                              topic = RefqaTopic.all;
                              searchCtrl.clear();
                            }), child: const Text('إزالة الفلاتر')),
                          ]),
                        ),
                    ],
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: FloatingActionButton(
                      heroTag: 'refqa-community-compose',
                      onPressed: _create,
                      backgroundColor: RefqaColors.teal,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.add_rounded, size: 31),
                    ),
                  ),
                ]),
              ),
            ),
            RefqaBottomNavigation(onTap: _bottom),
          ]),
        ),
      );

}
