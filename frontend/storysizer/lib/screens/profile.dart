import 'package:flutter/material.dart';
import 'package:storysizer/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  static String routeName = 'ProfileScreen';

  const ProfileScreen({super.key});
  static Route<ProfileScreen> route() {
    return MaterialPageRoute<ProfileScreen>(
      settings: RouteSettings(name: routeName),
      builder: (BuildContext context) => const ProfileScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        const Center(
          child: Column(
            children: <Widget>[Icon( Icons.person,size: 180,color: Colors.amber,)
             ,
            ],
          ),
        ),
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
                return  Column(
            children: <Widget>[
              Center(
                    child: Text(
                        snapshot.data!['firstName']!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ),
                  Center(
                    child: Text(
                        snapshot.data!['lastName']!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ),
                  Center(
                    child: Text(
                        snapshot.data!['username']!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ),
                  ]
                );
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
                        backgroundColor: Colors.amber, // Colore grigio
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // Bordi stondati
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10), // Spaziatura interna
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
