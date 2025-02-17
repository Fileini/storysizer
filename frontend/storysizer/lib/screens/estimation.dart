import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class EstimationView extends StatelessWidget {
  final String points = "22";
  final String title = "Title of the Story";
  final String outcome = "XL";
  final double complexity = 3;
  final double reach = 2;
  final double risk = 1;
  final double dimensions = 2;
  final double interaction = 3;

  

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
            child: Column(
              children: [
                // Riga superiore con points, title e outcome
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row( 
                    children: [
                      // Top left: points
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            points,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                      ),
                      // Top center: title
                      Expanded(
                        child: Center(
                          child: Text(
                            title,
                            // Puoi scegliere uno stile appropriato per il titolo
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      // Top right: outcome
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            outcome,
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
                              name: 'name',
                              sortingOrder: SortingOrder.ascending,
                              sortFieldValueMapper: (ChartData data, _) => data.value,
                              maximumValue: 5,
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
                                ChartData('Complexity', complexity),
                                ChartData('Reach', reach),
                                ChartData('Risk', risk),
                                ChartData('Dimensions', dimensions),
                                ChartData('Interaction', interaction),
                              ],
                              xValueMapper: (ChartData data, _) => data.label,
                              yValueMapper: (ChartData data, _) => data.value,
                              dataLabelMapper: (ChartData data, _) => data.label,
                              dataLabelSettings:  DataLabelSettings(isVisible: true, textStyle: Theme.of(context).textTheme.bodySmall),
                              
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
                        child: Align( alignment: Alignment.centerLeft,
                          child: Text(
                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
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
  
  }
}

// Classe di supporto per i dati del chart
class ChartData {
  final String label;
  final double value;
  ChartData(this.label, this.value);
}
