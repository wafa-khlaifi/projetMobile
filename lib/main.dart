import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:projetmobile/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCzLJOH-YetkduQ6pJXiuHQ8vLmBFovJs4", //  ==   current_key in google-services.json file
      appId: "1:63215065631:android:c3fd509809ec2ee4ae132a", // ==  mobilesdk_app_id  in google-services.json file
      messagingSenderId: "63215065631", // ==   project_number in google-services.json file
      projectId: "projetmobile-27ead", // ==   project_id   in google-services.json file
    ),
  ).then((_) {
    print("Firebase initialisé avec succès !");
  }).catchError((error) {
    print("Erreur lors de l'initialisation de Firebase : $error");
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
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

  late User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  void addTask(String taskName) async {
    try {
      await _firestore.collection('liste').doc(_user!.uid).collection('user_tasks').add({
        'name': taskName,
        'completed': false,
      });
      setState(() {
        // Actualisez l'affichage pour refléter la nouvelle tâche
      });
    } catch (e) {
      print("Erreur lors de l'ajout de la tâche : $e");
    }
  }

  void toggleTask(String taskId, bool currentStatus) async {
    try {
      await _firestore.collection('liste').doc(_user!.uid).collection('user_tasks').doc(taskId).update({
        'completed': !currentStatus,
      });
      setState(() {
        // Actualisez l'affichage pour refléter le basculement de la tâche
      });
    } catch (e) {
      print("Erreur lors de la mise à jour de la tâche : $e");
    }
  }

  void deleteTask(String taskId) async {
    try {
      await _firestore.collection('liste').doc(_user!.uid).collection('user_tasks').doc(taskId).delete();
      setState(() {
        // Actualisez l'affichage pour refléter la suppression de la tâche
      });
    } catch (e) {
      print("Erreur lors de la suppression de la tâche : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        backgroundColor: Colors.purple[100],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('liste').doc(_user!.uid).collection('user_tasks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          List<Task> tasks = [];
          final taskDocs = snapshot.data!.docs;
          for (var taskDoc in taskDocs) {
            final taskData = taskDoc.data() as Map<String, dynamic>;
            tasks.add(Task(
              id: taskDoc.id,
              name: taskData['name'],
              completed: taskData['completed'],
            ));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: Key(task.id),
                onDismissed: (direction) {
                  deleteTask(task.id);
                },
                child: ListTile(
                  leading: IconButton(
                    icon: task.completed
                        ? Icon(Icons.check_circle)
                        : Icon(Icons.radio_button_unchecked),
                    onPressed: () {
                      toggleTask(task.id, task.completed);
                    },
                    color: task.completed ? Colors.green : Colors.grey,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.name,
                          style: TextStyle(
                            color: task.completed ? Colors.green : Colors.red,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteTask(task.id);
                        },
                        color: Colors.red,
                      ),
                    ],
                  ),
                  onTap: () {
                    toggleTask(task.id, task.completed);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String newTask = '';
              return AlertDialog(
                title: Text('Add Task'),
                content: TextField(
                  onChanged: (value) {
                    newTask = value;
                  },
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      addTask(newTask);
                      Navigator.of(context).pop();
                    },
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Task {
  String id;
  String name;
  bool completed;

  Task({required this.id, required this.name, required this.completed});
}
