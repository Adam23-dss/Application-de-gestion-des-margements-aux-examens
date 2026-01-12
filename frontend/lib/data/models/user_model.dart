import 'dart:convert';

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
  
  factory UserModel.fromJson(dynamic jsonData) {
    print('=== UserModel.fromJson ===');
    
    // Si la réponse est vide, utiliser des valeurs par défaut
    if (jsonData == null || 
        (jsonData is String && jsonData.isEmpty) ||
        (jsonData is Map && jsonData.isEmpty)) {
      print('⚠️ Empty or null response, using defaults');
      return UserModel._default();
    }
    
    // Convertir en Map
    Map<String, dynamic> jsonMap = {};
    
    if (jsonData is String) {
      try {
        final decoded = json.decode(jsonData);
        if (decoded is Map) {
          jsonMap = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        print('⚠️ Could not parse string as JSON: $e');
        return UserModel._default();
      }
    } else if (jsonData is Map) {
      jsonMap = Map<String, dynamic>.from(jsonData);
    }
    
    print('JSON keys found: ${jsonMap.keys.toList()}');
    
    // Essayer plusieurs structures
    Map<String, dynamic> userData = {};
    String accessToken = '';
    
    // Structure 1: {data: {user: {...}, tokens: {...}}}
    if (jsonMap.containsKey('data') && jsonMap['data'] is Map) {
      final data = jsonMap['data'] as Map<String, dynamic>;
      
      if (data.containsKey('user') && data['user'] is Map) {
        userData = Map<String, dynamic>.from(data['user'] as Map);
      }
      
      if (data.containsKey('tokens') && data['tokens'] is Map) {
        final tokens = data['tokens'] as Map<String, dynamic>;
        accessToken = tokens['access']?.toString() ?? '';
      }
    }
    // Structure 2: Direct fields
    else {
      userData = jsonMap;
      accessToken = jsonMap['token']?.toString() ?? 
                   jsonMap['accessToken']?.toString() ?? '';
    }
    
    // Si userData est vide, utiliser jsonMap
    if (userData.isEmpty) {
      userData = jsonMap;
    }
    
    // Extraire les valeurs
    final id = userData['id']?.toString() ?? 
               userData['_id']?.toString() ?? 
               'default_${DateTime.now().millisecondsSinceEpoch}';
    
    final firstName = userData['first_name']?.toString() ?? 
                     userData['firstName']?.toString() ?? 
                     'User';
    
    final lastName = userData['last_name']?.toString() ?? 
                    userData['lastName']?.toString() ?? 
                    '';
    
    final email = userData['email']?.toString() ?? 'user@example.com';
    final role = (userData['role']?.toString() ?? 'USER').toUpperCase();
    
    // Si aucun token n'a été trouvé, en créer un factice pour le test
    if (accessToken.isEmpty) {
      print('⚠️ No access token found, using test token');
      accessToken = 'test_token_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    print('✅ Created user: $firstName $lastName ($email) - Role: $role');
    
    return UserModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: role,
      ufr: userData['ufr']?.toString(),
      department: userData['department']?.toString(),
      isActive: true,
      accessToken: accessToken,
      refreshToken: '',
    );
  }
  
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