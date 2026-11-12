import 'package:flutter/material.dart';

void main() {
  runApp(const RecuerdosVivosApp());
}

class RecuerdosVivosApp extends StatelessWidget {
  const RecuerdosVivosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recuerdos Vivos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      home: const InicioPantalla(),
    );
  }
}

class InicioPantalla extends StatelessWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Recuerdos Vivos',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Revisa tus fotos y recuerda juntos, paso a paso.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                height: 72,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Elegir una foto', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 72,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Mi diario', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
