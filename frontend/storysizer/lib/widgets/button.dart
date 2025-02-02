import 'package:flutter/material.dart';


class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    this.onPressed,
    this.highlighColor = false,
    this.text,
    this.child,
    this.padding = const EdgeInsets.fromLTRB(55, 15, 55, 15),
  });

  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;
  final bool highlighColor;
  final EdgeInsets padding;

  Color get backgroundColor {
    return Colors.white;
  }

  Color get textColor {
    return Colors.white ;
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: key,
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(
          backgroundColor,
        ),
        side: WidgetStateProperty.all<BorderSide>(
          const BorderSide(color: Colors.white),
        ),
        padding: WidgetStateProperty.all<EdgeInsets>(padding),
        shape: WidgetStateProperty.all(
          const StadiumBorder(),
        ),
      ),
      child: child != null
          ? child ?? const SizedBox()
          : Text(
              text ?? '',
              style: TextStyle(color: textColor),
            ),
    );
  }
}
