class TopicDto {
  final int id;
  final String name;
  final double accuracy;
  final bool unlocked;

  TopicDto({
    required this.id,
    required this.name,
    required this.accuracy,
    required this.unlocked,
  });

  factory TopicDto.fromJson(Map<String, dynamic> json) {
    final int id = (json['id'] ?? json['topicId'] ?? 0) as int;
    final String name =
        (json['name'] ?? json['topicName'] ?? json['topic_name'] ?? '')
            .toString();
    final double accuracy = ((json['accuracy'] ?? json['progress'] ?? 0) as num)
        .toDouble();
    final bool unlocked = json['unlocked'] == null
        ? true
        : (json['unlocked'] as bool);

    return TopicDto(id: id, name: name, accuracy: accuracy, unlocked: unlocked);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'accuracy': accuracy,
    'unlocked': unlocked,
  };
}
