import 'package:flutter/material.dart';
import '../../../models/madinah/salawat_item.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';
import 'salawat_calm_mode_screen.dart';

class SalawatReaderScreen extends StatefulWidget {
  const SalawatReaderScreen({
    super.key,
    required this.repository,
    required this.item,
  });
  final MadinahRepository repository;
  final SalawatItem item;

  @override
  State<SalawatReaderScreen> createState() => _SalawatReaderScreenState();
}

class _SalawatReaderScreenState extends State<SalawatReaderScreen> {
  @override
  Widget build(BuildContext context) {
    final fav = widget.repository.isFavoriteSalawat(widget.item.id);
    return MPage(
      title: widget.item.title,
      emoji: 'ﷺ',
      subtitle: widget.item.subtitle,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            widget.item.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: emerald,
              fontSize: 22,
              height: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        MSourceBox(
          source: widget.item.sourceDisplay,
          note: widget.item.editorialNote ?? widget.item.meaning,
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await widget.repository.toggleFavoriteSalawat(widget.item.id);
                  if (mounted) setState(() {});
                },
                icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
                label: Text(fav ? 'في المفضلة' : 'أضيفي للمفضلة'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: emerald),
                onPressed: () => go(
                  context,
                  SalawatCalmModeScreen(item: widget.item),
                ),
                child: const Text('وضع السكينة'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
