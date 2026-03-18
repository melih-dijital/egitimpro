import 'package:flutter/material.dart';

import '../../../models/schedule_teacher_model.dart';

class TeacherFormDialog extends StatefulWidget {
  final ScheduleTeacherModel? teacher;

  const TeacherFormDialog({super.key, this.teacher});

  static Future<ScheduleTeacherPayload?> show(
    BuildContext context, {
    ScheduleTeacherModel? teacher,
  }) {
    return showDialog<ScheduleTeacherPayload>(
      context: context,
      builder: (_) => TeacherFormDialog(teacher: teacher),
    );
  }

  @override
  State<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<TeacherFormDialog> {
  late final TextEditingController _nameController;
  late int _maxDailyHours;
  late final Set<String> _selectedSlots;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher?.name ?? '');
    _maxDailyHours = widget.teacher?.maxDailyHours ?? 8;
    _selectedSlots = {
      for (final slot
          in widget.teacher?.unavailableTimes ??
              const <ScheduleTeacherUnavailableTime>[])
        '${slot.day}-${slot.hour}',
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.teacher == null ? 'Öğretmen Ekle' : 'Öğretmeni Düzenle',
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Öğretmen Adı',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _maxDailyHours,
                decoration: const InputDecoration(
                  labelText: 'Günlük Maksimum Saat',
                  prefixIcon: Icon(Icons.timelapse_outlined),
                ),
                items: List.generate(
                  8,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1} saat'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _maxDailyHours = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Müsait Olmadığı Saatler',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int day = 0; day < 5; day++)
                    for (int hour = 1; hour <= 8; hour++)
                      FilterChip(
                        label: Text(
                          '${const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum'][day]}-$hour',
                        ),
                        selected: _selectedSlots.contains('$day-$hour'),
                        onSelected: (selected) {
                          setState(() {
                            final key = '$day-$hour';
                            if (selected) {
                              _selectedSlots.add(key);
                            } else {
                              _selectedSlots.remove(key);
                            }
                          });
                        },
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.teacher == null ? 'Ekle' : 'Kaydet'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final unavailableTimes = _selectedSlots
        .map((item) {
          final parts = item.split('-');
          return ScheduleTeacherUnavailableTime(
            day: int.parse(parts[0]),
            hour: int.parse(parts[1]),
          );
        })
        .toList()
      ..sort((a, b) {
        final dayCompare = a.day.compareTo(b.day);
        if (dayCompare != 0) return dayCompare;
        return a.hour.compareTo(b.hour);
      });

    Navigator.pop(
      context,
      ScheduleTeacherPayload(
        name: name,
        maxDailyHours: _maxDailyHours,
        unavailableTimes: unavailableTimes,
      ),
    );
  }
}
