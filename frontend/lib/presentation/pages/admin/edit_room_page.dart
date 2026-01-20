// presentation/pages/admin/edit_room_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/room_provider.dart';
import 'package:frontend1/data/models/room_model.dart';

class EditRoomPage extends StatefulWidget {
  final int roomId;
  
  const EditRoomPage({
    super.key,
    required this.roomId,
  });
  
  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  final _formKey = GlobalKey<FormState>();
  late RoomModel _room;
  
  // Contrôleurs
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _capacityController;
  
  // Variables
  bool _hasComputer = false;
  bool _isActive = true;
  
  // Données pour les dropdowns
  final List<String> _buildingOptions = [
    'Bâtiment A',
    'Bâtiment B', 
    'Bâtiment C',
    'Bâtiment D',
    'Bâtiment E',
    'Bâtiment F',
    'Bibliothèque',
    'Amphithéâtre Principal',
    'Centre Informatique',
  ];
  
  final List<int> _floorOptions = [0, 1, 2, 3, 4, 5];
  final List<int> _capacityOptions = [20, 30, 40, 50, 60, 80, 100, 150, 200];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadRoom();
  }
  
  Future<void> _loadRoom() async {
    try {
      final roomProvider = context.read<RoomProvider>();
      final room = await roomProvider.getRoomById(widget.roomId);
      
      if (room == null) {
        throw Exception('Salle non trouvée');
      }
      
      setState(() {
        _room = room;
        
        // Initialiser les contrôleurs
        _codeController = TextEditingController(text: room.code);
        _nameController = TextEditingController(text: room.name);
        _buildingController = TextEditingController(text: room.building);
        _floorController = TextEditingController(text: room.floor?.toString() ?? '');
        _capacityController = TextEditingController(text: room.capacity.toString());
        
        // Initialiser les variables
        _hasComputer = room.hasComputer;
        _isActive = room.isActive;
        
        _isLoading = false;
      });
      
      print('🎯 Salle chargée:');
      print('  Bâtiment: ${_room.building}');
      print('  Capacité: ${_room.capacity}');
      
    } catch (e) {
      print('❌ Erreur chargement salle: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
  
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final roomProvider = context.read<RoomProvider>();
      
      final roomData = {
        'name': _nameController.text.trim(),
        'building': _buildingController.text.trim(),
        if (_floorController.text.isNotEmpty) 'floor': int.tryParse(_floorController.text),
        'capacity': int.parse(_capacityController.text),
        'has_computer': _hasComputer,
      };
      
      print('📤 Données envoyées: $roomData');
      
      final updatedRoom = await roomProvider.updateRoom(
        widget.roomId,
        roomData,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salle "${updatedRoom.name}" mise à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      setState(() {
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    bool readOnly = false,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator ?? (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'Ce champ est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: value.isEmpty ? null : value,
            items: [
              DropdownMenuItem<String>(
                value: '',
                child: Text(
                  required ? 'Sélectionnez...' : 'Non spécifié',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
              ...items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ],
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            hint: Text(
              required ? 'Sélectionnez...' : 'Non spécifié',
              style: TextStyle(color: Colors.grey[500]),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildNumberDropdown({
    required String label,
    required String value,
    required List<int> items,
    required Function(String?) onChanged,
    bool required = false,
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: value.isEmpty ? null : value,
            items: [
              DropdownMenuItem<String>(
                value: '',
                child: Text(
                  required ? 'Sélectionnez...' : 'Non spécifié',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
              ...items.map((item) {
                return DropdownMenuItem<String>(
                  value: item.toString(),
                  child: Text('$item$suffix'),
                );
              }).toList(),
            ],
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            hint: Text(
              required ? 'Sélectionnez...' : 'Non spécifié',
              style: TextStyle(color: Colors.grey[500]),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Modifier la salle',
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Modifier la salle',
          showBackButton: true,
        ),
        body: Center(
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
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRoom,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Modifier la salle',
        showBackButton: true,
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Modifier les informations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mettez à jour les informations de la salle',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Code salle (lecture seule)
              _buildTextField(
                label: 'Code salle',
                controller: _codeController,
                readOnly: true,
                hintText: 'ex: A101',
              ),
              
              // Nom salle
              _buildTextField(
                label: 'Nom de la salle',
                controller: _nameController,
                required: true,
                hintText: 'ex: Salle de conférence A',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom de la salle est requis';
                  }
                  return null;
                },
              ),
              
              // Bâtiment
              _buildDropdown(
                label: 'Bâtiment',
                value: _buildingController.text,
                items: _buildingOptions,
                required: true,
                onChanged: (value) {
                  setState(() {
                    _buildingController.text = value ?? '';
                  });
                },
              ),
              
              // Étage
              _buildNumberDropdown(
                label: 'Étage',
                value: _floorController.text,
                items: _floorOptions,
                suffix: _floorController.text == '0' ? ' (Rez-de-chaussée)' : '',
                onChanged: (value) {
                  setState(() {
                    _floorController.text = value ?? '';
                  });
                },
              ),
              
              // Capacité
              _buildNumberDropdown(
                label: 'Capacité',
                value: _capacityController.text,
                items: _capacityOptions,
                suffix: ' places',
                required: true,
                onChanged: (value) {
                  setState(() {
                    _capacityController.text = value ?? '';
                  });
                },
              ),
              
              // Équipement informatique
              SwitchListTile(
                title: const Text('Équipement informatique'),
                subtitle: const Text('La salle est équipée d\'ordinateurs'),
                value: _hasComputer,
                onChanged: (value) {
                  setState(() {
                    _hasComputer = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
              
              // Statut actif
              SwitchListTile(
                title: const Text('Salle active'),
                subtitle: const Text('La salle est disponible pour les examens'),
                value: _isActive,
                onChanged: null, // Le statut ne peut être changé que via suppression
                activeColor: AppColors.primary,
              ),
              
              // Note sur le statut
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pour désactiver/activer la salle, utilisez le bouton "Désactiver" dans la page de détails.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Message d'erreur
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 20),
                                SizedBox(width: 8),
                                Text('Enregistrer'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}