import 'package:flutter/material.dart';

import '../../../models/schedule_classroom_model.dart';

class ClassroomFormDialog extends StatefulWidget {
  final ScheduleClassroomModel? classroom;

  const ClassroomFormDialog({super.key, this.classroom});

  static Future<ScheduleClassroomPayload?> show(
    BuildContext context, {
    ScheduleClassroomModel? classroom,
  }) {
    return showDialog<ScheduleClassroomPayload>(
      context: context,
      builder: (_) => ClassroomFormDialog(classroom: classroom),
    );
  }

  @override
  State<ClassroomFormDialog> createState() => _ClassroomFormDialogState();
}

class _ClassroomFormDialogState extends State<ClassroomFormDialog> {
  late final TextEditingController _nameController;
  late int _gradeLevel;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.classroom?.name ?? '',
    );
    _gradeLevel = widget.classroom?.gradeLevel ?? 9;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.classroom == null ? 'Sınıf Ekle' : 'Sınıfı Düzenle'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Sınıf Adı',
                prefixIcon: Icon(Icons.meeting_room_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _gradeLevel,
              decoration: const InputDecoration(
                labelText: 'Sınıf Seviyesi',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: List.generate(
                12,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}. sınıf'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _gradeLevel = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.classroom == null ? 'Ekle' : 'Kaydet'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      ScheduleClassroomPayload(name: name, gradeLevel: _gradeLevel),
    );
  }
}
