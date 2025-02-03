import 'package:flutter/material.dart';

class QuestionWidget extends StatefulWidget {
  final String question;
  final String description;
  final List<String> labels;
  final int selectedValue;
  final ValueChanged<int>? onChanged;
  final IconData icon;

  const QuestionWidget({
    Key? key,
    required this.question,
    required this.description,
    required this.labels,
    this.selectedValue = 0,
    this.onChanged,
    required this.icon,
  }) : super(key: key);

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selectedValue;
  }

  Color getSliderColor(double value) {
    int level = value.round();
    return Color.lerp(Colors.blue, Colors.red, level / 4)!;
  }

  @override
  Widget build(BuildContext context) {
    return Card( 
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                widget.question,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.left,
              ),
              subtitle: Text(
                widget.description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.left,
              ),
              leading: Icon(widget.icon,color: Theme.of(context).primaryColor,),
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                activeTrackColor: getSliderColor(_currentValue.toDouble()),
                thumbColor: getSliderColor(_currentValue.toDouble()),
              ),
              child: Slider(
                value: _currentValue.toDouble(),
                min: 0,
                max: 4,
                divisions: 4,
                onChanged: (value) {
                  setState(() {
                    _currentValue = value.round();
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(_currentValue);
                  }
                },
              ),
            ),
            Center(
              child: Text(
                widget.labels[_currentValue],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: getSliderColor(_currentValue.toDouble()),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
