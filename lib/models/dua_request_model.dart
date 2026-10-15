enum DuaRequestStatus {
  pending,
  prayed,
}

class DuaRequest {
  const DuaRequest({
    required this.id,
    required this.personName,
    required this.request,
    this.note = '',
    this.status = DuaRequestStatus.pending,
    this.createdAt,
    this.prayedAt,
  });

  final String id;
  final String personName;
  final String request;
  final String note;
  final DuaRequestStatus status;
  final DateTime? createdAt;
  final DateTime? prayedAt;

  bool get isPrayed => status == DuaRequestStatus.prayed;

  DuaRequest copyWith({
    String? personName,
    String? request,
    String? note,
    DuaRequestStatus? status,
    DateTime? createdAt,
    DateTime? prayedAt,
    bool clearPrayedAt = false,
  }) {
    return DuaRequest(
      id: id,
      personName: personName ?? this.personName,
      request: request ?? this.request,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      prayedAt: clearPrayedAt ? null : prayedAt ?? this.prayedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'request': request,
      'note': note,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
      'prayedAt': prayedAt?.toIso8601String(),
    };
  }

  factory DuaRequest.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;

    return DuaRequest(
      id: json['id'] as String? ?? '',
      personName: json['personName'] as String? ?? '',
      request: json['request'] as String? ?? '',
      note: json['note'] as String? ?? '',
      status: DuaRequestStatus.values.any(
        (e) => e.name == statusName,
      )
          ? DuaRequestStatus.values.firstWhere(
              (e) => e.name == statusName,
            )
          : DuaRequestStatus.pending,
      createdAt: DateTime.tryParse(
        json['createdAt'] as String? ?? '',
      ),
      prayedAt: DateTime.tryParse(
        json['prayedAt'] as String? ?? '',
      ),
    );
  }
}
