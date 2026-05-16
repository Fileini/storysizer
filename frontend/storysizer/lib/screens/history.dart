import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/models/group_estimation.dart';
import 'package:storysizer/providers.dart';
import 'package:storysizer/widgets/history-item.dart';

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> with RouteAware {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(estimationsNotifierProvider.notifier).loadEstimations();
      ref.read(groupEstimationFeedNotifierProvider.notifier).loadFeed();
      ref.read(pendingCountNotifierProvider.notifier).refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    ref.read(estimationsNotifierProvider.notifier).loadEstimations();
    ref.read(groupEstimationFeedNotifierProvider.notifier).loadFeed();
    ref.read(pendingCountNotifierProvider.notifier).refresh();
  }

  void _navigateToEstimation(GroupEstimationItemModel item) {
    if (item.isPending) {
      context.go('/groups/${item.groupId}/estimation/${item.id}/vote');
    } else {
      context.go('/groups/${item.groupId}/estimation/${item.id}/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimState = ref.watch(estimationsNotifierProvider);
    final feedState = ref.watch(groupEstimationFeedNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Estimations"),
      ),
      body: (estimState.isLoading && feedState.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(estimationsNotifierProvider.notifier).loadEstimations();
                ref.read(groupEstimationFeedNotifierProvider.notifier).loadFeed();
                ref.read(pendingCountNotifierProvider.notifier).refresh();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  // ── Group estimations section ──────────────────────────────
                  if (feedState.items?.isNotEmpty == true) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Group Estimations',
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    ...feedState.items!.map((item) => _GroupEstimationFeedItem(
                          item: item,
                          onTap: () => _navigateToEstimation(item),
                        )),
                    const Divider(height: 24),
                  ],

                  // ── Quick estimations section ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Quick Estimations',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  if (estimState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (estimState.error != null)
                    Center(child: Text("Error: ${estimState.error}"))
                  else if (estimState.estimations == null || estimState.estimations!.isEmpty)
                    const Center(child: Text("No quick estimations yet."))
                  else
                    ...estimState.estimations!.map((estimation) => HistoryItem(
                          id: estimation.story.id,
                          title: estimation.story.name,
                          description: '',
                          points: estimation.size.toString(),
                          icon: CupertinoIcons.delete_solid,
                          onDeleted: () async {
                            await ref
                                .read(storiesNotifierProvider.notifier)
                                .deleteStory(estimation.story.id);
                            await ref
                                .read(estimationsNotifierProvider.notifier)
                                .loadEstimations();
                          },
                          onTap: () {
                            context.go('/home/estimation/${estimation.id}');
                          },
                        )),
                ],
              ),
            ),
    );
  }
}

class _GroupEstimationFeedItem extends StatelessWidget {
  final GroupEstimationItemModel item;
  final VoidCallback onTap;

  const _GroupEstimationFeedItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPending = item.isPending;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: isPending
            ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.4)
            : null,
        child: ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor:
                isPending ? Colors.amber.shade600 : Colors.green.shade600,
            child: Icon(
              isPending ? CupertinoIcons.exclamationmark : CupertinoIcons.checkmark,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(item.title,
              style: Theme.of(context).textTheme.titleMedium),
          subtitle: item.groupName != null
              ? Text(item.groupName!,
                  style: Theme.of(context).textTheme.bodySmall)
              : null,
          trailing: isPending
              ? Chip(
                  label: const Text('Vote now'),
                  backgroundColor: Colors.amber.shade100,
                  labelStyle: const TextStyle(fontSize: 11),
                )
              : const Icon(CupertinoIcons.chart_bar_fill, size: 18),
        ),
      ),
    );
  }
}
