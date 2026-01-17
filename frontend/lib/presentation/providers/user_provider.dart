import 'package:flutter/material.dart';
import 'package:frontend1/data/models/user_model.dart';
import 'package:frontend1/data/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository();

  // État
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  String _searchQuery = '';
  String? _roleFilter;
  bool? _statusFilter; // true = actif, false = inactif, null = tous

  // Getters
  List<UserModel> get users => List.unmodifiable(_users);
  UserModel? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalUsers => _totalUsers;
  String get searchQuery => _searchQuery;
  String? get roleFilter => _roleFilter;
  bool? get statusFilter => _statusFilter;

  // État pour la pagination infinie
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  // ============================
  // CHARGEMENT DES UTILISATEURS
  // ============================

  Future<void> loadUsers({bool refresh = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _repository.getUsers(
        page: _currentPage,
        search: _searchQuery,
        role: _roleFilter,
        status: _statusFilter != null
            ? (_statusFilter! ? 'active' : 'inactive')
            : null,
      );

      _users = result['users'] as List<UserModel>;
      _totalUsers = result['total'] as int;
      _totalPages = result['totalPages'] as int;
      _hasMore = _currentPage < _totalPages;

      notifyListeners();
    } catch (e) {
      print('❌ Error in loadUsers: $e');
      setError('Erreur chargement utilisateurs: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger plus d'utilisateurs (pagination infinie)
  Future<void> loadMoreUsers() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      _currentPage++;
      await loadUsers();
    } catch (e) {
      print('❌ Error in loadMoreUsers: $e');
      _currentPage--; // Revenir à la page précédente en cas d'erreur
      rethrow;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ============================
  // FILTRES ET RECHERCHE
  // ============================

  Future<void> searchUsers(String query) async {
    _searchQuery = query.trim();
    await loadUsers(refresh: true);
  }

  Future<void> filterByRole(String? role) async {
    _roleFilter = role;
    await loadUsers(refresh: true);
  }

  Future<void> filterByStatus(bool? isActive) async {
    _statusFilter = isActive;
    await loadUsers(refresh: true);
  }

  Future<void> resetFilters() async {
    _searchQuery = '';
    _roleFilter = null;
    _statusFilter = null;
    await loadUsers(refresh: true);
  }

  // ============================
  // CRUD OPERATIONS
  // ============================

  // Créer un utilisateur
  Future<UserModel> createUser(Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newUser = await _repository.createUser(userData);

      // Ajouter en début de liste
      _users.insert(0, newUser);
      _totalUsers++;

      notifyListeners();
      return newUser;
    } catch (e) {
      print('❌ Error creating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour un utilisateur
  Future<UserModel> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedUser = await _repository.updateUser(id, userData);

      // Mettre à jour dans la liste
      final index = _users.indexWhere((user) => user.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }

      // Si l'utilisateur est sélectionné, le mettre à jour aussi
      if (_selectedUser?.id == id) {
        _selectedUser = updatedUser;
      }

      return updatedUser;
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Changer le statut d'un utilisateur (activer/désactiver)
  Future<void> toggleUserStatus(int id, bool isActive) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.toggleUserStatus(id, isActive);

      // Mettre à jour localement
      final index = _users.indexWhere((user) => user.id == id);
      if (index != -1) {
        _users[index] = _users[index].copyWith(isActive: isActive);
      }

      // Mettre à jour l'utilisateur sélectionné
      if (_selectedUser?.id == id) {
        _selectedUser = _selectedUser!.copyWith(isActive: isActive);
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error toggling user status: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Supprimer un utilisateur (soft delete)
  Future<void> deleteUser(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.deleteUser(id);

      // Retirer de la liste
      _users.removeWhere((user) => user.id == id);
      _totalUsers = _totalUsers > 0 ? _totalUsers - 1 : 0;

      // Si l'utilisateur est sélectionné, le désélectionner
      if (_selectedUser?.id == id) {
        _selectedUser = null;
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================
  // SÉLECTION ET UTILITAIRE
  // ============================

  void selectUser(UserModel? user) {
    _selectedUser = user;
    notifyListeners();
  }

  void clearSelection() {
    _selectedUser = null;
    notifyListeners();
  }

  // Vérifier si l'utilisateur actuel peut modifier un autre utilisateur
  bool canModifyUser(UserModel currentUser, UserModel targetUser) {
    // Un admin peut modifier tout le monde sauf lui-même
    if (currentUser.isAdmin && currentUser.id != targetUser.id) {
      return true;
    }

    // Un utilisateur ne peut modifier que son propre compte
    return currentUser.id == targetUser.id;
  }

  // Vérifier si l'utilisateur actuel peut supprimer un autre utilisateur
  bool canDeleteUser(UserModel currentUser, UserModel targetUser) {
    // Seul un admin peut supprimer, et pas son propre compte
    return currentUser.isAdmin && currentUser.id != targetUser.id;
  }

  // Rechercher un utilisateur par ID
  UserModel? findUserById(int id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtenir les utilisateurs filtrés par rôle
  List<UserModel> getUsersByRole(String role) {
    return _users.where((user) => user.role == role).toList();
  }

  // Obtenir les statistiques
  Map<String, int> getUserStatistics() {
    final stats = {
      'total': _users.length,
      'active': _users.where((user) => user.isActive).length,
      'inactive': _users.where((user) => !user.isActive).length,
      'admins': _users.where((user) => user.isAdmin).length,
      'supervisors': _users.where((user) => user.isSupervisor).length,
      'students': _users.where((user) => user.isStudent).length,
    };

    return stats;
  }

  // Rafraîchir toutes les données
  Future<void> refreshData() async {
    await loadUsers(refresh: true);
  }

  // Réinitialiser complètement le provider
  void reset() {
    _users.clear();
    _selectedUser = null;
    _isLoading = false;
    _currentPage = 1;
    _totalPages = 1;
    _totalUsers = 0;
    _searchQuery = '';
    _roleFilter = null;
    _statusFilter = null;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();
  }

  // ============================
  // GESTION DES ERREURS
  // ============================

  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  // ============================
  // DISPOSE
  // ============================

  @override
  void dispose() {
    _users.clear();
    super.dispose();
  }
}
