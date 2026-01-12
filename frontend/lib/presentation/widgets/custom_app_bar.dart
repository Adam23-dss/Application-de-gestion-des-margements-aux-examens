import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showLogout;
  
  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.onBackPressed,
    this.showLogout = false,
  });
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    List<Widget> appBarActions = actions ?? [];
    
    // Ajouter le bouton de déconnexion si demandé
    if (showLogout) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            // Afficher une boîte de dialogue de confirmation
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Déconnexion'),
                content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Déconnexion'),
                  ),
                ],
              ),
            );
            
            if (confirm == true) {
              await authProvider.logout(context: context);
            }
          },
          tooltip: 'Déconnexion',
        ),
      );
    }
    
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
              tooltip: 'Retour',
            )
          : null,
      actions: appBarActions.isNotEmpty ? appBarActions : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
    );
  }
}