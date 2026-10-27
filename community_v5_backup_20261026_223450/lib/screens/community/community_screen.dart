import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/community/community_service.dart';
import '../groups/friends_screen.dart';

class _C {
  static const forest = Color(0xFF075246);
  static const deep = Color(0xFF043D34);
  static const teal = Color(0xFF008B79);
  static const gold = Color(0xFFC49D58);
  static const ink = Color(0xFF1D3934);
  static const muted = Color(0xFF778882);
  static const cream = Color(0xFFFBF9F2);
  static const jade = Color(0xFFE6F3ED);
  static const border = Color(0xFFE7ECE6);
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _svc = CommunityService.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _feed = _svc.latest();
  final _search = TextEditingController();
  bool _searchOpen = false;
  String _category = 'الكل';
  bool _mine = false;

  @override
  void initState() {
    super.initState();
    _refreshVerification();
  }

  Future<void> _refreshVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      // Offline users still see the appropriate sign-in/retry state.
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is StateError
        ? error.message
        : error is FirebaseException && error.code == 'permission-denied'
            ? 'ليس لديك صلاحية. تأكدي من تسجيل الدخول وتأكيد البريد ومن نشر قواعد Firestore.'
            : error is FirebaseException
                ? (error.message ?? error.code)
                : 'حدث خطأ: $error';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _compose() async {
    try {
      _svc.member;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: _C.cream,
        builder: (_) => const _Composer(),
      );
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final eligible = user != null && !user.isAnonymous && user.emailVerified;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _C.cream,
        // Deliberately no bottomNavigationBar: this screen is pushed from Home.
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6F8F0), _C.cream, Color(0xFFF0F6F1)],
            ),
          ),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: eligible ? _feed : null,
            builder: (context, snap) {
              final search = _search.text.trim().toLowerCase();
              final docs = (snap.data?.docs ?? [])
                  .where((doc) {
                    final d = doc.data();
                    if (d['isHidden'] == true) return false;
                    if (_category != 'الكل' && d['category'] != _category) {
                      return false;
                    }
                    if (_mine && d['authorId'] != user?.uid) return false;
                    return search.isEmpty ||
                        '${d['body']} ${d['authorName']} ${d['location']}'
                            .toLowerCase()
                            .contains(search);
                  })
                  .toList();
              return RefreshIndicator(
                color: _C.teal,
                onRefresh: () async {
                  if (eligible) {
                    await _svc.posts.limit(1).get(const GetOptions(source: Source.server));
                  }
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _hero()),
                    if (_searchOpen)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                          child: TextField(
                            controller: _search,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'ابحثي في مجتمع رفقة...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _search.clear()),
                                icon: const Icon(Icons.close),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(child: _composerEntry()),
                    SliverToBoxAdapter(child: _filters()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(children: [
                          const Icon(Icons.auto_awesome, color: _C.gold, size: 17),
                          const SizedBox(width: 8),
                          Text(_mine ? 'منشوراتي' : 'تجارب وأسئلة رفاق الرحلة',
                              style: const TextStyle(
                                  color: _C.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                          const Spacer(),
                          if (docs.isNotEmpty)
                            Text('${docs.length} منشور',
                                style: const TextStyle(color: _C.muted)),
                        ]),
                      ),
                    ),
                    if (!eligible)
                      SliverToBoxAdapter(
                        child: _notice('المجتمع مخصص للحسابات مؤكدة البريد',
                            'سجّلي الدخول وأكّدي بريدك الإلكتروني من شاشة الحساب، ثم افتحي المجتمع.'),
                      )
                    else if (snap.hasError)
                      SliverToBoxAdapter(
                        child: _notice('تعذر تحميل المنشورات',
                            'راجعي الاتصال وقواعد Firestore. ${snap.error}'),
                      )
                    else if (!snap.hasData)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(
                            child: CircularProgressIndicator(color: _C.teal),
                          ),
                        ),
                      )
                    else if (docs.isEmpty)
                      SliverToBoxAdapter(
                        child: _notice('لسه مفيش منشورات هنا',
                            'كوني أول واحدة تسأل أو تشارك نصيحة مع ضيوف الرحمن.'),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 95),
                        sliver: SliverList.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, i) => _PostCard(
                            key: ValueKey(docs[i].id),
                            doc: docs[i],
                            onError: _showError,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: _C.teal,
          foregroundColor: Colors.white,
          tooltip: 'إضافة منشور',
          onPressed: _compose,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add_rounded, size: 31),
        ),
      ),
    );
  }

  Widget _hero() => Container(
        height: 225,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(31)),
          gradient: LinearGradient(colors: [_C.forest, _C.deep]),
        ),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/rifqa_profile/makkah.jpg', fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xE8045548), Color(0xDF034438), Color(0xB900413A)],
              ),
            ),
          ),
          Positioned(
            right: -22,
            bottom: -34,
            child: Icon(Icons.mosque_rounded,
                size: 190, color: Colors.white.withValues(alpha: .06)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 20),
              child: Column(children: [
                Row(children: [
                  IconButton.filledTonal(
                    tooltip: 'الرجوع للرئيسية',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .17),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
                  ),
                  const Spacer(),
                  const Text('مجتمع رِفقة',
                      style: TextStyle(color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.w900)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'بحث',
                    onPressed: () => setState(() => _searchOpen = !_searchOpen),
                    icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                  ),
                ]),
                const Spacer(),
                const Text('معًا في رحلة تطمئن لها القلوب',
                    style: TextStyle(color: Color(0xFFF5E4BD), fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('اسألي، شاركي تجربتك، وساعدي رفاق الرحلة',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFE0F0E8), fontSize: 12)),
                const SizedBox(height: 13),
                Container(width: 50, height: 3,
                    decoration: BoxDecoration(color: _C.gold,
                        borderRadius: BorderRadius.circular(4))),
              ]),
            ),
          ),
        ]),
      );

  Widget _composerEntry() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 5),
        child: Material(
          color: Colors.white,
          elevation: 2,
          shadowColor: _C.forest.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _compose,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(children: [
                const CircleAvatar(radius: 21, backgroundColor: _C.jade,
                    child: Icon(Icons.person_rounded, color: _C.forest)),
                const SizedBox(width: 12),
                const Expanded(child: Text('عندك سؤال أو نصيحة؟ شاركي رفاقك...',
                    style: TextStyle(color: _C.muted, fontSize: 13))),
                const Icon(Icons.add_photo_alternate_outlined,
                    color: _C.teal, size: 24),
              ]),
            ),
          ),
        ),
      );

  Widget _filters() => Column(children: [
        SizedBox(
          height: 58,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            children: [for (final t in const ['الكل', 'الحرمين', 'الحج', 'العمرة', 'الأسواق'])
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: ChoiceChip(
                  label: Text(t),
                  selected: _category == t,
                  showCheckmark: false,
                  selectedColor: _C.teal,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: _category == t ? _C.teal : _C.border),
                  labelStyle: TextStyle(
                    color: _category == t ? Colors.white : _C.ink,
                    fontWeight: FontWeight.w800),
                  onSelected: (_) => setState(() => _category = t),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Row(children: [
            TextButton.icon(
              onPressed: () => setState(() => _mine = !_mine),
              icon: Icon(_mine ? Icons.public : Icons.person_outline, size: 18),
              label: Text(_mine ? 'كل المنشورات' : 'منشوراتي'),
              style: TextButton.styleFrom(foregroundColor: _C.forest),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const FriendsScreen(),
              )),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('إضافة صديق'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _C.teal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ]),
        ),
      ]);

  Widget _notice(String title, String subtitle) => Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: _C.border)),
          child: Column(children: [
            const Icon(Icons.forum_outlined, color: _C.teal, size: 42),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, color: _C.ink,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(subtitle, textAlign: TextAlign.center,
                style: const TextStyle(color: _C.muted, height: 1.6)),
          ]),
        ),
      );
}

class _PostCard extends StatefulWidget {
  const _PostCard({super.key, required this.doc, required this.onError});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final ValueChanged<Object> onError;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  CommunityService get svc => CommunityService.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _likesStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _commentsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _dislikesStream;

  @override
  void initState() {
    super.initState();
    _likesStream = svc.likes(widget.doc.id);
    _commentsStream = svc.comments(widget.doc.id);
    _dislikesStream = svc.dislikes(widget.doc.id);
  }

  Future<void> _menu(BuildContext context, String authorId) async {
    final mine = FirebaseAuth.instance.currentUser?.uid == authorId;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (mine)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('حذف منشوري'),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          if (!mine)
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_rounded,
                  color: Colors.deepOrange),
              title: const Text('Spam — إبلاغ عن منشور مزعج'),
              subtitle: const Text('بعد 4 بلاغات من حسابات مختلفة يختفي تلقائيًا'),
              onTap: () => Navigator.pop(sheetContext, 'spam'),
            ),
          if (!mine)
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('إبلاغ عن مخالفة أخرى'),
              onTap: () => Navigator.pop(sheetContext, 'report'),
            ),
        ]),
      ),
    );
    if (!context.mounted) return;
    try {
      if (choice == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('حذف المنشور؟'),
            content: const Text('لن يظهر المنشور بعد حذفه.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('حذف')),
            ],
          ),
        );
        if (confirm == true) await svc.deleteOwnPost(widget.doc.id, authorId);
      } else if (choice == 'spam') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('الإبلاغ عن Spam؟'),
            content: const Text(
              'يتحسب بلاغ واحد من حسابك فقط. بعد أكثر من 3 بلاغات مختلفة يختفي البوست تلقائيًا.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('إبلاغ Spam')),
            ],
          ),
        );
        if (confirm != true) return;
        final count = await svc.reportSpam(widget.doc.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(count >= 4
                ? 'وصل البوست إلى 4 بلاغات Spam وتم إخفاؤه تلقائيًا.'
                : 'تم تسجيل البلاغ ($count من 4). المنشور ما زال ظاهرًا.'),
          ));
        }
      } else if (choice == 'report') {
        final reason = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('سبب الإبلاغ'),
            children: [
              for (final r in const [
                'محتوى غير مناسب', 'إساءة أو تنمر', 'معلومات مضللة', 'إعلان مزعج'
              ])
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, r),
                  child: Text(r),
                ),
            ],
          ),
        );
        if (reason != null) {
          await svc.report(widget.doc.id, reason);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم إرسال البلاغ للمراجعة'),
            ));
          }
        }
      }
    } catch (e) {
      widget.onError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data();
    final name = (d['authorName'] ?? 'عضو رفقة').toString();
    final authorId = (d['authorId'] ?? '').toString();
    final kind = (d['kind'] ?? 'معلومة').toString();
    final date = d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : null;
    final mins = date == null ? null : DateTime.now().difference(date).inMinutes;
    final time = mins == null || mins < 1 ? 'الآن' : mins < 60 ? 'منذ $mins دقيقة'
        : mins < 1440 ? 'منذ ${mins ~/ 60} ساعة' : 'منذ ${mins ~/ 1440} يوم';
    final rawImage = d['imageBase64'] as String?;
    Uint8List? imageBytes;
    if (rawImage != null && rawImage.isNotEmpty) {
      try { imageBytes = base64Decode(rawImage); } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(24), border: Border.all(color: _C.border),
          boxShadow: [BoxShadow(color: _C.forest.withValues(alpha: .04),
              blurRadius: 18, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: _C.jade, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.person_rounded, color: _C.forest)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _C.ink)),
            const SizedBox(height: 3),
            Text('${(d['location'] as String?)?.isNotEmpty == true ? '${d['location']} · ' : ''}$time',
                style: const TextStyle(color: _C.muted, fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(color: kind == 'سؤال' ? const Color(0xFFE5F1FD) :
                const Color(0xFFFFF1DA), borderRadius: BorderRadius.circular(25)),
            child: Text(kind, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12,
                color: kind == 'سؤال' ? const Color(0xFF2872AB) : const Color(0xFFAE823D)))),
          IconButton(onPressed: () => _menu(context, authorId),
              icon: const Icon(Icons.more_vert_rounded, color: _C.muted)),
        ]),
        const SizedBox(height: 15),
        Text((d['body'] ?? '').toString(),
            style: const TextStyle(color: _C.ink, fontSize: 15, height: 1.7)),
        if (imageBytes != null) ...[
          const SizedBox(height: 13),
          ClipRRect(borderRadius: BorderRadius.circular(17),
            child: Image.memory(imageBytes, fit: BoxFit.cover, width: double.infinity,
                height: 200, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        ],
        const SizedBox(height: 15),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(color: _C.jade, borderRadius: BorderRadius.circular(12)),
            child: Text((d['category'] ?? '').toString(),
                style: const TextStyle(fontSize: 11, color: _C.forest, fontWeight: FontWeight.w700))),
          const Spacer(),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _likesStream,
            builder: (context, s) {
              final liked = s.data?.docs.any((x) => x.id == FirebaseAuth.instance.currentUser?.uid) ?? false;
              return TextButton.icon(
                onPressed: () async {
                  try { await svc.toggleLike(widget.doc.id, liked); } catch (e) { widget.onError(e); }
                },
                icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: liked ? const Color(0xFFE05268) : _C.muted, size: 21),
                label: Text('${s.data?.docs.length ?? 0}',
                    style: const TextStyle(color: _C.muted)),
              );
            },
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _dislikesStream,
            builder: (context, s) {
              final disliked = s.data?.docs.any(
                  (x) => x.id == FirebaseAuth.instance.currentUser?.uid) ?? false;
              return TextButton.icon(
                onPressed: () async {
                  try {
                    await svc.toggleDislike(widget.doc.id, disliked);
                  } catch (e) {
                    widget.onError(e);
                  }
                },
                icon: Icon(disliked
                    ? Icons.thumb_down_rounded
                    : Icons.thumb_down_outlined,
                    color: disliked ? _C.teal : _C.muted, size: 19),
                label: Text('${s.data?.docs.length ?? 0}',
                    style: const TextStyle(color: _C.muted)),
              );
            },
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _commentsStream,
            builder: (context, s) => TextButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context, isScrollControlled: true,
                showDragHandle: true, backgroundColor: _C.cream,
                builder: (_) => _CommentsSheet(postId: widget.doc.id)),
              icon: const Icon(Icons.mode_comment_outlined, color: _C.muted, size: 21),
              label: Text('${s.data?.docs.length ?? 0}',
                  style: const TextStyle(color: _C.muted)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer();
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _body = TextEditingController();
  final _location = TextEditingController();
  String _category = 'العمرة';
  String _kind = 'سؤال';
  Uint8List? _photo;
  bool _busy = false;

  @override
  void dispose() { _body.dispose(); _location.dispose(); super.dispose(); }

  Future<void> _pick() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery,
          imageQuality: 35, maxWidth: 700, maxHeight: 700);
      if (file == null) return;
      final data = await file.readAsBytes();
      if (data.lengthInBytes > CommunityService.maxPhotoBytes) {
        throw StateError('الصورة ما زالت كبيرة. اختاري صورة أصغر من 240 كيلوبايت.');
      }
      if (mounted) setState(() => _photo = data);
    } catch (e) { _toast(e.toString()); }
  }

  void _toast(String t) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await CommunityService.instance.createPost(text: _body.text,
        category: _category, kind: _kind, location: _location.text, photo: _photo);
      if (mounted) Navigator.pop(context);
    } catch (e) { _toast(e is StateError ? e.message : '$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Padding(padding: EdgeInsets.only(left: 20, right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('شاركي مجتمع رفقة', style: TextStyle(fontSize: 21,
            color: _C.deep, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('سؤالك أو تجربتك قد تساعد معتمرًا آخر',
            style: TextStyle(color: _C.muted)),
        const SizedBox(height: 17),
        Wrap(spacing: 8, children: [for (final k in CommunityService.kinds)
          ChoiceChip(label: Text(k), selected: _kind == k,
            onSelected: (_) => setState(() => _kind = k),
            showCheckmark: false, selectedColor: _C.jade)]),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'القسم'),
          items: [for (final c in CommunityService.categories)
            DropdownMenuItem(value: c, child: Text(c))],
          onChanged: (value) => setState(() => _category = value ?? _category),
        ),
        TextField(controller: _location, maxLength: 80,
          decoration: const InputDecoration(labelText: 'الموقع (اختياري)',
              hintText: 'مثل: مكة المكرمة')),
        TextField(controller: _body, maxLength: 1500, minLines: 3, maxLines: 6,
          decoration: const InputDecoration(labelText: 'اكتبي منشورك هنا...')),
        if (_photo != null) Stack(alignment: Alignment.topLeft, children: [
          ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.memory(_photo!, height: 115, fit: BoxFit.cover)),
          IconButton.filled(onPressed: () => setState(() => _photo = null),
            icon: const Icon(Icons.close)),
        ]),
        Row(children: [
          TextButton.icon(onPressed: _pick,
            icon: const Icon(Icons.image_outlined), label: const Text('صورة')),
          const Spacer(),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _C.teal),
            onPressed: _busy ? null : _submit,
            icon: _busy ? const SizedBox(width: 15, height: 15,
                child: CircularProgressIndicator(strokeWidth: 2)) :
                const Icon(Icons.send_rounded, size: 17),
            label: const Text('نشر'),
          ),
        ]),
      ])),
    ));
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.postId});
  final String postId;
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _text = TextEditingController();
  bool _busy = false;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = CommunityService.instance.comments(widget.postId);
  }

  @override
  void dispose() { _text.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await CommunityService.instance.addComment(widget.postId, _text.text);
      _text.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is StateError ? e.message : '$e')));
      }
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Directionality(
      textDirection: TextDirection.rtl,
      child: FractionallySizedBox(heightFactor: .76,
        child: Padding(padding: EdgeInsets.only(left: 16, right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 12),
          child: Column(children: [
            const Text('التعليقات', style: TextStyle(fontSize: 19,
                fontWeight: FontWeight.w900, color: _C.deep)),
            const Divider(height: 24),
            Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _commentsStream,
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('تعذر تحميل التعليقات: ${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final items = snap.data!.docs;
                if (items.isEmpty) return const Center(child: Text('كوني أول من يعلق'));
                return ListView.builder(itemCount: items.length, itemBuilder: (_, i) {
                  final d = items[i].data();
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: _C.jade,
                        child: Icon(Icons.person, color: _C.forest)),
                    title: Text('${d['authorName'] ?? 'عضو'}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${d['body'] ?? ''}'),
                  );
                });
              },
            )),
            Row(children: [
              Expanded(child: TextField(controller: _text, maxLength: 500,
                minLines: 1, maxLines: 3,
                decoration: const InputDecoration(hintText: 'اكتبي تعليقًا...',
                    counterText: '', filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _busy ? null : _send,
                  style: IconButton.styleFrom(backgroundColor: _C.teal),
                  icon: const Icon(Icons.send_rounded)),
            ]),
          ]),
        ),
      ));
}
