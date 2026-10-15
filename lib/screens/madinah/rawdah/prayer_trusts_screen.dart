import 'package:flutter/material.dart';
import '../../../services/duas/duas_repository.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';

class PrayerTrustsScreen extends StatefulWidget {
  const PrayerTrustsScreen({
    super.key,
    required this.repository,
    required this.duasRepository,
  });

  final MadinahRepository repository;
  final DuasRepository duasRepository;

  @override
  State<PrayerTrustsScreen> createState() => _PrayerTrustsScreenState();
}

class _PrayerTrustsScreenState extends State<PrayerTrustsScreen> {
  final name = TextEditingController();
  final request = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    request.dispose();
    super.dispose();
  }

  Future<void> add() async {
    if (request.text.trim().isEmpty) return;
    await widget.duasRepository.addAmanah(
      personName: name.text.trim(),
      request: request.text.trim(),
    );
    name.clear();
    request.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.duasRepository.amanat;
    return MPage(
      title: 'أمانات الدعاء',
      emoji: '💌',
      subtitle: 'من حملتِ طلباتهم معك إلى المدينة. خاصة على جهازك حاليًا.',
      children: [
        if (items.isEmpty)
          const MCard(
            title: 'لا أمانات بعد',
            subtitle: 'أضيفي اسمًا اختياريًا والدعوة التي تريدين حملها.',
            emoji: '🤍',
          )
        else
          ...items.map(
            (a) => MCard(
              title: a.personName.trim().isEmpty ? 'صاحب أمانة' : a.personName,
              subtitle: a.request,
              emoji: a.isPrayed ? '✓' : '💌',
              trailing: IconButton(
                icon: Icon(
                  a.isPrayed ? Icons.check_circle : Icons.circle_outlined,
                  color: emerald,
                ),
                onPressed: () async {
                  await widget.duasRepository.toggleAmanahDone(a.id);
                  if (mounted) setState(() {});
                },
              ),
            ),
          ),
        const MSection('أضيفي أمانة'),
        TextField(
          controller: name,
          decoration: const InputDecoration(
            labelText: 'الاسم (اختياري)',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: request,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'الدعوة',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: add,
          style: FilledButton.styleFrom(backgroundColor: emerald),
          icon: const Icon(Icons.add),
          label: const Text('إضافة الأمانة'),
        ),
      ],
    );
  }
}
