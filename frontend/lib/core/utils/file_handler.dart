// utils/file_handler.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class FileHandler {
  // NOUVELLE MÉTHODE : GESTION DES PERMISSIONS AMÉLIORÉE
  static Future<bool> requestPermissions() async {
    try {
      print('🔐 Demande de permissions en cours...');
      
      if (Platform.isAndroid) {
        // Vérifier la version Android
        if (await Permission.storage.isDenied) {
          print('📱 Demande permission storage...');
          final storageStatus = await Permission.storage.request();
          print('📱 Statut storage: ${storageStatus.name}');
          
          if (!storageStatus.isGranted) {
            // Essayer avec manageExternalStorage pour Android 11+
            if (await Permission.manageExternalStorage.isDenied) {
              print('📱 Demande permission manageExternalStorage...');
              final manageStatus = await Permission.manageExternalStorage.request();
              print('📱 Statut manageExternalStorage: ${manageStatus.name}');
              
              if (!manageStatus.isGranted) {
                // Dernier recours : demander des permissions de base
                final photosStatus = await Permission.photos.request();
                print('📱 Statut photos: ${photosStatus.name}');
                return photosStatus.isGranted;
              }
              return manageStatus.isGranted;
            }
          }
          return storageStatus.isGranted;
        }
        return true;
      }
      
      // Pour iOS
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        print('📱 iOS Statut photos: ${status.name}');
        return status.isGranted;
      }
      
      return true;
    } catch (e) {
      print('❌ Erreur permissions: $e');
      return false;
    }
  }
  
  // SAUVEGARDER UN FICHIER - VERSION AMÉLIORÉE
  static Future<File?> saveFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      print('💾 Tentative de sauvegarde: $fileName');
      
      // Vérifier les permissions
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('❌ Permissions non accordées');
        throw Exception('Veuillez accorder les permissions de stockage dans les paramètres de l\'application');
      }
      
      // Déterminer le répertoire
      Directory directory;
      if (Platform.isAndroid) {
        // Essayer plusieurs chemins
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            print('📁 Download non trouvé, essai external storage...');
            directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          print('⚠️ Erreur chemin Android: $e');
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      print('📁 Répertoire cible: ${directory.path}');
      
      // Créer le répertoire si nécessaire
      if (!await directory.exists()) {
        print('📁 Création du répertoire...');
        await directory.create(recursive: true);
      }
      
      // Créer le chemin du fichier
      final filePath = '${directory.path}/$fileName';
      print('📄 Chemin fichier: $filePath');
      
      // Écrire le fichier
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      
      // Vérifier que le fichier existe
      if (await file.exists()) {
        print('✅ Fichier sauvegardé avec succès');
        print('📊 Taille: ${file.lengthSync()} bytes');
        return file;
      } else {
        print('❌ Fichier non créé');
        return null;
      }
      
    } catch (e) {
      print('❌ Erreur sauvegarde fichier: $e');
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