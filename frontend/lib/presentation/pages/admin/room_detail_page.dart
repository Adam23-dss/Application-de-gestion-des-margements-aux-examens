// presentation/pages/admin/room_detail_page.dart
import 'package:flutter/material.dart';
import 'package:frontend1/presentation/pages/admin/edit_room_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/room_provider.dart';
import 'package:frontend1/data/models/room_model.dart';

class RoomDetailPage extends StatefulWidget {
  final int roomId;
  
  const RoomDetailPage({
    super.key,
    required this.roomId,
  });
  
  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  RoomModel? _room;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadRoom();
  }
  
  Future<void> _loadRoom() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final roomProvider = context.read<RoomProvider>();
      final room = await roomProvider.getRoomById(widget.roomId);
      
      setState(() {
        _room = room;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Widget _buildInfoCard({
    required String title,
    required String value,
    IconData? icon,
    Color? iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor ?? Colors.grey),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEquipmentBadge(bool hasComputer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasComputer ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasComputer ? Icons.computer : Icons.computer_outlined,
            size: 12,
            color: hasComputer ? Colors.purple : Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            hasComputer ? 'Avec ordinateurs' : 'Sans ordinateurs',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: hasComputer ? Colors.purple : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteRoom() async {
    if (_room == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver la salle'),
        content: Text(
          'Voulez-vous vraiment désactiver la salle "${_room!.name}" ? '
          'Cette salle ne sera plus disponible pour les examens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Désactiver',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final roomProvider = context.read<RoomProvider>();
        await roomProvider.deleteRoom(_room!.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salle désactivée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails de la salle',
        showBackButton: true,
        actions: _room != null
            ? [
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
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
                    PopupMenuItem(
                      value: _room!.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            _room!.isActive ? Icons.person_off : Icons.person_add,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(_room!.isActive ? 'Désactiver' : 'Activer'),
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
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditRoomPage(roomId: _room!.id),
                          ),
                        );
                        break;
                      case 'deactivate':
                      case 'activate':
                        _deleteRoom();
                        break;
                      case 'delete':
                        _deleteRoom();
                        break;
                    }
                  },
                ),
              ]
            : null,
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRoom,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _room == null
                  ? const Center(child: Text('Salle non trouvée'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: _room!.hasComputer
                                        ? Colors.purple.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _room!.hasComputer ? Icons.computer : Icons.meeting_room,
                                    size: 40,
                                    color: _room!.hasComputer ? Colors.purple : Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _room!.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _room!.code,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusBadge(_room!.isActive),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildEquipmentBadge(_room!.hasComputer),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Informations de la salle
                          const Text(
                            'Informations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInfoCard(
                            title: 'Code salle',
                            value: _room!.code,
                            icon: Icons.code,
                            iconColor: Colors.blue,
                          ),
                          
                          _buildInfoCard(
                            title: 'Nom',
                            value: _room!.name,
                            icon: Icons.meeting_room,
                            iconColor: Colors.green,
                          ),
                          
                          _buildInfoCard(
                            title: 'Bâtiment',
                            value: _room!.building as String,
                            icon: Icons.business,
                            iconColor: Colors.orange,
                          ),
                          
                          if (_room!.floor != null)
                            _buildInfoCard(
                              title: 'Étage',
                              value: 'Étage ${_room!.floor}',
                              icon: Icons.stairs,
                              iconColor: Colors.purple,
                            ),
                          
                          _buildInfoCard(
                            title: 'Capacité',
                            value: '${_room!.capacity} places',
                            icon: Icons.people,
                            iconColor: Colors.teal,
                          ),
                          
                          // Statut
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _room!.isActive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _room!.isActive ? Icons.check_circle : Icons.cancel,
                                      size: 20,
                                      color: _room!.isActive ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Statut',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _room!.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _room!.isActive ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          if (_room!.createdAt != null)
                            _buildInfoCard(
                              title: 'Date de création',
                              value: '${_room!.createdAt!.day}/${_room!.createdAt!.month}/${_room!.createdAt!.year}',
                              icon: Icons.calendar_today,
                              iconColor: Colors.indigo,
                            ),
                          
                          // Actions
                          const SizedBox(height: 32),
                          const Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    title: const Text('Modifier la salle'),
                                    subtitle: const Text('Modifier les informations de la salle'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditRoomPage(roomId: _room!.id),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  const Divider(height: 1),
                                  
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _room!.isActive
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _room!.isActive ? Icons.person_off : Icons.person_add,
                                        color: _room!.isActive ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      _room!.isActive ? 'Désactiver la salle' : 'Activer la salle',
                                      style: TextStyle(
                                        color: _room!.isActive ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _room!.isActive
                                          ? 'La salle ne sera plus disponible pour les examens'
                                          : 'La salle sera disponible pour les examens',
                                      style: TextStyle(
                                        color: _room!.isActive ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: _room!.isActive ? Colors.red : Colors.green,
                                    ),
                                    onTap: _deleteRoom,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
    );
  }
}