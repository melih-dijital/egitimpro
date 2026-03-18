import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/schedule_builder_models.dart';
import '../../services/schedule_builder_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';

class ScheduleHistoryScreen extends StatefulWidget {
  final ScheduleBuilderService service;
  final SchoolContext schoolContext;
  final void Function(int runId) onNavigateToPdfs;

  const ScheduleHistoryScreen({
    super.key,
    required this.service,
    required this.schoolContext,
    required this.onNavigateToPdfs,
  });

  @override
  State<ScheduleHistoryScreen> createState() => _ScheduleHistoryScreenState();
}

class _ScheduleHistoryScreenState extends State<ScheduleHistoryScreen> {
  List<ScheduleRunBrief> _runs = const [];
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
      final runs = await widget.service.getScheduleRuns();
      if (!mounted) return;
      setState(() {
        _runs = runs;
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

  Future<void> _showDetails(ScheduleRunBrief run) async {
    try {
      final detail = await widget.service.getScheduleRunDetail(run.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Run #${run.id} Detayı'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Durum: ${detail.status}'),
                const SizedBox(height: 8),
                Text(
                  'Oluşturma: ${DateFormat('dd.MM.yyyy HH:mm', 'tr').format(detail.createdAt.toLocal())}',
                ),
                const SizedBox(height: 8),
                Text('School ID: ${detail.schoolId}'),
                const SizedBox(height: 8),
                Text(
                  'Meta: ${detail.meta.isEmpty ? 'Yok' : detail.meta.toString()}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _generatePdfs(ScheduleRunBrief run) async {
    try {
      final response = await widget.service.generateRunPdfs(
        runId: run.id,
        schoolName: widget.schoolContext.schoolName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']?.toString() ?? 'PDF üretildi')),
      );
      widget.onNavigateToPdfs(run.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteRun(ScheduleRunBrief run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Program Sürümünü Sil'),
        content: Text('Run #${run.id} silinsin mi? İlişkili kayıtlar da kaldırılır.'),
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
      await widget.service.deleteScheduleRun(run.id);
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
            title: 'Program Geçmişi',
            subtitle: 'Oluşturulan tüm program sürümlerini yönetin',
            actions: [
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
          else if (_runs.isEmpty)
            const ScheduleEmptyStateCard(
              icon: Icons.history_outlined,
              title: 'Henüz program geçmişi yok',
              subtitle: 'İlk program üretildiğinde burada listelenecek.',
            )
          else
            Column(
              children: _runs.map((run) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Run #${run.id}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            RunStatusBadge(status: run.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat(
                            'dd.MM.yyyy HH:mm',
                            'tr',
                          ).format(run.createdAt.toLocal()),
                          style: const TextStyle(
                            color: DutyPlannerColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _showDetails(run),
                              child: const Text('Detay'),
                            ),
                            OutlinedButton(
                              onPressed: () => _generatePdfs(run),
                              child: const Text('PDF Üret'),
                            ),
                            OutlinedButton(
                              onPressed: () => widget.onNavigateToPdfs(run.id),
                              child: const Text('PDF Listesine Git'),
                            ),
                            OutlinedButton(
                              onPressed: () => _deleteRun(run),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DutyPlannerColors.error,
                                side: const BorderSide(
                                  color: DutyPlannerColors.error,
                                ),
                              ),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
