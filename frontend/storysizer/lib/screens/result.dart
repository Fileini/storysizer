import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ResultView extends StatelessWidget {
  final String points = "22";
  final String title = "title";
  final String outcome = "Split";
  final double complexity = 3;
  final double reach = 2;
  final double risk = 1;
  final double dimensions = 2;
  final double interaction = 3;

  

  @override
  Widget build(BuildContext context) {
    return Card(
          child: Column(
            children: [
              // Riga superiore con points, title e outcome
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Top left: points
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          points,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                    ),
                    // Top center: title
                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          // Puoi scegliere uno stile appropriato per il titolo
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    // Top right: outcome
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          outcome,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Area centrale: Radial Bar Chart di Syncfusion
              Expanded(
                child: Center(
                  child: SfCircularChart(
                    series: <CircularSeries>[
                      RadialBarSeries<ChartData, String>(
                        dataSource: [
                          ChartData('Complexity', complexity),
                          ChartData('Reach', reach),
                          ChartData('Risk', risk),
                          ChartData('Dimensions', dimensions),
                          ChartData('Interaction', interaction),
                        ],
                        xValueMapper: (ChartData data, _) => data.label,
                        yValueMapper: (ChartData data, _) => data.value,
                        dataLabelSettings: const DataLabelSettings(isVisible: true),
                      )
                    ],
                  ),
                ),
              ),
              // Testo in basso con lorem ipsum
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
  
  }
}

// Classe di supporto per i dati del chart
class ChartData {
  final String label;
  final double value;
  ChartData(this.label, this.value);
}
