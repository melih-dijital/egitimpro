import 'package:flutter/material.dart';

import '../../../models/schedule_classroom_model.dart';
import '../../../models/schedule_course_model.dart';

class CourseFormDialog extends StatefulWidget {
  final ScheduleCourseModel? course;
  final List<ScheduleClassroomModel> classrooms;

  const CourseFormDialog({
    super.key,
    this.course,
    required this.classrooms,
  });

  static Future<ScheduleCoursePayload?> show(
    BuildContext context, {
    ScheduleCourseModel? course,
    required List<ScheduleClassroomModel> classrooms,
  }) {
    return showDialog<ScheduleCoursePayload>(
      context: context,
      builder: (_) => CourseFormDialog(course: course, classrooms: classrooms),
    );
  }

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  late final TextEditingController _nameController;
  late int _weeklyHours;
  late int _classroomId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course?.name ?? '');
    _weeklyHours = widget.course?.weeklyHours ?? 2;
    _classroomId = widget.course?.classroomId ?? widget.classrooms.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.course == null ? 'Ders Ekle' : 'Dersi Düzenle'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ders Adı',
                prefixIcon: Icon(Icons.book_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _classroomId,
              decoration: const InputDecoration(
                labelText: 'Sınıf',
                prefixIcon: Icon(Icons.meeting_room_outlined),
              ),
              items: widget.classrooms
                  .map(
                    (classroom) => DropdownMenuItem(
                      value: classroom.id,
                      child: Text(classroom.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _classroomId = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _weeklyHours,
              decoration: const InputDecoration(
                labelText: 'Haftalık Saat',
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
              items: List.generate(
                40,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1} saat'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _weeklyHours = value);
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
          child: Text(widget.course == null ? 'Ekle' : 'Kaydet'),
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
      ScheduleCoursePayload(
        name: name,
        weeklyHours: _weeklyHours,
        classroomId: _classroomId,
      ),
    );
  }
}
