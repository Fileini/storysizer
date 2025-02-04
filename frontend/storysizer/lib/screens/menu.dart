import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/widgets/profilelogo.dart';


class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.view});
  final Widget view;

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {

 

  final List<Map<String, dynamic>> menuItems = [
    {'icon': CupertinoIcons.bolt_circle_fill, 'title': 'Quick Size', 'index': 0},
    {'icon': CupertinoIcons.doc_plaintext, 'title': 'History', 'index': 1},
    {'icon': CupertinoIcons.group_solid, 'title': 'Groups', 'index': 2},
  ];

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/home/sizer-name');
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        context.go('/groups');
        break;
    }
    Navigator.of(context).pop(); // Chiude il drawer dopo la navigazione
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerScrimColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.bodyLarge,
        leading: MenuButton(),
        actions: [
          ProfileLogo()
        ],
      ),
      drawer: GestureDetector(
        onTap: Navigator.of(context).pop,
        child: Drawer(
          width: 300,
          backgroundColor: Colors.transparent,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(38.0),
            child: ListView(
              children: [
                SizedBox(height: 30),
                ...menuItems.map((item) => Card(
                      elevation: 5,
                      shadowColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
                      ),
                      child: ListTile(
                        leading: Icon(item['icon']),
                        title: Text(item['title']),
                        onTap: () => _onItemTapped(item['index']),
                        visualDensity: VisualDensity(horizontal: -2, vertical: -1),
                      ),
                    ))
              ],
            ),
          ),
        ),
      ),
      body: widget.view,
    );
  }
}

class MenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.amber,
          child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                  child: Container(
                      color: Colors.white,
                      child: Image.asset("assets/logo.png"))))),
      onPressed: () {
        Scaffold.of(context).openDrawer();
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }
}
