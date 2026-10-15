import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../services/duas/duas_repository.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';
import 'prayer_bag_screen.dart';
import 'prayer_trusts_screen.dart';

class RawdahQuietModeScreen extends StatefulWidget {
  const RawdahQuietModeScreen({
    super.key,
    required this.repository,
    required this.duasRepository,
  });
  final MadinahRepository repository;
  final DuasRepository duasRepository;

  @override
  State<RawdahQuietModeScreen> createState() => _RawdahQuietModeScreenState();
}

class _RawdahQuietModeScreenState extends State<RawdahQuietModeScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MPage(
        title: 'أنتِ هنا الآن',
        emoji: '🤍',
        subtitle: 'اتركي الهاتف جانبًا، وعيشي اللحظة.',
        calm: true,
        children: [
          const SizedBox(height: 60),
          const Text(
            '🌿',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 62),
          ),
          const SizedBox(height: 60),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => go(
              context,
              PrayerBagScreen(
                repository: widget.repository,
                duasRepository: widget.duasRepository,
              ),
            ),
            child: const Text('حقيبة دعائي فقط'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => go(
              context,
              PrayerTrustsScreen(
                repository: widget.repository,
                duasRepository: widget.duasRepository,
              ),
            ),
            child: const Text('أماناتي فقط'),
          ),
        ],
      );
}
