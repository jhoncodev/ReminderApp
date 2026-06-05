import 'package:flutter/material.dart';

class ColorSelector extends StatelessWidget {
  final int selectedColor;
  final Function(int) onColorSelected;

  const ColorSelector({
    Key? key,
    required this.selectedColor,
    required this.onColorSelected,
  }) : super(key: key);

  // A curated list of beautiful, modern colors for courses
  static const List<int> courseColors = [
    0xFF6C63FF, // Default Purple (Matches your app's primary accent)
    0xFFFF6B6B, // Coral Red
    0xFF4ECDC4, // Mint/Teal
    0xFFFFD166, // Yellow
    0xFF06D6A0, // Neon Green
    0xFF118AB2, // Light Blue
    0xFF073B4C, // Dark Navy
    0xFF9D4EDD, // Deep Violet
    0xFFFF9F1C, // Bright Orange
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color Curso',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50, // Fixed height for the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courseColors.length,
            itemBuilder: (context, index) {
              final colorValue = courseColors[index];
              final isSelected = colorValue == selectedColor;

              return GestureDetector(
                onTap: () => onColorSelected(colorValue),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    shape: BoxShape.circle,
                    // Add a white border if selected
                    border: isSelected 
                        ? Border.all(color: Colors.white, width: 2.5) 
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}