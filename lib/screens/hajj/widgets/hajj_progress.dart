import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../umrah/umrah_data.dart';
import '../hajj_data.dart';

/// مسار الحج: 8 محطات متصلة، تضغط على أي محطة لتفتحها
class HajjProgress extends StatelessWidget {
  final int current;
  final bool Function(int) isDone;
  final ValueChanged<int> onTap;
  const HajjProgress(
      {super.key,
      required this.current,
      required this.isDone,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final off = UC.border;
    return Row(
      children: [
        for (int i = 0; i < 8; i++)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTap(i),
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 3,
                                color: i == 0
                                    ? Colors.transparent
                                    : (isDone(i - 1) ? AppColors.gold : off),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 3,
                                color: i == 7
                                    ? Colors.transparent
                                    : (isDone(i) ? AppColors.gold : off),
                              ),
                            ),
                          ],
                        ),
                        _Node(index: i, current: i == current, done: isDone(i)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        hajjGuide[i].tabLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: i == current ? AppColors.greenDark : UC.muted,
                          fontWeight:
                              i == current ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  final int index;
  final bool current, done;
  const _Node({required this.index, required this.current, required this.done});

  @override
  Widget build(BuildContext context) {
    final size = current ? 34.0 : 28.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: current
            ? const LinearGradient(
                colors: [AppColors.green, AppColors.greenDark])
            : null,
        color: current ? null : (done ? AppColors.gold : Colors.white),
        border: Border.all(
          color: current || done ? AppColors.gold : UC.border,
          width: current ? 2.5 : 1.5,
        ),
        boxShadow: current
            ? [
                BoxShadow(
                  color: AppColors.green.withOpacity(.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: done && !current
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : Text('${index + 1}',
              style: TextStyle(
                color: current ? Colors.white : UC.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              )),
    );
  }
}
