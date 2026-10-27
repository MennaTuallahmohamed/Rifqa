import 'package:flutter/material.dart';
import 'refqa_community_data.dart';

class RefqaColors {
  static const navy = Color(0xFF073D48);
  static const darkTeal = Color(0xFF004E58);
  static const teal = Color(0xFF008D85);
  static const mint = Color(0xFFE3F5EF);
  static const ivory = Color(0xFFF7F7F3);
  static const ink = Color(0xFF182E37);
  static const muted = Color(0xFF89979A);
  static const line = Color(0xFFE9EDEB);
  static const golden = Color(0xFFC99646);
  static const paleGold = Color(0xFFFFF3DC);
}

const refqaFont = 'Arial';

class RefqaRoot extends StatelessWidget {
  const RefqaRoot({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: RefqaColors.ivory,
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: RefqaColors.teal,
                  surface: Colors.white,
                ),
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: RefqaColors.ink,
                  displayColor: RefqaColors.ink,
                ),
          ),
          child: child,
        ),
      );
}

class RefqaTopBar extends StatelessWidget {
  const RefqaTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.leading,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 23),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [RefqaColors.navy, RefqaColors.darkTeal, Color(0xFF00675F)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: subtitle == null ? 55 : 68,
          child: Row(
            children: [
              leading ?? const SizedBox(width: 42),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        )),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: const TextStyle(color: Color(0xFFD8E6E5), fontSize: 11)),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showBack)
                IconButton(
                  tooltip: 'رجوع',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                )
              else
                const SizedBox(width: 42),
            ],
          ),
        ),
      ),
    );
  }
}

class RefqaWhitePanel extends StatelessWidget {
  const RefqaWhitePanel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.margin = EdgeInsets.zero});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RefqaColors.line),
          boxShadow: const [BoxShadow(color: Color(0x0C1F4C4A), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: child,
      );
}

class RefqaAvatar extends StatelessWidget {
  const RefqaAvatar({super.key, required this.path, this.radius = 20});
  final String path;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: RefqaColors.mint,
        backgroundImage: AssetImage(path),
      );
}

class RefqaTag extends StatelessWidget {
  const RefqaTag({super.key, required this.label, required this.textColor, required this.background, this.icon});
  final String label;
  final Color textColor;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: textColor),
              const SizedBox(width: 3),
            ],
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ),
      );
}

Color refqaTypeColor(RefqaPostType type) => switch (type) {
      RefqaPostType.question => const Color(0xFF1274D8),
      RefqaPostType.tip => const Color(0xFFC38C3F),
      RefqaPostType.information => const Color(0xFF069A7A),
    };

Color refqaTypeBackground(RefqaPostType type) => switch (type) {
      RefqaPostType.question => const Color(0xFFE3F0FF),
      RefqaPostType.tip => const Color(0xFFFFF1D9),
      RefqaPostType.information => const Color(0xFFDDF8ED),
    };

IconData refqaTypeIcon(RefqaPostType type) => switch (type) {
      RefqaPostType.question => Icons.help_outline_rounded,
      RefqaPostType.tip => Icons.lightbulb_outline_rounded,
      RefqaPostType.information => Icons.description_outlined,
    };

class RefqaTypeStrip extends StatelessWidget {
  const RefqaTypeStrip({super.key, required this.selected, required this.onSelected, this.includeAll = true});
  final RefqaPostType? selected;
  final ValueChanged<RefqaPostType?> onSelected;
  final bool includeAll;

  @override
  Widget build(BuildContext context) {
    final types = <RefqaPostType?>[if (includeAll) null, ...RefqaPostType.values];
    return Row(
      children: [
        for (final type in types)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: selected == type ? RefqaColors.teal : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: selected == type ? RefqaColors.teal : RefqaColors.line),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(type),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Icon(type == null ? Icons.dashboard_customize_outlined : refqaTypeIcon(type),
                            color: selected == type ? Colors.white : (type == null ? RefqaColors.teal : refqaTypeColor(type)),
                            size: 22),
                        const SizedBox(height: 4),
                        Text(type?.title ?? 'الكل',
                            style: TextStyle(
                              color: selected == type ? Colors.white : RefqaColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class RefqaTopicStrip extends StatelessWidget {
  const RefqaTopicStrip({super.key, required this.current, required this.onChanged, this.includeAll = true});
  final RefqaTopic current;
  final ValueChanged<RefqaTopic> onChanged;
  final bool includeAll;

  @override
  Widget build(BuildContext context) {
    final topics = RefqaTopic.values.where((t) => includeAll || t != RefqaTopic.all).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final topic in topics)
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: ChoiceChip(
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                selectedColor: RefqaColors.mint,
                backgroundColor: Colors.white,
                label: Text(topic.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: current == topic ? RefqaColors.teal : RefqaColors.ink)),
                selected: current == topic,
                onSelected: (_) => onChanged(topic),
              ),
            ),
        ],
      ),
    );
  }
}

class RefqaPrimaryButton extends StatelessWidget {
  const RefqaPrimaryButton({super.key, required this.text, required this.onTap, this.icon = Icons.send_rounded});
  final String text;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 51,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 19),
          label: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          style: FilledButton.styleFrom(
            backgroundColor: RefqaColors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
      );
}

class RefqaBottomNavigation extends StatelessWidget {
  const RefqaBottomNavigation({super.key, this.onTap});
  final ValueChanged<int>? onTap;
  @override
  Widget build(BuildContext context) {
    const labels = ['الرئيسية', 'الحجوزات', 'الأسواق', 'المجتمع', 'المزيد'];
    const icons = [Icons.home_outlined, Icons.mosque_outlined, Icons.storefront_outlined, Icons.forum_outlined, Icons.menu_rounded];
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: RefqaColors.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap?.call(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[i], size: 22, color: i == 3 ? RefqaColors.teal : RefqaColors.muted),
                      const SizedBox(height: 3),
                      Text(labels[i], style: TextStyle(fontSize: 10, color: i == 3 ? RefqaColors.teal : RefqaColors.muted, fontWeight: i == 3 ? FontWeight.w800 : FontWeight.w500)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void refqaNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: RefqaColors.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}

/// Shared post layout, used on the feed screen.
class RefqaPostCard extends StatelessWidget {
  const RefqaPostCard({super.key, required this.post, required this.onDetails, required this.onLike, required this.onFriend, required this.onReport, this.onBlock});
  final RefqaPost post;
  final VoidCallback onDetails;
  final VoidCallback onLike;
  final VoidCallback onFriend;
  final VoidCallback onReport;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    final store = RefqaCommunityData.instance;
    final requested = store.requestedFriends.contains(post.author);
    return RefqaWhitePanel(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            RefqaAvatar(path: post.avatar, radius: 21),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(post.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
                  if (post.verified) ...[const SizedBox(width: 3), const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF1677E8))],
                ]),
                Text('${post.location} • ${post.time}', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: RefqaColors.muted, fontSize: 10)),
              ]),
            ),
            if (post.pending)
              const RefqaTag(label: 'بانتظار المراجعة', textColor: Color(0xFF976E30), background: RefqaColors.paleGold)
            else
              RefqaTag(label: post.type.title, textColor: refqaTypeColor(post.type), background: refqaTypeBackground(post.type)),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (value) {
                if (value == 'report') onReport();
                if (value == 'block') onBlock?.call();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'report', child: Text('إبلاغ عن المنشور')),
                if (post.author != 'أنتِ') const PopupMenuItem(value: 'block', child: Text('حظر صاحب المنشور')),
              ],
            ),
          ]),
          const SizedBox(height: 11),
          if (post.image != null && post.type != RefqaPostType.question)
            InkWell(
              onTap: onDetails,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(post.image!, height: 93, width: 96, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(post.body, maxLines: 4, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: RefqaColors.ink, height: 1.65, fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
            )
          else ...[
            InkWell(
              onTap: onDetails,
              child: Text(post.body, maxLines: 4, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: RefqaColors.ink, height: 1.65, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            if (post.imageBytes.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: onDetails,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(post.imageBytes.first, height: 125, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
          Row(children: [
            InkWell(
              onTap: onLike,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: const Color(0xFFEF4B55), size: 19),
                const SizedBox(width: 4),
                Text('${post.likes}', style: const TextStyle(color: RefqaColors.muted, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 18),
            InkWell(
              onTap: onDetails,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: RefqaColors.muted, size: 18),
                const SizedBox(width: 5),
                Text('${post.commentCount}', style: const TextStyle(color: RefqaColors.muted, fontSize: 12)),
              ]),
            ),
            const Spacer(),
            if (post.author != 'أنتِ')
              OutlinedButton.icon(
                onPressed: onFriend,
                icon: Icon(requested ? Icons.hourglass_bottom : Icons.person_add_alt_1_outlined, size: 15),
                label: Text(requested ? 'تم الطلب' : 'إضافة صديق', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: RefqaColors.teal,
                  side: const BorderSide(color: Color(0xFFBCE2DA)),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ]),
        ],
      ),
    );
  }
}
