import 'package:flutter/material.dart';

class LightScreen extends StatelessWidget {
  const LightScreen({super.key});
  static const routeName = '/light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مستشعر الإضاءة')),
      body: const Center(child: Text('ميزة قياس الإضاءة ستتوفر في تحديث لاحق.')),
    );
  }
}
