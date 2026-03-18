import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../models/schedule_pdf_model.dart';
import '../../models/schedule_run_model.dart';
import '../../theme/duty_planner_theme.dart';
import '../../services/schedule_pdf_service.dart';
import '../../services/schedule_run_service.dart';
import 'shared.dart';

class SchedulePdfPage extends StatefulWidget {
  final SchedulePdfService pdfService;
  final ScheduleRunService scheduleRunService;
  final int? initialRunId;

  const SchedulePdfPage({
    super.key,
    required this.pdfService,
    required this.scheduleRunService,
    this.initialRunId,
  });

  @override
  State<SchedulePdfPage> createState() => _SchedulePdfPageState();
}

class _SchedulePdfPageState extends State<SchedulePdfPage> {
  List<ScheduleRunModel> _runs = const [];
  List<SchedulePdfModel> _pdfs = const [];
  bool _isLoadingRuns = true;
  bool _isLoadingPdfs = false;
  bool _isGenerating = false;
  String? _error;
  int? _selectedRunId;

  bool get _isLoading => _isLoadingRuns || _isLoadingPdfs;

  @override
  void initState() {
    super.initState();
    _selectedRunId = widget.initialRunId;
    _loadRuns();
  }

  @override
  void didUpdateWidget(covariant SchedulePdfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRunId != null &&
        widget.initialRunId != oldWidget.initialRunId) {
      _selectedRunId = widget.initialRunId;
      _loadPdfs();
    }
  }

  Future<void> _loadRuns() async {
    setState(() {
      _isLoadingRuns = true;
      _error = null;
    });

    try {
      final runs = await widget.scheduleRunService.getScheduleRuns();
      if (!mounted) return;

      final hasSelectedRun = runs.any((run) => run.id == _selectedRunId);
      setState(() {
        _runs = runs;
        _selectedRunId = hasSelectedRun
            ? _selectedRunId
            : (runs.isNotEmpty ? runs.first.id : null);
        _isLoadingRuns = false;
      });

      await _loadPdfs();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoadingRuns = false;
      });
    }
  }

  Future<void> _loadPdfs() async {
    final runId = _selectedRunId;
    if (runId == null) {
      setState(() {
        _pdfs = const [];
        _isLoadingPdfs = false;
      });
      return;
    }

    setState(() {
      _isLoadingPdfs = true;
      _error = null;
    });

    try {
      final pdfs = await widget.pdfService.getRunPdfs(runId);
      if (!mounted) return;
      setState(() {
        _pdfs = pdfs;
        _isLoadingPdfs = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoadingPdfs = false;
      });
    }
  }

  Future<void> _generatePdf() async {
    final runId = _selectedRunId;
    if (runId == null) return;

    setState(() => _isGenerating = true);
    try {
      final result = await widget.pdfService.generateRunPdf(runId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      await _loadPdfs();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _openPdf(SchedulePdfModel pdf) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SchedulePdfPreviewScreen(
          pdf: pdf,
          pdfService: widget.pdfService,
        ),
      ),
    );
  }

  Future<void> _downloadPdf(SchedulePdfModel pdf) async {
    try {
      final bytes = await widget.pdfService.downloadPdfBytes(pdf);
      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: pdf.fileName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SchedulePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScheduleSectionHeader(
            title: 'PDF Listesi',
            subtitle: 'Secilen program calistirmasi icin PDF olusturun ve yonetin',
            actions: [
              IconButton(
                onPressed: _loadRuns,
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
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<int>(
                      value: _selectedRunId,
                      decoration: const InputDecoration(
                        labelText: 'Program calistirmasi sec',
                        prefixIcon: Icon(Icons.history_outlined),
                      ),
                      items: _runs
                          .map(
                            (run) => DropdownMenuItem<int>(
                              value: run.id,
                              child: Text(
                                'Run #${run.id} - ${DateFormat('dd.MM.yyyy HH:mm', 'tr').format(run.createdAt.toLocal())}',
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
                        ? _generatePdf
                        : null,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF Uret'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ScheduleErrorCard(message: _error!, onRetry: _loadRuns)
          else if (_selectedRunId == null)
            const ScheduleEmptyStateCard(
              icon: Icons.history_toggle_off_outlined,
              title: 'Program gecmisi bulunamadi',
              subtitle: 'PDF olusturabilmek icin once bir program calistirmasi gerekir.',
            )
          else if (_pdfs.isEmpty)
            const ScheduleEmptyStateCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Bu run icin PDF bulunamadi',
              subtitle: 'Yukaridaki butonla secilen run icin PDF olusturabilirsiniz.',
            )
          else
            Column(
              children: _pdfs
                  .map(
                    (pdf) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  color: DutyPlannerColors.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pdf.fileName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Run #${pdf.scheduleRunId} - ${DateFormat('dd.MM.yyyy HH:mm', 'tr').format(pdf.createdAt.toLocal())}',
                                        style: const TextStyle(
                                          color: DutyPlannerColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _openPdf(pdf),
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Ac'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _downloadPdf(pdf),
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('Indir'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SchedulePdfPreviewScreen extends StatefulWidget {
  final SchedulePdfModel pdf;
  final SchedulePdfService pdfService;

  const _SchedulePdfPreviewScreen({
    required this.pdf,
    required this.pdfService,
  });

  @override
  State<_SchedulePdfPreviewScreen> createState() =>
      _SchedulePdfPreviewScreenState();
}

class _SchedulePdfPreviewScreenState extends State<_SchedulePdfPreviewScreen> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.pdfService.downloadPdfBytes(widget.pdf);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdf.fileName),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                final bytes = await _bytesFuture;
                if (!mounted) return;
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: widget.pdf.fileName,
                );
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.toString())));
              }
            },
            tooltip: 'Indir',
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
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
                  snapshot.error?.toString() ?? 'PDF yuklenemedi.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final bytes = snapshot.data!;
          return PdfPreview(
            build: (_) async => bytes,
            pdfFileName: widget.pdf.fileName,
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowPrinting: true,
            allowSharing: true,
          );
        },
      ),
    );
  }
}
