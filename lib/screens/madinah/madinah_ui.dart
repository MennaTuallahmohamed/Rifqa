import 'package:flutter/material.dart';

const emerald = Color(0xFF123D35);
const emeraldDark = Color(0xFF082A24);
const gold = Color(0xFFC9A96E);
const ivory = Color(0xFFFAF7F0);
const ink = Color(0xFF24352F);
const muted = Color(0xFF6B7B74);

Future<T?> go<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(builder: (_) => page),
  );
}

class MPage extends StatelessWidget {
  const MPage({
    super.key,
    required this.title,
    this.emoji = '🕌',
    this.subtitle = '',
    required this.children,
    this.calm = false,
  });

  final String title;
  final String emoji;
  final String subtitle;
  final List<Widget> children;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: calm ? emeraldDark : ivory,
      appBar: AppBar(
        backgroundColor: calm ? emeraldDark : ivory,
        foregroundColor: calm ? Colors.white : emerald,
        elevation: 0,
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [emerald, emeraldDark],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: gold.withValues(alpha: .28)),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        height: 1.7,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Text(
                    '──────  ◇  ──────',
                    style: TextStyle(color: gold, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class MCard extends StatelessWidget {
  const MCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.emoji = '◇',
    this.onTap,
    this.trailing,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? const Color(0xFFF0E8D7) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? gold : gold.withValues(alpha: .22),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 27)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: emerald,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: muted,
                          height: 1.55,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (trailing == null && onTap != null)
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: gold,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MSection extends StatelessWidget {
  const MSection(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: emerald,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: const TextStyle(color: muted, height: 1.5)),
            ],
          ],
        ),
      );
}

class MSourceBox extends StatelessWidget {
  const MSourceBox({
    super.key,
    required this.source,
    this.note,
  });
  final String source;
  final String? note;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEE2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_rounded, color: emerald, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                note == null ? source : '$source\n$note',
                style: const TextStyle(color: ink, height: 1.55, fontSize: 12),
              ),
            ),
          ],
        ),
      );
}
