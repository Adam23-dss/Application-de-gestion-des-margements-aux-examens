// presentation/providers/room_provider.dart
import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/room_model.dart';
import 'package:frontend1/data/repositories/room_repository.dart';

class RoomProvider with ChangeNotifier {
  List<RoomModel> _rooms = [];
  RoomModel? _selectedRoom;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingFilters = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  
  // Filtres
  String? _selectedBuilding;
  String? _selectedMinCapacity;
  bool? _hasComputerFilter;
  List<String> _buildingOptions = [];
  List<String> _capacityOptions = [];
  bool _isSearching = false;
  
  // Statistiques
  Map<String, dynamic> _buildingStats = {};
  
  // Getters
  List<RoomModel> get rooms => _rooms;
  RoomModel? get selectedRoom => _selectedRoom;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingFilters => _isLoadingFilters;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get selectedBuilding => _selectedBuilding;
  String? get selectedMinCapacity => _selectedMinCapacity;
  bool? get hasComputerFilter => _hasComputerFilter;
  List<String> get buildingOptions => _buildingOptions;
  List<String> get capacityOptions => _capacityOptions;
  bool get isSearching => _isSearching;
  Map<String, dynamic> get buildingStats => _buildingStats;
  
  final RoomRepository _repository = RoomRepository();
  
  // CHARGER LES SALLES
  Future<void> loadRooms({bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      _rooms.clear();
      _hasMore = true;
    }
    
    _isLoading = true;
    _error = null;
    _isSearching = false;
    notifyListeners();
    
    try {
      final filters = {
        if (_selectedBuilding != null && _selectedBuilding!.isNotEmpty) 'building': _selectedBuilding,
        if (_selectedMinCapacity != null && _selectedMinCapacity!.isNotEmpty) 'minCapacity': _selectedMinCapacity,
        if (_hasComputerFilter != null) 'hasComputer': _hasComputerFilter,
      };
      
      final response = await _repository.getRooms(
        page: _currentPage,
        limit: 20,
        filters: filters,
      );
      
      if (reset) {
        _rooms = response.rooms;
      } else {
        _rooms.addAll(response.rooms);
      }
      
      _currentPage = response.pagination.currentPage;
      _totalPages = response.pagination.totalPages;
      _hasMore = response.pagination.totalItems < response.pagination.totalPages;
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // CHARGER PLUS DE SALLES
  Future<void> loadMoreRooms() async {
    if (_isLoadingMore || !_hasMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      _currentPage++;
      await loadRooms(reset: false);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  // RECHERCHER DES SALLES
  Future<void> searchRooms(String query) async {
    if (query.isEmpty) {
      await loadRooms();
      return;
    }
    
    _isSearching = true;
    _isLoading = true;
    notifyListeners();
    
    try {
      final results = await _repository.searchRooms(query);
      _rooms = results;
      _hasMore = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _rooms = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // CRÉER UNE SALLE
  Future<RoomModel> createRoom(Map<String, dynamic> roomData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newRoom = await _repository.createRoom(roomData);
      
      _rooms.insert(0, newRoom);
      _error = null;
      
      // Recharger les options de filtres
      await loadFilterOptions();
      await loadBuildingStats();
      
      notifyListeners();
      return newRoom;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // METTRE À JOUR UNE SALLE
  Future<RoomModel> updateRoom(int id, Map<String, dynamic> roomData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedRoom = await _repository.updateRoom(id, roomData);
      
      // Mettre à jour dans la liste
      final index = _rooms.indexWhere((room) => room.id == id);
      if (index != -1) {
        _rooms[index] = updatedRoom;
      }
      
      // Mettre à jour la salle sélectionnée
      if (_selectedRoom?.id == id) {
        _selectedRoom = updatedRoom;
      }
      
      _error = null;
      notifyListeners();
      return updatedRoom;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // SUPPRIMER UNE SALLE
  Future<void> deleteRoom(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.deleteRoom(id);
      
      // Retirer de la liste
      _rooms.removeWhere((room) => room.id == id);
      
      // Désélectionner si c'était la salle sélectionnée
      if (_selectedRoom?.id == id) {
        _selectedRoom = null;
      }
      
      // Recharger les options de filtres
      await loadFilterOptions();
      await loadBuildingStats();
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // OBTENIR UNE SALLE PAR ID
  Future<RoomModel?> getRoomById(int roomId) async {
    try {
      return await _repository.getRoomById(roomId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  // OBTENIR LES SALLES DISPONIBLES
  Future<List<RoomModel>> getAvailableRooms({
    required int capacity,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      return await _repository.getAvailableRooms(
        capacity: capacity,
        date: date,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  // CHARGER LES OPTIONS DE FILTRES
  Future<void> loadFilterOptions() async {
    _isLoadingFilters = true;
    notifyListeners();
    
    try {
      final options = await _repository.getFilterOptions();
      _buildingOptions = options['buildings'] ?? [];
      _capacityOptions = options['capacities'] ?? [];
    } catch (e) {
      print('❌ Error loading filter options: $e');
    } finally {
      _isLoadingFilters = false;
      notifyListeners();
    }
  }
  
  // CHARGER LES STATISTIQUES
  Future<void> loadBuildingStats() async {
    try {
      _buildingStats = await _repository.getBuildingStats();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading building stats: $e');
    }
  }
  
  // SÉLECTIONNER UNE SALLE
  void selectRoom(RoomModel? room) {
    _selectedRoom = room;
    notifyListeners();
  }
  
  // DÉFINIR LES FILTRES
  void setBuildingFilter(String? building) {
    _selectedBuilding = building;
    loadRooms();
  }
  
  void setMinCapacityFilter(String? capacity) {
    _selectedMinCapacity = capacity;
    loadRooms();
  }
  
  void setHasComputerFilter(bool? hasComputer) {
    _hasComputerFilter = hasComputer;
    loadRooms();
  }
  
  // EFFACER LES FILTRES
  void clearFilters() {
    _selectedBuilding = null;
    _selectedMinCapacity = null;
    _hasComputerFilter = null;
    loadRooms();
  }
  
  // EFFACER LES ERREURS
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // RÉINITIALISER
  void reset() {
    _rooms.clear();
    _selectedRoom = null;
    _isLoading = false;
    _isLoadingMore = false;
    _isLoadingFilters = false;
    _error = null;
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    _selectedBuilding = null;
    _selectedMinCapacity = null;
    _hasComputerFilter = null;
    _buildingOptions.clear();
    _capacityOptions.clear();
    _isSearching = false;
    _buildingStats.clear();
    notifyListeners();
  }
}