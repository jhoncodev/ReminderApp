import 'package:flutter/material.dart';

class DaysSelector extends StatefulWidget {
  final List<bool> selectedDays;
  final ValueChanged<List<bool>> onSelectionChanged;
  final List<String> dayLabels;

  const DaysSelector({
    super.key,
    required this.selectedDays,
    required this.onSelectionChanged,
    this.dayLabels = const ["L", "M", "M", "J", "V", "S", "D"],
  });

  @override
  State<DaysSelector> createState() => _DaysSelectorState();
}

class _DaysSelectorState extends State<DaysSelector> {
  late List<bool> _localSelectedDays;

  @override
  void initState() {
    super.initState();
    _localSelectedDays = List.from(widget.selectedDays);
  }

  void _toggleDay(int index) {
    setState(() {
      _localSelectedDays[index] = !_localSelectedDays[index];
    });
    widget.onSelectionChanged(_localSelectedDays);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.dayLabels.length, (index) {
        return GestureDetector(
          onTap: () => _toggleDay(index),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _localSelectedDays[index]
                  ? const Color(0xFF9D65FF)
                  : const Color(0xFF232329),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.dayLabels[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
