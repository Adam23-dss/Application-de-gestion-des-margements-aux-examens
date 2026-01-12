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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardStats = await _repository.getDashboardStats();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _dashboardStats = null;
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
      _dailyStats = await _repository.getDailyStats(date: dateString);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _dailyStats = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> loadExamStats(int examId) async {
    try {
      return await _repository.getExamStats(examId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
