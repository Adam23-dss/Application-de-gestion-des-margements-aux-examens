// lib/core/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Vérifier et demander la permission caméra
  static Future<bool> checkAndRequestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  // Vérifier si les permissions sont nécessaires (pour iOS)
  static Future<bool> get isCameraPermissionRequired async {
    final status = await Permission.camera.status;
    return !status.isGranted;
  }

  // Vérifier les permissions de galerie
  static Future<bool> checkGalleryPermission() async {
    if (await Permission.photos.request().isGranted) {
      return true;
    }
    return false;
  }
}
