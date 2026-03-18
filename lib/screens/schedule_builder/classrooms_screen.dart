import 'package:flutter/material.dart';

import '../../models/schedule_builder_models.dart';
import '../../services/schedule_builder_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';

class ScheduleClassroomsScreen extends StatefulWidget {
  final ScheduleBuilderService service;

  const ScheduleClassroomsScreen({super.key, required this.service});

  @override
  State<ScheduleClassroomsScreen> createState() =>
      _ScheduleClassroomsScreenState();
}

class _ScheduleClassroomsScreenState extends State<ScheduleClassroomsScreen> {
  List<ScheduleClassroom> _classrooms = const [];
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
      final classrooms = await widget.service.getClassrooms();
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

  Future<void> _showDialog([ScheduleClassroom? classroom]) async {
    final nameController = TextEditingController(text: classroom?.name ?? '');
    int gradeLevel = classroom?.gradeLevel ?? 9;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(classroom == null ? 'Sınıf Ekle' : 'Sınıfı Düzenle'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Sınıf Adı',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: gradeLevel,
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
                      setDialogState(() => gradeLevel = value);
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
                  if (classroom == null) {
                    await widget.service.createClassroom(
                      name: name,
                      gradeLevel: gradeLevel,
                    );
                  } else {
                    await widget.service.updateClassroom(
                      classroomId: classroom.id,
                      name: name,
                      gradeLevel: gradeLevel,
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
              child: Text(classroom == null ? 'Ekle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadClassrooms();
    }
  }

  Future<void> _deleteClassroom(ScheduleClassroom classroom) async {
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
      await widget.service.deleteClassroom(classroom.id);
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
            subtitle: 'Program üretiminde yer alacak sınıflar',
            actions: [
              OutlinedButton.icon(
                onPressed: _showDialog,
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
              subtitle: 'Dersleri bağlayabilmek için en az bir sınıf ekleyin.',
              actionLabel: 'Sınıf Ekle',
              onAction: _showDialog,
            )
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.groups_2_outlined),
                    title: Text('${_classrooms.length} sınıf kayıtlı'),
                    subtitle: const Text('Her ders kaydı bir sınıfa bağlanır'),
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
                        subtitle: Text('${classroom.gradeLevel}. sınıf seviyesi'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showDialog(classroom);
                            } else if (value == 'delete') {
                              _deleteClassroom(classroom);
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
