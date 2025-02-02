import 'package:flutter/material.dart';

class QuickSizerView extends StatelessWidget {
  const QuickSizerView({super.key});

  /// -----------------------------------
  ///  QuickSizerView
  /// -----------------------------------
  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            
            Text("Quick Size",
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
          ],
        );
  }
}
