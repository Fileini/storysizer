import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/models/group_estimation.dart';
import 'package:storysizer/providers.dart';

class GroupEstimationDashboardView extends ConsumerWidget {
  final String groupId;
  final String estimationId;

  const GroupEstimationDashboardView({
    super.key,
    required this.groupId,
    required this.estimationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(groupEstimationDashboardProvider(estimationId));

    return dashAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (dash) => Scaffold(
        appBar: AppBar(
          title: Text(dash.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/groups/$groupId'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(groupEstimationDashboardProvider(estimationId)),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(groupEstimationDashboardProvider(estimationId)),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Header
              Text(dash.groupName,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    dash.allVoted ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: dash.allVoted ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${dash.submittedVoters} / ${dash.totalVoters} voted',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!dash.allVoted)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Waiting for ${dash.totalVoters - dash.submittedVoters} more vote(s)…\nResults may change.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              if (!dash.allVoted) const SizedBox(height: 16),

              // Parameter bars
              _ParameterBar(
                label: 'Reach',
                avg: dash.reachAvg,
                agreement: dash.reachAgreement,
              ),
              _ParameterBar(
                label: 'Complexity',
                avg: dash.complexityAvg,
                agreement: dash.complexityAgreement,
              ),
              _ParameterBar(
                label: 'Dimensions',
                avg: dash.dimensionsAvg,
                agreement: dash.dimensionsAgreement,
              ),
              _ParameterBar(
                label: 'Risk',
                avg: dash.riskAvg,
                agreement: dash.riskAgreement,
              ),
              _ParameterBar(
                label: 'Interaction',
                avg: dash.interactionAvg,
                agreement: dash.interactionAgreement,
              ),

              const SizedBox(height: 16),
              _AgreementLegend(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Parameter bar widget ─────────────────────────────────────────────────────

class _ParameterBar extends StatelessWidget {
  final String label;
  final double avg;      // 1.0 – 5.0
  final double agreement; // 0.0 – 1.0

  const _ParameterBar(
      {required this.label, required this.avg, required this.agreement});

  /// Maps agreement 0→red, 0.5→orange, 1→blue using HSV interpolation.
  Color _agreementColor() {
    // Hue: 0 = red, 220 = blue
    final hue = 220.0 * agreement;
    // Saturation and value slightly muted for nice aesthetics
    return HSVColor.fromAHSV(1.0, hue, 0.75, 0.85).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final color = _agreementColor();
    final progress = ((avg - 1.0) / 4.0).clamp(0.0, 1.0);
    final pct = (agreement * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'avg ${avg.toStringAsFixed(1)}  •  $pct% agreement',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Agreement legend ─────────────────────────────────────────────────────────

class _AgreementLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Text('Agreement: ', style: TextStyle(fontSize: 12)),
          _legendDot(Colors.red, 'Low'),
          const SizedBox(width: 8),
          _legendDot(Colors.orange, 'Medium'),
          const SizedBox(width: 8),
          _legendDot(const Color(0xFF1565C0), 'High'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
