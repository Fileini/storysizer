import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NameInputScreen extends StatefulWidget {
  @override
  _NameInputScreenState createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(
                              'Sizing a new Story,',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.left,
                            ),
                            subtitle: Text(
                              'Insert a name.',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.left,
                            ),
                            leading: Icon(
                              CupertinoIcons.add_circled_solid  ,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  labelText: "Name",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              ),
                            ),Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        final name = _controller.text.trim();
                        if (name.isNotEmpty) {
                          context.go('/home/sizer-questions/$name');
                        }
                      },
                      child: Text("Create"),
                    ),
                  ),
                          ],
                        ),
                    
                      ],
                    ),
                  ),
                  
                ],
              ),
            ),
          ],
        ),
      
    );
  }
}




