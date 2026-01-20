// data/models/export_model.dart
class ExportData {
  final String fileName;
  final List<int> fileBytes;
  final String mimeType;
  final int fileSize;
  
  ExportData({
    required this.fileName,
    required this.fileBytes,
    required this.mimeType,
    required this.fileSize,
  });
  
  String get formattedSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
  }
}

class ExportResult {
  final bool success;
  final String message;
  final ExportData? data;
  
  ExportResult({
    required this.success,
    required this.message,
    this.data,
  });
}