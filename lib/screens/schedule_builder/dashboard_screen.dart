import 'package:flutter/material.dart';

import '../../models/schedule_builder_models.dart';
import '../../services/schedule_builder_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'shared.dart';

class ScheduleDashboardScreen extends StatefulWidget {
  final ScheduleBuilderService service;
  final SchoolContext schoolContext;
  final void Function(int tabIndex) onNavigate;

  const ScheduleDashboardScreen({
    super.key,
    required this.service,
    required this.schoolContext,
    required this.onNavigate,
  });

  @override
  State<ScheduleDashboardScreen> createState() => _ScheduleDashboardScreenState();
}

class _ScheduleDashboardScreenState extends State<ScheduleDashboardScreen> {
  ScheduleDashboardData? _data;
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

  @override
  Widget build(BuildContext context) {
    return SchedulePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScheduleSectionHeader(
            title: 'Ders Programı Ana Sayfası',
            subtitle:
                '${widget.schoolContext.schoolName} için hazırlık ve üretim merkezi',
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Akış',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Önce öğretmen, sınıf, ders ve eşleştirmeleri tanımlayın. Ardından program üretip geçmiş ve PDF ekranlarından çıktıları yönetin.',
                    style: TextStyle(color: DutyPlannerColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ScheduleErrorCard(message: _error!, onRetry: _load)
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SummaryCard(
                  icon: Icons.people_outline,
                  title: 'Öğretmenler',
                  value: '${_data!.teacherCount}',
                  subtitle: 'Müsaitlik ve saat sınırları',
                  color: DutyPlannerColors.primary,
                  onTap: () => widget.onNavigate(1),
                ),
                _SummaryCard(
                  icon: Icons.meeting_room_outlined,
                  title: 'Sınıflar',
                  value: '${_data!.classroomCount}',
                  subtitle: 'Program üretilecek sınıflar',
                  color: Colors.teal,
                  onTap: () => widget.onNavigate(2),
                ),
                _SummaryCard(
                  icon: Icons.book_outlined,
                  title: 'Dersler',
                  value: '${_data!.courseCount}',
                  subtitle: 'Haftalık ders saatleri',
                  color: Colors.indigo,
                  onTap: () => widget.onNavigate(3),
                ),
                _SummaryCard(
                  icon: Icons.link_outlined,
                  title: 'Eşleştirmeler',
                  value: '${_data!.mappingCount}',
                  subtitle: 'Öğretmen-ders bağlantıları',
                  color: Colors.orange,
                  onTap: () => widget.onNavigate(4),
                ),
                _SummaryCard(
                  icon: Icons.history_outlined,
                  title: 'Program Geçmişi',
                  value: '${_data!.runCount}',
                  subtitle: 'Oluşturulan tüm sürümler',
                  color: Colors.deepPurple,
                  onTap: () => widget.onNavigate(6),
                ),
                _SummaryCard(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Program Oluştur',
                  value: 'Hazır',
                  subtitle: 'Solver ve PDF akışı',
                  color: DutyPlannerColors.success,
                  onTap: () => widget.onNavigate(5),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: DutyPlannerColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
