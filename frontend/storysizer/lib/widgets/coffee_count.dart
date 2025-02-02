import 'package:flutter/material.dart';

import 'button.dart';

class CoffeeCount extends StatefulWidget {
  const CoffeeCount({
    super.key,
    this.price,
    this.notifyValue,
  });

  final num? price;
  final Function(int)? notifyValue;

  @override
  _CoffeeCountState createState() => _CoffeeCountState();
}

class _CoffeeCountState extends State<CoffeeCount> {
  int count = 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CommonButton(
          padding: const EdgeInsets.all(5),
          onPressed: () {
            if (count > 1) {
              setState(() {
                count = count - 1;
              });
            }
            widget.notifyValue!(count);
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(width: 20),
        Text(
          "$count",
          style: TextStyle(
            color: Colors.brown.shade800,
            fontSize: 26,
          ),
        ),
        const SizedBox(width: 20),
        CommonButton(
          padding: const EdgeInsets.all(5),
          onPressed: () {
            setState(() {
              count = count + 1;
            });
            widget.notifyValue!(count);
          },
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}
