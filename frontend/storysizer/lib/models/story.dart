class Story {
  final String id;
  final String name;

  Story({required this.id, required this.name});

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}


