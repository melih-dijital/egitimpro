import 'package:flutter/material.dart';

import '../../theme/duty_planner_theme.dart';

class ScheduleModuleHomePage extends StatelessWidget {
  const ScheduleModuleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Programı Modülü'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: DutyPlannerTheme.screenPadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DutyPlannerTheme.maxContentWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            size: 32,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ders Programı Yönetimi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Öğretmen, sınıf, ders ve eşleştirme verilerini yönetin; ardından program oluşturup geçmiş ve PDF çıktıları üzerinden süreci takip edin.',
                          style: TextStyle(
                            color: DutyPlannerColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 2.3 : 2.7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ModuleEntryCard(
                      icon: Icons.people_outline,
                      title: 'Öğretmenler',
                      subtitle: 'Öğretmen listesi, müsaitlik ve saat sınırları',
                      color: DutyPlannerColors.primary,
                      onTap: () => _openRoute(context, '/schedule-module/teachers'),
                    ),
                    _ModuleEntryCard(
                      icon: Icons.meeting_room_outlined,
                      title: 'Sınıflar',
                      subtitle: 'Program üretilecek sınıf kayıtları',
                      color: Colors.teal,
                      onTap: () => _openRoute(context, '/schedule-module/classrooms'),
                    ),
                    _ModuleEntryCard(
                      icon: Icons.book_outlined,
                      title: 'Dersler',
                      subtitle: 'Sınıf bazlı ders ve haftalık saat tanımları',
                      color: Colors.indigo,
                      onTap: () => _openRoute(context, '/schedule-module/courses'),
                    ),
                    _ModuleEntryCard(
                      icon: Icons.link_outlined,
                      title: 'Öğretmen-Ders Eşleştirme',
                      subtitle: 'Ders atama ilişkilerini tanımlayın',
                      color: Colors.orange,
                      onTap: () => _openRoute(context, '/schedule-module/mappings'),
                    ),
                    _ModuleEntryCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Program Oluştur',
                      subtitle: 'Solver çalıştırıp yeni program üretin',
                      color: DutyPlannerColors.success,
                      onTap: () => _openRoute(context, '/schedule-module/runs'),
                    ),
                    _ModuleEntryCard(
                      icon: Icons.history_outlined,
                      title: 'Program Geçmişi',
                      subtitle: 'Önceki run kayıtlarını görüntüleyin',
                      color: Colors.deepPurple,
                      onTap: () => _openRoute(context, '/schedule-module/history'),
                    ),
                    _ModuleEntryCard(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'PDF Listesi',
                      subtitle: 'Oluşturulan PDF dosyalarına erişin',
                      color: Colors.redAccent,
                      onTap: () => _openRoute(context, '/schedule-module/pdfs'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRoute(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }
}

class _ModuleEntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: DutyPlannerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
