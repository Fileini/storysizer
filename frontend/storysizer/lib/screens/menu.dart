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
      backgroundColor: Colors.white,
      appBar: AppBar(
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
                return const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
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
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    avatar:
                        const Icon(Icons.person_2_rounded, color: Colors.black),
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
      drawer: Drawer(
        width: 250,
        backgroundColor: Colors.transparent,
        elevation: 2,
        child: ListView(
          padding: const EdgeInsets.only(left: 16.0),
          // Rimuovi eventuali padding default se preferisci con: padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 50),
            ListTile(
              tileColor: Colors.amber,
              leading: const Icon(
                Icons.flash_on,
                color: Colors.black,
              ),
              title: const Text("Quick Size"),
              onTap: () => _onItemTapped(0),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
            ),
            ListTile(
              tileColor: Colors.amber,
              leading: const Icon(
                Icons.list_alt,
                color: Colors.black,
              ),
              title: const Text("History"),
              onTap: () => _onItemTapped(1),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
            ),
            ListTile(
              tileColor: Colors.amber,
              leading: const Icon(
                Icons.group,
                color: Colors.black,
              ),
              title: const Text("Groups"),
              onTap: () => _onItemTapped(2),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
            )
          ],
        ),
      ),
      body: _buildBody(), // 🔥 Adesso mostra il contenuto corretto
    );
  }
}
