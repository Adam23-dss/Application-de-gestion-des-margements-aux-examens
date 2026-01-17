import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/user_provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/data/models/user_model.dart';
import 'package:intl/intl.dart';

class CreateUserPage extends StatefulWidget {
  final UserModel? userToEdit;

  const CreateUserPage({super.key, this.userToEdit});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'supervisor';
  bool _isActive = true;
  bool _sendWelcomeEmail = false;
  bool _isLoading = false;
  bool _isEditing = false;

  final List<String> _roles = ['supervisor', 'admin', 'student'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.userToEdit != null;

    if (_isEditing) {
      _firstNameController.text = widget.userToEdit!.firstName;
      _lastNameController.text = widget.userToEdit!.lastName;
      _emailController.text = widget.userToEdit!.email;
      _selectedRole = widget.userToEdit!.role ?? 'supervisor';
      _isActive = widget.userToEdit!.isActive;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'supervisor':
        return 'Surveillant';
      case 'student':
        return 'Étudiant';
      default:
        return role;
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation du mot de passe si création
    if (!_isEditing) {
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez saisir un mot de passe'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les mots de passe ne correspondent pas'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le mot de passe doit faire au moins 6 caractères'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final authProvider = context.read<AuthProvider>();

      final userData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'first_name': _firstNameController.text.trim(), // snake_case
        'last_name': _lastNameController.text.trim(), // snake_case
        'role': _selectedRole,
        'is_active': _isActive, // snake_case
      };


      // Ajouter le mot de passe si création ou changement
      if (!_isEditing) {
        userData['password'] = _passwordController.text;
      } else if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text;
      }

      if (_isEditing) {
        // Vérifier les permissions
        if (!authProvider.user!.isAdmin &&
            widget.userToEdit!.id != authProvider.user!.id) {
          throw Exception(
            'Vous n\'êtes pas autorisé à modifier cet utilisateur',
          );
        }

        await userProvider.updateUser(widget.userToEdit!.id, userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await userProvider.createUser(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final canEditRole = authProvider.user?.isAdmin == true;

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Modifier Utilisateur' : 'Nouvel Utilisateur',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveUser,
            tooltip: 'Enregistrer',
          ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations personnelles
              _buildSectionTitle('Informations personnelles'),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        hintText: 'Ex: Jean',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir un prénom';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        hintText: 'Ex: Dupont',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir un nom';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'Ex: jean.dupont@universite.fr',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Veuillez saisir un email valide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Rôle et statut
              _buildSectionTitle('Rôle et statut'),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Sélectionner un rôle'),
                    ),
                    isExpanded: true,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_drop_down),
                    ),
                    items: _roles
                        .where((role) {
                          // Seuls les admins peuvent créer des admins
                          if (role == 'admin' && !canEditRole) {
                            return false;
                          }
                          return true;
                        })
                        .map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(_getRoleLabel(role)),
                            ),
                          );
                        })
                        .toList(),
                    onChanged: canEditRole
                        ? (value) {
                            if (value != null) {
                              setState(() => _selectedRole = value);
                            }
                          }
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Statut actif/inactif
              Row(
                children: [
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isActive ? 'Utilisateur actif' : 'Utilisateur inactif',
                    style: TextStyle(
                      color: _isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              if (!_isEditing) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _sendWelcomeEmail,
                      onChanged: (value) =>
                          setState(() => _sendWelcomeEmail = value ?? false),
                    ),
                    const SizedBox(width: 8),
                    const Text('Envoyer un email de bienvenue'),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Mot de passe
              _buildSectionTitle('Mot de passe'),

              if (_isEditing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Laissez vide pour conserver le mot de passe actuel',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Nouveau mot de passe'
                      : 'Mot de passe *',
                  hintText: 'Saisir le mot de passe',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                validator: !_isEditing
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir un mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Minimum 6 caractères';
                        }
                        return null;
                      }
                    : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Confirmer nouveau mot de passe'
                      : 'Confirmer mot de passe *',
                  hintText: 'Confirmer le mot de passe',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: !_isEditing
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez confirmer le mot de passe';
                        }
                        if (value != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      }
                    : null,
              ),

              const SizedBox(height: 32),

              // Informations
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditing
                                ? 'Vous modifiez le compte de ${_firstNameController.text} ${_lastNameController.text}'
                                : 'Un email de confirmation sera envoyé à l\'utilisateur',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (_selectedRole == 'supervisor')
                            const Text(
                              'Les surveillants peuvent valider les présences',
                              style: TextStyle(fontSize: 12),
                            ),
                          if (_selectedRole == 'admin')
                            const Text(
                              'Les administrateurs ont accès à toutes les fonctionnalités',
                              style: TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isEditing ? Icons.save : Icons.add),
                                const SizedBox(width: 12),
                                Text(
                                  _isEditing
                                      ? 'Mettre à jour'
                                      : 'Créer l\'utilisateur',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, size: 24),
                          SizedBox(width: 12),
                          Text('Annuler', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
