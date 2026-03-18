import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/schedule_builder_models.dart';
import '../../services/schedule_builder_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';

class ScheduleGenerateScreen extends StatefulWidget {
  final ScheduleBuilderService service;
  final SchoolContext schoolContext;
  final VoidCallback onNavigateToHistory;
  final void Function(int runId) onNavigateToPdfs;

  const ScheduleGenerateScreen({
    super.key,
    required this.service,
    required this.schoolContext,
    required this.onNavigateToHistory,
    required this.onNavigateToPdfs,
  });

  @override
  State<ScheduleGenerateScreen> createState() => _ScheduleGenerateScreenState();
}

class _ScheduleGenerateScreenState extends State<ScheduleGenerateScreen> {
  final TextEditingController _schoolNameController = TextEditingController();
  ScheduleDashboardData? _data;
  ScheduleGenerationResult? _result;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isGeneratingPdf = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _schoolNameController.text = widget.schoolContext.schoolName;
    _load();
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await widget.service.getDashboardData();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  bool get _canGenerate =>
      (_data?.teacherCount ?? 0) > 0 &&
      (_data?.classroomCount ?? 0) > 0 &&
      (_data?.courseCount ?? 0) > 0 &&
      (_data?.mappingCount ?? 0) > 0;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final result = await widget.service.generateSchedule();
      if (!mounted) return;
      setState(() => _result = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generatePdfs() async {
    final runId = _result?.scheduleRunId;
    if (runId == null) return;
    setState(() => _isGeneratingPdf = true);
    try {
      final response = await widget.service.generateRunPdfs(
        runId: runId,
        schoolName: _schoolNameController.text.trim().isEmpty
            ? widget.schoolContext.schoolName
            : _schoolNameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']?.toString() ?? 'PDF üretildi')),
      );
      widget.onNavigateToPdfs(runId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
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
            title: 'Program Oluştur',
            subtitle: 'Hazırlığı kontrol edin, solver çalıştırın ve PDF üretin',
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
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hazırlık Kontrolü',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatusChip(
                          label: 'Öğretmen: ${_data?.teacherCount ?? 0}',
                          ok: (_data?.teacherCount ?? 0) > 0,
                        ),
                        _StatusChip(
                          label: 'Sınıf: ${_data?.classroomCount ?? 0}',
                          ok: (_data?.classroomCount ?? 0) > 0,
                        ),
                        _StatusChip(
                          label: 'Ders: ${_data?.courseCount ?? 0}',
                          ok: (_data?.courseCount ?? 0) > 0,
                        ),
                        _StatusChip(
                          label: 'Eşleştirme: ${_data?.mappingCount ?? 0}',
                          ok: (_data?.mappingCount ?? 0) > 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _schoolNameController,
                      decoration: const InputDecoration(
                        labelText: 'PDF Başlığındaki Okul Adı',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _canGenerate && !_isGenerating ? _generate : null,
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Programı Oluştur'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              (_result != null && !_isGeneratingPdf) ? _generatePdfs : null,
                          icon: _isGeneratingPdf
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Son Run için PDF Üret'),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.onNavigateToHistory,
                          icon: const Icon(Icons.history_outlined),
                          label: const Text('Geçmişe Git'),
                        ),
                      ],
                    ),
                    if (!_canGenerate) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Program üretimi için dört hazırlık alanının da en az bir kaydı olmalı.',
                        style: TextStyle(color: DutyPlannerColors.warning),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Son Üretim Sonucu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_result!.message),
                      const SizedBox(height: 8),
                      Text('Run ID: ${_result!.scheduleRunId}'),
                      Text('Toplam ders slotu: ${_result!.totalEntries}'),
                      Text('Durum: ${_result!.status}'),
                      Text(
                        'Tarih: ${DateFormat('dd.MM.yyyy HH:mm', 'tr').format(_result!.createdAt.toLocal())}',
                      ),
                      const SizedBox(height: 16),
                      ..._result!.classrooms.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.classroomName)),
                              Text('${item.lessonCount} ders'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool ok;

  const _StatusChip({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        ok ? Icons.check_circle_outline : Icons.error_outline,
        size: 18,
        color: ok ? DutyPlannerColors.success : DutyPlannerColors.warning,
      ),
      label: Text(label),
    );
  }
}
