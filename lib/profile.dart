import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nom d\'utilisateur: John Doe',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'Adresse e-mail: johndoe@example.com',
              style: TextStyle(fontSize: 20),
            ),
            // Ajoutez d'autres informations sur le profil ici
          ],
        ),
      ),
    );
  }
}
