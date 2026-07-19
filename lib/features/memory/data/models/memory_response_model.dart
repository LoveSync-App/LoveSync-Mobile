class MemoryResponseModel {
  final String id;
  final String fileUrl;
  final String description;
  final DateTime time;

  MemoryResponseModel({
    required this.id,
    required this.fileUrl,
    required this.description,
    required this.time,
  });

  factory MemoryResponseModel.fromJson(Map<String, dynamic> json) {
    return MemoryResponseModel(
      id: json['_id'],
      fileUrl: json['file_url'],
      description: json['description'],
      time: (DateTime.tryParse(json['time'].toString()) ?? DateTime.now()),
    );
  }
}
