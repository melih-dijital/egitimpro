import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/schedule_teacher_model.dart';
import '../../services/schedule_teacher_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';
import 'widgets/teacher_form_dialog.dart';

class TeacherListPage extends StatefulWidget {
  final ScheduleTeacherService teacherService;

  const TeacherListPage({super.key, required this.teacherService});

  @override
  State<TeacherListPage> createState() => _TeacherListPageState();
}

class _TeacherListPageState extends State<TeacherListPage> {
  List<ScheduleTeacherModel> _teachers = const [];
  bool _isLoading = true;
  bool _isUploading = false;
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
      final teachers = await widget.teacherService.getTeachers();
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

  Future<void> _showTeacherForm([ScheduleTeacherModel? teacher]) async {
    final payload = await TeacherFormDialog.show(context, teacher: teacher);
    if (payload == null) return;

    try {
      if (teacher == null) {
        await widget.teacherService.createTeacher(payload);
      } else {
        await widget.teacherService.updateTeacher(teacher.id, payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            teacher == null
                ? 'Öğretmen eklendi.'
                : 'Öğretmen bilgileri güncellendi.',
          ),
        ),
      );
      _loadTeachers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteTeacher(ScheduleTeacherModel teacher) async {
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
      await widget.teacherService.deleteTeacher(teacher.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğretmen silindi.')),
      );
      _loadTeachers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _uploadTeachers() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya verisi okunamadı.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uploadResult = await widget.teacherService.uploadTeachers(
        bytes: bytes,
        fileName: file.name,
      );

      if (!mounted) return;
      final message = uploadResult.errorCount > 0
          ? '${uploadResult.message} (${uploadResult.errorCount} hata)'
          : uploadResult.message;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      _loadTeachers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
            subtitle:
                'Öğretmen listesi, saat sınırı, müsaitlik ve dosya yükleme yönetimi',
            actions: [
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _uploadTeachers,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                label: const Text('Excel/CSV Yükle'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showTeacherForm(),
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
              subtitle:
                  'İlk öğretmeni ekleyin veya Excel/CSV ile toplu yükleme yapın.',
              actionLabel: 'Öğretmen Ekle',
              onAction: () => _showTeacherForm(),
            )
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text('${_teachers.length} öğretmen kayıtlı'),
                    subtitle: const Text(
                      'max_daily_hours ve unavailable_times alanları aktif',
                    ),
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
                              DutyPlannerColors.primaryLight.withValues(
                                alpha: 0.15,
                              ),
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
                              _showTeacherForm(teacher);
                            } else if (value == 'delete') {
                              _deleteTeacher(teacher);
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
