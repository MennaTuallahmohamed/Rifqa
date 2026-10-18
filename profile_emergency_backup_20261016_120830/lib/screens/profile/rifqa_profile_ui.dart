import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/profile/rifqa_profile_store.dart';

class Rp {
  static const green = Color(0xFF075340);
  static const deep = Color(0xFF043C31);
  static const mint = Color(0xFFE8F1EC);
  static const gold = Color(0xFFD9B874);
  static const cream = Color(0xFFFAF6EE);
  static const ink = Color(0xFF15362E);
  static const muted = Color(0xFF7A827B);
  static const edge = Color(0xFFE9E1D3);
  static const red = Color(0xFFCB443C);
  static const softRed = Color(0xFFFFEAE4);
  static TextStyle style(double size,
          {Color color = ink, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.cairo(
          fontSize: size, fontWeight: weight, color: color, height: 1.45);
}

Widget rpTextScale(BuildContext context, Widget child) {
  final m = MediaQuery.of(context);
  return MediaQuery(
    data: m.copyWith(
        textScaler:
            TextScaler.linear(RifqaProfileStore.instance.largeText ? 1.14 : 1)),
    child: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}

class RpPhotoHeader extends StatelessWidget {
  const RpPhotoHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      this.image = 'assets/rifqa_profile/makkah.jpg',
      this.height = 230,
      this.trailing,
      this.bottom});
  final String title, subtitle, image;
  final double height;
  final Widget? trailing, bottom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(image, fit: BoxFit.cover),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xA603382D), Color(0xAB043E32), Color(0xE804352B)],
          ))),
          SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                child: Column(children: [
                  Row(children: [
                    IconButton.filledTonal(
                      onPressed: Navigator.of(context).canPop()
                          ? () => Navigator.pop(context)
                          : null,
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .16),
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    const Spacer(),
                    if (trailing != null) trailing!,
                  ]),
                  const Spacer(),
                  Text(title,
                      style: Rp.style(27,
                          color: Colors.white, weight: FontWeight.w900),
                      textAlign: TextAlign.center),
                  Text(subtitle,
                      style: Rp.style(12.5, color: const Color(0xFFEEE7D6)),
                      textAlign: TextAlign.center),
                  if (bottom != null) ...[const SizedBox(height: 14), bottom!],
                ]),
              )),
        ]),
      ),
    );
  }
}

class RpCard extends StatelessWidget {
  const RpCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.color = Colors.white});
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Rp.edge),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x07000000),
                  blurRadius: 13,
                  offset: Offset(0, 5))
            ]),
        padding: padding,
        child: child,
      );
}

class RpSectionTitle extends StatelessWidget {
  const RpSectionTitle(this.title, {super.key, this.icon});
  final String title;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 9),
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, color: Rp.green, size: 21),
            const SizedBox(width: 8)
          ],
          Text(title, style: Rp.style(17, weight: FontWeight.w900)),
          const Spacer(),
          Container(
              height: 21,
              width: 3,
              decoration: BoxDecoration(
                  color: Rp.gold, borderRadius: BorderRadius.circular(9))),
        ]),
      );
}

class RpMenuRow extends StatelessWidget {
  const RpMenuRow(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.danger = false,
      this.highlight = false});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  final bool danger, highlight;
  @override
  Widget build(BuildContext context) => Material(
        color: danger ? Rp.softRed : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: danger ? const Color(0xFFD44840) : Rp.cream,
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon,
                        color: danger ? Colors.white : Rp.green, size: 22)),
                const SizedBox(width: 11),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: Rp.style(13.5,
                              color: danger ? Rp.red : Rp.ink,
                              weight: FontWeight.w800)),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Rp.style(10.5, color: Rp.muted)),
                    ])),
                Icon(Icons.chevron_left_rounded,
                    size: 21, color: danger ? Rp.red : Rp.muted),
              ])),
        ),
      );
}

class RpFormField extends StatelessWidget {
  const RpFormField(
      {super.key,
      required this.controller,
      required this.label,
      required this.hint,
      this.icon,
      this.phone = false,
      this.maxLines = 1});
  final TextEditingController controller;
  final String label, hint;
  final IconData? icon;
  final bool phone;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Rp.style(12, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: phone ? TextInputType.phone : TextInputType.text,
            maxLines: maxLines,
            textAlign: TextAlign.right,
            style: Rp.style(14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Rp.style(12, color: Rp.muted),
              prefixIcon:
                  icon == null ? null : Icon(icon, color: Rp.green, size: 19),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Rp.edge)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Rp.green, width: 1.5)),
            ),
          ),
        ]),
      );
}

class RpPrimaryButton extends StatelessWidget {
  const RpPrimaryButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon = Icons.check_rounded});
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 21),
        label: Text(label,
            style: Rp.style(13, color: Colors.white, weight: FontWeight.w800)),
        style: FilledButton.styleFrom(
            backgroundColor: Rp.deep,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18))),
      );
}

bool rpValidPhone(String s) =>
    RegExp(r'^\+?[0-9\s\-()]{3,22}$').hasMatch(s.trim()) &&
    RegExp(r'\d').allMatches(s).length >= 3;

Future<void> rpCall(BuildContext context, String number) async {
  if (!rpValidPhone(number)) {
    rpToast(context, 'رقم غير صالح للاتصال؛ راجعي البيانات.');
    return;
  }
  try {
    final uri = Uri(
        scheme: 'tel', path: number.trim().replaceAll(RegExp(r'[\s()-]'), ''));
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted)
      rpToast(context, 'تعذر فتح تطبيق الهاتف على هذا الجهاز.');
  } catch (_) {
    if (context.mounted) rpToast(context, 'تعذر فتح تطبيق الهاتف.');
  }
}

Future<void> rpCopy(BuildContext context, String number) async {
  await Clipboard.setData(ClipboardData(text: number));
  if (context.mounted) rpToast(context, 'تم نسخ الرقم');
}

void rpToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}

class RpEmpty extends StatelessWidget {
  const RpEmpty(
      {super.key,
      required this.title,
      required this.subtitle,
      this.icon = Icons.contacts_outlined});
  final String title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => RpCard(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(children: [
          Icon(icon, color: Rp.gold, size: 45),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: Rp.style(16, weight: FontWeight.w800)),
          Text(subtitle,
              textAlign: TextAlign.center, style: Rp.style(11, color: Rp.muted))
        ]),
      ));
}
