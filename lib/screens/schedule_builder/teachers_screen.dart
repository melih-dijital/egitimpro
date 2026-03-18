import 'package:flutter/material.dart';

import '../../models/schedule_builder_models.dart';
import '../../services/schedule_builder_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';

class ScheduleTeachersScreen extends StatefulWidget {
  final ScheduleBuilderService service;

  const ScheduleTeachersScreen({super.key, required this.service});

  @override
  State<ScheduleTeachersScreen> createState() => _ScheduleTeachersScreenState();
}

class _ScheduleTeachersScreenState extends State<ScheduleTeachersScreen> {
  List<ScheduleTeacher> _teachers = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final teachers = await widget.service.getTeachers();
      if (!mounted) return;
      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showDialog([ScheduleTeacher? teacher]) async {
    final nameController = TextEditingController(text: teacher?.name ?? '');
    int maxDailyHours = teacher?.maxDailyHours ?? 8;
    final selected = {
      for (final slot
          in teacher?.unavailableTimes ?? const <ScheduleUnavailableTime>[])
        '${slot.day}-${slot.hour}',
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(teacher == null ? 'Öğretmen Ekle' : 'Öğretmeni Düzenle'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Öğretmen Adı',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: maxDailyHours,
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
                        setDialogState(() => maxDailyHours = value);
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
                            selected: selected.contains('$day-$hour'),
                            onSelected: (value) {
                              setDialogState(() {
                                final key = '$day-$hour';
                                if (value) {
                                  selected.add(key);
                                } else {
                                  selected.remove(key);
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final unavailableTimes = selected
                    .map((item) {
                      final parts = item.split('-');
                      return ScheduleUnavailableTime(
                        day: int.parse(parts[0]),
                        hour: int.parse(parts[1]),
                      );
                    })
                    .toList();

                try {
                  if (teacher == null) {
                    await widget.service.createTeacher(
                      name: name,
                      maxDailyHours: maxDailyHours,
                      unavailableTimes: unavailableTimes,
                    );
                  } else {
                    await widget.service.updateTeacher(
                      teacherId: teacher.id,
                      name: name,
                      maxDailyHours: maxDailyHours,
                      unavailableTimes: unavailableTimes,
                    );
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text(teacher == null ? 'Ekle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadTeachers();
    }
  }

  Future<void> _deleteTeacher(ScheduleTeacher teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğretmeni Sil'),
        content: Text('${teacher.name} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DutyPlannerColors.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteTeacher(teacher.id);
      _loadTeachers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SchedulePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScheduleSectionHeader(
            title: 'Öğretmenler',
            subtitle: 'Öğretmen listesi, saat sınırı ve müsaitlik yönetimi',
            actions: [
              OutlinedButton.icon(
                onPressed: _showDialog,
                icon: const Icon(Icons.add),
                label: const Text('Öğretmen Ekle'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadTeachers,
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ScheduleErrorCard(message: _error!, onRetry: _loadTeachers)
          else if (_teachers.isEmpty)
            ScheduleEmptyStateCard(
              icon: Icons.people_outline,
              title: 'Henüz öğretmen eklenmedi',
              subtitle: 'Program üretmeden önce öğretmen kaydı ekleyin.',
              actionLabel: 'Öğretmen Ekle',
              onAction: _showDialog,
            )
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text('${_teachers.length} öğretmen kayıtlı'),
                    subtitle: const Text('Ders saatleri bu kayıtlarla planlanır'),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _teachers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final teacher = _teachers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              DutyPlannerColors.primaryLight.withValues(alpha: 0.15),
                          child: Text(
                            teacher.name.isEmpty
                                ? '?'
                                : teacher.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: DutyPlannerColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(teacher.name),
                        subtitle: Text(
                          'Günlük max ${teacher.maxDailyHours} saat'
                          '${teacher.unavailableTimes.isEmpty ? '' : ' • ${teacher.unavailableTimes.length} kapalı slot'}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showDialog(teacher);
                            } else if (value == 'delete') {
                              _deleteTeacher(teacher);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                            PopupMenuItem(value: 'delete', child: Text('Sil')),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
