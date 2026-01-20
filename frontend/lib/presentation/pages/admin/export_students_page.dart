// presentation/pages/admin/export_students_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/export_provider.dart';
import 'package:frontend1/presentation/widgets/export_dialog.dart';

class ExportStudentsPage extends StatefulWidget {
  const ExportStudentsPage({super.key});

  @override
  State<ExportStudentsPage> createState() => _ExportStudentsPageState();
}

class _ExportStudentsPageState extends State<ExportStudentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Exportation des Étudiants',
        showBackButton: true,
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            const Text(
              'Exporter la liste des étudiants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Générez un rapport complet de tous les étudiants inscrits',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Carte d'export PDF
            _buildExportCard(
              icon: Icons.picture_as_pdf,
              title: 'Exporter en PDF',
              subtitle: 'Générer un document PDF optimisé pour l\'impression',
              description: 'Format professionnel avec mise en page structurée. '
                  'Idéal pour l\'archivage et la distribution papier.',
              color: Colors.red,
              onTap: () => _showExportDialog(),
            ),
            
            const SizedBox(height: 20),
            
            // Carte d'export Excel
            _buildExportCard(
              icon: Icons.table_chart,
              title: 'Exporter en Excel',
              subtitle: 'Créer un fichier Excel modifiable pour analyse',
              description: 'Format tableur avec données organisées en colonnes. '
                  'Parfait pour le traitement de données et les statistiques.',
              color: Colors.green,
              onTap: () => _showExportDialog(),
            ),
            
            const SizedBox(height: 32),
            
            // Informations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Informations sur l\'export',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les fichiers exportés contiendront :\n'
                    '• Informations personnelles des étudiants\n'
                    '• Numéro d\'inscription\n'
                    '• Programme et année d\'étude\n'
                    '• Date d\'inscription\n'
                    '• Statut actif/inactif',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icône
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              
              const SizedBox(width: 20),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Flèche
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _showExportDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ExportDialog(
        title: 'Exporter la liste des étudiants',
        description: 'Sélectionnez le format d\'exportation pour la liste complète des étudiants.',
        isStudentExport: true,
      ),
    );
  }
}