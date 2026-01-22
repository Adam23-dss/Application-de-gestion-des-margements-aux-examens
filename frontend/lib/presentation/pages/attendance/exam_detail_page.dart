// lib/presentation/pages/attendance/exam_detail_page.dart
import 'package:flutter/material.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/presentation/pages/admin/add_student_to_exam_page.dart';
import 'package:frontend1/presentation/pages/attendance/advanced_validation_page.dart';
import 'package:frontend1/presentation/pages/attendance/qr_scanner_page.dart';
import 'package:frontend1/presentation/widgets/export_dialog.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/pages/attendance/manual_validation_page.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:intl/intl.dart';

class ExamDetailPage extends StatefulWidget {
  final int examId;
  final bool isAdmin;

  const ExamDetailPage({super.key, required this.examId, required this.isAdmin});

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final attendanceProvider = context.read<AttendanceProvider>();
    await attendanceProvider.loadExamAttendance(widget.examId);
  }

  Future<void> _showExportDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ExportDialog(
        title: 'Exporter les présences',
        description:
            'Sélectionnez le format d\'exportation pour la liste des présences de cet examen.',
        examId: widget.examId,
        isStudentExport: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

    // Trouver l'examen
    final exam = examProvider.exams.firstWhere(
      (e) => e.id == widget.examId,
      orElse: () => ExamModel(
        id: 0,
        name: 'Examen non trouvé',
        examDate: DateTime.now(),
        startTime: '00:00',
        endTime: '00:00',
        status: 'scheduled',
        totalStudents: 0,
      ),
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails Examen',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
            tooltip: 'Actualiser',
          ),
          // Dans ExamDetailPage, ajouter dans actions app bar
          if(widget.isAdmin) IconButton(
            icon: Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddStudentToExamPage(examId: exam.id),
                ),
              );
            },
            tooltip: 'Ajouter des étudiants',
          ),
        ],
      ),

      body: Column(
        children: [
          // En-tête de l'examen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.9),
                  AppColors.textSecondary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      exam.formattedDate,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      exam.formattedTime,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                if (exam.courseName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.school, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        exam.courseName!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],

                if (exam.roomName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        exam.roomName!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Statistiques
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Étudiants',
                  exam.totalStudents.toString(),
                  Colors.blue,
                ),
                _buildStatItem(
                  'Présents',
                  attendanceProvider.presentCount.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  'Taux',
                  '${exam.totalStudents > 0 ? (attendanceProvider.presentCount / exam.totalStudents * 100).toStringAsFixed(1) : '0'}%',
                  AppColors.primary,
                ),
              ],
            ),
          ),

          // Liste des présences
          Expanded(
            child: attendanceProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendanceProvider.attendanceRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune présence enregistrée',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        if(widget.isAdmin == false) ElevatedButton(
                          onPressed: () {
                            _showValidationOptions(context, exam);
                          },
                          child: const Text('Valider une présence'),
                        ),
                        
                          const SizedBox(height: 8),
                          if(widget.isAdmin) ElevatedButton(                            
                            onPressed: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdvancedValidationPage(examId: exam.id),
                                ),
                              );
                            }, 
                            child: const Text('Validation avancée'),
                          ),
                        ]
                        // Dans ExamDetailPage, ajouter dans actions
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        attendanceProvider.loadExamAttendance(widget.examId),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: attendanceProvider.attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final attendance =
                            attendanceProvider.attendanceRecords[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: attendance.statusColor
                                  .withOpacity(0.1),
                              child: Icon(
                                attendance.statusIcon,
                                color: attendance.statusColor,
                              ),
                            ),
                            title: Text(
                              attendance.studentName ?? 'Étudiant inconnu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(attendance.studentCode ?? ''),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: attendance.statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                attendance.statusLabel,
                                style: TextStyle(
                                  color: attendance.statusColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),

      // Bouton d'action
      floatingActionButton: exam.isActive
          ? FloatingActionButton.extended(
              onPressed: () {
                _showValidationOptions(context, exam);
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Valider présence'),
            )
          : null,
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _showValidationOptions(BuildContext context, ExamModel exam) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Valider une présence',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildOptionCard(
                context,
                Icons.qr_code_scanner,
                'Scanner QR Code',
                'Scanner le QR code étudiant',
                Colors.blue,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRScannerPage(examId: exam.id),
                    ),
                  );
                },
              ),

              _buildOptionCard(
                context,
                Icons.keyboard,
                'Saisie manuelle',
                'Entrer le code étudiant',
                Colors.green,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ManualValidationPage(examId: exam.id),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Annuler'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
