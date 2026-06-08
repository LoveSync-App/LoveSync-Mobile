class CoupleDayModal {
  int loveDays;

  CoupleDayModal({required this.loveDays});

  factory CoupleDayModal.fromJson(Map<String, dynamic> json) {
    return CoupleDayModal(
      loveDays: json['loveDays'],
    );
  }
}