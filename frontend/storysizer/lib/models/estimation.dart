import 'story.dart';

class Estimation {
  final String id;
  final String owner;
  final int complexity;
  final int reach;
  final int dimensions;
  final int risk;
  final int interaction;
  final int? size;
  final Story story;
  
  Estimation({
    required this.id,
    required this.owner,
    required this.complexity,
    required this.reach,
    required this.dimensions,
    required this.risk,
    required this.interaction,
    this.size,
    required this.story,
  });
  
  factory Estimation.fromJson(Map<String, dynamic> json) {
    return Estimation(
      id: json['id'] as String,
      owner: json['owner'] as String,
      complexity: json['complexity'] as int,
      reach: json['reach'] as int,
      dimensions: json['dimensions'] as int,
      risk: json['risk'] as int,
      interaction: json['interaction'] as int,
      size: json['size'] != null ? json['size'] as int : null,
      story: Story.fromJson(json['story'] as Map<String, dynamic>),
    );
  }
}
