import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysizer/main.dart';
import 'package:storysizer/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
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

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider =
          Provider.of<ThemeModeProvider>(context, listen: false);
      setState(() {
        _isDarkMode = themeProvider.mode == ThemeMode.light;
      });
    });
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = !value;
    });
    Provider.of<ThemeModeProvider>(context, listen: false).changeMode(value);
  }

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ElevatedButton(
            onPressed: () {
              AuthService.instance.logout();
            },
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(200, 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Logout',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
