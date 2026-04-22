import 'story.dart';

class Estimation {
  final String id;
  final int complexity;
  final int reach;
  final int dimensions;
  final int risk;
  final int interaction;
  final int? size;
  final Story story;

  Estimation({
    required this.id,
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
      complexity: json['complexity'] as int,
      reach: json['reach'] as int,
      dimensions: json['dimensions'] as int,
      risk: json['risk'] as int,
      interaction: json['interaction'] as int,
      size: json['sizer'] != null ? int.tryParse(json['sizer'].toString()) : null,
      story: Story.fromJson(json['story'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'complexity': complexity,
        'reach': reach,
        'dimensions': dimensions,
        'risk': risk,
        'interaction': interaction,
        'sizer': size,
      };

  @override
  String toString() => toJson().toString();
  
}
