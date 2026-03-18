import 'package:flutter/material.dart';

import '../../models/schedule_builder_models.dart';
import '../../services/schedule_builder_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';

class ScheduleCoursesScreen extends StatefulWidget {
  final ScheduleBuilderService service;

  const ScheduleCoursesScreen({super.key, required this.service});

  @override
  State<ScheduleCoursesScreen> createState() => _ScheduleCoursesScreenState();
}

class _ScheduleCoursesScreenState extends State<ScheduleCoursesScreen> {
  List<ScheduleCourse> _courses = const [];
  List<ScheduleClassroom> _classrooms = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.service.getCourses(),
        widget.service.getClassrooms(),
      ]);
      if (!mounted) return;
      setState(() {
        _courses = results[0] as List<ScheduleCourse>;
        _classrooms = results[1] as List<ScheduleClassroom>;
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

  Future<void> _showDialog([ScheduleCourse? course]) async {
    if (_classrooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce en az bir sınıf eklemelisiniz.')),
      );
      return;
    }

    final nameController = TextEditingController(text: course?.name ?? '');
    int weeklyHours = course?.weeklyHours ?? 2;
    int classroomId = course?.classroomId ?? _classrooms.first.id;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(course == null ? 'Ders Ekle' : 'Dersi Düzenle'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ders Adı',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: classroomId,
                  decoration: const InputDecoration(
                    labelText: 'Sınıf',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  items: _classrooms
                      .map(
                        (classroom) => DropdownMenuItem(
                          value: classroom.id,
                          child: Text(classroom.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => classroomId = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: weeklyHours,
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
                      setDialogState(() => weeklyHours = value);
                    }
                  },
                ),
              ],
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
                try {
                  if (course == null) {
                    await widget.service.createCourse(
                      name: name,
                      weeklyHours: weeklyHours,
                      classroomId: classroomId,
                    );
                  } else {
                    await widget.service.updateCourse(
                      courseId: course.id,
                      name: name,
                      weeklyHours: weeklyHours,
                      classroomId: classroomId,
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
              child: Text(course == null ? 'Ekle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      _load();
    }
  }

  Future<void> _deleteCourse(ScheduleCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dersi Sil'),
        content: Text('${course.name} silinsin mi?'),
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
      await widget.service.deleteCourse(course.id);
      _load();
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
            title: 'Dersler',
            subtitle: 'Sınıf bazlı ders ve haftalık saat tanımları',
            actions: [
              OutlinedButton.icon(
                onPressed: _showDialog,
                icon: const Icon(Icons.add),
                label: const Text('Ders Ekle'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _load,
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ScheduleErrorCard(message: _error!, onRetry: _load)
          else if (_courses.isEmpty)
            ScheduleEmptyStateCard(
              icon: Icons.book_outlined,
              title: 'Henüz ders tanımı yok',
              subtitle: 'Programı oluşturmak için dersleri sınıflara bağlayın.',
              actionLabel: 'Ders Ekle',
              onAction: _showDialog,
            )
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text('${_courses.length} ders kayıtlı'),
                    subtitle: Text('${_classrooms.length} sınıfa dağıtılmış'),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _courses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.book_outlined,
                            color: Colors.indigo,
                          ),
                        ),
                        title: Text(course.name),
                        subtitle: Text(
                          '${course.classroomName} • Haftalık ${course.weeklyHours} saat',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showDialog(course);
                            } else if (value == 'delete') {
                              _deleteCourse(course);
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
