import 'package:flutter/material.dart';

import '../theme/haramain_ui.dart';

Future<T?> showHaramainSheet<T>(
  BuildContext context,
  Widget Function(BuildContext) builder,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            18, 0, 18, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(child: builder(ctx)),
      ),
    ),
  );
}

Widget haramainSheetTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: HmUi.ink,
        ),
      ),
    );
