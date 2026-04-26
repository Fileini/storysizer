import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:storysizer/providers.dart';
import 'package:storysizer/services/auth_service.dart';
import 'package:storysizer/services/themeprovider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  static String routeName = 'ProfileScreen';

  const ProfileScreen({super.key});
  static Route<ProfileScreen> route() {
    return MaterialPageRoute<ProfileScreen>(
      settings: RouteSettings(name: routeName),
      builder: (BuildContext context) => const ProfileScreen(),
    );
  }

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isDarkMode = ref.read(themeModeProvider).mode == ThemeMode.light;
      });
    });
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = !value;
    });
    ref.read(themeModeProvider).changeMode(value);
  }

  // ── Export My Data ────────────────────────────────────────────────────────
  Future<void> _exportMyData(BuildContext context) async {
    try {
      final repo = ref.read(dataRepositoryProvider);
      final data = await repo.exportMyData();

      final buffer = StringBuffer();

      // Sezione Stories
      buffer.writeln('# Stories');
      buffer.writeln('id,name');
      final stories = data['stories'] as List<dynamic>? ?? [];
      for (final s in stories) {
        final id = _csvEscape(s['id'].toString());
        final name = _csvEscape(s['name'].toString());
        buffer.writeln('$id,$name');
      }

      buffer.writeln();

      // Sezione Estimations
      buffer.writeln('# Estimations');
      buffer.writeln('id,story_id,story_name,complexity,reach,dimensions,risk,interaction,sizer');
      final estimations = data['estimations'] as List<dynamic>? ?? [];
      for (final e in estimations) {
        final story = e['story'] as Map<String, dynamic>? ?? {};
        final cols = [
          _csvEscape(e['id'].toString()),
          _csvEscape(story['id']?.toString() ?? ''),
          _csvEscape(story['name']?.toString() ?? ''),
          e['complexity'].toString(),
          e['reach'].toString(),
          e['dimensions'].toString(),
          e['risk'].toString(),
          e['interaction'].toString(),
          (e['sizer'] ?? '').toString(),
        ];
        buffer.writeln(cols.join(','));
      }

      // Trigger download nel browser
      final bytes = utf8.encode(buffer.toString());
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'storysizer_data.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ── Delete Account ────────────────────────────────────────────────────────
  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'All your data will be deleted permanently.\n\nThis action cannot be undone.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (context.mounted) context.go('/logging-out');
              await _deleteAccount(context);
            },
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final repo = ref.read(dataRepositoryProvider);
      await repo.deleteMyAccount();
      await AuthService.instance.logout();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        FutureBuilder<Map<String, String>>(
          future: AuthService.instance.getUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                ),
              );
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text("Errore nel caricamento del profilo"));
            } else {
              return Center(
                  child: Column(children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(
                        snapshot.data!['firstName']! +
                            ' ' +
                            snapshot.data!['lastName']!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.left,
                      ),
                      subtitle: Text(
                        snapshot.data!['username']!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.left,
                      ),
                      leading: Icon(Icons.person_2_rounded),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(
                      'Dark mode',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.left,
                    ),
                    subtitle: Text(
                      'Dark mode is ${_isDarkMode ? "off" : "on"}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.left,
                    ),
                    leading: Switch(
                      value: !_isDarkMode,
                      onChanged: _toggleTheme,
                    ),
                  ),
                )
              ]));
            }
          },
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
              child: ElevatedButton(
                onPressed: () {
                  context.go('/logging-out');
                  AuthService.instance.logout();
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(200, 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(
                  'Logout',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
              child: ElevatedButton(
                onPressed: () => _exportMyData(context),
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(200, 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(
                  'Export my data',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
              child: ElevatedButton(
                onPressed: () => _confirmDeleteAccount(context),
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(200, 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Delete account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

