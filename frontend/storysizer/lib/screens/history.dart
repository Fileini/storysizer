import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/widgets/history-item.dart';
import 'package:flutter/cupertino.dart';

class HistoryView extends StatefulWidget {
  // Se vuoi mostrare un titolo o altro, puoi aggiungere ulteriori parametri.
  final String name;
  const HistoryView({super.key, this.name = "Storico"});

  @override
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final List<String> ids = ["1", "2", "3", "4", "5"];
  final List<String> titles = [
    "Storia1",
    "Storia2",
    "Storia3",
    "Storia4",
    "Storia5"
  ];
  final List<String> points = ["21", "11", "2", "9", "33"];
  final List<String> descriptions = [
    "desc1",
    "desc2",
    "desc3",
    "desc4",
    "desc5"
  ];

  // Funzione che viene chiamata per rimuovere l'elemento (può essere modificata per interagire con un database o API)
  void deleteHistoryItem(String id) {
    // Logica per cancellare l'elemento dalla fonte dati, se necessario.
    print("Eliminato elemento con id: $id");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Center(child: Text('History: ' + widget.name)),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(titles.length, (index) {
                    return HistoryItem(
                      id: ids[index],
                      title: titles[index],
                      description: descriptions[index],
                      points: points[index],
                      icon: CupertinoIcons.delete_solid,
                      onDeleted: () {
                        // Salva l'id da voce da cancellare
                        final String removedId = ids[index];
                        setState(() {
                          // Rimuovi l'elemento da tutte le liste
                          ids.removeAt(index);
                          titles.removeAt(index);
                          points.removeAt(index);
                          descriptions.removeAt(index);
                        }
                        );
                        
                        // Chiamata alla funzione per cancellare l'elemento dalla fonte dati
                        deleteHistoryItem(removedId);
                      },
                      onTap: (){
                          context.go('/home/estimation');
                        }
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
