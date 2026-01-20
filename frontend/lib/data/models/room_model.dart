import 'package:frontend1/core/constants/api_endpoints.dart';

class RoomModel {
  final int id;
  final String code;
  final String name;
  final String? building;
  final int? floor;
  final int capacity;
  final bool hasComputer;
  final bool isActive;
  final DateTime? createdAt;

  RoomModel({
    required this.id,
    required this.code,
    required this.name,
    this.building,
    this.floor,
    required this.capacity,
    required this.hasComputer,
    required this.isActive,
    this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      building: json['building']?.toString(),
      floor: json['floor'] as int?,
      capacity: json['capacity'] ?? 0,
      hasComputer: json['has_computer'] ?? false,
      isActive: json['is_active'] ?? true,
       createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'building': building,
      'floor': floor,
      'capacity': capacity,
      'has_computer': hasComputer,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
  
   String get formattedInfo {
    return '$code - $name ($building${floor != null ? ', Étage $floor' : ''})';
  }
  

  String get location {
    if (building != null && floor != null) {
      return '$building - Étage $floor';
    } else if (building != null) {
      return building!;
    }
    return 'Non spécifié';
  }

  String get capacityInfo {
    return '$capacity places';
  }

   String get computerInfo {
    return hasComputer ? 'Avec ordinateurs' : 'Sans ordinateurs';
  }
}

class RoomResponse {
  final List<RoomModel> rooms;
  final PaginationData pagination;
  
  RoomResponse({required this.rooms, required this.pagination});
}

