import 'package:flutter/material.dart';
import 'package:gestionbudget/core/constants/app_strings.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.goals),
      ),
      body: const Center(
        child: Text('Écran Objectifs - À implémenter'),
      ),
    );
  }
}