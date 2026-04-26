import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ComingSoonScreen extends StatelessWidget {
  final String feature;
  const ComingSoonScreen({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🚧', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text(
                  '$feature login is coming',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This login method isn\'t live yet — implementing and maintaining '
                  'every identity provider takes real server time and dev work.\n\n'
                  'If you\'d like to see it happen sooner, consider buying us a coffee. '
                  'Every contribution directly funds new features like this one.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade600, height: 1.6),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDD00),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Text('☕', style: TextStyle(fontSize: 18)),
                  label: const Text(
                    'Buy me a coffee',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () {
                    html.window.open(
                        'https://www.buymeacoffee.com/storysizer', '_blank');
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('← Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
