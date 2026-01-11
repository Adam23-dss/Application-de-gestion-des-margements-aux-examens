class AppConstants {
  // URLs du backend
  static const String baseUrl = 'https://application-de-gestion-des-margements.onrender.com';
  static const String wsUrl = 'wss://application-de-gestion-des-margements.onrender.com';
  
  // Comptes de test
  static const Map<String, String> testAccounts = {
    'admin': 'admin@univ.fr',
    'supervisor': 'surveillant@univ.fr',
    'password': 'password123',
  };
  
  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String authUserKey = 'auth_user';
  
  // Durées
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration snackbarDuration = Duration(seconds: 3);
}