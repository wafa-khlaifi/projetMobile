import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  String _selectedPriority = 'Low';
  late User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _addTaskToFirestore() async {
    final String taskName = _taskNameController.text;

    if (taskName.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('liste').doc(_user!.uid).collection('user_tasks').add({
          'name': taskName,
          'priority': _selectedPriority,
          'createdAt': Timestamp.now(),
          'completed': false, // Ajout du champ 'completed' avec la valeur par défaut false
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task added successfully')),
        );
        Navigator.pop(context); // Retour à l'écran précédent
      } catch (error) {
        print('Error adding task: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter task name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
        backgroundColor: Colors.purple[100],
        actions: [
          IconButton(
            onPressed: () {
              // Action à effectuer lorsque l'icône de paramètres est cliquée
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _taskNameController,
                  decoration: InputDecoration(labelText: 'Task Name'),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: DropdownButtonFormField(
                  value: _selectedPriority,
                  items: ['Low', 'Medium', 'High'].map((priority) {
                    return DropdownMenuItem(
                      child: Text(priority),
                      value: priority,
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value.toString();
                    });
                  },
                  decoration: InputDecoration(labelText: 'Priority'),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Container(
              width: double.infinity, // Prend toute la largeur de l'écran
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: ElevatedButton(
                onPressed: _addTaskToFirestore,
                child: Text('Add Task'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.purple[100]!), // Couleur de l'appBar
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
