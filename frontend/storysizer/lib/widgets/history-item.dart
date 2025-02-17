import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HistoryItem extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String points;
  final VoidCallback onDeleted;
  final VoidCallback onTap;
  final IconData icon;

  const HistoryItem({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.onDeleted,
    required this.icon, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Card( 
        margin: const EdgeInsets.only(bottom: 12.0),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.left,
                ),
                subtitle: Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.left,
                ),
                leading: Text(
                  points,
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.right,
                ),
                trailing: GestureDetector(
                  child: Icon(
                    icon,
                    color: Theme.of(context).disabledColor,
                  ),
                  onTap: onDeleted,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
