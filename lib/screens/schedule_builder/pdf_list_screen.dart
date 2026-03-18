import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../models/schedule_builder_models.dart';
import '../../services/schedule_builder_service.dart';
import 'shared.dart';

class SchedulePdfListScreen extends StatefulWidget {
  final ScheduleBuilderService service;
  final SchoolContext schoolContext;
  final int? initialRunId;

  const SchedulePdfListScreen({
    super.key,
    required this.service,
    required this.schoolContext,
    required this.initialRunId,
  });

  @override
  State<SchedulePdfListScreen> createState() => _SchedulePdfListScreenState();
}

class _SchedulePdfListScreenState extends State<SchedulePdfListScreen> {
  List<ScheduleRunBrief> _runs = const [];
  List<SchedulePdfFile> _pdfs = const [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;
  int? _selectedRunId;

  @override
  void initState() {
    super.initState();
    _selectedRunId = widget.initialRunId;
    _load();
  }

  @override
  void didUpdateWidget(covariant SchedulePdfListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRunId != null &&
        widget.initialRunId != oldWidget.initialRunId) {
      _selectedRunId = widget.initialRunId;
      _loadPdfs();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final runs = await widget.service.getScheduleRuns();
      if (!mounted) return;
      final hasSelectedRun = runs.any((run) => run.id == _selectedRunId);
      setState(() {
        _runs = runs;
        _selectedRunId = hasSelectedRun
            ? _selectedRunId
            : (runs.isNotEmpty ? runs.first.id : null);
        _isLoading = false;
      });
      _loadPdfs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPdfs() async {
    final runId = _selectedRunId;
    if (runId == null) {
      setState(() => _pdfs = const []);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final pdfs = await widget.service.getRunPdfs(runId);
      if (!mounted) return;
      setState(() {
        _pdfs = pdfs;
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

  Future<void> _generatePdfs() async {
    final runId = _selectedRunId;
    if (runId == null) return;

    setState(() => _isGenerating = true);
    try {
      final response = await widget.service.generateRunPdfs(
        runId: runId,
        schoolName: widget.schoolContext.schoolName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']?.toString() ?? 'PDF üretildi')),
      );
      _loadPdfs();
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

  void _openPreview(SchedulePdfFile pdf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SchedulePdfPreviewScreen(
          service: widget.service,
          filePath: pdf.filePath,
          title: pdf.fileName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SchedulePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScheduleSectionHeader(
            title: 'PDF Listesi',
            subtitle: 'Run bazında üretilen PDF dosyalarını görüntüleyin',
            actions: [
              IconButton(
                onPressed: _load,
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<int>(
                      value: _selectedRunId,
                      decoration: const InputDecoration(
                        labelText: 'Program Run Seç',
                        prefixIcon: Icon(Icons.history_outlined),
                      ),
                      items: _runs
                          .map(
                            (run) => DropdownMenuItem(
                              value: run.id,
                              child: Text(
                                'Run #${run.id} - ${DateFormat('dd.MM HH:mm', 'tr').format(run.createdAt.toLocal())}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedRunId = value);
                        _loadPdfs();
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: (_selectedRunId != null && !_isGenerating)
                        ? _generatePdfs
                        : null,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF Üret'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ScheduleErrorCard(message: _error!, onRetry: _loadPdfs)
          else if (_selectedRunId == null)
            const ScheduleEmptyStateCard(
              icon: Icons.history_toggle_off_outlined,
              title: 'Program geçmişi bulunamadı',
              subtitle: 'Önce en az bir program run oluşturmalısınız.',
            )
          else if (_pdfs.isEmpty)
            const ScheduleEmptyStateCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Bu run için PDF yok',
              subtitle: 'Yukarıdaki butonla PDF üretimini başlatabilirsiniz.',
            )
          else
            Column(
              children: _pdfs.map((pdf) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    title: Text(pdf.fileName),
                    subtitle: Text(
                      'Run #${pdf.scheduleRunId} • ${DateFormat('dd.MM.yyyy HH:mm', 'tr').format(pdf.createdAt.toLocal())}',
                    ),
                    trailing: OutlinedButton.icon(
                      onPressed: () => _openPreview(pdf),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Önizle'),
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

class _SchedulePdfPreviewScreen extends StatefulWidget {
  final ScheduleBuilderService service;
  final String filePath;
  final String title;

  const _SchedulePdfPreviewScreen({
    required this.service,
    required this.filePath,
    required this.title,
  });

  @override
  State<_SchedulePdfPreviewScreen> createState() =>
      _SchedulePdfPreviewScreenState();
}

class _SchedulePdfPreviewScreenState extends State<_SchedulePdfPreviewScreen> {
  late Future<List<int>> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.service.downloadPdfBytes(widget.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<int>>(
        future: _bytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error?.toString() ?? 'PDF yüklenemedi',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final bytes = snapshot.data!;
          return PdfPreview(
            build: (_) async => bytes,
            pdfFileName: widget.title,
            canChangePageFormat: false,
            canChangeOrientation: false,
          );
        },
      ),
    );
  }
}
