import 'package:flutter/material.dart';

import '../../models/schedule_builder_models.dart';
import '../../services/schedule_classroom_service.dart';
import '../../services/schedule_course_service.dart';
import '../../services/school_context_service.dart';
import '../../services/schedule_builder_service.dart';
import '../../services/schedule_module_api_client.dart';
import '../../services/schedule_pdf_service.dart';
import '../../services/schedule_run_service.dart';
import '../../services/schedule_teacher_course_service.dart';
import '../../services/schedule_teacher_service.dart';
import 'classroom_list_page.dart';
import 'course_list_page.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'schedule_pdf_page.dart';
import 'schedule_run_page.dart';
import 'shared.dart';
import 'teacher_list_page.dart';
import 'teacher_course_mapping_page.dart';

class ScheduleBuilderHomeScreen extends StatefulWidget {
  final int initialTab;

  const ScheduleBuilderHomeScreen({super.key, this.initialTab = 0});

  @override
  State<ScheduleBuilderHomeScreen> createState() =>
      _ScheduleBuilderHomeScreenState();
}

class _ScheduleBuilderHomeScreenState extends State<ScheduleBuilderHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final SchoolContextService _schoolContextService = SchoolContextService();

  SchoolContext? _schoolContext;
  ScheduleModuleApiClient? _apiClient;
  ScheduleBuilderService? _service;
  ScheduleTeacherService? _teacherService;
  ScheduleClassroomService? _classroomService;
  ScheduleCourseService? _courseService;
  ScheduleTeacherCourseService? _teacherCourseService;
  ScheduleRunService? _scheduleRunService;
  SchedulePdfService? _schedulePdfService;
  bool _isLoading = true;
  String? _error;
  int? _pdfRunSelection;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _tabController.index = widget.initialTab.clamp(0, 7);
    _loadContext();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final context = await _schoolContextService.getCurrentSchoolContext();
      if (!mounted) return;
      final apiClient = ScheduleModuleApiClient(schoolContext: context);
      setState(() {
        _schoolContext = context;
        _apiClient = apiClient;
        _service = ScheduleBuilderService(
          schoolContext: context,
          apiClient: apiClient,
        );
        _teacherService = ScheduleTeacherService(apiClient: apiClient);
        _classroomService = ScheduleClassroomService(apiClient: apiClient);
        _courseService = ScheduleCourseService(apiClient: apiClient);
        _teacherCourseService = ScheduleTeacherCourseService(apiClient: apiClient);
        _scheduleRunService = ScheduleRunService(apiClient: apiClient);
        _schedulePdfService = SchedulePdfService(apiClient: apiClient);
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

  void _goToTab(int index, {int? pdfRunId}) {
    if (pdfRunId != null) {
      setState(() => _pdfRunSelection = pdfRunId);
    }
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ders Programı Oluşturucu')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_service == null ||
        _schoolContext == null ||
        _teacherService == null ||
        _classroomService == null ||
        _courseService == null ||
        _teacherCourseService == null ||
        _scheduleRunService == null ||
        _schedulePdfService == null ||
        _apiClient == null ||
        _error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ders Programı Oluşturucu')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ScheduleErrorCard(
                message: _error ?? 'Modül başlatılamadı.',
                onRetry: _loadContext,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Programı Oluşturucu'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            onPressed: _loadContext,
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Ana Sayfa'),
            Tab(icon: Icon(Icons.people_outline), text: 'Öğretmenler'),
            Tab(icon: Icon(Icons.meeting_room_outlined), text: 'Sınıflar'),
            Tab(icon: Icon(Icons.book_outlined), text: 'Dersler'),
            Tab(icon: Icon(Icons.link_outlined), text: 'Eşleştirme'),
            Tab(icon: Icon(Icons.auto_awesome_outlined), text: 'Program Oluştur'),
            Tab(icon: Icon(Icons.history_outlined), text: 'Geçmiş'),
            Tab(icon: Icon(Icons.picture_as_pdf_outlined), text: 'PDF Listesi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ScheduleDashboardScreen(
            service: _service!,
            schoolContext: _schoolContext!,
            onNavigate: (tabIndex) => _goToTab(tabIndex),
          ),
          TeacherListPage(teacherService: _teacherService!),
          ClassroomListPage(classroomService: _classroomService!),
          CourseListPage(
            courseService: _courseService!,
            classroomService: _classroomService!,
          ),
          TeacherCourseMappingPage(
            teacherCourseService: _teacherCourseService!,
            teacherService: _teacherService!,
            courseService: _courseService!,
          ),
          ScheduleRunPage(scheduleRunService: _scheduleRunService!),
          ScheduleHistoryScreen(
            service: _service!,
            schoolContext: _schoolContext!,
            onNavigateToPdfs: (runId) => _goToTab(7, pdfRunId: runId),
          ),
          SchedulePdfPage(
            pdfService: _schedulePdfService!,
            scheduleRunService: _scheduleRunService!,
            initialRunId: _pdfRunSelection,
          ),
        ],
      ),
    );
  }
}
