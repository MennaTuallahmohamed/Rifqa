class HaramFloor {
  final String id;
  final String haramId;

  final String name;
  final int level;

  final bool available;

  const HaramFloor({
    required this.id,
    required this.haramId,
    required this.name,
    required this.level,
    this.available = true,
  });

  String get levelLabel {
    if (level == 0) {
      return 'الدور الأرضي';
    }

    if (level < 0) {
      return 'المستوى $level';
    }

    return 'الدور $level';
  }
}