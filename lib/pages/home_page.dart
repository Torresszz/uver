import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'register_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: Colors.blue,
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.directions_car, size: 100, color: Colors.blue),

            const SizedBox(height: 20),

            const Text(
              'Bienvenido a Routemate',
              style: TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 10),

            const Text(
              'Encuentra o publica viajes fácilmente',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RegisterPage()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text(
                'Iniciar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}