import 'package:flutter/material.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/presentation/pages/auth/login_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/widgets/exam_card.dart';
import 'package:frontend1/presentation/pages/attendance/exam_detail_page.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExams();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadExams({bool loadMore = false}) async {
    final examProvider = context.read<ExamProvider>();
    
    if (!loadMore) {
      _currentPage = 1;
      _hasMore = true;
    }
    
    if (_isLoadingMore) return;
    
    try {
      if (!loadMore) {
        await examProvider.loadExams();
      } else {
        setState(() {
          _isLoadingMore = true;
        });
        
        // Exemple de chargement paginé (à adapter selon votre API)
        // final response = await _repository.getExams(page: _currentPage, limit: _itemsPerPage);
        
        setState(() {
          _isLoadingMore = false;
          _currentPage++;
          
          // Vérifier s'il y a encore des données
          if (examProvider.exams.length < _itemsPerPage) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      print('Error loading exams: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final examProvider = context.watch<ExamProvider>();
    
    // Si pas connecté, retourner au login
    if (authProvider.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mes Examens',
        showBackButton: false,
        showLogout: true, // Active le bouton de déconnexion dans l'app bar
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadExams(),
            tooltip: 'Actualiser',
          ),
          // Le bouton de déconnexion est maintenant géré par CustomAppBar
        ],
      ),
      body: Column(
        children: [
          // Header utilisateur
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.textSecondary.withOpacity(0.9),
                ],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    authProvider.user?.firstName.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${authProvider.user?.firstName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        authProvider.user?.isAdmin == true ? 'Administrateur' : 'Surveillant d\'examens',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${examProvider.activeExams.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.today), text: 'Aujourd\'hui'),
                Tab(icon: Icon(Icons.upcoming), text: 'À venir'),
                Tab(icon: Icon(Icons.play_circle_filled), text: 'En cours'),
                Tab(icon: Icon(Icons.done_all), text: 'Terminés'),
              ],
            ),
          ),
          
          // Contenu
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExamList('Aujourd\'hui', examProvider.todayExams, examProvider),
                _buildExamList('À venir', examProvider.upcomingExams, examProvider),
                _buildExamList('En cours', examProvider.inProgressExams, examProvider),
                _buildExamList('Terminés', examProvider.completedExams, examProvider),
              ],
            ),
          ),
        ],
      ),
      
      // Floating Action Button pour scan QR
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showScanOptions(context);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner QR'),
        elevation: 4,
      ),
      
      // Menu de navigation dans le drawer
      drawer: _buildDrawer(context, authProvider),
    );
  }
  
  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    authProvider.user?.firstName.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.user?.fullName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blue),
            title: const Text('Tableau de bord'),
            onTap: () {
              Navigator.pop(context);
              // Pour le surveillant, on reste sur cette page
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner, color: Colors.green),
            title: const Text('Scanner QR Code'),
            onTap: () {
              Navigator.pop(context);
              _openQRScanner();
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.purple),
            title: const Text('Gérer les étudiants'),
            onTap: () {
              Navigator.pop(context);
              // Naviguer vers la gestion des étudiants
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              // Naviguer vers les paramètres
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.grey),
            title: const Text('Aide & Support'),
            onTap: () {
              Navigator.pop(context);
              // Naviguer vers l'aide
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildExamList(String title, List<ExamModel> exams, ExamProvider examProvider) {
    if (examProvider.isLoading && exams.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (examProvider.error != null && exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                examProvider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadExams(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(title),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(title),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubtitle(title),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => _loadExams(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exams.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == exams.length) {
            // Bouton "Charger plus"
            return _isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () => _loadExams(loadMore: true),
                        child: const Text('Charger plus d\'examens'),
                      ),
                    ),
                  );
          }
          
          final exam = exams[index];
          return ExamCard(
            exam: exam,
            onTap: () {
              _openExamDetails(exam);
            },
            onStart: exam.status == 'scheduled'
                ? () => _startExam(exam)
                : null,
            onEnd: exam.status == 'in_progress'
                ? () => _endExam(exam)
                : null,
          );
        },
      ),
    );
  }
  
  IconData _getEmptyIcon(String title) {
    switch (title) {
      case 'Aujourd\'hui':
        return Icons.event_busy;
      case 'À venir':
        return Icons.schedule;
      case 'En cours':
        return Icons.play_circle_filled;
      case 'Terminés':
        return Icons.history;
      default:
        return Icons.event_note;
    }
  }
  
  String _getEmptyMessage(String title) {
    switch (title) {
      case 'Aujourd\'hui':
        return 'Aucun examen aujourd\'hui';
      case 'À venir':
        return 'Aucun examen à venir';
      case 'En cours':
        return 'Aucun examen en cours';
      case 'Terminés':
        return 'Aucun examen terminé';
      default:
        return 'Aucun examen';
    }
  }
  
  String _getEmptySubtitle(String title) {
    switch (title) {
      case 'Aujourd\'hui':
        return 'Profitez de votre journée !';
      case 'À venir':
        return 'Les examens à venir apparaîtront ici';
      case 'En cours':
        return 'Commencez un examen pour qu\'il apparaisse ici';
      case 'Terminés':
        return 'Les examens terminés seront archivés ici';
      default:
        return '';
    }
  }
  
  void _openExamDetails(ExamModel exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamDetailPage(examId: exam.id),
      ),
    );
  }
  
  Future<void> _startExam(ExamModel exam) async {
    final examProvider = context.read<ExamProvider>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Démarrer l\'examen'),
        content: Text('Voulez-vous démarrer l\'examen "${exam.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await examProvider.startExam(exam.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Examen "${exam.name}" démarré'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _endExam(ExamModel exam) async {
    final examProvider = context.read<ExamProvider>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer l\'examen'),
        content: Text('Voulez-vous terminer l\'examen "${exam.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await examProvider.endExam(exam.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Examen "${exam.name}" terminé'),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showScanOptions(BuildContext context) {
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
                'Options de scan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildScanOption(
                context,
                Icons.qr_code_scanner,
                'Scanner QR Code',
                'Scanner le QR code d\'un étudiant',
                () {
                  Navigator.pop(context);
                  _openQRScanner();
                },
              ),
              
              _buildScanOption(
                context,
                Icons.nfc,
                'Scanner NFC',
                'Approcher la carte étudiante NFC',
                () {
                  Navigator.pop(context);
                  _openNFCScanner();
                },
              ),
              
              _buildScanOption(
                context,
                Icons.keyboard,
                'Saisie manuelle',
                'Entrer manuellement le code étudiant',
                () {
                  Navigator.pop(context);
                  _openManualInput();
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
  
  Widget _buildScanOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
  
  void _openQRScanner() {
    // Implémenter le scan QR code ici
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouvrir le scanner QR code...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implémenter la navigation vers le scanner QR
  }
  
  void _openNFCScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanner NFC - à implémenter'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _openManualInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouvrir la saisie manuelle...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implémenter la navigation vers la saisie manuelle
  }
}