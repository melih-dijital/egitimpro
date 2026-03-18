import 'package:flutter/material.dart';

import '../../models/schedule_classroom_model.dart';
import '../../models/schedule_course_model.dart';
import '../../services/schedule_classroom_service.dart';
import '../../services/schedule_course_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';
import 'widgets/course_form_dialog.dart';

class CourseListPage extends StatefulWidget {
  final ScheduleCourseService courseService;
  final ScheduleClassroomService classroomService;

  const CourseListPage({
    super.key,
    required this.courseService,
    required this.classroomService,
  });

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  List<ScheduleCourseModel> _courses = const [];
  List<ScheduleClassroomModel> _classrooms = const [];
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
        widget.courseService.getCourses(),
        widget.classroomService.getClassrooms(),
      ]);
      if (!mounted) return;
      setState(() {
        _courses = results[0] as List<ScheduleCourseModel>;
        _classrooms = results[1] as List<ScheduleClassroomModel>;
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

  Future<void> _showCourseForm([ScheduleCourseModel? course]) async {
    if (_classrooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce en az bir sınıf eklemelisiniz.')),
      );
      return;
    }

    final payload = await CourseFormDialog.show(
      context,
      course: course,
      classrooms: _classrooms,
    );
    if (payload == null) return;

    try {
      if (course == null) {
        await widget.courseService.createCourse(payload);
      } else {
        await widget.courseService.updateCourse(course.id, payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            course == null ? 'Ders eklendi.' : 'Ders bilgileri güncellendi.',
          ),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteCourse(ScheduleCourseModel course) async {
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
      await widget.courseService.deleteCourse(course.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ders silindi.')));
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
            subtitle: 'Ders listesi, weekly_hours ve sınıf seçimi yönetimi',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _showCourseForm(),
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
              subtitle:
                  'Programı oluşturmak için dersleri sınıflarla ilişkilendirin.',
              actionLabel: 'Ders Ekle',
              onAction: () => _showCourseForm(),
            )
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text('${_courses.length} ders kayıtlı'),
                    subtitle: Text('${_classrooms.length} sınıf için hazır'),
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
                              _showCourseForm(course);
                            } else if (value == 'delete') {
                              _deleteCourse(course);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Düzenle'),
                            ),
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
