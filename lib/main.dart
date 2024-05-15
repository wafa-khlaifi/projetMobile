import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home.dart';
import 'AddTaskScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCiDFVVA_skb4tgRhJNGlnNWFivu_Brgrk",
      appId: "1:251371728481:android:446ef892568edcf1298420",
      messagingSenderId: "251371728481",
      projectId: "projetmobile-95993",
    ),
  ).then((_) {
    print("Firebase initialisé avec succès !");
    isCollectionExists('liste').then((exists) {
      if (!exists) {
        FirebaseFirestore.instance.collection('liste');
        print("Collection 'liste' créée avec succès !");
      }
    });
  }).catchError((error) {
    print("Erreur lors de l'initialisation de Firebase : $error");
  });
  runApp(MyApp());
}

Future<bool> isCollectionExists(String collectionPath) async {
  final CollectionReference collectionReference = FirebaseFirestore.instance.collection(collectionPath);
  final QuerySnapshot querySnapshot = await collectionReference.limit(1).get();
  return querySnapshot.docs.isNotEmpty;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        appBarTheme: AppBarTheme(
          color: Colors.purple[300], // Modifier la couleur de l'AppBar en violet 100
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(), // Définir HomeScreen comme écran initial
    );
  }
}

class ToDoList extends StatefulWidget {
  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  Stream<QuerySnapshot>? _tasksStream;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _tasksStream = _firestore
          .collection('liste')
          .doc(_user!.uid)
          .collection('user_tasks')
          .snapshots();
    }
  }

  void addTask(String taskName, String priority) async {
    if (_user == null) return;

    try {
      final CollectionReference userTasksCollection = _firestore
          .collection('liste')
          .doc(_user!.uid)
          .collection('user_tasks');

      await userTasksCollection.add({
        'name': taskName,
        'priority': priority,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Erreur lors de l'ajout de la tâche : $e");
    }
  }

  void toggleTask(String taskId, bool currentStatus) async {
    if (_user == null) return;

    try {
      await _firestore
          .collection('liste')
          .doc(_user!.uid)
          .collection('user_tasks')
          .doc(taskId)
          .update({
        'completed': !currentStatus,
      });
    } catch (e) {
      print("Erreur lors de la mise à jour de la tâche : $e");
    }
  }

  void deleteTask(String taskId) async {
    if (_user == null) return;

    try {
      await _firestore
          .collection('liste')
          .doc(_user!.uid)
          .collection('user_tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      print("Erreur lors de la suppression de la tâche : $e");
    }
  }

  void editTask(String taskId, String newTaskName) async {
    if (_user == null) return;

    try {
      await _firestore
          .collection('liste')
          .doc(_user!.uid)
          .collection('user_tasks')
          .doc(taskId)
          .update({'name': newTaskName});
    } catch (e) {
      print("Erreur lors de la mise à jour de la tâche : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      buildToDoList(),
      Center(child: Text("Profile")),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: Column(
        children: [
          SearchBar(
            onSearchTextChanged: (String text) {
              // Implémentez la logique de filtrage ici
            },
          ),
          Expanded(
            child: pages[_pageIndex],
          ),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: Colors.purple[300],
        color: Colors.purple,
        animationDuration: const Duration(milliseconds: 300),
        items: const <Widget>[
          Icon(Icons.home, size: 26, color: Colors.white, semanticLabel: 'home'),
          Icon(Icons.account_circle_outlined, size: 26, color: Colors.white, semanticLabel: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
      ),
      floatingActionButton: _pageIndex == 0
          ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );
          setState(() {
            _tasksStream = _firestore
                .collection('liste')
                .doc(_user!.uid)
                .collection('user_tasks')
                .snapshots();
          });
        },
        child: Icon(Icons.add),
      )
          : null,
    );
  }


  Widget buildToDoList() {
    if (_tasksStream == null) {
      return Center(child: Text("Aucun utilisateur trouvé"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return Center(child: Text("Aucune tâche trouvée"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final task = Task.fromFirestore(snapshot.data!.docs[index]);
            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: IconButton(
                  icon: task.completed
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.radio_button_unchecked),
                  onPressed: () {
                    toggleTask(task.id, task.completed);
                  },
                ),
                title: Text(
                  task.name,
                  style: TextStyle(
                    color: task.completed ? Colors.green : Colors.black,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Text('Priority: ${task.priority}'),
                    SizedBox(width: 8),
                    Text('Created at: ${task.createdAt}'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteTask(task.id);
                  },
                  color: Colors.red,
                ),
                onTap: () {
                  toggleTask(task.id, task.completed);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class Task {
  String id;
  String name;
  String priority;
  DateTime createdAt;
  bool completed;

  Task({
    required this.id,
    required this.name,
    required this.priority,
    required this.createdAt,
    required this.completed,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      name: data['name'],
      priority: data['priority'],
      completed: data['completed'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class SearchBar extends StatefulWidget {
  final Function(String) onSearchTextChanged;

  const SearchBar({Key? key, required this.onSearchTextChanged}) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    widget.onSearchTextChanged(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }
}