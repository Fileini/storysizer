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

  // Ignoriamo le descrizioni, oppure le lasciamo vuote
  final List<String> descriptions = [
    "",
    "",
    "",
    "",
    ""
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

  // Valori degli slider inizializzati a 2 (valore medio)
  List<int> selectedValues = List.filled(5, 2);

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
          try {
            // Creazione della Story con il nome passato
            final story = await repository.createStory(widget.name);
            // Mappatura dei valori:
            // - Reach    -> selectedValues[0]
            // - Complexity -> selectedValues[1]
            // - Dimensions -> selectedValues[2]
            // - Risk       -> selectedValues[3]
            // - Interaction-> selectedValues[4]
            print("storia creata :"+story.toString());
            print("storia creata :"+story.id);
            final estimation = await repository.createEstimation(
              name: widget.name,
              complexity: selectedValues[1],
              reach: selectedValues[0],
              dimension: selectedValues[2],
              risk: selectedValues[3],
              interaction: selectedValues[4],
              storyId: story.id,
            );


            // Puoi opzionalmente navigare o mostrare un messaggio di successo
            print("Estimation creata: ${estimation.id}");
            print("Estimation creata sto: ${estimation.story.id}");
            // Ad esempio, naviga alla pagina dei dettagli o torna indietro
            context.go('/home/estimation');
          } catch (e) {
            print("Errore durante la creazione dell'estimazione: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Errore durante la creazione dell'estimazione")),
            );
          }
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
