enum HaramType {
  makkah,
  madinah,
}

class Haram {
  final String id;
  final HaramType type;

  final String name;
  final String city;
  final String subtitle;

  final String emoji;

  final double mapWidth;
  final double mapHeight;

  const Haram({
    required this.id,
    required this.type,
    required this.name,
    required this.city,
    required this.subtitle,
    required this.emoji,
    this.mapWidth = 1000,
    this.mapHeight = 1000,
  });

  bool get isMakkah => type == HaramType.makkah;

  bool get isMadinah => type == HaramType.madinah;

  String get shortName {
    switch (type) {
      case HaramType.makkah:
        return 'الحرم المكي';

      case HaramType.madinah:
        return 'الحرم المدني';
    }
  }

  String get locationLabel => '$city • $name';

  Haram copyWith({
    String? id,
    HaramType? type,
    String? name,
    String? city,
    String? subtitle,
    String? emoji,
    double? mapWidth,
    double? mapHeight,
  }) {
    return Haram(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      city: city ?? this.city,
      subtitle: subtitle ?? this.subtitle,
      emoji: emoji ?? this.emoji,
      mapWidth: mapWidth ?? this.mapWidth,
      mapHeight: mapHeight ?? this.mapHeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'city': city,
      'subtitle': subtitle,
      'emoji': emoji,
      'mapWidth': mapWidth,
      'mapHeight': mapHeight,
    };
  }

  factory Haram.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;

    final type = HaramType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => HaramType.makkah,
    );

    return Haram(
      id: json['id'] as String? ?? '',
      type: type,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🕌',
      mapWidth: (json['mapWidth'] as num?)?.toDouble() ?? 1000,
      mapHeight: (json['mapHeight'] as num?)?.toDouble() ?? 1000,
    );
  }

  @override
  String toString() {
    return 'Haram(id: $id, name: $name, city: $city)';
  }
}