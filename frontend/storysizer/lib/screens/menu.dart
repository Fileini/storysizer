import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/providers.dart';
import 'package:storysizer/widgets/profilelogo.dart';


class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key, required this.view});
  final Widget view;

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(pendingCountNotifierProvider.notifier).refresh());
  }

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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(pendingCountNotifierProvider);

    final List<Map<String, dynamic>> menuItems = [
      {'icon': CupertinoIcons.bolt_circle_fill, 'title': 'Quick Size', 'index': 0},
      {'icon': CupertinoIcons.doc_plaintext, 'title': 'Estimations', 'index': 1, 'badge': pendingCount},
      {'icon': CupertinoIcons.group_solid, 'title': 'Group Estimation', 'index': 2},
    ];

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
                ...menuItems.map((item) {
                  final int badge = (item['badge'] as int?) ?? 0;
                  return Card(
                    elevation: 5,
                    shadowColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
                    ),
                    child: ListTile(
                      leading: badge > 0
                          ? Badge(
                              label: Text(badge.toString()),
                              child: Icon(item['icon'] as IconData),
                            )
                          : Icon(item['icon'] as IconData),
                      title: Text(item['title'] as String),
                      onTap: () => _onItemTapped(item['index'] as int),
                      visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
                    ),
                  );
                }),
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
