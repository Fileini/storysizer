import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storysizer/providers.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Classe di supporto per i dati del chart
class ChartData {
  final String label;
  final double value;
  ChartData(this.label, this.value);
}

class EstimationView extends ConsumerStatefulWidget {
  final String id;
  const EstimationView({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<EstimationView> createState() => _EstimationViewState();
}

class _EstimationViewState extends ConsumerState<EstimationView> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sottoscrivi la route corrente all'observer
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Quando torni a questa pagina, rinfresca il provider
    ref.refresh(estimationProvider(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final asyncEstimation = ref.watch(estimationProvider(widget.id));

    return asyncEstimation.when(
      data: (estimation) {
        return SingleChildScrollView(
          child: Card(
            child: Column(
              children: [
                // Riga superiore con points, title e outcome
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Top left: per esempio, visualizziamo il campo "owner" come points
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            estimation.size?.toString() ?? '',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                      ),
                      // Top center: titolo, ad esempio il nome della Story collegata
                      Expanded(
                        child: Center(
                          child: Text(
                            estimation.story.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      // Top right: outcome, ad esempio il campo size (o un altro valore da definire)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            estimation.size?.toString() ?? '',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Area centrale: Radial Bar Chart di Syncfusion
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: SfCircularChart(
                          series: <CircularSeries>[
                            RadialBarSeries<ChartData, String>(
                              name: 'Estimation',
                              sortingOrder: SortingOrder.ascending,
                              sortFieldValueMapper: (ChartData data, _) => data.value,
                              maximumValue: 6,
                              pointColorMapper: (ChartData data, _) => Color.lerp(
                                const Color.fromARGB(66, 255, 193, 7),
                                Colors.amber,
                                data.value / 4,
                              ),
                              trackColor: Colors.transparent,
                              trackBorderColor: Colors.transparent,
                              strokeColor: Colors.transparent,
                              cornerStyle: CornerStyle.bothCurve,
                              dataSource: [
                                ChartData('Complexity', estimation.complexity.toDouble()),
                                ChartData('Reach', estimation.reach.toDouble()),
                                ChartData('Risk', estimation.risk.toDouble()),
                                ChartData('Dimensions', estimation.dimensions.toDouble()),
                                ChartData('Interaction', estimation.interaction.toDouble()),
                              ],
                              xValueMapper: (ChartData data, _) => data.label,
                              yValueMapper: (ChartData data, _) => data.value,
                              dataLabelMapper: (ChartData data, _) => data.label,
                              dataLabelSettings: DataLabelSettings(
                                isVisible: true,
                                textStyle: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Testo in basso con lorem ipsum
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "This is the estimation in Story Points with the single details, the most critical aspects of this story are represented by the outer rings.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Errore: $error')),
    );
  }
}
