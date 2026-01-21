import 'package:flutter/material.dart';
import 'package:frontend1/presentation/pages/admin/create_exam_page.dart';
import 'package:frontend1/presentation/pages/admin/create_user_page.dart';
import 'package:frontend1/presentation/pages/admin/export_students_page.dart';
import 'package:frontend1/presentation/pages/admin/manage_courses_page.dart';
import 'package:frontend1/presentation/pages/admin/manage_exams_page.dart';
import 'package:frontend1/presentation/pages/admin/manage_rooms_page.dart';
import 'package:frontend1/presentation/pages/admin/manage_students_page.dart';
import 'package:frontend1/presentation/pages/admin/manage_users_page.dart';
import 'package:frontend1/presentation/pages/attendance/scan_page.dart';
import 'package:frontend1/presentation/pages/auth/login_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/dashboard_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/widgets/stat_card.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final dashboardProvider = context.read<DashboardProvider>();
    final examProvider = context.read<ExamProvider>();

    dashboardProvider.loadDashboardStats();
    dashboardProvider.loadDailyStats();
    examProvider.loadExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Vérifier que l'utilisateur est admin
    if (authProvider.user?.isAdmin != true) {
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
        title: 'Tableau de Bord Admin',
        showBackButton: false,
        showLogout: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec informations
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    authProvider.user?.firstName
                            .substring(0, 1)
                            .toUpperCase() ??
                        'A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrateur',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.user?.fullName ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'EEEE dd MMMM yyyy',
                          'fr_FR',
                        ).format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                Tab(icon: Icon(Icons.dashboard), text: 'Vue Globale'),
                Tab(icon: Icon(Icons.today), text: 'Aujourd\'hui'),
                Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
              ],
            ),
          ),

          // Contenu des tabs - CORRECTION ICI
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Vue Globale - UTILISE LE PROVIDER EXISTANT
                const _GlobalView(),

                // Tab 2: Aujourd'hui - UTILISE LE PROVIDER EXISTANT
                const _TodayView(),

                // Tab 3: Statistiques
                const _StatisticsView(),
              ],
            ),
          ),
        ],
      ),

      // Menu latéral
      drawer: _buildDrawer(context, authProvider),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStat(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    authProvider.user?.firstName
                            .substring(0, 1)
                            .toUpperCase() ??
                        'A',
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
                  'Administrateur',
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
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Gestion',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.green),
            title: const Text('Utilisateurs'),
            onTap: () {
              // Naviguer vers la gestion des utilisateurs
              Navigator.pop(context); // Fermer drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageUsersPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.purple),
            title: const Text('Étudiants'),
            onTap: () {
              // Naviguer vers la gestion des étudiants
              Navigator.pop(context); // Fermer drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageStudentsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Examens'),
            onTap: () {
              Navigator.pop(context); // Fermer drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageExamsPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.green),
            title: const Text('Cours'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCoursesPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: const Text('Salles'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageRoomsPage(),
                ),
              );
              // Naviguer vers la gestion des salles
            },
          ),
          // Dans AdminDashboard ou Drawer
          ListTile(
            leading: Icon(Icons.qr_code_scanner),
            title: Text('Surveillance'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScanPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.teal),
            title: const Text('Rapports'),
            onTap: () {
              // Naviguer vers les rapports
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.blue),
            title: const Text('Exports'),
            onTap: () {
              // Naviguer vers les exports
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExportStudentsPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Paramètres'),
            onTap: () {
              // Naviguer vers les paramètres
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.grey),
            title: const Text('Aide'),
            onTap: () {
              // Naviguer vers l'aide
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion'),
            onTap: () {
              authProvider.logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// --- NOUVELLES CLASSES POUR CHAQUE TAB ---

// Tab 1: Vue Globale
class _GlobalView extends StatelessWidget {
  const _GlobalView();

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final examProvider = context.watch<ExamProvider>();

    if (dashboardProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = dashboardProvider.dashboardStats;

    return RefreshIndicator(
      onRefresh: () => dashboardProvider.loadDashboardStats(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Statistiques principales
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                StatCard(
                  title: 'Utilisateurs',
                  value: stats?.totalUsers.toString() ?? '0',
                  icon: Icons.people,
                  color: Colors.blue,
                  subtitle: 'Actifs',
                ),
                StatCard(
                  title: 'Étudiants',
                  value: stats?.totalStudents.toString() ?? '0',
                  icon: Icons.school,
                  color: Colors.green,
                  subtitle: 'Inscrits',
                ),
                StatCard(
                  title: 'Examens Aujourd\'hui',
                  value: stats?.todayExams.toString() ?? '0',
                  icon: Icons.event,
                  color: Colors.orange,
                  subtitle: 'Programmés',
                ),
                StatCard(
                  title: 'Présences',
                  value: stats?.todayPresent.toString() ?? '0',
                  icon: Icons.check_circle,
                  color: Colors.purple,
                  subtitle: 'Validées aujourd\'hui',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Examens en cours
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Examens en cours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (examProvider.inProgressExams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Aucun examen en cours',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...examProvider.inProgressExams.take(3).map((exam) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: exam.statusColor.withOpacity(0.2),
                            child: Icon(
                              Icons.play_circle_filled,
                              color: exam.statusColor,
                            ),
                          ),
                          title: Text(exam.name),
                          subtitle: Text(
                            '${exam.formattedDate} à ${exam.startTime}',
                          ),
                          trailing: Text(
                            '${exam.presentCount ?? 0}/${exam.totalStudents}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            // Naviguer vers les détails de l'examen
                          },
                        );
                      }).toList(),

                    if (examProvider.inProgressExams.length > 3)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Voir tous les examens
                          },
                          child: const Text('Voir tout'),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions rapides
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildQuickAction(
                          context,
                          Icons.add,
                          'Nouvel examen',
                          Colors.blue,
                          () {
                            // Créer un examen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateExamPage(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          context,
                          Icons.person_add,
                          'Ajouter utilisateur',
                          Colors.green,
                          () {
                            // Ajouter un utilisateur
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateUserPage(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          context,
                          Icons.download,
                          'Exporter rapports',
                          Colors.orange,
                          () {
                            // Exporter des rapports
                          },
                        ),
                        _buildQuickAction(
                          context,
                          Icons.settings,
                          'Paramètres',
                          Colors.grey,
                          () {
                            // Aller aux paramètres
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 2: Aujourd'hui
class _TodayView extends StatelessWidget {
  const _TodayView();

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    if (dashboardProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dailyStats = dashboardProvider.dailyStats;

    return RefreshIndicator(
      onRefresh: () => dashboardProvider.loadDailyStats(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sélecteur de date
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat(
                          'EEEE dd MMMM yyyy',
                          'fr_FR',
                        ).format(dashboardProvider.selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: dashboardProvider.selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (selectedDate != null) {
                          dashboardProvider.setSelectedDate(selectedDate);
                          await dashboardProvider.loadDailyStats();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Totaux du jour
            if (dailyStats != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Résumé du jour',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDailyStat(
                            'Présents',
                            dailyStats.totals.present.toString(),
                            Colors.green,
                            Icons.check_circle,
                          ),
                          _buildDailyStat(
                            'Absents',
                            dailyStats.totals.absent.toString(),
                            Colors.red,
                            Icons.cancel,
                          ),
                          _buildDailyStat(
                            'Taux',
                            '${dailyStats.attendanceRate}%',
                            Colors.blue,
                            Icons.percent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Liste des examens du jour
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Examens du jour',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${dailyStats.exams.length} examens',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (dailyStats.exams.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Aucun examen prévu aujourd\'hui',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...dailyStats.exams.map((exam) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: const Icon(
                                  Icons.event,
                                  color: Colors.blue,
                                ),
                              ),
                              title: Text(exam.examName),
                              subtitle: Text(
                                '${exam.startTime} - ${exam.endTime}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${exam.presentCount}/${exam.totalStudents}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${(exam.totalStudents > 0 ? (exam.presentCount / exam.totalStudents * 100) : 0).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Voir les détails de l'examen
                              },
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStat(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

// Tab 3: Statistiques
class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Statistiques détaillées', style: TextStyle(fontSize: 20)),
    );
  }
}
