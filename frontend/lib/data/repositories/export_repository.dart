// data/repositories/export_repository.dart
import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/export_model.dart';

class ExportRepository {
  final Dio _dio = ApiClient.instance;
  
  // EXPORTER PRÉSENCES EN PDF
  Future<ExportData> exportAttendancePDF(int examId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.exports}/attendance/$examId/pdf',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'application/pdf',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final bytes = (response.data as List).cast<int>();
        final contentDisposition = response.headers.value('content-disposition') ?? '';
        final fileName = _extractFileName(contentDisposition) ?? 'presence-examen-$examId.pdf';
        
        return ExportData(
          fileName: fileName,
          fileBytes: bytes,
          mimeType: 'application/pdf',
          fileSize: bytes.length,
        );
      } else {
        throw Exception('Échec de l\'export PDF: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Examen non trouvé');
      }
      throw Exception('Erreur réseau: ${e.message}');
    }
  }
  
  // EXPORTER PRÉSENCES EN EXCEL
  Future<ExportData> exportAttendanceExcel(int examId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.exports}/attendance/$examId/excel',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final bytes = (response.data as List).cast<int>();
        final contentDisposition = response.headers.value('content-disposition') ?? '';
        final fileName = _extractFileName(contentDisposition) ?? 'presence-examen-$examId.xlsx';
        
        return ExportData(
          fileName: fileName,
          fileBytes: bytes,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          fileSize: bytes.length,
        );
      } else {
        throw Exception('Échec de l\'export Excel: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Examen non trouvé');
      }
      throw Exception('Erreur réseau: ${e.message}');
    }
  }
  
  // EXPORTER LISTE ÉTUDIANTS EN PDF
  Future<ExportData> exportStudentsPDF() async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.exports}/students/pdf',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'application/pdf',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final bytes = (response.data as List).cast<int>();
        final contentDisposition = response.headers.value('content-disposition') ?? '';
        final fileName = _extractFileName(contentDisposition) ?? 'liste-etudiants.pdf';
        
        return ExportData(
          fileName: fileName,
          fileBytes: bytes,
          mimeType: 'application/pdf',
          fileSize: bytes.length,
        );
      } else {
        throw Exception('Échec de l\'export PDF étudiants: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erreur réseau: ${e.message}');
    }
  }
  
  // EXPORTER LISTE ÉTUDIANTS EN EXCEL
  Future<ExportData> exportStudentsExcel() async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.exports}/students/excel',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final bytes = (response.data as List).cast<int>();
        final contentDisposition = response.headers.value('content-disposition') ?? '';
        final fileName = _extractFileName(contentDisposition) ?? 'liste-etudiants.xlsx';
        
        return ExportData(
          fileName: fileName,
          fileBytes: bytes,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          fileSize: bytes.length,
        );
      } else {
        throw Exception('Échec de l\'export Excel étudiants: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erreur réseau: ${e.message}');
    }
  }
  
  // MÉTHODE UTILITAIRE POUR EXTRAIRE LE NOM DE FICHIER
  String? _extractFileName(String contentDisposition) {
    final regex = RegExp(r'filename[^;=\n]*=(([\"]).*?\2|[^\n]*)');
    final matches = regex.allMatches(contentDisposition);
    
    if (matches.isNotEmpty) {
      String fileName = matches.first.group(1) ?? '';
      // Retirer les guillemets
      fileName = fileName.replaceAll('"', '').replaceAll("'", '');
      return fileName;
    }
    
    return null;
  }
}