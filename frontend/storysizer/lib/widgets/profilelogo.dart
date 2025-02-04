import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/services/auth_service.dart';


class ProfileLogo extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FutureBuilder<Map<String, String>>(
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
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                      child: ActionChip(
                    onPressed: () {
                      context.go('/profile');
                    },
                    shadowColor: Theme.of(context).colorScheme.tertiary,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    label: Text(
                      snapshot.data!['firstName']!,
                      overflow: TextOverflow
                          .ellipsis, // 🔥 Se ancora troppo lungo, mette i puntini
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )),
                );
              }
            },
          );
  }

}


