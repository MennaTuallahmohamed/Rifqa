import 'package:flutter/material.dart';
import '../../../models/dua_model.dart';
import '../dua_premium_theme.dart';

class DuaCategoryCard extends StatelessWidget {
  const DuaCategoryCard(
      {super.key,
      required this.category,
      required this.count,
      required this.onTap});
  final DuaCategory category;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        decoration: DuaPremium.card(radius: 20),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Row(children: [
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category.label,
                                    style: DuaPremium.type(13,
                                        weight: FontWeight.w900),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                Text('$count دعاء',
                                    style: DuaPremium.type(10,
                                        color: DuaPremium.muted)),
                              ]))),
                  ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20)),
                      child: Image.asset(DuaPremium.imageFor(category),
                          width: 65,
                          height: double.infinity,
                          fit: BoxFit.cover)),
                ]))),
      );
}
