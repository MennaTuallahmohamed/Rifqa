import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

class LostScreen extends StatefulWidget {
  const LostScreen({super.key});

  @override
  State<LostScreen> createState() => _LostScreenState();
}

class _LostScreenState extends State<LostScreen> {
  String? place;

  final List<String> opts = [
    'عند باب الملك عبدالعزيز',
    'عند باب الملك فهد',
    'عند باب العمرة',
    'عند باب الفتح',
    'عند باب الصفا',
    'في المطاف',
    'في المسعى',
    'في الساحات الخارجية',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB8352A),
                  Color(0xFF7E1D15),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place == null ? 'لا تقلق، أنت لست وحدك' : place!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place == null
                      ? 'اختر أقرب شيء تراه حولك وسنرشدك'
                      : 'ابقَ في مكان ظاهر وأبلغ مجموعتك بمكانك',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: place == null
                ? _buildPlaceSelection()
                : _buildLostActions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceSelection() {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أين أنت الآن؟',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: opts.map((item) {
                  return ActionChip(
                    label: Text(item),
                    onPressed: () {
                      setState(() {
                        place = item;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        AppCard(
          child: const Text(
            '💡 قواعد ذهبية\n'
            '1) ابقَ في مكان ظاهر عند عمود أو باب.\n'
            '2) لا تتنقل كثيرًا.\n'
            '3) اطلب أقرب رجل أمن بزي رسمي.\n'
            '4) اعرض بطاقة «أنا تائه» على أي شخص.',
          ),
        ),
      ],
    );
  }

  Widget _buildLostActions(BuildContext context) {
    final bool atKnownGate = place!.startsWith('عند باب');

    return Column(
      children: [
        AppCard(
          child: Text(
            atKnownGate
                ? '✅ أنت عند بوابة معروفة، وهذا أسهل مكان للقاء'
                : 'اتجه لأقرب بوابة وانتظر عندها.',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        AppCard(
          child: Column(
            children: [
              const Text(
                '👥 أبلغ مجموعتك',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text('سيصلهم موقعك الحالي'),
              const SizedBox(height: 12),

              PrimaryButton(
                'أرسل موقعي للمجموعة',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال موقعك للمجموعة'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        PrimaryButton(
          '🪪 أعرض بطاقة «أنا تائه» لمن حولي',
          red: true,
          onTap: () {
            _showLostCard(context);
          },
        ),

        const SizedBox(height: 8),

        PrimaryButton(
          'رجوع',
          outline: true,
          onTap: () {
            setState(() {
              place = null;
            });
          },
        ),
      ],
    );
  }

  void _showLostCard(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog.fullscreen(
          backgroundColor: const Color(0xFF7E1D15),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🆘',
                  style: TextStyle(fontSize: 60),
                ),
                const Text(
                  'أنا تائه',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'I am lost',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Saya tersesat • Ben kayboldum • میں کھو گیا ہوں',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}