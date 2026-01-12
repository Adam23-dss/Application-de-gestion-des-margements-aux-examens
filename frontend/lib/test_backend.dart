import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== Testing Backend Connection ===\n');
  
  final client = HttpClient();
  
  try {
    // Test 1: Test endpoint
    print('1. Testing /api/test endpoint...');
    final testResponse = await client.getUrl(
      Uri.parse('https://application-de-gestion-des-margements.onrender.com/api/test'),
    );
    final testResult = await testResponse.close();
    final testBody = await testResult.transform(utf8.decoder).join();
    print('   Status: ${testResult.statusCode}');
    print('   Body: $testBody');
    
    print('\n2. Testing login endpoint...');
    final loginRequest = await client.postUrl(
      Uri.parse('https://application-de-gestion-des-margements.onrender.com/api/auth/login'),
    );
    
    loginRequest.headers.set('Content-Type', 'application/json');
    loginRequest.write(json.encode({
      'email': 'surveillant@univ.fr',
      'password': 'password123',
    }));
    
    final loginResponse = await loginRequest.close();
    final loginBody = await loginResponse.transform(utf8.decoder).join();
    
    print('   Status: ${loginResponse.statusCode}');
    print('   Body: ${loginBody.substring(0, min(500, loginBody.length))}');
    
    // Parse the response
    final loginData = json.decode(loginBody);
    if (loginData['success'] == true) {
      final tokens = loginData['data']['tokens'];
      print('\n3. Token found:');
      print('   Access Token length: ${tokens['accessToken']?.toString().length ?? 0}');
      print('   Refresh Token length: ${tokens['refreshToken']?.toString().length ?? 0}');
      print('   First 50 chars of access token: ${tokens['accessToken']?.toString().substring(0, min(50, tokens['accessToken']?.toString().length ?? 0))}');
    }
    
  } catch (e) {
    print('\n❌ Error: $e');
  } finally {
    client.close();
  }
  
  print('\n=== Test Complete ===');
}

int min(int a, int b) => a < b ? a : b;