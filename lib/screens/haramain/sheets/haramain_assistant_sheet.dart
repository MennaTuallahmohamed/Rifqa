import 'package:flutter/material.dart';

import '../../../services/haramain/haramain_assistant_service.dart';
import '../theme/haramain_design.dart';
import 'haramain_poi_sheet.dart';

/// "رِفقة، ساعديني" — a contextual assistant, not a chatbot.
///
/// The UI states plainly that this is deterministic and on-device, so the
/// pilgrim is never misled into thinking an AI is reasoning about the mosque.
class HmAssistantSheet extends StatefulWidget {
  const HmAssistantSheet({
    super.key,
    required this.backend,
    required this.onPlan,
  });

  final HaramainAssistantBackend backend;
  final void Function(HmAssistantPlan plan) onPlan;

  @override
  State<HmAssistantSheet> createState() => _HmAssistantSheetState();
}

class _HmAssistantSheetState extends State<HmAssistantSheet> {
  final _controller = TextEditingController();
  final _history = <(String, String)>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) return;
    final plan = await widget.backend.resolve(q);
    if (!mounted) return;
    setState(() {
      _history.add((q, plan.utterance));
      _controller.clear();
    });
    widget.onPlan(plan);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final backend = widget.backend;
    final suggestions =
        backend is LocalHaramainAssistantBackend ? backend.suggestions : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle(
          'رِفقة، ساعديني',
          subtitle: 'مساعد سياقي داخل التطبيق — يعمل دون إنترنت وبنتائج ثابتة.',
        ),
        const SizedBox(height: 10),
        HmNotice(
          message:
              'هذا المساعد يحدد نيّتك ثم ينفّذ إجراءً محددًا في التطبيق. '
              'لا يخترع معلومات ولا يقترح مسارات غير موثّقة.',
          icon: Icons.info_outline_rounded,
          color: HmTheme.muted,
          background: HmTheme.ivory,
        ),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final (q, a) in _history.reversed.take(4))
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HmTheme.emeraldSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      )),
                  const SizedBox(height: 4),
                  Text(a, style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('اقتراحات', style: HmTheme.sectionLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in suggestions)
                ActionChip(
                  label: Text(s),
                  onPressed: () => _submit(s),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _submit,
                decoration: InputDecoration(
                  hintText: 'اكتب طلبًا قصيرًا...',
                  filled: true,
                  fillColor: HmTheme.ivory,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: HmTheme.emerald,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _submit(_controller.text),
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}