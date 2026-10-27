import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'refqa_community_data.dart';
import 'refqa_community_widgets.dart';

class RefqaCommunityPostDetailsScreen extends StatefulWidget {
  const RefqaCommunityPostDetailsScreen({super.key, required this.post});
  final RefqaPost post;

  @override
  State<RefqaCommunityPostDetailsScreen> createState() => _RefqaCommunityPostDetailsScreenState();
}

class _RefqaCommunityPostDetailsScreenState extends State<RefqaCommunityPostDetailsScreen> {
  final store = RefqaCommunityData.instance;
  final commentCtrl = TextEditingController();
  final commentFocus = FocusNode();
  bool newestFirst = false;

  @override
  void initState() {
    super.initState();
    commentCtrl.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    commentCtrl.removeListener(_changed);
    commentCtrl.dispose();
    commentFocus.dispose();
    super.dispose();
  }

  void _addComment() {
    final value = commentCtrl.text.trim();
    if (value.isEmpty) return;
    if (value.length > 500) {
      refqaNotice(context, 'التعليق يجب ألا يتجاوز 500 حرف');
      return;
    }
    store.addComment(widget.post, value);
    commentCtrl.clear();
    FocusScope.of(context).unfocus();
    refqaNotice(context, 'التعليق أضيف إلى المعاينة المحلية فقط');
  }

  @override
  Widget build(BuildContext context) => RefqaRoot(
        child: Scaffold(
          body: Column(children: [
            const RefqaTopBar(title: 'تفاصيل المنشور'),
            Expanded(child: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                final post = widget.post;
                final comments = [...post.comments];
                final requested = store.requestedFriends.contains(post.author);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                  children: [
                    const SizedBox(height: 9),
                    RefqaWhitePanel(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          RefqaAvatar(path: post.avatar, radius: 23),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Flexible(child: Text(post.author, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                              if (post.verified) ...[const SizedBox(width: 3), const Icon(Icons.verified_rounded, color: Color(0xFF1677E8), size: 14)],
                            ]),
                            Text('${post.location} • ${post.time}', style: const TextStyle(fontSize: 11, color: RefqaColors.muted)),
                          ])),
                          RefqaTag(label: post.type.title, textColor: refqaTypeColor(post.type), background: refqaTypeBackground(post.type)),
                        ]),
                        const SizedBox(height: 13),
                        Text(post.body, style: const TextStyle(fontSize: 14, height: 1.75)),
                        if (post.image != null || post.imageBytes.isNotEmpty) ...[
                          const SizedBox(height: 13),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: post.imageBytes.isNotEmpty
                                ? Image.memory(post.imageBytes.first, fit: BoxFit.cover, height: 175, width: double.infinity)
                                : Image.asset(post.image!, fit: BoxFit.cover, height: 175, width: double.infinity),
                          ),
                          if (post.imageBytes.length > 1) ...[
                            const SizedBox(height: 8),
                            SizedBox(height: 65, child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: post.imageBytes.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 5),
                              itemBuilder: (ctx, i) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(post.imageBytes[i], height: 65, width: 75, fit: BoxFit.cover)),
                            )),
                          ],
                        ],
                        const SizedBox(height: 14),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          _DetailAction(
                            icon: post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            label: '${post.likes}',
                            color: const Color(0xFFF34B58),
                            onTap: () => store.toggleLike(post),
                          ),
                          _DetailAction(icon: Icons.chat_bubble_outline_rounded, label: '${post.commentCount}', onTap: () => commentFocus.requestFocus()),
                          _DetailAction(
                            icon: post.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            label: post.saved ? 'محفوظ' : 'حفظ',
                            onTap: () => store.toggleSave(post),
                          ),
                          _DetailAction(
                            icon: Icons.share_outlined,
                            label: 'مشاركة',
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: post.body));
                              if (context.mounted) refqaNotice(context, 'تم نسخ نص المنشور للمشاركة');
                            },
                          ),
                        ]),
                        if (post.author != 'أنتِ') ...[
                          const SizedBox(height: 13),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                store.requestFriend(post.author);
                                refqaNotice(context, requested ? 'تم إلغاء الطلب التجريبي' : 'تم إرسال طلب الصداقة في المعاينة');
                              },
                              icon: Icon(requested ? Icons.hourglass_top_outlined : Icons.person_add_alt_1_rounded, size: 19),
                              label: Text(requested ? 'طلب الصداقة مُرسل' : 'إضافة صديق'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: RefqaColors.teal,
                                side: const BorderSide(color: RefqaColors.teal),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                              ),
                            ),
                          ),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('التعليقات (${post.commentCount})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      DropdownButton<bool>(
                        value: newestFirst,
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(fontSize: 12, color: RefqaColors.ink),
                        items: const [
                          DropdownMenuItem(value: false, child: Text('الأبرز أولاً')),
                          DropdownMenuItem(value: true, child: Text('الأحدث أولاً')),
                        ],
                        onChanged: (v) { if (v != null) setState(() => newestFirst = v); },
                      ),
                    ]),
                    const SizedBox(height: 3),
                    for (final c in (newestFirst ? comments.reversed : comments))
                      RefqaWhitePanel(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            RefqaAvatar(path: c.avatar, radius: 18),
                            const SizedBox(width: 7),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.author, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                              Text('${c.location} • ${c.time}', style: const TextStyle(color: RefqaColors.muted, fontSize: 10)),
                            ])),
                            if (c.trusted) const RefqaTag(label: 'مساهم موثوق', textColor: Color(0xFF997127), background: RefqaColors.paleGold, icon: Icons.star_rounded),
                          ]),
                          const SizedBox(height: 9),
                          Text(c.text, style: const TextStyle(fontSize: 12, height: 1.6)),
                          const SizedBox(height: 6),
                          Text('♥ ${c.likes}', style: const TextStyle(fontSize: 11, color: Color(0xFFF0535F))),
                        ]),
                      ),
                    if (post.extraDemoCommentCount > 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text('يتم عرض تعليقات نموذجية فقط في نسخة التصميم.', textAlign: TextAlign.center,
                            style: TextStyle(color: RefqaColors.muted, fontSize: 11)),
                      ),
                  ],
                );
              },
            )),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: RefqaColors.line))),
              child: SafeArea(
                top: false,
                child: Row(children: [
                  const RefqaAvatar(path: '${RefqaCommunityData.assetRoot}avatar_female.jpg', radius: 17),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: commentCtrl,
                    focusNode: commentFocus,
                    maxLength: 500,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      hintText: 'أضيفي تعليقك هنا...',
                      hintStyle: const TextStyle(fontSize: 12, color: RefqaColors.muted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: RefqaColors.line)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
                    ),
                  )),
                  IconButton(onPressed: commentCtrl.text.trim().isEmpty ? null : _addComment,
                    icon: const Icon(Icons.send_rounded, color: RefqaColors.teal)),
                ]),
              ),
            ),
          ]),
        ),
      );
}

class _DetailAction extends StatelessWidget {
  const _DetailAction({required this.icon, required this.label, required this.onTap, this.color = RefqaColors.muted});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 11, color: RefqaColors.muted)),
          ]),
        ),
      );
}
