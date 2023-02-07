import 'package:flutter/material.dart';
import '../../database/db_repository.dart';
import '../../entites/person.dart';

import 'components/compose.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PersonDB _crudStorage;

  @override
  void initState() {
    super.initState();
    _crudStorage = PersonDB(dbName: 'db.sqlite');
    _crudStorage.open();
  }

  @override
  void dispose() {
    _crudStorage.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();

    Future<bool> _showDeleteDialog(BuildContext context) {
      return showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              content: const Text('Are you sure you want to delete this item?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Delete'),
                )
              ],
            );
          })).then((value) {
        if (value is bool) {
          return value;
        } else {
          return false;
        }
      });
    }

    Future<Person?> _showUpdateDialog(BuildContext context, Person person) {
      firstNameController.text = person.firstName;
      lastNameController.text = person.lastName;
      return showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your updated values here:'),
                  const SizedBox(
                    height: 8.0,
                  ),
                  TextField(
                    controller: firstNameController,
                  ),
                  TextField(
                    controller: lastNameController,
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      final editedPerson = Person(
                        id: person.id,
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                      );
                      Navigator.of(context).pop(editedPerson);
                    },
                    child: const Text('Save'))
              ],
            );
          }).then((value) {
        if (value is Person) {
          return value;
        } else {
          return null;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crud example'),
      ),
      body: StreamBuilder(
        stream: _crudStorage.all(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.active:
              if (snapshot.data == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              final people = snapshot.data as List<Person>;
              return Column(
                children: [
                  ComposeWidget(
                    onCompose: (firstName, lastName) async {
                      await _crudStorage.create(firstName, lastName);
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: people.length,
                      itemBuilder: ((context, index) {
                        final person = people[index];
                        return ListTile(
                          title: Text(person.fullName),
                          subtitle: Text('ID: ${person.id}'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.disabled_by_default_rounded,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              _showDeleteDialog(context).then((shouldDelete) {
                                if (shouldDelete) {
                                  _crudStorage.delete(person.id);
                                }
                              });
                            },
                          ),
                          onTap: () async {
                            final editedPerson =
                                await _showUpdateDialog(context, person);
                            if (editedPerson != null) {
                              await _crudStorage.update(editedPerson);
                            }
                          },
                        );
                      }),
                    ),
                  ),
                ],
              );
            default:
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        },
      ),
    );
  }
}
