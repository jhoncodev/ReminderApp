import 'package:flutter/material.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});
  
  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Activity'),
      ),
      body: Center(
        child: Text('Create Activity Screen'),
      ),
    );
  }
}