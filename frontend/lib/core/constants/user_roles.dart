class UserRole {
  static const String admin = 'ADMIN';
  static const String surveillant = 'SURVEILLANT';
  
  static String getRoleFromString(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return admin;
      case 'SURVEILLANT':
        return surveillant;
      default:
        return '';
    }
  }
  
  static bool isAdmin(String role) => role == admin;
  static bool isSurveillant(String role) => role == surveillant;
}