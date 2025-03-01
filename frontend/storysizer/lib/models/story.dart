class Story {
  final String id;
  final String name;
  final String owner;
  
  Story({required this.id, required this.name, required this.owner});
  
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      name: json['name'] as String,
      owner: json['owner'] as String,
    );
  }
}


