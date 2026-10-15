import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../haramain_geo.dart';
import '../haramain_nav_session.dart';
import '../theme/haramain_design.dart';

/// Active navigation HUD.
///
/// This widget is only ever built when [HaramainNavSession.active] is true,
/// which only happens after the safety gate produced a verified route. There
/// is intentionally no way to construct it without a real route.
class HmNavigationHud extends StatelessWidget {
  const HmNavigationHud({
    super.key,
    required this.session,
    required this.onExit,
    required this.onRecenter,
    required this.onToggleVoice,
    required this.highContrast,
    required this.wheelchairMode,
    this.topPadding = 0,
  });

  final HaramainNavSession session;
  final VoidCallback onExit;
  final VoidCallback onRecenter;
  final VoidCallback onToggleVoice;
  final bool highContrast;
  final bool wheelchairMode;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final step = session.next;
        final headline = session.arrived
            ? 'وصلت إلى وجهتك'
            : (step?.text ?? 'الوصول إلى ${session.targetName}');
        final detail = session.arrived
            ? session.targetName
            : 'لمسافة ${HmGeo.meters(session.toNext)} تقريبًا';

        return Container(
          margin: EdgeInsets.fromLTRB(14, topPadding, 14, 0),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: HmTheme.shadowSheet,
            border: highContrast
                ? Border.all(color: Colors.black, width: 2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onExit,
                    icon: const Icon(Icons.close_rounded),
                    color: HmTheme.danger,
                    tooltip: 'إنهاء التوجيه',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                            color: HmTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HmTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.rotate(
                    angle: session.arrow * math.pi / 180,
                    child: Icon(
                      session.arrived
                          ? Icons.flag_rounded
                          : Icons.navigation_rounded,
                      size: 52,
                      color: session.arrived
                          ? HmTheme.emerald
                          : HmTheme.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'المتبقي',
                      value: '${session.minutes} دقيقة',
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  Container(width: 1, height: 38, color: HmTheme.line),
                  Expanded(
                    child: _Stat(
                      label: 'المسافة',
                      value: HmGeo.meters(session.remaining),
                      icon: Icons.straighten_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRecenter,
                      icon: const Icon(Icons.my_location_rounded, size: 18),
                      label: const Text('إعادة التمركز'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onToggleVoice,
                      icon: Icon(
                        session.voiceOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        size: 18,
                      ),
                      label: Text(session.voiceOn ? 'الصوت' : 'مكتوم'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (session.offRoute) ...[
                const SizedBox(height: 12),
                HmNotice(
                  message:
                      'ابتعدت عن المسار الموثّق. ارجع إلى الخط الأخضر أو أعد '
                      'التمركز. لا نعيد حساب الطريق تلقائيًا بعد.',
                  icon: Icons.warning_amber_rounded,
                  color: HmTheme.danger,
                  background: HmTheme.dangerSoft,
                  highContrast: highContrast,
                ),
              ],
              if (wheelchairMode) ...[
                const SizedBox(height: 10),
                const HmNotice(
                  message:
                      'المسار الحالي ميسّر وموثّق. إن احتجت مصعدًا فاسأل أحد '
                      'العاملين، فبيانات المصاعد الداخلية غير مكتملة بعد.',
                  icon: Icons.accessible_rounded,
                  color: HmTheme.info,
                  background: Color(0xFFE8F0FE),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 17, color: HmTheme.muted),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: HmTheme.ink,
          ),
        ),
        Text(label, style: HmTheme.caption),
      ],
    );
  }
}