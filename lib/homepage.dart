import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
// https://learnflutterwithme.com/sqlite

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? selectedId;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.star),
        title: Text("Sqflite Example"),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(15),
              width: MediaQuery.of(context).size.width,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(45),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.lightBlueAccent,
                    Colors.lightGreenAccent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 15),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    height: 25,
                    child: TextField(
                      textAlign: TextAlign.center,
                      controller: textController,
                    ),
                  ),
                  SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      print(textController.text);

                      selectedId != null
                          ? await DatabaseHelper.instance.update(
                              Names(id: selectedId, name: textController.text),
                            )
                          : await DatabaseHelper.instance.add(
                              Names(name: textController.text),
                            );
                      setState(() {
                        textController.clear();
                        selectedId = null;
                      });
                    },
                    child: Container(
                      height: 50,
                      width: 150,
                      child: Icon(
                        Icons.save,
                        color: Colors.black,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('1. Type A name and press the Button to Add the Name'),
                  Text('2. Long Press a Name to Delete'),
                  Text('3. Press a Name to Update'),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Names>>(
                  future: DatabaseHelper.instance.getNames(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Names>> snapshot) {
                    return snapshot.hasData != true
                        ? Center(child: Text('No Names in List.'))
                        : ListView(
                            children: snapshot.data!.map((names) {
                              return Center(
                                child: Card(
                                  color: selectedId == names.id
                                      ? Colors.white70
                                      : Colors.white,
                                  child: ListTile(
                                    title: Text(names.name),
                                    onLongPress: () {
                                      setState(() {
                                        DatabaseHelper.instance
                                            .remove(names.id!);
                                      });
                                    },
                                    onTap: () {
                                      setState(() {
                                        if (selectedId == null) {
                                          textController.text = names.name;
                                          selectedId = names.id;
                                        } else {
                                          textController.text = '';
                                          selectedId = null;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

class Names {
  final int? id;
  final String name;

  Names({this.id, required this.name});

  factory Names.fromMap(Map<String, dynamic> json) => new Names(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class DatabaseHelper {
  //let's create the class and let's make it a _privateConstructor which will create a singleton, or a class that only has one instance
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'names.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE names(
          id INTEGER PRIMARY KEY,
          name TEXT
      )
      ''');
  }

  Future<List<Names>> getNames() async {
    Database db = await instance.database;
    var _names = await db.query('names', orderBy: 'name');
    List<Names> namesList =
        _names.isNotEmpty ? _names.map((c) => Names.fromMap(c)).toList() : [];
    return namesList;
  }

  Future<int> add(Names names) async {
    Database db = await instance.database;
    return await db.insert('names', names.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('names', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Names names) async {
    Database db = await instance.database;
    return await db
        .update('names', names.toMap(), where: "id = ?", whereArgs: [names.id]);
  }
}
