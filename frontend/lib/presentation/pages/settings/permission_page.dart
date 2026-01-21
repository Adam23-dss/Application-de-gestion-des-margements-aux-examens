// presentation/pages/settings/permission_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  Map<Permission, PermissionStatus> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = Platform.isAndroid
        ? [
            Permission.storage,
            Permission.manageExternalStorage,
            Permission.photos,
          ]
        : [
            Permission.photos,
          ];

    final status = <Permission, PermissionStatus>{};
    for (var permission in permissions) {
      status[permission] = await permission.status;
    }

    setState(() {
      _permissionStatus = status;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    setState(() {
      _permissionStatus[permission] = status;
    });
  }

  Widget _buildPermissionCard(
    Permission permission,
    String title,
    String description,
    IconData icon,
  ) {
    final status = _permissionStatus[permission] ?? PermissionStatus.denied;
    
    Color statusColor;
    String statusText;
    
    switch (status) {
      case PermissionStatus.granted:
        statusColor = Colors.green;
        statusText = 'Accordée';
        break;
      case PermissionStatus.limited:
        statusColor = Colors.orange;
        statusText = 'Limitée';
        break;
      case PermissionStatus.denied:
        statusColor = Colors.red;
        statusText = 'Refusée';
        break;
      case PermissionStatus.permanentlyDenied:
        statusColor = Colors.red[800]!;
        statusText = 'Refusée définitivement';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Inconnue';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            if (status != PermissionStatus.granted &&
                status != PermissionStatus.permanentlyDenied)
              ElevatedButton(
                onPressed: () => _requestPermission(permission),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Demander la permission'),
              ),
            if (status == PermissionStatus.permanentlyDenied)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Allez dans Paramètres → Applications → ${Platform.isAndroid ? 'Gestion Émargements' : 'Nom de l\'app'} → Permissions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Ouvrir les paramètres'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestion des permissions',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Permissions requises',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Certaines fonctionnalités nécessitent des permissions pour fonctionner correctement.',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            if (Platform.isAndroid) ...[
              _buildPermissionCard(
                Permission.storage,
                'Stockage',
                'Permet de sauvegarder les fichiers exportés (PDF, Excel)',
                Icons.storage,
              ),
              const SizedBox(height: 12),
              _buildPermissionCard(
                Permission.manageExternalStorage,
                'Gestion du stockage (Android 11+)',
                'Nécessaire pour accéder aux fichiers sur les versions récentes d\'Android',
                Icons.sd_storage,
              ),
            ],
            
            const SizedBox(height: 12),
            _buildPermissionCard(
              Permission.photos,
              'Photos/Média',
              'Permet d\'accéder aux fichiers médias pour le partage',
              Icons.photo_library,
            ),
            
            const SizedBox(height: 24),
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
                        'Pourquoi ces permissions ?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Exportation des présences en PDF/Excel\n'
                    '• Sauvegarde des rapports sur votre appareil\n'
                    '• Partage des fichiers avec d\'autres applications\n'
                    '• Aucune donnée personnelle n\'est collectée',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _checkPermissions,
              icon: const Icon(Icons.refresh),
              label: const Text('Vérifier à nouveau'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}