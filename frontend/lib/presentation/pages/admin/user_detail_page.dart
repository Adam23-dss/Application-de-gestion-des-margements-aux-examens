import 'package:flutter/material.dart';
import 'package:frontend1/data/repositories/user_repository.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/user_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/data/models/user_model.dart';
import 'package:frontend1/presentation/pages/admin/create_user_page.dart';
import 'package:intl/intl.dart';

class UserDetailPage extends StatefulWidget {
  final int userId;
  
  const UserDetailPage({
    super.key,
    required this.userId,
  });
  
  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  UserModel? _user;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    try {
      final userProvider = context.read<UserProvider>();
      final _repository = UserRepository();
      _user = await _repository.getUserById(widget.userId);
    } catch (e) {
      print('❌ Error loading user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _toggleUserStatus() async {
    if (_user == null) return;
    
    final userProvider = context.read<UserProvider>();
    final newStatus = !_user!.isActive;
    // 
    try {
      await userProvider.toggleUserStatus(_user!.id, newStatus);
      setState(() {
        _user = _user!.copyWith(isActive: newStatus);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Utilisateur activé avec succès'
                : 'Utilisateur désactivé avec succès',
          ),
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
  }
  
  Future<void> _deleteUser() async {
    if (_user == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cet utilisateur ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final userProvider = context.read<UserProvider>();
        await userProvider.deleteUser(_user!.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur supprimé avec succès'),
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
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Chargement...',
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_user == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Utilisateur non trouvé',
          showBackButton: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Utilisateur non trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails Utilisateur',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUser,
            tooltip: 'Actualiser',
          ),
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
                value: _user!.isActive ? 'deactivate' : 'activate',
                child: Row(
                  children: [
                    Icon(
                      _user!.isActive ? Icons.person_off : Icons.person_add,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_user!.isActive ? 'Désactiver' : 'Activer'),
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
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateUserPage(userToEdit: _user),
                    ),
                  );
                  break;
                case 'activate':
                case 'deactivate':
                  await _toggleUserStatus();
                  break;
                case 'delete':
                  await _deleteUser();
                  break;
              }
            },
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête avec avatar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: _user!.statusColor.withOpacity(0.1),
                      child: Icon(
                        _user!.roleIcon,
                        size: 60,
                        color: _user!.statusColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user!.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user!.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _user!.roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _user!.roleLabel,
                            style: TextStyle(
                              color: _user!.roleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _user!.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _user!.statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _user!.statusLabel,
                                style: TextStyle(
                                  color: _user!.statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informations détaillées
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoRow('ID', _user!.id.toString()),
                    _buildInfoRow('Nom complet', _user!.fullName),
                    _buildInfoRow('Email', _user!.email),
                    _buildInfoRow('Rôle', _user!.roleLabel),
                    _buildInfoRow('Statut', _user!.statusLabel),
                    _buildInfoRow(
                      'Date de création',
                      DateFormat('dd/MM/yyyy HH:mm').format(_user!.createdAt as DateTime),
                    ),
                    if (_user!.lastLogin != null)
                      _buildInfoRow(
                        'Dernière connexion',
                        DateFormat('dd/MM/yyyy HH:mm').format(_user!.lastLogin!),
                      ),
                    _buildInfoRow(
                      'Dernière mise à jour',
                      DateFormat('dd/MM/yyyy HH:mm').format(_user!.updatedAt as DateTime),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions rapides
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          Icons.edit,
                          'Modifier',
                          Colors.blue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateUserPage(userToEdit: _user),
                              ),
                            );
                          },
                        ),
                        _buildActionButton(
                          _user!.isActive ? Icons.person_off : Icons.person_add,
                          _user!.isActive ? 'Désactiver' : 'Activer',
                          _user!.isActive ? Colors.orange : Colors.green,
                          _toggleUserStatus,
                        ),
                        _buildActionButton(
                          Icons.delete,
                          'Supprimer',
                          Colors.red,
                          _deleteUser,
                        ),
                        _buildActionButton(
                          Icons.mail,
                          'Envoyer email',
                          Colors.purple,
                          () {
                            // TODO: Implémenter l'envoi d'email
                          },
                        ),
                        _buildActionButton(
                          Icons.reset_tv,
                          'Réinitialiser mot de passe',
                          Colors.teal,
                          () {
                            // TODO: Implémenter la réinitialisation
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistiques (si applicable)
            if (_user!.role == 'supervisor' || _user!.role == 'student')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistiques',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (_user!.role == 'supervisor') ...[
                            _buildStatCard('Examens', '0', Icons.event, Colors.blue),
                            _buildStatCard('Présences validées', '0', Icons.check_circle, Colors.green),
                          ] else if (_user!.role == 'student') ...[
                            _buildStatCard('Examens passés', '0', Icons.school, Colors.purple),
                            _buildStatCard('Présences', '0', Icons.check, Colors.orange),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}