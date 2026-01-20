// presentation/pages/admin/manage_rooms_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/room_provider.dart';
import 'package:frontend1/presentation/pages/admin/create_room_page.dart';
import 'package:frontend1/presentation/pages/admin/room_detail_page.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/data/models/room_model.dart';

class ManageRoomsPage extends StatefulWidget {
  const ManageRoomsPage({super.key});

  @override
  State<ManageRoomsPage> createState() => _ManageRoomsPageState();
}

class _ManageRoomsPageState extends State<ManageRoomsPage> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomProvider = context.read<RoomProvider>();
      roomProvider.loadRooms();
      roomProvider.loadFilterOptions();
      roomProvider.loadBuildingStats();
    });
    
    _searchController.addListener(() {
      final roomProvider = context.read<RoomProvider>();
      if (_searchController.text.isEmpty) {
        roomProvider.loadRooms();
      } else {
        roomProvider.searchRooms(_searchController.text);
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _showFilterDialog(BuildContext context) {
    final roomProvider = context.read<RoomProvider>();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String? selectedBuilding = roomProvider.selectedBuilding;
            String? selectedMinCapacity = roomProvider.selectedMinCapacity;
            bool? hasComputerFilter = roomProvider.hasComputerFilter;
            
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Filtrer les salles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Filtre par bâtiment
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bâtiment',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      roomProvider.isLoadingFilters
                          ? const Center(child: CircularProgressIndicator())
                          : Wrap(
                              spacing: 8,
                              children: [
                                _buildFilterChip(
                                  'Tous',
                                  selectedBuilding == null,
                                  () => setState(() => selectedBuilding = null),
                                ),
                                ...roomProvider.buildingOptions.map((building) {
                                  return _buildFilterChip(
                                    building,
                                    selectedBuilding == building,
                                    () => setState(() => selectedBuilding = building),
                                  );
                                }).toList(),
                              ],
                            ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Filtre par capacité minimale
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Capacité minimale',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      roomProvider.isLoadingFilters
                          ? const Center(child: CircularProgressIndicator())
                          : Wrap(
                              spacing: 8,
                              children: [
                                _buildFilterChip(
                                  'Toutes',
                                  selectedMinCapacity == null,
                                  () => setState(() => selectedMinCapacity = null),
                                ),
                                ...roomProvider.capacityOptions.map((capacity) {
                                  return _buildFilterChip(
                                    '$capacity places',
                                    selectedMinCapacity == capacity,
                                    () => setState(() => selectedMinCapacity = capacity),
                                  );
                                }).toList(),
                              ],
                            ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Filtre par équipement informatique
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Équipement informatique',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip(
                            'Toutes',
                            hasComputerFilter == null,
                            () => setState(() => hasComputerFilter = null),
                          ),
                          _buildFilterChip(
                            'Avec ordinateurs',
                            hasComputerFilter == true,
                            () => setState(() => hasComputerFilter = true),
                          ),
                          _buildFilterChip(
                            'Sans ordinateurs',
                            hasComputerFilter == false,
                            () => setState(() => hasComputerFilter = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            roomProvider.setBuildingFilter(selectedBuilding);
                            roomProvider.setMinCapacityFilter(selectedMinCapacity);
                            roomProvider.setHasComputerFilter(hasComputerFilter);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withOpacity(0.2),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : Colors.black,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
  
  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailPage(roomId: room.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: room.hasComputer 
                      ? Colors.purple.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  room.hasComputer ? Icons.computer : Icons.meeting_room,
                  color: room.hasComputer ? Colors.purple : Colors.blue,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            room.code,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${room.building}${room.floor != null ? ', Étage ${room.floor}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${room.capacity} places',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          room.hasComputer ? Icons.computer : Icons.computer_outlined,
                          size: 12,
                          color: room.hasComputer ? Colors.purple : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          room.hasComputer ? 'Avec PC' : 'Sans PC',
                          style: TextStyle(
                            fontSize: 12,
                            color: room.hasComputer ? Colors.purple : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Menu d'actions
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text('Voir détails'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Désactiver',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  final roomProvider = context.read<RoomProvider>();
                  
                  switch (value) {
                    case 'view':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailPage(roomId: room.id),
                        ),
                      );
                      break;
                    
                    case 'edit':
                      // TODO: Naviguer vers la page d'édition
                      break;
                    
                    case 'delete':
                      await _showConfirmationDialog(
                        context,
                        'Désactiver la salle',
                        'Voulez-vous vraiment désactiver la salle "${room.name}" ?',
                        () async {
                          try {
                            await roomProvider.deleteRoom(room.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Salle désactivée avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                      break;
                  }
                },
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestion des Salles',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filtrer',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final roomProvider = context.read<RoomProvider>();
              roomProvider.clearFilters();
            },
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      
      body: Consumer<RoomProvider>(
        builder: (context, roomProvider, child) {
          if (roomProvider.isLoading && roomProvider.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une salle...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              roomProvider.loadRooms();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              
              // Statistiques rapides
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      roomProvider.rooms.length.toString(),
                      Colors.blue,
                      Icons.meeting_room,
                    ),
                    _buildStatItem(
                      'Bâtiments',
                      roomProvider.buildingOptions.length.toString(),
                      Colors.purple,
                      Icons.business,
                    ),
                    _buildStatItem(
                      'Filtres',
                      roomProvider.selectedBuilding != null ||
                      roomProvider.selectedMinCapacity != null ||
                      roomProvider.hasComputerFilter != null
                          ? 'Actifs'
                          : 'Inactifs',
                      roomProvider.selectedBuilding != null ||
                      roomProvider.selectedMinCapacity != null ||
                      roomProvider.hasComputerFilter != null
                          ? Colors.orange
                          : Colors.grey,
                      roomProvider.selectedBuilding != null ||
                      roomProvider.selectedMinCapacity != null ||
                      roomProvider.hasComputerFilter != null
                          ? Icons.filter_alt
                          : Icons.filter_alt_off,
                    ),
                  ],
                ),
              ),
              
              // Liste des salles
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => roomProvider.loadRooms(),
                  child: roomProvider.rooms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.meeting_room_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                roomProvider.isSearching
                                    ? 'Aucune salle trouvée'
                                    : roomProvider.selectedBuilding != null ||
                                      roomProvider.selectedMinCapacity != null ||
                                      roomProvider.hasComputerFilter != null
                                        ? 'Aucune salle avec ces filtres'
                                        : 'Aucune salle',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              if (!roomProvider.isSearching &&
                                  roomProvider.selectedBuilding == null &&
                                  roomProvider.selectedMinCapacity == null &&
                                  roomProvider.hasComputerFilter == null)
                                const SizedBox(height: 8),
                              if (!roomProvider.isSearching &&
                                  roomProvider.selectedBuilding == null &&
                                  roomProvider.selectedMinCapacity == null &&
                                  roomProvider.hasComputerFilter == null)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CreateRoomPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Ajouter une salle'),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: roomProvider.rooms.length +
                            (roomProvider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == roomProvider.rooms.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: roomProvider.isLoadingMore
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton(
                                          onPressed: roomProvider.loadMoreRooms,
                                          child: const Text('Charger plus'),
                                        ),
                                ),
                              );
                            }
                            
                            final room = roomProvider.rooms[index];
                            return _buildRoomCard(context, room);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRoomPage(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}