import 'dart:math';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? ufr;
  final String? department;
  final bool isActive;
  final String accessToken;
  final String refreshToken;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.ufr,
    this.department,
    required this.isActive,
    required this.accessToken,
    required this.refreshToken,
  });

  String get fullName => '$firstName $lastName';
  String get token => accessToken;

  factory UserModel.fromJson(Map<String, dynamic> json) {
  print('=== UserModel.fromJson ===');
  print('JSON keys: ${json.keys.toList()}');
  
  // Extraire les données selon la structure du backend
  final data = json['data'];
  if (data == null) {
    print('❌ ERROR: No "data" key in response');
    throw Exception('Invalid response format: missing "data" key');
  }
  
  final userData = data['user'];
  if (userData == null) {
    print('❌ ERROR: No "user" key in data');
    throw Exception('Invalid response format: missing "user" key');
  }
  
  final tokens = data['tokens'] ?? {};
  print('✅ Found user data and tokens');
  print('Tokens keys: ${tokens.keys.toList()}');
  
  // Extraire les informations utilisateur
  final id = userData['id']?.toString() ?? '';
  
  final firstName = userData['firstName']?.toString() ?? '';
  final lastName = userData['lastName']?.toString() ?? '';
  
  final email = userData['email']?.toString() ?? '';
  final role = userData['role']?.toString() ?? '';
  final ufr = userData['ufr']?.toString();
  final department = userData['department']?.toString();
  
  final isActive = userData['isActive'] == true ||
                   userData['isActive']?.toString() == 'true';
  
  // IMPORTANT: Dans votre API, c'est "accessToken" avec un T majuscule
  final accessToken = tokens['accessToken']?.toString() ?? '';
  
  final refreshToken = tokens['refreshToken']?.toString() ?? '';
  
  if (accessToken.isEmpty) {
    print('❌ ERROR: Access token is empty');
    print('Available tokens: $tokens');
    throw Exception('No access token received');
  }
  
  print('✅ Parsed user:');
  print('   ID: $id');
  print('   Name: $firstName $lastName');
  print('   Email: $email');
  print('   Role: $role');
  print('   UFR: $ufr');
  print('   Department: $department');
  print('   Access token present: ${accessToken.isNotEmpty}');
  print('   Access token first 20 chars: ${accessToken.substring(0, accessToken.length < 20 ? accessToken.length : 20)}...');
  
  return UserModel(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    role: role.toUpperCase(),
    ufr: ufr,
    department: department,
    isActive: isActive,
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}

int min(int a, int b) => a < b ? a : b;

  // Constructeur pour un utilisateur par défaut
  UserModel._default()
    : id = 'default_user',
      firstName = 'Default',
      lastName = 'User',
      email = 'default@example.com',
      role = 'USER',
      ufr = null,
      department = null,
      isActive = true,
      accessToken = 'default_token',
      refreshToken = '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role,
      'ufr': ufr,
      'department': department,
      'is_active': isActive,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isSurveillant => role == 'SURVEILLANT' || role == 'SUPERVISOR';

  @override
  String toString() {
    return 'UserModel(name: $fullName, email: $email, role: $role)';
  }
}
