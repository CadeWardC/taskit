import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorSelector extends StatefulWidget {
  final String selectedColor;
  final ValueChanged<String> onColorChanged;
  final List<String> presetColors;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.presetColors = const [
      '#BB86FC',
      '#03DAC6',
      '#CF6679',
      '#FFA000',
      '#4CAF50',
      '#2196F3',
      '#FFEB3B', // Yellow
    ],
  });

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  void _showColorPicker() {
    Color currentColor = _hexToColor(widget.selectedColor);
    // Track local color state for the picker dialog
    Color pickerColor = currentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
            labelTypes: const [],
            hexInputBar: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
               final hex = '#${pickerColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
               widget.onColorChanged(hex);
               Navigator.of(context).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFBB86FC);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if selected color is one of the presets
    // We normalize to uppercase for comparison
    final isPreset = widget.presetColors.any((c) => c.toUpperCase() == widget.selectedColor.toUpperCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...widget.presetColors.map((colorHex) {
              final isSelected = widget.selectedColor.toUpperCase() == colorHex.toUpperCase();
              final color = _hexToColor(colorHex);
              return GestureDetector(
                onTap: () => widget.onColorChanged(colorHex),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                ),
              );
            }),
            // Custom picker button
            GestureDetector(
              onTap: _showColorPicker,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const SweepGradient(
                    colors: [
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                      Colors.red,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: !isPreset
                      ? Border.all(color: Colors.white, width: 3)
                      : Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(Icons.colorize, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
