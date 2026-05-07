import 'package:flutter/material.dart';

class AppLabel extends StatelessWidget{
  final String text;
  const AppLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context){
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

}