class CoupleDayModal {
  int loveDays;
  DateTime? startDate;

  CoupleDayModal({required this.loveDays, this.startDate});

  factory CoupleDayModal.fromJson(Map<String, dynamic> json) {
    return CoupleDayModal(
      loveDays: json['loveDays'],
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
    );
  }
}
