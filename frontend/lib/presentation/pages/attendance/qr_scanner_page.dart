// lib/presentation/pages/attendance/qr_scanner_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/pages/attendance/manual_validation_page.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class QRScannerPage extends StatefulWidget {
  final int? examId;
  
  const QRScannerPage({super.key, this.examId});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isFlashOn = false;
  bool _isScanning = true;
  String _scannedCode = '';
  bool _showValidationResult = false;
  bool _validationSuccess = false;
  String _validationMessage = '';
  
  // Simulation de scan (à remplacer par vrai scanner plus tard)
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    _scanTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isScanning && !_showValidationResult) {
        _simulateQRScan();
      }
    });
  }

  void _simulateQRScan() {
    // Codes de test
    final testCodes = ['ETU001', 'ETU002', 'ETU003', 'ETU004'];
    final randomCode = testCodes[DateTime.now().second % testCodes.length];
    
    setState(() {
      _scannedCode = randomCode;
      _isScanning = false;
    });
    
    _processScannedCode(randomCode);
  }

  Future<void> _processScannedCode(String code) async {
    final attendanceProvider = context.read<AttendanceProvider>();
    final examProvider = context.read<ExamProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // Chercher un examen en cours si aucun n'est spécifié
    int examId = widget.examId ?? 0;
    if (examId == 0 && examProvider.inProgressExams.isNotEmpty) {
      examId = examProvider.inProgressExams.first.id;
    }
    
    if (examId == 0) {
      setState(() {
        _showValidationResult = true;
        _validationSuccess = false;
        _validationMessage = 'Aucun examen en cours';
      });
      return;
    }
    
    try {
      await attendanceProvider.validateAttendance(
        examId: examId,
        studentCode: code,
        status: 'present',
        validationMethod: 'qr_code',
      );
      
      setState(() {
        _showValidationResult = true;
        _validationSuccess = true;
        _validationMessage = 'Présence validée pour $code';
      });
      
      // Auto-reset après 3 secondes
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showValidationResult = false;
            _isScanning = true;
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _showValidationResult = true;
        _validationSuccess = false;
        _validationMessage = 'Erreur: $e';
      });
      
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showValidationResult = false;
            _isScanning = true;
          });
        }
      });
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _showValidationResult = false;
      _scannedCode = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    
    // Trouver l'examen actuel
    final currentExam = widget.examId != null 
        ? examProvider.exams.firstWhere(
            (exam) => exam.id == widget.examId,
            orElse: () => examProvider.exams.isNotEmpty 
                ? examProvider.exams.first 
                : ExamModel(
                    id: 0,
                    name: 'Aucun examen',
                    examDate: DateTime.now(),
                    startTime: '00:00',
                    endTime: '00:00',
                    status: 'scheduled',
                    totalStudents: 0,
                  ),
          )
        : examProvider.inProgressExams.isNotEmpty
            ? examProvider.inProgressExams.first
            : null;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scanner QR Code',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
        ],
      ),
      
      body: Stack(
        children: [
          // Vue de scan
          Column(
            children: [
              // Informations sur l'examen
              if (currentExam != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentExam.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currentExam.formattedDate} • ${currentExam.startTime}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (examProvider.exams.length > 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: () {
                            _showExamSelector(examProvider);
                          },
                        ),
                    ],
                  ),
                ),
              
              // Zone de scan
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cadre de scan
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isScanning
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    size: 80,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'En attente du scan...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 60,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _scannedCode,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Instructions
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Positionnez le QR code de l\'étudiant dans le cadre',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Contrôles
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManualValidationPage(
                              examId: currentExam?.id ?? 0,
                            ),
                          ),
                        );
                      },
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.keyboard,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 20),
                    FloatingActionButton(
                      onPressed: _resetScanner,
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Résultat de validation
          if (_showValidationResult)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _validationSuccess ? Icons.check_circle : Icons.error,
                            size: 64,
                            color: _validationSuccess ? Colors.green : Colors.red,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _validationMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _validationSuccess ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _resetScanner,
                            child: const Text('Scanner à nouveau'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Messages du provider
          if (attendanceProvider.error != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attendanceProvider.error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: attendanceProvider.clearError,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showExamSelector(ExamProvider examProvider) {
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
                'Changer d\'examen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (examProvider.inProgressExams.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aucun examen en cours',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...examProvider.inProgressExams.map((exam) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Colors.blue),
                      title: Text(exam.name),
                      subtitle: Text('${exam.formattedDate} • ${exam.startTime}'),
                      trailing: widget.examId == exam.id
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRScannerPage(examId: exam.id),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              
              const SizedBox(height: 20),
              
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }
}