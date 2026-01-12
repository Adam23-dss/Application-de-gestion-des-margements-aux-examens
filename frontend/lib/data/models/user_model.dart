import 'dart:convert';

class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? role;
  final String? ufr;
  final String? department;
  final bool isActive;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final int? expiresIn;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role,
    this.ufr,
    this.department,
    required this.isActive,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiresIn,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('=== UserModel.fromJson ===');
    print('JSON keys: ${json.keys.toList()}');

    String? accessToken;
    String? refreshToken;
    String? tokenType;
    int? expiresIn;

    // Extraire les tokens si présents
    if (json.containsKey('accessToken')) {
      accessToken = json['accessToken']?.toString();
    } else if (json.containsKey('access_token')) {
      accessToken = json['access_token']?.toString();
    } else if (json.containsKey('token')) {
      accessToken = json['token']?.toString();
    }

    if (json.containsKey('refreshToken')) {
      refreshToken = json['refreshToken']?.toString();
    } else if (json.containsKey('refresh_token')) {
      refreshToken = json['refresh_token']?.toString();
    }

    if (json.containsKey('tokenType')) {
      tokenType = json['tokenType']?.toString();
    } else if (json.containsKey('token_type')) {
      tokenType = json['token_type']?.toString();
    }

    // CORRECTION ICI : Gérer le cas où expiresIn pourrait être une String
    if (json.containsKey('expiresIn')) {
      final expiresInValue = json['expiresIn'];
      if (expiresInValue is int) {
        expiresIn = expiresInValue;
      } else if (expiresInValue is String) {
        expiresIn = int.tryParse(expiresInValue);
      } else if (expiresInValue is num) {
        expiresIn = expiresInValue.toInt();
      }
    } else if (json.containsKey('expires_in')) {
      final expiresInValue = json['expires_in'];
      if (expiresInValue is int) {
        expiresIn = expiresInValue;
      } else if (expiresInValue is String) {
        expiresIn = int.tryParse(expiresInValue);
      } else if (expiresInValue is num) {
        expiresIn = expiresInValue.toInt();
      }
    }

    // Si les tokens sont dans un sous-objet 'tokens'
    if (json.containsKey('tokens') && json['tokens'] is Map<String, dynamic>) {
      final tokens = json['tokens'] as Map<String, dynamic>;
      print('✅ Found tokens object');
      print('🔑 Tokens keys: ${tokens.keys.toList()}');

      if (tokens.containsKey('accessToken')) {
        accessToken = tokens['accessToken']?.toString();
      } else if (tokens.containsKey('access_token')) {
        accessToken = tokens['access_token']?.toString();
      }

      if (tokens.containsKey('refreshToken')) {
        refreshToken = tokens['refreshToken']?.toString();
      } else if (tokens.containsKey('refresh_token')) {
        refreshToken = tokens['refresh_token']?.toString();
      }

      if (tokens.containsKey('tokenType')) {
        tokenType = tokens['tokenType']?.toString();
      } else if (tokens.containsKey('token_type')) {
        tokenType = tokens['token_type']?.toString();
      }

      // CORRECTION ICI aussi pour le sous-objet tokens
      if (tokens.containsKey('expiresIn')) {
        final expiresInValue = tokens['expiresIn'];
        if (expiresInValue is int) {
          expiresIn = expiresInValue;
        } else if (expiresInValue is String) {
          expiresIn = int.tryParse(expiresInValue);
        } else if (expiresInValue is num) {
          expiresIn = expiresInValue.toInt();
        }
      } else if (tokens.containsKey('expires_in')) {
        final expiresInValue = tokens['expires_in'];
        if (expiresInValue is int) {
          expiresIn = expiresInValue;
        } else if (expiresInValue is String) {
          expiresIn = int.tryParse(expiresInValue);
        } else if (expiresInValue is num) {
          expiresIn = expiresInValue.toInt();
        }
      }
    }

    print('🔑 Access token present: ${accessToken != null}');
    if (accessToken != null) {
      print(
        '🔑 Access token first 20 chars: ${accessToken!.substring(0, accessToken!.length > 20 ? 20 : accessToken!.length)}...',
      );
    }

    // CORRECTION pour gérer les IDs qui pourraient être des strings
    int? id;
    final idValue = json['id'];
    if (idValue is int) {
      id = idValue;
    } else if (idValue is String) {
      id = int.tryParse(idValue);
    } else if (idValue is num) {
      id = idValue.toInt();
    }

    return UserModel(
      id: id ?? 0,
      email: json['email']?.toString() ?? '',
      firstName:
          json['firstName']?.toString() ?? json['first_name']?.toString() ?? '',
      lastName:
          json['lastName']?.toString() ?? json['last_name']?.toString() ?? '',
      role: json['role']?.toString(),
      ufr: json['ufr']?.toString(),
      department: json['department']?.toString(),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
    );
  }

  // Méthode pour créer un UserModel à partir du stockage (sans tokens)
  factory UserModel.fromStorage(Map<String, dynamic> storageData) {
    return UserModel(
      id: storageData['id']?.toInt() ?? 0,
      email: storageData['email']?.toString() ?? '',
      firstName: storageData['firstName']?.toString() ?? '',
      lastName: storageData['lastName']?.toString() ?? '',
      role: storageData['role']?.toString(),
      ufr: storageData['ufr']?.toString(),
      department: storageData['department']?.toString(),
      isActive: storageData['isActive'] ?? true,
      // Les tokens ne sont pas stockés dans les données utilisateur
      accessToken: null,
      refreshToken: null,
      tokenType: null,
      expiresIn: null,
    );
  }

  // Convertir en JSON pour le stockage (sans les tokens)
  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'ufr': ufr,
      'department': department,
      'isActive': isActive,
    };
  }

  // Convertir en JSON complet (avec tokens)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'ufr': ufr,
      'department': department,
      'isActive': isActive,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
    };
  }

  // Méthode pour copier avec nouveaux tokens
  UserModel copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? ufr,
    String? department,
    bool? isActive,
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      ufr: ufr ?? this.ufr,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }

  String get fullName => '$firstName $lastName';

  bool get isAdmin => role?.toLowerCase() == 'admin';
  bool get isSupervisor => role?.toLowerCase() == 'supervisor';

  // Vérifier si le token est valide (basique)
  bool get hasValidToken => accessToken != null && accessToken!.isNotEmpty;

  // Obtenir le bearer token pour les headers
  String? get bearerToken => accessToken != null ? 'Bearer $accessToken' : null;

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, fullName: $fullName, role: $role, hasToken: ${accessToken != null}}';
  }
}
