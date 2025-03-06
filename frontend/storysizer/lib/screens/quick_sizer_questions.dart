import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/widgets/question.dart';
import 'package:storysizer/providers.dart';

class QuickSizerQuestionsView extends ConsumerStatefulWidget {
  final String name;

  const QuickSizerQuestionsView({Key? key, required this.name}) : super(key: key);

  @override
  ConsumerState<QuickSizerQuestionsView> createState() => _QuickSizerQuestionsViewState();
}

class _QuickSizerQuestionsViewState extends ConsumerState<QuickSizerQuestionsView> {
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
    CupertinoIcons.arrow_branch,         // Complexity
    CupertinoIcons.layers,               // Dimensions
    CupertinoIcons.exclamationmark_triangle, // Risk
    CupertinoIcons.person_3_fill         // Interaction
  ];

  // Valori degli slider inizializzati a 1
  List<int> selectedValues = List.filled(5, 0);

  @override
  Widget build(BuildContext context) {
    List<Widget> list = List.generate(questions.length, (index) {
      return QuestionWidget(
        question: questions[index],
        description: descriptions[index],
        labels: labels[index],
        icon: icons[index],
        selectedValue: selectedValues[index],
        onChanged: (value) {
          setState(() {
            selectedValues[index] = value;
          });
        },
      );
    });

    // Bottone Estimate che crea prima la Story e poi l'Estimation
    list.add(
      ElevatedButton(
        onPressed: () async {
          final repository = ref.read(dataRepositoryProvider);
           String estimationid = '';
          try {
            final story = await repository.createStory(widget.name);

            final estimation = await repository.createEstimation(
              name: widget.name,
              complexity: selectedValues[1]+1,
              reach: selectedValues[0]+1,
              dimension: selectedValues[2]+1,
              risk: selectedValues[3]+1,
              interaction: selectedValues[4]+1,
              storyId: story.id,
            );
            estimationid = estimation.id;
          } catch (e) {
            print("Error");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error")),
            );
          }
           await ref.refresh(estimationProvider(estimationid).future);
            context.go('/home/estimation/$estimationid');
        },
        style: ElevatedButton.styleFrom(
          fixedSize: const Size(200, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Text(
          'Estimate',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Center(child: Text('Sizing: ' + widget.name)),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: list,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
