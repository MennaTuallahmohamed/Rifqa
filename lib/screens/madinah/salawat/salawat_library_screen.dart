import 'package:flutter/material.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../../../services/madinah/salawat_repository.dart';
import '../madinah_ui.dart';
import 'salawat_reader_screen.dart';

class SalawatLibraryScreen extends StatefulWidget {
  const SalawatLibraryScreen({
    super.key,
    required this.repository,
    required this.salawatRepository,
  });
  final MadinahRepository repository;
  final SalawatRepository salawatRepository;

  @override
  State<SalawatLibraryScreen> createState() => _SalawatLibraryScreenState();
}

class _SalawatLibraryScreenState extends State<SalawatLibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final items = widget.salawatRepository.publishedItems;
    return MPage(
      title: 'الصلاة والسلام ﷺ',
      emoji: 'ﷺ',
      subtitle: 'صيغ موثقة وقارئ هادئ — بلا عدادات منافسة أو streaks.',
      children: [
        ...items.map(
          (item) => MCard(
            title: item.title,
            subtitle: '${item.subtitle} • ${item.verificationLabel}',
            emoji: widget.repository.isFavoriteSalawat(item.id) ? '♥' : '🤍',
            onTap: () async {
              await go(
                context,
                SalawatReaderScreen(
                  repository: widget.repository,
                  item: item,
                ),
              );
              if (mounted) setState(() {});
            },
          ),
        ),
      ],
    );
  }
}
