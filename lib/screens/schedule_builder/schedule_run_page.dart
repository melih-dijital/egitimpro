import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/schedule_run_model.dart';
import '../../services/schedule_run_service.dart';
import 'shared.dart';

class ScheduleRunPage extends StatefulWidget {
  final ScheduleRunService scheduleRunService;

  const ScheduleRunPage({super.key, required this.scheduleRunService});

  @override
  State<ScheduleRunPage> createState() => _ScheduleRunPageState();
}

class _ScheduleRunPageState extends State<ScheduleRunPage> {
  List<ScheduleRunModel> _runs = const [];
  ScheduleRunCreateResult? _lastResult;
  bool _isLoading = true;
  bool _isCreating = false;
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
      final runs = await widget.scheduleRunService.getScheduleRuns();
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

  Future<void> _createRun() async {
    setState(() => _isCreating = true);

    try {
      final result = await widget.scheduleRunService.createScheduleRun();
      if (!mounted) return;

      setState(() => _lastResult = result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _showRunDetail(ScheduleRunModel run) async {
    try {
      final detail = await widget.scheduleRunService.getScheduleRunDetail(run.id);
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
                Text('Kullanıcı: ${detail.createdByUserId}'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
            subtitle: 'Yeni program üretin ve oluşan geçmiş kayıtlarını izleyin',
            actions: [
              ElevatedButton.icon(
                onPressed: _isCreating ? null : _createRun,
                icon: _isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: const Text('Program Oluştur'),
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
          if (_lastResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Son Sonuç',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_lastResult!.message),
                    const SizedBox(height: 8),
                    Text('Run ID: ${_lastResult!.scheduleRunId}'),
                    Text('Durum: ${_lastResult!.status}'),
                    Text('Toplam ders slotu: ${_lastResult!.totalEntries}'),
                    Text(
                      'Tarih: ${DateFormat('dd.MM.yyyy HH:mm', 'tr').format(_lastResult!.createdAt.toLocal())}',
                    ),
                  ],
                ),
              ),
            ),
          if (_lastResult != null) const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ScheduleErrorCard(message: _error!, onRetry: _load)
          else if (_runs.isEmpty)
            ScheduleEmptyStateCard(
              icon: Icons.history_outlined,
              title: 'Henüz program geçmişi yok',
              subtitle:
                  'İlk programı oluşturduğunuzda geçmiş kayıtları burada listelenecek.',
              actionLabel: 'Program Oluştur',
              onAction: _createRun,
            )
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: Text('${_runs.length} program kaydı'),
                    subtitle: const Text(
                      'Oluşturulan program geçmişi ve detay görüntüleme',
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _runs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final run = _runs[index];
                      return ListTile(
                        leading: RunStatusBadge(status: run.status),
                        title: Text('Run #${run.id}'),
                        subtitle: Text(
                          DateFormat(
                            'dd.MM.yyyy HH:mm',
                            'tr',
                          ).format(run.createdAt.toLocal()),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () => _showRunDetail(run),
                          child: const Text('Detay'),
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
