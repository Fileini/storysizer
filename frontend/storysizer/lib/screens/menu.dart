import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/screens/mysizings.dart';
import 'package:storysizer/screens/quick_sizer.dart';
import 'package:storysizer/services/auth_service.dart';
import 'profile.dart';

import 'groups.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.selectedTab = 0});
  final int selectedTab;

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;

  final List<Widget> tabs = [
    const QuickSizerView(),
    const HistoryView(),
    const GroupsView(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/home/quick-size');
        break;
      case 1:
        context.go('/home/history');
        break;
      case 2:
        context.go('/home/groups');
        break;
    }
    Navigator.of(context).pop(); // Chiude il drawer dopo la navigazione
  }

  Widget _buildBody() {
    switch (widget.selectedTab) {
      case 0:
        return QuickSizerView();
      case 1:
        return HistoryView();
      case 2:
        return GroupsView();
      case 3:
        return ProfileScreen();
      default:
        return QuickSizerView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerScrimColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // L’hamburger menu viene aggiunto in automatico quando usiamo la proprietà 'drawer'
        automaticallyImplyLeading: true,
        centerTitle: false,
        title: const Text("StorySizer"),
        titleTextStyle: Theme.of(context).textTheme.bodyLarge,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.amber,
                  child: Padding(
                      padding: const EdgeInsets.all(3), // Border radius
                      child: ClipOval(
                          child: Container(
                              color: Colors.white,
                              child: Image.asset("assets/logo.png"))))),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: [
          FutureBuilder<Map<String, String>>(
            future: AuthService.instance.getUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              } else if (snapshot.hasError || !snapshot.hasData) {
                // Se non c'è un utente loggato o si verifica un errore, non mostriamo nulla
                return const SizedBox.shrink();
              } else {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                      child: ActionChip(
                    onPressed: () {
                      context.go('/home/profile');
                    },
                    shadowColor: Theme.of(context).colorScheme.tertiary,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    avatar: Icon(Icons.person_2_rounded,
                        color: Theme.of(context).colorScheme.tertiary),
                    label: Text(
                      snapshot.data!['firstName']!,
                      maxLines: 2, // 🔥 Permettiamo massimo 2 righe
                      softWrap: true, // 🔥 Permette la rottura delle righe
                      overflow: TextOverflow
                          .ellipsis, // 🔥 Se ancora troppo lungo, mette i puntini
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )),
                );
              }
            },
          ),
        ],
      ),
      drawer: GestureDetector(onTap: Navigator.of(context).pop,
        child: Drawer(
          width: 300,
          backgroundColor: Colors.transparent,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(38.0),
            child: ListView(
              children: [
                SizedBox(height: 30,),
                Card(elevation: 5,shadowColor: Theme.of(context).primaryColor,shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
                  ),
                  child: ListTile(
                    leading: const Icon(
                       CupertinoIcons.bolt_circle_fill,
                    ),
                    title: const Text("Quick Size"),
                    onTap: () => _onItemTapped(0),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
                  ),
                ),
                Card(elevation: 5,shadowColor: Theme.of(context).primaryColor,shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
                  ),
                  child: ListTile(
                    style: Theme.of(context).listTileTheme.style,
                    leading: const Icon(
                      CupertinoIcons.doc_plaintext,
                    ),
                    title: const Text("History"),
                    onTap: () => _onItemTapped(1),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
                  ),
                ),
                Card(elevation: 5,shadowColor: Theme.of(context).primaryColor,shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      CupertinoIcons.group_solid,
                    ),
                    title: const Text("Groups"),
                    onTap: () => _onItemTapped(2),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(), // 🔥 Adesso mostra il contenuto corretto
    );
  }
}
