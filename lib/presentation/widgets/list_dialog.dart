import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/color_selector.dart';

class ListDialog extends StatefulWidget {
  final dynamic list;

  const ListDialog({super.key, this.list});

  @override
  State<ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends State<ListDialog> {
  late TextEditingController _titleController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.list?.title);
    
    _selectedColor = const Color(0xFFBB86FC); // Default purple
    if (widget.list?.color != null) {
      try {
        _selectedColor = Color(int.parse(widget.list!.color!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.list != null;
    
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(isEditing ? 'Edit List' : 'New List'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'List Name',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ColorSelector(
            selectedColor: '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            onColorChanged: (hex) {
              setState(() {
                _selectedColor = Color(int.parse(hex.replaceFirst('#', '0xFF')));
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              final colorString = '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              
              if (isEditing) {
                context.read<TodoProvider>().updateList(
                  widget.list!.id!,
                  title: _titleController.text,
                  color: colorString,
                );
              } else {
                context.read<TodoProvider>().addList(
                  _titleController.text,
                  colorString,
                );
              }
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
          ),
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
