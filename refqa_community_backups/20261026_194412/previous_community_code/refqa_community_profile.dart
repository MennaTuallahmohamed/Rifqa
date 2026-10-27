import 'package:flutter/material.dart';
import 'refqa_community_data.dart';
import 'refqa_community_widgets.dart';

class RefqaCommunityProfileScreen extends StatefulWidget {
  const RefqaCommunityProfileScreen({super.key});
  @override
  State<RefqaCommunityProfileScreen> createState() => _RefqaCommunityProfileScreenState();
}

class _RefqaCommunityProfileScreenState extends State<RefqaCommunityProfileScreen> {
  final store = RefqaCommunityData.instance;
  int activeTab = 2;

  void _friend(String author) {
    store.requestFriend(author);
    refqaNotice(context, store.requestedFriends.contains(author)
        ? 'تم إرسال طلب صداقة تجريبي إلى $author'
        : 'تم إلغاء الطلب التجريبي');
  }

  @override
  Widget build(BuildContext context) => RefqaRoot(
        child: Scaffold(
          body: Column(children: [
            const RefqaTopBar(title: 'الملف والمجتمع'),
            Expanded(child: AnimatedBuilder(
              animation: store,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 15),
                children: [
                  RefqaWhitePanel(
                    child: Column(children: [
                      Row(children: [
                        const RefqaAvatar(path: '${RefqaCommunityData.assetRoot}avatar_landmark.jpg', radius: 36),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [
                            Flexible(child: Text('سالم الهاشمي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                            SizedBox(width: 6),
                            Icon(Icons.verified_rounded, color: Color(0xFF1379E7), size: 18),
                          ]),
                          const Text('📍 مكة المكرمة', style: TextStyle(fontSize: 11, color: RefqaColors.muted)),
                          const SizedBox(height: 7),
                          const RefqaTag(label: 'مساهم موثوق', textColor: Color(0xFF9D712E), background: RefqaColors.paleGold, icon: Icons.workspace_premium_rounded),
                        ])),
                        const Icon(Icons.chevron_left_rounded, color: RefqaColors.muted),
                      ]),
                      const SizedBox(height: 13),
                      const Row(children: [
                        Expanded(child: _Stat(value: '124', name: 'المنشورات')),
                        Expanded(child: _Stat(value: '1.2K', name: 'المتابعون')),
                        Expanded(child: _Stat(value: '356', name: 'أتابع')),
                      ]),
                      const SizedBox(height: 12),
                      const Text('أشارك خبراتي وتجربتي في مكة والمدينة لمساعدة إخواني المعتمرين والحجاج.',
                          style: TextStyle(fontSize: 12, height: 1.55, color: RefqaColors.muted)),
                      const SizedBox(height: 12),
                      RefqaPrimaryButton(
                        text: store.requestedFriends.contains('سالم الهاشمي') ? 'طلب الصداقة مُرسل' : 'إضافة صديق',
                        icon: Icons.person_add_alt_1_rounded,
                        onTap: () => _friend('سالم الهاشمي'),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  RefqaWhitePanel(
                    padding: const EdgeInsets.all(9),
                    child: Column(children: [
                      Row(children: [
                        _segment('المساهمون', Icons.groups_rounded, 2),
                        _segment('الأصدقاء', Icons.people_outline_rounded, 1),
                        _segment('الطلبات', Icons.markunread_mailbox_outlined, 0, count: store.requests.length),
                      ]),
                      const SizedBox(height: 15),
                      if (activeTab == 0) ...[
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('طلبات الصداقة (${store.requests.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const Text('عرض الكل', style: TextStyle(color: RefqaColors.teal, fontSize: 11)),
                        ]),
                        const SizedBox(height: 8),
                        for (final request in store.requests)
                          _friendRequest(request),
                        if (store.requests.isEmpty)
                          const Padding(padding: EdgeInsets.symmetric(vertical: 22), child: Text('لا توجد طلبات جديدة')),
                      ] else if (activeTab == 1) ...[
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('الأصدقاء (${store.acceptedFriends.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const Text('معاينة', style: TextStyle(color: RefqaColors.muted, fontSize: 11)),
                        ]),
                        for (final name in store.acceptedFriends)
                          ListTile(
                            leading: const RefqaAvatar(path: '${RefqaCommunityData.assetRoot}avatar_male.jpg'),
                            title: Text(name),
                            trailing: const Icon(Icons.check_circle_rounded, color: RefqaColors.teal),
                          ),
                        if (store.acceptedFriends.isEmpty)
                          const Padding(padding: EdgeInsets.symmetric(vertical: 22), child: Text('اقبلي طلب صداقة لتظهر هنا')),
                      ] else ...[
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('طلبات الصداقة (${store.requests.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const Text('عرض الكل', style: TextStyle(color: RefqaColors.teal, fontSize: 11)),
                        ]),
                        const SizedBox(height: 8),
                        for (final request in store.requests.take(3)) _friendRequest(request),
                        const SizedBox(height: 12),
                        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('مساهمون مميزون', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('عرض الكل', style: TextStyle(color: RefqaColors.teal, fontSize: 11)),
                        ]),
                        const SizedBox(height: 8),
                        _contributor('أم عبدالله', 'المدينة المنورة • 890 مساهمة', '${RefqaCommunityData.assetRoot}avatar_landmark.jpg', 'مساهم موثوق'),
                        _contributor('نورة', 'جدة • 430 مساهمة', '${RefqaCommunityData.assetRoot}avatar_female.jpg', 'مساهمة نشطة'),
                        _contributor('عبدالله الشهري', 'مكة المكرمة • 610 مساهمة', '${RefqaCommunityData.assetRoot}avatar_male.jpg', 'خبير أماكن'),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 11),
                  RefqaWhitePanel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.shield_outlined, color: RefqaColors.teal),
                        SizedBox(width: 7),
                        Text('السلامة والخصوصية', style: TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 5),
                      const Text('المساهم الموثوق وصف توضيحي في النسخة التجريبية، وليس توثيقًا فعليًا.',
                          style: TextStyle(fontSize: 11, color: RefqaColors.muted)),
                      TextButton.icon(
                        onPressed: () => refqaNotice(context, 'إدارة الحظر والبلاغات ستتصل بالباك إند لاحقًا'),
                        icon: const Icon(Icons.block_rounded),
                        label: const Text('إدارة الحظر والبلاغات'),
                      ),
                    ]),
                  ),
                ],
              ),
            )),
          ]),
        ),
      );

  Widget _segment(String label, IconData icon, int key, {int count = 0}) {
    final selected = activeTab == key;
    return Expanded(child: InkWell(
      onTap: () => setState(() => activeTab = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? RefqaColors.mint : RefqaColors.ivory,
          border: Border.all(color: selected ? RefqaColors.teal : Colors.transparent),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: selected ? RefqaColors.teal : RefqaColors.muted),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: selected ? RefqaColors.teal : RefqaColors.muted)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            CircleAvatar(radius: 9, backgroundColor: const Color(0xFFEF5860),
                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10))),
          ],
        ]),
      ),
    ));
  }

  Widget _friendRequest(RefqaFriendRequest request) => Column(children: [
        Row(children: [
          RefqaAvatar(path: request.avatar, radius: 19),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(request.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            Text(request.city, style: const TextStyle(fontSize: 10, color: RefqaColors.muted)),
          ])),
          IconButton(
            tooltip: 'قبول',
            onPressed: () { store.acceptRequest(request); refqaNotice(context, 'تم قبول الطلب في المعاينة'); },
            icon: const Icon(Icons.check_circle_outline_rounded, color: RefqaColors.teal),
          ),
          IconButton(
            tooltip: 'رفض',
            onPressed: () { store.rejectRequest(request); refqaNotice(context, 'تم رفض الطلب في المعاينة'); },
            icon: const Icon(Icons.cancel_outlined, color: Color(0xFFE7555D)),
          ),
        ]),
        const Divider(height: 13, color: RefqaColors.line),
      ]);

  Widget _contributor(String name, String desc, String avatar, String badge) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          RefqaAvatar(path: avatar, radius: 20),
          const SizedBox(width: 7),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
              const SizedBox(width: 4),
              Flexible(child: RefqaTag(label: badge,
                  textColor: badge == 'مساهمة نشطة' ? const Color(0xFF1671D4) : const Color(0xFF9C722D),
                  background: badge == 'مساهمة نشطة' ? const Color(0xFFE9F2FF) : RefqaColors.paleGold)),
            ]),
            Text(desc, style: const TextStyle(fontSize: 10, color: RefqaColors.muted)),
          ])),
          OutlinedButton.icon(
            onPressed: () => _friend(name),
            icon: Icon(store.requestedFriends.contains(name) ? Icons.hourglass_empty_rounded : Icons.person_add_alt_1_outlined, size: 13),
            label: Text(store.requestedFriends.contains(name) ? 'تم الطلب' : 'إضافة صديق', style: const TextStyle(fontSize: 10)),
            style: OutlinedButton.styleFrom(
              foregroundColor: RefqaColors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: Color(0xFFBCE2DA)),
            ),
          ),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.name});
  final String value;
  final String name;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        Text(name, style: const TextStyle(fontSize: 11, color: RefqaColors.muted)),
      ]);
}
