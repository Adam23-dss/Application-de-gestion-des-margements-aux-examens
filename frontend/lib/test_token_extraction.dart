// import 'package:frontend1/data/models/user_model.dart';
// import 'package:frontend1/test_backend.dart';

// void main() {
//   print('=== Testing Token Extraction ===\n');
  
//   // Simuler la réponse API exacte
//   final apiResponse = {
//     "success": true,
//     "message": "Connexion réussie",
//     "data": {
//       "user": {
//         "id": 2,
//         "email": "surveillant@univ.fr",
//         "firstName": "Jean",
//         "lastName": "Dupont",
//         "fullName": "Jean Dupont",
//         "role": "supervisor",
//         "ufr": "Sciences",
//         "department": "Mathématiques",
//         "isActive": true,
//         "lastLogin": "2026-01-12T17:12:34.423Z",
//         "createdAt": "2025-12-30T15:49:47.696Z",
//         "updatedAt": "2026-01-12T17:12:34.423Z"
//       },
//       "tokens": {
//         "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwiZW1haWwiOiJzdXJ2ZWlsbGFudEB1bml2LmZyIiwicm9sZSI6InN1cGVydmlzb3IiLCJ1ZnIiOiJTY2llbmNlcyIsImRlcGFydG1lbnQiOiJNYXRow6ltYXRpcXVlcyIsImlhdCI6MTc2ODIzNzk1NCwiZXhwIjoxNzY4MzI0MzU0fQ.tFIGX38ACcTSy7Mud1GhqqcuSNEnPc56xCy88hQtSE4",
//         "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwiaWF0IjoxNzY4MjM3OTU0LCJleHAiOjE3Njg4NDI3NTR9.j2yQdp2IhlmU7SpCHCL8yL4_ADdd7quzKO4Cu-D_Jw4",
//         "tokenType": "Bearer",
//         "expiresIn": "24h"
//       }
//     }
//   };
  
//   print('1. Testing UserModel.fromJson...');
//   try {
//     final user = UserModel.fromJson(apiResponse);
//     print('✅ User parsed successfully:');
//     print('   Name: ${user.fullName}');
//     print('   Role: ${user.role}');
//     print('   Access token length: ${user..length}');
//     print('   Access token (first 50): ${user.accessToken.substring(0, min(50, user.accessToken.length))}...');
    
//     if (user.accessToken.isEmpty) {
//       print('❌ ERROR: Access token is empty!');
//     }
//   } catch (e) {
//     print('❌ ERROR: $e');
//   }
// }