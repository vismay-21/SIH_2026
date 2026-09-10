class GigDraft {
  GigDraft({
    required this.category,
    this.categoryId,
    this.taskIds = const [],
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.duration,
    required this.isEmergency,
    required this.photoCount,
    required this.instructions,
    required this.customerBuysMaterials,
    this.requiresVisitation = false,
  });

  final String category;
  final String? categoryId;
  final List<String> taskIds;
  final String description;
  final String location;
  final DateTime? date;
  final String? time;
  final String duration;
  final bool isEmergency;
  final int photoCount;
  final String instructions;
  final bool customerBuysMaterials;
  final bool requiresVisitation;
}
