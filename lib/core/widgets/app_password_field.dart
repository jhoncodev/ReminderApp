import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';

class AppPasswordField extends StatefulWidget{
  final String hint;
  final TextEditingController controller;

  const AppPasswordField({
    super.key, 
    required this.controller,
    this.hint = '••••••••'
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField>{
  bool _obscuredPassword = true;
  
  @override
  Widget build(BuildContext context){
    return TextField(
      controller: widget.controller,
      obscureText: _obscuredPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: AppColors.hint),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscuredPassword = !_obscuredPassword), 
          icon: Icon(
            _obscuredPassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.hint,
          )
        )
      ),
    );
  }
} 