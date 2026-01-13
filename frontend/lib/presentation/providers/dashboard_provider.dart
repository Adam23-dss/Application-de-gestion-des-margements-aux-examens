// lib/presentation/providers/dashboard_provider.dart
import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/stats_model.dart';
import 'package:frontend1/data/repositories/stats_repository.dart';

class DashboardProvider with ChangeNotifier {
  DashboardStats? _dashboardStats;
  DailyStats? _dailyStats;
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  DashboardStats? get dashboardStats => _dashboardStats;
  DailyStats? get dailyStats => _dailyStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  final StatsRepository _repository = StatsRepository();

  Future<void> loadDashboardStats() async {
    print('🔄 [DashboardProvider] Loading dashboard stats...');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stats = await _repository.getDashboardStats();
      
      print('✅ [DashboardProvider] Stats loaded successfully!');
      print('📊 Total Users: ${stats.totalUsers}');
      print('📊 Total Students: ${stats.totalStudents}');
      print('📊 Today Exams: ${stats.todayExams}');
      print('📊 Today Present: ${stats.todayPresent}');
      
      _dashboardStats = stats;
      _error = null;
      
    } catch (e) {
      _error = e.toString();
      _dashboardStats = null;
      print('❌ [DashboardProvider] Error: $e');
      
      // // Fallback: données mock pour développement
      // if (kDebugMode) {
      //   print('⚠️ Using mock data for development');
      //   _dashboardStats = DashboardStats(
      //     totalUsers: 5,
      //     totalStudents: 3,
      //     todayExams: 1,
      //     activeExams: 1,
      //     todayPresent: 0,
      //     monthlyExams: 2,
      //   );
      //}
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDailyStats({DateTime? date}) async {
    _isLoading = true;
    _error = null;

    if (date != null) {
      _selectedDate = date;
    }

    notifyListeners();

    try {
      final dateString = _selectedDate.toIso8601String().split('T')[0];
      print('📅 [DashboardProvider] Loading daily stats for: $dateString');
      
      _dailyStats = await _repository.getDailyStats(date: dateString);
      
      print('✅ [DashboardProvider] Daily stats loaded');
      print('📅 Present: ${_dailyStats?.totals.present}');
      print('📅 Absent: ${_dailyStats?.totals.absent}');
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      _dailyStats = null;
      print('❌ [DashboardProvider] Error loading daily stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> loadExamStats(int examId) async {
    try {
      print('📈 [DashboardProvider] Loading exam stats for exam $examId');
      final stats = await _repository.getExamStats(examId);
      return stats;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print('❌ [DashboardProvider] Error loading exam stats: $e');
      return {};
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}