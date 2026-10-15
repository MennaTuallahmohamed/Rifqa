import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../models/madinah/salawat_item.dart';
import '../madinah_ui.dart';

class SalawatCalmModeScreen extends StatefulWidget {
  const SalawatCalmModeScreen({super.key, required this.item});
  final SalawatItem item;
  @override
  State<SalawatCalmModeScreen> createState() => _SalawatCalmModeScreenState();
}

class _SalawatCalmModeScreenState extends State<SalawatCalmModeScreen> {
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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: emeraldDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const Spacer(),
                const Text('ﷺ', style: TextStyle(color: gold, fontSize: 52)),
                const SizedBox(height: 28),
                Text(
                  widget.item.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 2.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.item.sourceDisplay,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
