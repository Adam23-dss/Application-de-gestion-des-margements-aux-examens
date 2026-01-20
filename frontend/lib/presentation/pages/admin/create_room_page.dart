// presentation/pages/admin/create_room_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/room_provider.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  
  // Variables pour les dropdowns
  String _selectedBuilding = '';
  String _selectedCapacity = '30';
  String _selectedFloor = '0';
  
  // Équipement
  bool _hasComputer = false;
  
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
  
  final List<String> _floorOptions = ['0', '1', '2', '3', '4', '5'];
  final List<String> _capacityOptions = ['20', '30', '40', '50', '60', '80', '100', '150', '200'];

  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // Initialiser avec des valeurs par défaut
    _selectedFloor = _floorOptions.first;
    _selectedCapacity = _capacityOptions[1]; // 30 par défaut
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
  
  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedBuilding.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un bâtiment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final roomProvider = context.read<RoomProvider>();
      
      final roomData = {
        'code': _codeController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
        'building': _selectedBuilding,
        'floor': int.tryParse(_selectedFloor),
        'capacity': int.parse(_selectedCapacity),
        'has_computer': _hasComputer,
      };
      
      print('📤 Données de création: $roomData');
      
      final newRoom = await roomProvider.createRoom(roomData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salle "${newRoom.name}" créée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Retourner à la liste des salles
      Navigator.pop(context);
      
    } catch (e) {
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
        _isLoading = false;
      });
    }
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
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
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
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
    String? hint,
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
              if (hint != null)
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(
                    hint,
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
              hint ?? (required ? 'Sélectionnez...' : 'Non spécifié'),
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
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Créer une Salle',
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
                'Nouvelle salle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remplissez les informations de la nouvelle salle',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Code salle
              _buildTextField(
                label: 'Code salle',
                controller: _codeController,
                required: true,
                hintText: 'ex: A101, B205, LIB001',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le code salle est requis';
                  }
                  if (value.length < 2) {
                    return 'Le code doit contenir au moins 2 caractères';
                  }
                  return null;
                },
              ),
              
              // Nom salle
              _buildTextField(
                label: 'Nom de la salle',
                controller: _nameController,
                required: true,
                hintText: 'ex: Salle de conférence A, Amphithéâtre B',
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
                value: _selectedBuilding,
                items: _buildingOptions,
                required: true,
                hint: 'Sélectionnez un bâtiment',
                onChanged: (value) {
                  setState(() {
                    _selectedBuilding = value ?? '';
                  });
                },
              ),
              
              // Étage
              _buildDropdown(
                label: 'Étage',
                value: _selectedFloor,
                items: _floorOptions,
                hint: 'Sélectionnez l\'étage',
                onChanged: (value) {
                  setState(() {
                    _selectedFloor = value ?? '0';
                  });
                },
              ),
              
              // Aide pour l'étage
              if (_selectedFloor == '0')
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
                          'Étage 0 = Rez-de-chaussée',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Capacité
              _buildDropdown(
                label: 'Capacité',
                value: _selectedCapacity,
                items: _capacityOptions,
                required: true,
                hint: 'Sélectionnez la capacité',
                onChanged: (value) {
                  setState(() {
                    _selectedCapacity = value ?? '30';
                  });
                },
              ),
              
              // Équipement informatique
              SwitchListTile(
                title: const Text('Équipement informatique'),
                subtitle: const Text('La salle est équipée d\'ordinateurs pour les examens'),
                value: _hasComputer,
                onChanged: (value) {
                  setState(() {
                    _hasComputer = value;
                  });
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              
              // Note sur les salles avec ordinateurs
              if (_hasComputer)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.computer, color: Colors.purple[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cette salle sera disponible pour les examens nécessitant des ordinateurs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Exemple de salle créée
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exemple de salle créée :',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_codeController.text.isNotEmpty ? _codeController.text.toUpperCase() : "A101"} - ${_nameController.text.isNotEmpty ? _nameController.text : "Salle de conférence"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedBuilding.isNotEmpty ? _selectedBuilding : "Bâtiment A"}${_selectedFloor != "0" ? ', Étage $_selectedFloor' : ', Rez-de-chaussée'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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
                          '$_selectedCapacity places',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          _hasComputer ? Icons.computer : Icons.computer_outlined,
                          size: 12,
                          color: _hasComputer ? Colors.purple : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _hasComputer ? 'Avec PC' : 'Sans PC',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hasComputer ? Colors.purple : Colors.grey,
                          ),
                        ),
                      ],
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
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                      onPressed: _isLoading ? null : _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
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
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text('Créer'),
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