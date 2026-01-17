import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  
  // Nouveaux champs OPTIONNELS pour rester rétrocompatible
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

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
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('=== UserModel.fromJson ===');
    print('JSON keys: ${json.keys.toList()}');

    String? accessToken;
    String? refreshToken;
    String? tokenType;
    int? expiresIn;

    // Extraire les tokens si présents (CODE EXISTANT - NE PAS CHANGER)
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

    // CORRECTION CRITIQUE : Parse les nouveaux champs SEULEMENT s'ils existent
    DateTime? parseOptionalDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return null;
        }
      }
      if (dateValue is DateTime) return dateValue;
      return null;
    }

    // Les nouveaux champs sont OPTIONNELS
    final createdAt = parseOptionalDate(json['createdAt'] ?? json['created_at']);
    final updatedAt = parseOptionalDate(json['updatedAt'] ?? json['updated_at']);
    final lastLogin = parseOptionalDate(json['lastLogin'] ?? json['last_login']);

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
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLogin: lastLogin,
    );
  }

  // Méthode pour créer un UserModel à partir du stockage (sans tokens)
  factory UserModel.fromStorage(Map<String, dynamic> storageData) {
    DateTime? parseStorageDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }

    return UserModel(
      id: storageData['id']?.toInt() ?? 0,
      email: storageData['email']?.toString() ?? '',
      firstName: storageData['firstName']?.toString() ?? '',
      lastName: storageData['lastName']?.toString() ?? '',
      role: storageData['role']?.toString(),
      ufr: storageData['ufr']?.toString(),
      department: storageData['department']?.toString(),
      isActive: storageData['isActive'] ?? true,
      createdAt: parseStorageDate(storageData['createdAt']?.toString()),
      updatedAt: parseStorageDate(storageData['updatedAt']?.toString()),
      lastLogin: parseStorageDate(storageData['lastLogin']?.toString()),
      // Les tokens ne sont pas stockés dans les données utilisateur
      accessToken: null,
      refreshToken: null,
      tokenType: null,
      expiresIn: null,
    );
  }

  // Convertir en JSON pour le stockage (sans les tokens)
  Map<String, dynamic> toStorageJson() {
    final data = {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'ufr': ufr,
      'department': department,
      'isActive': isActive,
    };

    // Ajouter les dates seulement si elles existent
    if (createdAt != null) {
      data['createdAt'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      data['updatedAt'] = updatedAt!.toIso8601String();
    }
    if (lastLogin != null) {
      data['lastLogin'] = lastLogin!.toIso8601String();
    }

    return data;
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
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // ============================
  // GETTERS POUR L'UI (RÉTROCOMPATIBLES)
  // ============================

  String get fullName => '$firstName $lastName';

  bool get isAdmin => role?.toLowerCase() == 'admin';
  bool get isSupervisor => role?.toLowerCase() == 'supervisor';
  bool get isStudent => role?.toLowerCase() == 'student';

  // Vérifier si le token est valide (basique)
  bool get hasValidToken => accessToken != null && accessToken!.isNotEmpty;

  // Obtenir le bearer token pour les headers
  String? get bearerToken => accessToken != null ? 'Bearer $accessToken' : null;

  // Getters pour l'UI - TOUJOURS FONCTIONNELS même si les champs sont null
  String get statusLabel => isActive ? 'Actif' : 'Inactif';
  Color get statusColor => isActive ? Colors.green : Colors.red;
  IconData get statusIcon => isActive ? Icons.check_circle : Icons.cancel;
  
  String get roleLabel {
    switch (role?.toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'supervisor':
        return 'Surveillant';
      case 'student':
        return 'Étudiant';
      default:
        return role ?? 'Utilisateur';
    }
  }
  
  Color get roleColor {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'supervisor':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  IconData get roleIcon {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Icons.security;
      case 'supervisor':
        return Icons.supervised_user_circle;
      case 'student':
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  // Formatage des dates - safe avec les valeurs null
  String? get formattedCreatedAt => createdAt != null 
      ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt!) 
      : null;
  
  String? get formattedUpdatedAt => updatedAt != null 
      ? DateFormat('dd/MM/yyyy HH:mm').format(updatedAt!) 
      : null;
  
  String? get formattedLastLogin => lastLogin != null 
      ? DateFormat('dd/MM/yyyy HH:mm').format(lastLogin!) 
      : null;

  // Méthode utilitaire pour afficher une date ou "Non disponible"
  String safeFormattedDate(DateTime? date) {
    return date != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : 'Non disponible';
  }

  // Pour la création d'utilisateur (envoi vers backend)
  Map<String, dynamic> toCreateJson() {
    return {
      'email': email,
      'password': 'password', // À remplacer par un vrai mot de passe
      'first_name': firstName,
      'last_name': lastName,
      'role': role ?? 'supervisor',
      'ufr': ufr,
      'department': department,
      'is_active': isActive,
    };
  }

  // Pour la mise à jour d'utilisateur
  Map<String, dynamic> toUpdateJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'ufr': ufr,
      'department': department,
    };
  }

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, fullName: $fullName, role: $role, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}