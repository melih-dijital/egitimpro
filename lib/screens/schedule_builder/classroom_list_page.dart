import 'package:flutter/material.dart';

import '../../models/schedule_classroom_model.dart';
import '../../services/schedule_classroom_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';
import 'widgets/classroom_form_dialog.dart';

class ClassroomListPage extends StatefulWidget {
  final ScheduleClassroomService classroomService;

  const ClassroomListPage({super.key, required this.classroomService});

  @override
  State<ClassroomListPage> createState() => _ClassroomListPageState();
}

class _ClassroomListPageState extends State<ClassroomListPage> {
  List<ScheduleClassroomModel> _classrooms = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final classrooms = await widget.classroomService.getClassrooms();
      if (!mounted) return;
      setState(() {
        _classrooms = classrooms;
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

  Future<void> _showClassroomForm([ScheduleClassroomModel? classroom]) async {
    final payload = await ClassroomFormDialog.show(
      context,
      classroom: classroom,
    );
    if (payload == null) return;

    try {
      if (classroom == null) {
        await widget.classroomService.createClassroom(payload);
      } else {
        await widget.classroomService.updateClassroom(classroom.id, payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            classroom == null
                ? 'Sınıf eklendi.'
                : 'Sınıf bilgileri güncellendi.',
          ),
        ),
      );
      _loadClassrooms();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteClassroom(ScheduleClassroomModel classroom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınıfı Sil'),
        content: Text('${classroom.name} silinsin mi?'),
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
      await widget.classroomService.deleteClassroom(classroom.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sınıf silindi.')));
      _loadClassrooms();
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
            title: 'Sınıflar',
            subtitle: 'Sınıf listesi ve grade_level yönetimi',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _showClassroomForm(),
                icon: const Icon(Icons.add),
                label: const Text('Sınıf Ekle'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadClassrooms,
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ScheduleErrorCard(message: _error!, onRetry: _loadClassrooms)
          else if (_classrooms.isEmpty)
            ScheduleEmptyStateCard(
              icon: Icons.meeting_room_outlined,
              title: 'Henüz sınıf eklenmedi',
              subtitle:
                  'Ders programı oluşturmadan önce ilk sınıf kaydını ekleyin.',
              actionLabel: 'Sınıf Ekle',
              onAction: () => _showClassroomForm(),
            )
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.groups_2_outlined),
                    title: Text('${_classrooms.length} sınıf kayıtlı'),
                    subtitle: const Text(
                      'Her sınıf için name ve grade_level alanları kullanılır',
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _classrooms.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final classroom = _classrooms[index];
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${classroom.gradeLevel}',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(classroom.name),
                        subtitle: Text(
                          '${classroom.gradeLevel}. sınıf seviyesi',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showClassroomForm(classroom);
                            } else if (value == 'delete') {
                              _deleteClassroom(classroom);
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
