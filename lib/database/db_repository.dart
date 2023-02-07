import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../entites/person.dart';

class PersonDB {
  final String dbName;
  Database? _db;
  List<Person> _persons = [];
  final StreamController<List<Person>> _streamController =
      StreamController<List<Person>>.broadcast();

  PersonDB({
    required this.dbName,
  });

  Future<bool> open() async {
    if (_db != null) {
      return true;
    }
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$dbName';

    try {
      _db = await openDatabase(path);

      const String create = '''CREATE TABLE IF NOT EXISTS PEOPLE (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        FIRST_NAME STRING NOT NULL,
        LAST_NAME STRING NOT NULL)''';

      await _db!.execute(create);

      //read person objects
      _persons = await _fetchPeople();
      _streamController.add(_persons);
      return true;
    } catch (e) {
      debugPrint('Error = $e');
      return false;
    }
  }

  Future<bool> close() async {
    if (_db == null) {
      return false;
    }
    await _db!.close();
    return true;
  }

  Stream<List<Person>> all() =>
      _streamController.stream.map((persons) => persons..sort());

  //C in CRUD
  Future<bool> create(String firstName, String lastName) async {
    if (_db == null) return false;

    try {
      final id = await _db!.insert('PEOPLE', {
        'FIRST_NAME': firstName,
        'LAST_NAME': lastName,
      });
      final person = Person(
        id: id,
        firstName: firstName,
        lastName: lastName,
      );
      _persons.add(person);
      _streamController.add(_persons);
      return true;
    } catch (e) {
      return false;
    }
  }

  //R in CRUD
  Future<List<Person>> _fetchPeople() async {
    if (_db == null) {
      return [];
    }
    try {
      final read = await _db!.query('PEOPLE',
          distinct: true,
          columns: ['ID', 'FIRST_NAME', 'LAST_NAME'],
          orderBy: 'ID');
      return read.map((r) => Person.fromRow(r)).toList();
    } catch (e) {
      debugPrint('Error fetching people = $e');
      return [];
    }
  }

  //U in CRUD
  Future<bool?> update(Person person) async {
    if (_db == null) return false;
    try {
      final updateCount = await _db!.update('PEOPLE',
          {'FIRST_NAME': person.firstName, 'LAST_NAME': person.lastName},
          where: 'ID = ?', whereArgs: [person.id]);
      if (updateCount == 1) {
        _persons.removeWhere((element) => element.id == person.id);
        _persons.add(person);
        _streamController.add(_persons);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  //D in CRUD
  Future<bool> delete(int id) async {
    if (_db == null) return false;
    try {
      final deletedCount =
          await _db!.delete('PEOPLE', where: 'ID = ?', whereArgs: [id]);
      if (deletedCount == 1) {
        _persons.removeWhere((person) => person.id == id);
        _streamController.add(_persons);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
