import 'package:flutter/material.dart';
import '../../../models/dua_model.dart';
import '../dua_premium_theme.dart';

class DuaSourceBadge extends StatelessWidget {
  const DuaSourceBadge(this.type, {super.key});
  final DuaSourceType type;
  @override
  Widget build(BuildContext context) {
    final documented = type.isDocumented;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
            color:
                documented ? const Color(0xFFE3EEE5) : const Color(0xFFF6ECD7),
            borderRadius: BorderRadius.circular(21)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
              documented ? Icons.verified_outlined : Icons.info_outline_rounded,
              size: 15,
              color: DuaPremium.green),
          const SizedBox(width: 5),
          Text(type.label, style: DuaPremium.type(10, weight: FontWeight.w700)),
        ]));
  }
}

class DuaCard extends StatelessWidget {
  const DuaCard(
      {super.key,
      required this.dua,
      required this.isFavorite,
      required this.onTap,
      required this.onFavorite});
  final Dua dua;
  final bool isFavorite;
  final VoidCallback onTap, onFavorite;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 11),
      decoration: DuaPremium.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(DuaPremium.imageFor(dua.category),
                          width: 72, height: 79, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(dua.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                DuaPremium.type(13.5, weight: FontWeight.w900)),
                        Text(dua.arabicText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DuaPremium.type(11,
                                color: DuaPremium.muted, height: 1.8)),
                        const SizedBox(height: 5),
                        DuaSourceBadge(dua.sourceType),
                      ])),
                  IconButton(
                      onPressed: onFavorite,
                      icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color:
                              isFavorite ? DuaPremium.gold : DuaPremium.green)),
                ]))),
      ));
}
