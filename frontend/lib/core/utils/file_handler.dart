// utils/file_handler.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class FileHandler {
  // DEMANDER LES PERMISSIONS
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Pour Android 13+ (API 33+)
      if (Platform.isAndroid && await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return false;
        }
      }
      
      // Demander aussi la permission de gestion des fichiers si Android 11+
      if (await Permission.manageExternalStorage.isDenied) {
        final manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          // Essayer avec storage seulement
          final storageStatus = await Permission.storage.request();
          return storageStatus.isGranted;
        }
      }
    }
    
    return true;
  }
  
  // SAUVEGARDER UN FICHIER LOCALEMENT
  static Future<File?> saveFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      // Vérifier les permissions
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Permissions de stockage non accordées');
      }
      
      // Chemin du répertoire de téléchargement
      Directory directory;
      if (Platform.isAndroid) {
        // Essayer le répertoire Download
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // Pour iOS, utiliser le répertoire documents
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      // S'assurer que le répertoire existe
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Créer le fichier
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      // Écrire les bytes dans le fichier
      await file.writeAsBytes(bytes, flush: true);
      
      return file;
    } catch (e) {
      print('Erreur sauvegarde fichier: $e');
      return null;
    }
  }
  
  // OUVIR UN FICHIER - CORRIGÉ ICI
  static Future<void> openFile(File file) async {
    try {
      // CORRECTION : Utiliser OpenFile.open() au lieu de openFile.open()
      final result = await OpenFile.open(file.path);
      
      // Vérifier le résultat
      switch (result.type) {
        case ResultType.done:
          // Fichier ouvert avec succès
          break;
        case ResultType.noAppToOpen:
          throw Exception('Aucune application disponible pour ouvrir ce fichier');
        case ResultType.fileNotFound:
          throw Exception('Fichier non trouvé');
        case ResultType.permissionDenied:
          throw Exception('Permission refusée pour ouvrir le fichier');
        case ResultType.error:
        default:
          throw Exception('Erreur: ${result.message}');
      }
    } catch (e) {
      print('Erreur ouverture fichier: $e');
      rethrow;
    }
  }
  
  // PARTAGER UN FICHIER
  static Future<void> shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: _getMimeType(file.path))],
        subject: file.path.split('/').last,
      );
    } catch (e) {
      print('Erreur partage fichier: $e');
      rethrow;
    }
  }
  
  // MÉTHODE UTILITAIRE POUR OBTENIR LE TYPE MIME
  static String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'xlsx':
      case 'xls':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'txt':
        return 'text/plain';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
  
  // OBTENIR LA TAILLE DU FICHIER FORMATÉE
  static String getFormattedFileSize(File file) {
    try {
      final size = file.lengthSync();
      if (size < 1024) {
        return '${size}B';
      } else if (size < 1024 * 1024) {
        return '${(size / 1024).toStringAsFixed(2)}KB';
      } else {
        return '${(size / (1024 * 1024)).toStringAsFixed(2)}MB';
      }
    } catch (e) {
      return 'Taille inconnue';
    }
  }
  
  // VÉRIFIER SI UN FICHIER EXISTE
  static Future<bool> fileExists(String fileName) async {
    try {
      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      final file = File('${directory.path}/$fileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  // SUPPRIMER UN FICHIER
  static Future<bool> deleteFile(String fileName) async {
    try {
      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      final file = File('${directory.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // NOUVELLE MÉTHODE : OBTENIR LE RÉPERTOIRE DE TÉLÉCHARGEMENT
  static Future<String> getDownloadDirectory() async {
    Directory directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    return directory.path;
  }
  
  // NOUVELLE MÉTHODE : LISTER LES FICHIERS EXPORTÉS RÉCENTS
  static Future<List<File>> getRecentExports({int limit = 10}) async {
    try {
      final dirPath = await getDownloadDirectory();
      final directory = Directory(dirPath);
      
      if (!await directory.exists()) {
        return [];
      }
      
      final files = await directory.list().toList();
      final fileList = <File>[];
      
      for (var entity in files) {
        if (entity is File) {
          final fileName = entity.path.split('/').last.toLowerCase();
          if (fileName.contains('presence') || fileName.contains('etudiant') || 
              fileName.contains('.pdf') || fileName.contains('.xlsx')) {
            fileList.add(entity);
          }
        }
      }
      
      // Trier par date de modification (le plus récent d'abord)
      fileList.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return fileList.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}