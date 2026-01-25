// lib/presentation/pages/qr/generate_qr_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:frontend1/presentation/providers/qr_code_provider.dart';
import 'package:frontend1/presentation/providers/student_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'dart:ui' as ui;

class GenerateQRPage extends StatefulWidget {
  final int? examId;
  final String? studentId;

  const GenerateQRPage({super.key, this.examId, this.studentId});

  @override
  State<GenerateQRPage> createState() => _GenerateQRPageState();
}

class _GenerateQRPageState extends State<GenerateQRPage> {
  int? _selectedExamId;
  int? _selectedStudentId;
  final TextEditingController _studentSearchController =
      TextEditingController();
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _selectedExamId = widget.examId;
    _selectedStudentId = widget.studentId != null
        ? int.tryParse(widget.studentId!)
        : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final examProvider = context.read<ExamProvider>();
    final studentProvider = context.read<StudentProvider>();

    examProvider.loadExams();
    studentProvider.loadStudents();
  }

  Future<void> _generateQRCode() async {
    if (_selectedExamId == null || _selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un examen et un étudiant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final qrProvider = context.read<QRCodeProvider>();
    await qrProvider.generateQRCodeForStudent(
      examId: _selectedExamId!,
      studentId: _selectedStudentId!,
    );
  }

  Future<void> _generateBulkQRCodes() async {
    if (_selectedExamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un examen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final examProvider = context.read<ExamProvider>();
    final studentProvider = context.read<StudentProvider>();

    final exam = examProvider.exams.firstWhere(
      (e) => e.id == _selectedExamId,
      orElse: () => throw Exception('Examen non trouvé'),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générer les QR codes'),
        content: Text(
          'Générer les QR codes pour tous les ${exam.totalStudents} étudiants '
          'inscrits à l\'examen "${exam.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Générer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final registeredStudents = await examProvider.getExamStudents(
        _selectedExamId!,
      );
      final studentIds = registeredStudents.map((s) => s.id).toList();

      final qrProvider = context.read<QRCodeProvider>();
      await qrProvider.generateBulkQRCodes(
        examId: _selectedExamId!,
        studentIds: studentIds,
      );
    }
  }

  Future<void> _shareQRCode() async {
    final qrProvider = context.read<QRCodeProvider>();
    if (qrProvider.generatedQRCode == null) return;

    try {
      final boundary = await _captureQrImage();
      if (boundary == null) return;

      // TODO: Implémenter le partage avec share_plus
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité de partage à implémenter'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<Uint8List?> _captureQrImage() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing QR image: $e');
      return null;
    }
  }

  Widget _buildExamSelector() {
    final examProvider = context.watch<ExamProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionner un examen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            if (examProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (examProvider.exams.isEmpty)
              const Text('Aucun examen disponible')
            else
              DropdownButtonFormField<int>(
                value: _selectedExamId,
                decoration: const InputDecoration(
                  labelText: 'Examen',
                  border: OutlineInputBorder(),
                ),
                items: examProvider.exams.map((exam) {
                  return DropdownMenuItem<int>(
                    value: exam.id,
                    child: Text(
                      '${exam.name} (${exam.startTime} - ${exam.endTime})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExamId = value;
                    _selectedStudentId =
                        null; // Réinitialiser la sélection d'étudiant
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelector() {
    final studentProvider = context.watch<StudentProvider>();
    final examProvider = context.watch<ExamProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionner un étudiant',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _studentSearchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un étudiant',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _studentSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _studentSearchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),

            const SizedBox(height: 16),

            if (studentProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (studentProvider.students.isEmpty)
              const Text('Aucun étudiant disponible')
            else
              SizedBox(
                height: 200,
                child: FutureBuilder<List<StudentModel>>(
                  future: _selectedExamId != null
                      ? examProvider.getExamStudents(_selectedExamId!)
                      : Future.value(studentProvider.students),
                  builder: (context, snapshot) {
                    final students = snapshot.data ?? studentProvider.students;

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final isSelected = _selectedStudentId == student.id;

                        // Filtrer par recherche
                        if (_studentSearchController.text.isNotEmpty &&
                            !student.fullName.toLowerCase().contains(
                              _studentSearchController.text.toLowerCase(),
                            ) &&
                            !student.studentCode.toLowerCase().contains(
                              _studentSearchController.text.toLowerCase(),
                            )) {
                          return const SizedBox.shrink();
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              student.firstName.substring(0, 1),
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                          title: Text(student.fullName),
                          subtitle: Text(student.studentCode),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withOpacity(0.1),
                          onTap: () {
                            setState(() {
                              _selectedStudentId = student.id;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedQRCode() {
  final qrProvider = context.watch<QRCodeProvider>();

  if (qrProvider.isGenerating) {
    return const Center(child: CircularProgressIndicator());
  }

  if (qrProvider.error != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Erreur: ${qrProvider.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateQRCode,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  if (qrProvider.generatedQRCode == null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucun QR code généré',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionnez un examen et un étudiant',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  return _QRCodeWithTimer(qrProvider: qrProvider);
}

  Widget _buildBulkQRGeneration() {
    final qrProvider = context.watch<QRCodeProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Génération en masse',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Générer les QR codes pour tous les étudiants d\'un examen',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),

            if (qrProvider.bulkQRCodes != null)
              Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    '${qrProvider.bulkQRCodes!.length} QR codes générés',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les QR codes ont été générés avec succès',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Exporter tous les QR codes
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Export des QR codes à implémenter'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    child: const Text('Exporter tous les QR codes'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _generateBulkQRCodes,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Générer les QR codes en masse'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Générer QR Code', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildExamSelector(),
            const SizedBox(height: 16),
            _buildStudentSelector(),
            const SizedBox(height: 24),

            // Bouton générer
            ElevatedButton.icon(
              onPressed: _generateQRCode,
              icon: const Icon(Icons.qr_code),
              label: const Text('Générer QR Code'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 24),

            // QR Code généré
            _buildGeneratedQRCode(),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Génération en masse
            _buildBulkQRGeneration(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
// NOUVEAU WIDGET AVEC TIMER DYNAMIQUE
class _QRCodeWithTimer extends StatefulWidget {
  final QRCodeProvider qrProvider;
  
  const _QRCodeWithTimer({required this.qrProvider});
  
  @override
  State<_QRCodeWithTimer> createState() => _QRCodeWithTimerState();
}

class _QRCodeWithTimerState extends State<_QRCodeWithTimer> {
  late DateTime expiresAt;
  late Timer _timer;
  final GlobalKey _qrKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    final qrResponse = widget.qrProvider.generatedQRCode!;
    
    // Parse la date d'expiration depuis le QR code
    expiresAt = DateTime.parse(qrResponse.qrData.expiresAt as String);
    
    // Timer qui se met à jour toutes les secondes
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  Future<Uint8List?> _captureQrImage() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing QR image: $e');
      return null;
    }
  }
  
  Future<void> _shareQRCode() async {
    final qrProvider = widget.qrProvider;
    if (qrProvider.generatedQRCode == null) return;

    try {
      final boundary = await _captureQrImage();
      if (boundary == null) return;

      // TODO: Implémenter le partage avec share_plus
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité de partage à implémenter'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final qrResponse = widget.qrProvider.generatedQRCode!;
    final now = DateTime.now();
    final timeUntilExpiry = expiresAt.difference(now);
    
    // Si le QR code est expiré, arrêter le timer
    if (timeUntilExpiry.inSeconds <= 0 && _timer.isActive) {
      _timer.cancel();
    }
    
    return Column(
      children: [
        // QR Code avec capture
        RepaintBoundary(
          key: _qrKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  QrImageView(
                    data: qrResponse.qrString,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Code étudiant: ${qrResponse.student.code}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(qrResponse.student.name),
                  Text(
                    'Examen: ${qrResponse.exam.name}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Généré le: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(qrResponse.qrData.generatedAt as String))}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  
                  // TIMER DYNAMIQUE
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: timeUntilExpiry.inSeconds > 0 
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: timeUntilExpiry.inSeconds > 0 
                            ? Colors.orange 
                            : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeUntilExpiry.inSeconds > 0
                            ? 'Expire dans ${timeUntilExpiry.inMinutes}m ${(timeUntilExpiry.inSeconds % 60).toString().padLeft(2, '0')}s'
                            : 'QR CODE EXPIRÉ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: timeUntilExpiry.inSeconds > 0 
                              ? Colors.orange 
                              : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: timeUntilExpiry.inSeconds > 0 ? _shareQRCode : null,
              icon: const Icon(Icons.share),
              label: const Text('Partager'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implémenter le téléchargement
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Fonctionnalité de téléchargement à implémenter',
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Télécharger'),
              style: ElevatedButton.styleFrom(
                backgroundColor: timeUntilExpiry.inSeconds > 0 
                  ? Colors.green 
                  : Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Générer un nouveau
        OutlinedButton(
          onPressed: () {
            widget.qrProvider.clearGeneratedQR();
          },
          child: const Text('Générer un nouveau QR code'),
        ),
      ],
    );
  }
}