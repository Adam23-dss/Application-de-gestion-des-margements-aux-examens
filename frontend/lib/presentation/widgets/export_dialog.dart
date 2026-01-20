// presentation/widgets/export_dialog.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend1/core/utils/file_handler.dart';
import 'package:frontend1/data/models/export_model.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/export_provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class ExportDialog extends StatefulWidget {
  final String title;
  final String description;
  final int? examId;
  final bool isStudentExport;
  
  const ExportDialog({
    super.key,
    required this.title,
    required this.description,
    this.examId,
    this.isStudentExport = false,
  });
  
  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportAction? _selectedAction;
  bool _isProcessing = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 20),
          
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          
          _buildExportOption(
            icon: Icons.picture_as_pdf,
            title: 'Exporter en PDF',
            subtitle: 'Format optimisé pour impression',
            action: ExportAction.pdf,
            selected: _selectedAction == ExportAction.pdf,
          ),
          
          const SizedBox(height: 12),
          
          _buildExportOption(
            icon: Icons.table_chart,
            title: 'Exporter en Excel',
            subtitle: 'Format modifiable pour analyse',
            action: ExportAction.excel,
            selected: _selectedAction == ExportAction.excel,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedAction == null || _isProcessing ? null : _export,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Exporter'),
        ),
      ],
    );
  }
  
  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required ExportAction action,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedAction = action),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? AppColors.primary : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _export() async {
    if (_selectedAction == null) return;
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    
    try {
      final exportProvider = context.read<ExportProvider>();
      
      ExportData exportData;
      
      if (widget.isStudentExport) {
        if (_selectedAction == ExportAction.pdf) {
          exportData = await exportProvider.exportStudentsPDF();
        } else {
          exportData = await exportProvider.exportStudentsExcel();
        }
      } else {
        if (widget.examId == null) {
          throw Exception('ID d\'examen requis');
        }
        
        if (_selectedAction == ExportAction.pdf) {
          exportData = await exportProvider.exportAttendancePDF(widget.examId!);
        } else {
          exportData = await exportProvider.exportAttendanceExcel(widget.examId!);
        }
      }
      
      // Sauvegarder le fichier
      final file = await FileHandler.saveFile(
        bytes: exportData.fileBytes,
        fileName: exportData.fileName,
        mimeType: exportData.mimeType,
      );
      
      if (file == null) {
        throw Exception('Impossible de sauvegarder le fichier');
      }
      
      // Montrer le dialogue de succès
      await _showSuccessDialog(file, exportData);
      
      // Fermer le dialogue d'export
      if (mounted) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _showSuccessDialog(File file, ExportData exportData) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Exportation réussie'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fichier exporté avec succès:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              file.path.split('/').last,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Taille: ${exportData.formattedSize}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'Que voulez-vous faire avec ce fichier ?',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          OutlinedButton(
            onPressed: () async {
              try {
                await FileHandler.openFile(file);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ouvrir'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FileHandler.shareFile(file);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Partager'),
          ),
        ],
      ),
    );
  }
}

enum ExportAction { pdf, excel }