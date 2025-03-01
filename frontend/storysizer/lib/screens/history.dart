import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/providers.dart';
import 'package:storysizer/widgets/history-item.dart';

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  @override
  void initState() {
    super.initState();
    // Carica le stories appena la view viene creata
    Future.microtask(() =>
        ref.read(storiesNotifierProvider.notifier).loadStories());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storiesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Storico"),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text("Errore: ${state.error}"))
              : state.stories == null || state.stories!.isEmpty
                  ? const Center(child: Text("Nessuna storia presente"))
                  : ListView.builder(
                      itemCount: state.stories!.length,
                      itemBuilder: (context, index) {
                        final story = state.stories![index];
                        return HistoryItem(
                          id: story.id,
                          title: story.name,
                          // Ignoriamo il campo description
                          description: '',
                          // Per esempio, possiamo mostrare l'owner come "points"
                          points: story.owner,
                          icon: CupertinoIcons.delete_solid,
                          onDeleted: () {
                            ref
                                .read(storiesNotifierProvider.notifier)
                                .deleteStory(story.id);
                          },
                          onTap: () {
                            context.go('/home/estimation');
                          },
                        );
                      },
                    ),
    );
  }
}
