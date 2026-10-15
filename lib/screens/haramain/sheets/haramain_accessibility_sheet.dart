import 'package:flutter/material.dart';

import '../../../models/haramain/accessibility_profile.dart';
import '../theme/haramain_design.dart';
import 'haramain_poi_sheet.dart';

/// Accessibility settings.
///
/// Wheelchair mode is deliberately strict: it does not "make routes easier",
/// it restricts results to POIs the dataset explicitly marks accessible and
/// refuses any route that is not marked accessible. Nothing is inferred.
class HmAccessibilitySheet extends StatelessWidget {
  const HmAccessibilitySheet({
    super.key,
    required this.profile,
    required this.onChanged,
  });

  final AccessibilityProfile profile;
  final void Function(AccessibilityProfile next) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle(
          'إمكانية الوصول',
          subtitle: 'تُحفظ على جهازك وتؤثر على كل شاشات الحرمين',
        ),
        const SizedBox(height: 10),
        _Switch(
          icon: Icons.accessible_rounded,
          title: 'وضع الكرسي المتحرك',
          subtitle:
              'يعرض الخدمات الميسّرة الموثّقة فقط، ولا يقبل أي مسار غير ميسّر.',
          value: profile.wheelchairMode,
          onChanged: (v) =>
              onChanged(profile.copyWith(wheelchairMode: v)),
        ),
        _Switch(
          icon: Icons.text_fields_rounded,
          title: 'خط أكبر',
          subtitle: 'تكبير النصوص في كل الواجهات.',
          value: profile.largeText,
          onChanged: (v) => onChanged(profile.copyWith(largeText: v)),
        ),
        _Switch(
          icon: Icons.contrast_rounded,
          title: 'تباين عالٍ',
          subtitle: 'حدود سوداء وألوان أوضح للوحات.',
          value: profile.highContrast,
          onChanged: (v) => onChanged(profile.copyWith(highContrast: v)),
        ),
        _Switch(
          icon: Icons.visibility_off_outlined,
          title: 'تقليل التعقيد البصري',
          subtitle: 'إخفاء الطبقات الثانوية والتسميات على الخريطة.',
          value: profile.reduceVisualComplexity,
          onChanged: (v) =>
              onChanged(profile.copyWith(reduceVisualComplexity: v)),
        ),
        _Switch(
          icon: Icons.record_voice_over_rounded,
          title: 'التوجيه الصوتي',
          subtitle: 'نطق التعليمات بالعربية عند الحاجة فقط.',
          value: profile.voiceGuidance,
          onChanged: (v) => onChanged(profile.copyWith(voiceGuidance: v)),
        ),
        const SizedBox(height: 6),
        HmNotice(
          message:
              'لا نخمّن إمكانية الوصول لأي مكان. لا يظهر رمز الكرسي المتحرك '
              'إلا عندما يكون مذكورًا في بيانات موثّقة.',
          icon: Icons.verified_user_rounded,
          color: HmTheme.emerald,
          background: HmTheme.emeraldSoft,
          highContrast: profile.highContrast,
        ),
      ],
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HmTheme.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: value ? HmTheme.emeraldSoft : HmTheme.ivory,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: value ? HmTheme.emerald : HmTheme.muted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: HmTheme.h3),
                      const SizedBox(height: 2),
                      Text(subtitle, style: HmTheme.caption),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  activeThumbColor: HmTheme.emerald,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}