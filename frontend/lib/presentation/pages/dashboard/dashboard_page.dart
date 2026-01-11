import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final examProvider = Provider.of<ExamProvider>(context, listen: false);
    await examProvider.fetchExams();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final examProvider = Provider.of<ExamProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, ${authProvider.user?.name ?? 'Utilisateur'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            authProvider.isAdmin ? 'Administrateur' : 'Surveillant',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Statistiques
              const Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatCard('Examens du jour', '3', Icons.event, AppColors.primary),
                  _buildStatCard('Présences', '142', Icons.check_circle, AppColors.success),
                  _buildStatCard('Absences', '8', Icons.cancel, AppColors.error),
                  _buildStatCard('Taux présence', '94%', Icons.percent, AppColors.warning),
                ],
              ),

              const SizedBox(height: 24),

              // Examens à venir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Examens à venir',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (examProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (examProvider.exams.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: const Column(
                    children: [
                      Icon(Icons.event_busy, size: 64, color: AppColors.textSecondary),
                      SizedBox(height: 16),
                      Text('Aucun examen prévu'),
                    ],
                  ),
                )
              else
                ...examProvider.exams.take(3).map((exam) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.event, color: AppColors.primary),
                      title: Text(exam.name),
                      subtitle: Text('${exam.course} • ${exam.room}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {},
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/scan');
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}