import 'package:flutter/material.dart';

import '../../models/schedule_builder_models.dart';
import '../../services/schedule_builder_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';

class ScheduleTeacherCourseScreen extends StatefulWidget {
  final ScheduleBuilderService service;

  const ScheduleTeacherCourseScreen({super.key, required this.service});

  @override
  State<ScheduleTeacherCourseScreen> createState() =>
      _ScheduleTeacherCourseScreenState();
}

class _ScheduleTeacherCourseScreenState
    extends State<ScheduleTeacherCourseScreen> {
  List<ScheduleTeacher> _teachers = const [];
  List<ScheduleCourse> _courses = const [];
  List<ScheduleTeacherCourse> _mappings = const [];
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
        widget.service.getTeachers(),
        widget.service.getCourses(),
        widget.service.getTeacherCourses(),
      ]);
      if (!mounted) return;
      setState(() {
        _teachers = results[0] as List<ScheduleTeacher>;
        _courses = results[1] as List<ScheduleCourse>;
        _mappings = results[2] as List<ScheduleTeacherCourse>;
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

  Future<void> _showDialog() async {
    if (_teachers.isEmpty || _courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce öğretmen ve ders kayıtlarını tamamlayın.'),
        ),
      );
      return;
    }

    int teacherId = _teachers.first.id;
    int courseId = _courses.first.id;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Öğretmen-Ders Eşleştirme'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: teacherId,
                  decoration: const InputDecoration(
                    labelText: 'Öğretmen',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: _teachers
                      .map(
                        (teacher) => DropdownMenuItem(
                          value: teacher.id,
                          child: Text(teacher.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => teacherId = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: courseId,
                  decoration: const InputDecoration(
                    labelText: 'Ders',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  items: _courses
                      .map(
                        (course) => DropdownMenuItem(
                          value: course.id,
                          child: Text('${course.name} (${course.classroomName})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => courseId = value);
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
                try {
                  await widget.service.createTeacherCourse(
                    teacherId: teacherId,
                    courseId: courseId,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      _load();
    }
  }

  Future<void> _deleteMapping(ScheduleTeacherCourse mapping) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eşleştirmeyi Sil'),
        content: Text('${mapping.teacherName} - ${mapping.courseName} silinsin mi?'),
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
      await widget.service.deleteTeacherCourse(
        teacherId: mapping.teacherId,
        courseId: mapping.courseId,
      );
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
    final coursesById = {for (final course in _courses) course.id: course};

    return SchedulePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScheduleSectionHeader(
            title: 'Öğretmen-Ders Eşleştirme',
            subtitle: 'Hangi öğretmenin hangi dersi vereceğini tanımlayın',
            actions: [
              OutlinedButton.icon(
                onPressed: _showDialog,
                icon: const Icon(Icons.add_link_outlined),
                label: const Text('Eşleştirme Ekle'),
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
          else if (_mappings.isEmpty)
            ScheduleEmptyStateCard(
              icon: Icons.link_outlined,
              title: 'Henüz eşleştirme yok',
              subtitle: 'Program üretmeden önce öğretmen-ders ilişkilerini tanımlayın.',
              actionLabel: 'Eşleştirme Ekle',
              onAction: _showDialog,
            )
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_tree_outlined),
                    title: Text('${_mappings.length} eşleştirme kayıtlı'),
                    subtitle: const Text('Solver bu ilişkileri kullanır'),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mappings.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final mapping = _mappings[index];
                      final course = coursesById[mapping.courseId];
                      return ListTile(
                        leading: const Icon(Icons.link, color: Colors.orange),
                        title: Text(mapping.teacherName),
                        subtitle: Text(
                          '${mapping.courseName}${course == null ? '' : ' • ${course.classroomName}'}',
                        ),
                        trailing: IconButton(
                          onPressed: () => _deleteMapping(mapping),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: DutyPlannerColors.error,
                          ),
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
