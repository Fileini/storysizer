import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:storysizer/widgets/question.dart';

class QuickSizerQuestionsView extends StatefulWidget {
  final String name;

  const QuickSizerQuestionsView({super.key,required this.name});

  @override
  _QuickSizerQuestionsViewState createState() => _QuickSizerQuestionsViewState();
}

class _QuickSizerQuestionsViewState extends State<QuickSizerQuestionsView> {
  final List<String> questions = [
    "Reach",
    "Complexity",
    "Dimensions",
    "Risk",
    "Interaction"
  ];

  final List<String> descriptions = [
    "How much do you think the technical aspects of this story fall within the scrum team’s competences?",
    "How interconnected are the different parts of this story?",
    "How many different parts do you think this story has?",
    "How high do you think the probability of encountering risks with significant impact on the realisation is?",
    "How many stakeholders are involved outside the scrum team?"
  ];

  final List<List<String>> labels = [
    ["Completely", "Mostly within", "Partially within", "Mostly outside", "Completely outside"],
    ["Very simple", "Slightly interconnected", "Moderately interconnected", "Highly interconnected", "Extremely complex"],
    ["Single unit", "Few parts", "Several parts", "Many parts", "Highly modular"],
    ["Negligible", "Low risk", "Moderate Risk", "High risk", "Critical risk"],
    ["None", "Single person", "Few People", "Many People", "High Interaction"]
  ];

  final List<IconData> icons = [
    CupertinoIcons.check_mark_circled, // Reach
    CupertinoIcons.arrow_branch, // Complexity
    CupertinoIcons.layers, // Dimensions
    CupertinoIcons.exclamationmark_triangle, // Risk
    CupertinoIcons.person_3_fill // Interaction
  ];

  List<int> selectedValues = List.filled(5, 2);

  Color getSliderColor(double value) {
    int level = value.round();
    return Color.lerp(Colors.blue, Colors.red, level / 4)!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Padding(
        padding: const EdgeInsets.all(3.0),
        child: Center(child: Text('Sizing: '+ widget.name)),
      ),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(questions.length, (index) {
                    return QuestionWidget(
                      question: questions[index],
                      description: descriptions[index],
                      labels: labels[index],
                      icon: icons[index], // Passa l'icona al widget
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
