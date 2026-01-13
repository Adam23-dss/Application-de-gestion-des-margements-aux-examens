// lib/presentation/pages/attendance/qr_scanner_page.dart - API CORRECTE
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/pages/attendance/manual_validation_page.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/core/services/permission_service.dart';
import 'package:vibration/vibration.dart';

class QRScannerPage extends StatefulWidget {
  final int? examId;
  
  const QRScannerPage({super.key, this.examId});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250,
    returnImage: false,
  );
  
  bool _isScanning = true;
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isFlashOn = false;
  CameraFacing _cameraFacing = CameraFacing.back;
  String _lastScannedCode = '';
  DateTime? _lastScanTime;
  List<String> _recentScans = [];
  
  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }
  
  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeScanner() async {
    final hasPermission = await PermissionService.checkAndRequestCameraPermission();
    
    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });
    
    if (!hasPermission) {
      _showPermissionDeniedDialog();
    }
  }
  
  void _handleBarcode(BarcodeCapture barcodeCapture) {
    if (!_isScanning || !_hasPermission) return;
    
    final barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    final code = barcode.rawValue;
    
    if (code == null || code.isEmpty) return;
    
    // Anti-rebond
    final now = DateTime.now();
    if (_lastScanTime != null && 
        now.difference(_lastScanTime!) < const Duration(milliseconds: 500) &&
        code == _lastScannedCode) {
      return;
    }
    
    _lastScanTime = now;
    _lastScannedCode = code;
    
    if (_recentScans.length >= 10) {
      _recentScans.removeAt(0);
    }
    _recentScans.add(code);
    
    _processScannedCode(code);
  }
  
  Future<void> _processScannedCode(String code) async {
    setState(() {
      _isScanning = false;
    });
    
    // Vibration
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
    
    final attendanceProvider = context.read<AttendanceProvider>();
    final examProvider = context.read<ExamProvider>();
    
    int examId = widget.examId ?? 0;
    if (examId == 0 && examProvider.inProgressExams.isNotEmpty) {
      examId = examProvider.inProgressExams.first.id;
    }
    
    if (examId == 0) {
      _showMessage('Aucun examen en cours', isError: true);
      _resumeScanner();
      return;
    }
    
    try {
      await attendanceProvider.validateAttendance(
        examId: examId,
        studentCode: code,
        status: 'present',
        validationMethod: 'qr_code',
      );
      
      _showSuccessDialog(code);
      
      Future.delayed(const Duration(seconds: 2), () {
        _resumeScanner();
      });
      
    } catch (e) {
      _showMessage('Erreur: $e', isError: true);
      _resumeScanner();
    }
  }
  
  void _resumeScanner() {
    if (mounted) {
      setState(() {
        _isScanning = true;
      });
    }
  }
  
  void _showSuccessDialog(String studentCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
        
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PRÉSENCE VALIDÉE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    studentCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permission requise'),
          content: const Text(
            'L\'application a besoin d\'accéder à la caméra pour scanner les QR codes des étudiants.\n\n'
            'Veuillez autoriser l\'accès à la caméra dans les paramètres de votre appareil.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                //openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Paramètres'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    
    final currentExam = _getCurrentExam(examProvider);

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (!_hasPermission) {
      return _buildPermissionDeniedScreen();
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scanner QR Code',
        showBackButton: true,
        actions: _buildAppBarActions(),
      ),
      
      body: Column(
        children: [
          // En-tête de l'examen
          if (currentExam != null) _buildExamHeader(currentExam, examProvider),
          
          // Scanner QR
          Expanded(
            child: Stack(
              children: [
                // Vue du scanner
                MobileScanner(
                  controller: cameraController,
                  onDetect: _handleBarcode,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error) {
                    return _buildScannerError(error);
                  },
                ),
                
                // Overlay de scan
                _buildScannerOverlay(),
                
                // Instructions
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Scanner le QR Code',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Positionnez le code dans le cadre',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Messages d'état
          if (attendanceProvider.error != null) _buildErrorContainer(attendanceProvider),
          
          // Contrôles
          _buildControls(currentExam),
        ],
      ),
    );
  }
  
  // === MÉTHODES HELPER ===
  
  ExamModel? _getCurrentExam(ExamProvider examProvider) {
    if (widget.examId != null) {
      return examProvider.exams.firstWhere(
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
      );
    } else if (examProvider.inProgressExams.isNotEmpty) {
      return examProvider.inProgressExams.first;
    }
    return null;
  }
  
  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scanner QR Code',
        showBackButton: true,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scanner QR Code',
        showBackButton: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Accès à la caméra requis',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Pour scanner les QR codes des étudiants, l\'application a besoin d\'accéder à votre caméra.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _initializeScanner,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Demander la permission'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildAppBarActions() {
    return [
      // Contrôle du flash
      IconButton(
        icon: Icon(
          _isFlashOn ? Icons.flash_on : Icons.flash_off,
          color: _isFlashOn ? Colors.yellow : Colors.white,
        ),
        onPressed: () {
          setState(() {
            _isFlashOn = !_isFlashOn;
          });
          // Mettre à jour le flash dans le contrôleur
          // Note: L'API actuelle peut nécessiter une approche différente
          // Pour l'instant, on gère juste l'état visuel
        },
        tooltip: _isFlashOn ? 'Flash ON' : 'Flash OFF',
      ),
      
      // Changement de caméra
      IconButton(
        icon: Icon(
          _cameraFacing == CameraFacing.front 
              ? Icons.camera_front 
              : Icons.camera_rear,
        ),
        onPressed: () {
          setState(() {
            _cameraFacing = _cameraFacing == CameraFacing.front
                ? CameraFacing.back
                : CameraFacing.front;
          });
          // Note: Dans certaines versions, switchCamera() n'a pas de paramètre
          cameraController.switchCamera();
        },
        tooltip: _cameraFacing == CameraFacing.front 
            ? 'Caméra avant' 
            : 'Caméra arrière',
      ),
    ];
  }
  
  Widget _buildExamHeader(ExamModel currentExam, ExamProvider examProvider) {
    return Container(
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
    );
  }
  
  Widget _buildScannerError(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur caméra: ${error.toString()}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeScanner,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScannerOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ScannerOverlayPainter(),
        child: Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isScanning
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 40,
                          color: Colors.white70,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'En attente...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorContainer(AttendanceProvider attendanceProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.red.withOpacity(0.9),
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
    );
  }

  Widget _buildControls(ExamModel? currentExam) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.extended(
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
            foregroundColor: Colors.black,
            icon: const Icon(Icons.keyboard),
            label: const Text('Manuel'),
            heroTag: 'manual_btn',
          ),
          
          const SizedBox(width: 20),
          
          FloatingActionButton.extended(
            onPressed: _resumeScanner,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner'),
            heroTag: 'scan_btn',
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
                'Sélectionner un examen',
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

// Custom painter pour l'overlay du scanner
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final scannerRect = Rect.fromCenter(
      center: center,
      width: 250,
      height: 250,
    );
    
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(scannerRect, const Radius.circular(12)),
      )
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, paint);
    
    final framePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(scannerRect, const Radius.circular(12)),
      framePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}