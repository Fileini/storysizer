import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/providers.dart';
import 'package:storysizer/widgets/question.dart';

class GroupEstimationVoteView extends ConsumerStatefulWidget {
  final String groupId;
  final String estimationId;

  const GroupEstimationVoteView({
    super.key,
    required this.groupId,
    required this.estimationId,
  });

  @override
  ConsumerState<GroupEstimationVoteView> createState() =>
      _GroupEstimationVoteViewState();
}

class _GroupEstimationVoteViewState extends ConsumerState<GroupEstimationVoteView> {
  final List<String> questions = [
    "Reach",
    "Complexity",
    "Dimensions",
    "Risk",
    "Interaction",
  ];

  final List<String> descriptions = [
    "How much do you think the technical aspects of this story fall within the scrum team's competences?",
    "How interconnected are the different parts of this story?",
    "How many different parts do you think this story has?",
    "How high do you think the probability of encountering risks with significant impact on the realisation is?",
    "How many stakeholders are involved outside the scrum team?",
  ];

  final List<List<String>> labels = [
    ["Completely", "Mostly within", "Partially within", "Mostly outside", "Completely outside"],
    ["Very simple", "Slightly interconnected", "Moderately interconnected", "Highly interconnected", "Extremely complex"],
    ["Single unit", "Few parts", "Several parts", "Many parts", "Highly modular"],
    ["Negligible", "Low risk", "Moderate Risk", "High risk", "Critical risk"],
    ["None", "Single person", "Few People", "Many People", "High Interaction"],
  ];

  final List<IconData> icons = [
    CupertinoIcons.check_mark_circled,
    CupertinoIcons.arrow_branch,
    CupertinoIcons.layers,
    CupertinoIcons.exclamationmark_triangle,
    CupertinoIcons.person_3_fill,
  ];

  List<int> selectedValues = List.filled(5, 0);
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate from existing vote if already voted (shouldn't happen but defensive)
    Future.microtask(() async {
      final vote = await ref.read(dataRepositoryProvider).fetchMyVote(widget.estimationId);
      if (vote != null && vote.isSubmitted && mounted) {
        // Already voted — send to dashboard
        context.go('/groups/${widget.groupId}/estimation/${widget.estimationId}/dashboard');
        return;
      }
      if (vote != null && !vote.isSubmitted && mounted) {
        setState(() {
          selectedValues[0] = (vote.reach ?? 1) - 1;
          selectedValues[1] = (vote.complexity ?? 1) - 1;
          selectedValues[2] = (vote.dimensions ?? 1) - 1;
          selectedValues[3] = (vote.risk ?? 1) - 1;
          selectedValues[4] = (vote.interaction ?? 1) - 1;
        });
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(dataRepositoryProvider).submitGroupEstimationVote(
            groupEstimationId: widget.estimationId,
            reach: selectedValues[0] + 1,
            complexity: selectedValues[1] + 1,
            dimensions: selectedValues[2] + 1,
            risk: selectedValues[3] + 1,
            interaction: selectedValues[4] + 1,
          );
      ref.read(pendingCountNotifierProvider.notifier).refresh();
      ref.read(groupEstimationFeedNotifierProvider.notifier).loadFeed();
      if (mounted) {
        context.go('/groups/${widget.groupId}/estimation/${widget.estimationId}/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error submitting vote: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // The vote provider is loaded lazily in initState; title comes from the
  // groupEstimationsNotifier already loaded in the group detail.
  // We use a FutureProvider here for the vote to pre-populate values.
  @override
  Widget build(BuildContext context) {
    final voteAsync = ref.watch(myVoteProvider(widget.estimationId));

    final List<Widget> list = List.generate(questions.length, (index) {
      return QuestionWidget(
        question: questions[index],
        description: descriptions[index],
        labels: labels[index],
        icon: icons[index],
        selectedValue: selectedValues[index],
        onChanged: (value) => setState(() => selectedValues[index] = value),
      );
    });

    list.add(
      _submitting
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(200, 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text('Submit Vote',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
    );

    return Scaffold(
      appBar: AppBar(
        title: voteAsync.when(
          data: (_) => const Text('Group Estimation'),
          loading: () => const Text('Group Estimation'),
          error: (_, __) => const Text('Group Estimation'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/groups/${widget.groupId}'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      ),
    );
  }
}
