import 'package:flutter/material.dart';
import 'dart:ui';

class QuickSizerView extends StatefulWidget {
  const QuickSizerView({super.key});

  @override
  _QuickSizerViewState createState() => _QuickSizerViewState();
}

class _QuickSizerViewState extends State<QuickSizerView> {
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
    "How many stakeholders are involved outside the outside the scrum team?"
  ];

  final List<List<String>> labels = [
    ["Completely", "Mostly within", "Partially within", "Mostly outside", "Completely outside"],
    ["Very simple", "Slightly interconnected", "Moderately interconnected", "Highly interconnected", "Extremely complex"],
    ["Single unit", "Few parts", "Several parts", "Many parts", "Highly modular"],
    ["Negligible", "Low risk", "Moderate Risk", "High risk", "Critical risk"],
    ["None", "Single person", "Few People", "Many People", "High Interaction"]
  ];

  List<int> selectedValues = List.filled(5, 2);

  Color getSliderColor(double value) {
    int level = value.round();
    return Color.lerp(Colors.blue, Colors.red, level / 4)!;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(questions.length, (index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            questions[index],
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text( 
                          descriptions[index],
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(height: 10),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 5.0,
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                            activeTrackColor: getSliderColor(selectedValues[index].toDouble()),
                            thumbColor: getSliderColor(selectedValues[index].toDouble()),
                          ),
                          child: Slider(
                            value: selectedValues[index].toDouble(),
                            min: 0,
                            max: 4,
                            divisions: 4,
                            onChanged: (value) {
                              setState(() {
                                selectedValues[index] = value.round();
                              });
                            },
                          ),
                        ),
                        Center(
                          child: Text(
                            labels[index][selectedValues[index]],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: getSliderColor(selectedValues[index].toDouble()),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
