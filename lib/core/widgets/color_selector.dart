import 'package:flutter/material.dart';

class ColorSelector extends StatelessWidget {
  final int selectedColor;
  final Function(int) onColorSelected;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  // Lista curada de colores modernos para cursos
  static const List<int> courseColors = [
    0xFF6C63FF, // Morado por defecto
    0xFFFF6B6B, // Rojo coral
    0xFF4ECDC4, // Menta
    0xFFFFD166, // Amarillo
    0xFF06D6A0, // Verde neón
    0xFF118AB2, // Celeste
    0xFF073B4C, // Azul marino oscuro
    0xFF9D4EDD, // Violeta profundo
    0xFFFF9F1C, // Naranja brillante
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
          height: 50, // Alto fijo de la lista horizontal
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
                    // Borde blanco si está seleccionado
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