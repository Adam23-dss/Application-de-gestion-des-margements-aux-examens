import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== Testing API directly ===\n');
  
  final client = HttpClient();
  
  try {
    final request = await client.postUrl(
      Uri.parse('https://application-de-gestion-des-margements.onrender.com/api/auth/login'),
    );
    
    request.headers
      ..set('Content-Type', 'application/json')
      ..set('Accept', 'application/json');
    
    final body = json.encode({
      'email': 'admin@univ.fr',
      'password': 'password123',
    });
    
    print('Request body: $body');
    request.write(body);
    
    final response = await request.close();
    
    print('\nResponse Status: ${response.statusCode}');
    print('Response Headers:');
    response.headers.forEach((name, values) {
      print('  $name: $values');
    });
    
    // Lire la réponse
    final responseBytes = await response.fold<List<int>>([], (list, data) {
      list.addAll(data);
      return list;
    });
    
    final responseString = utf8.decode(responseBytes);
    
    print('\nResponse body length: ${responseString.length} bytes');
    print('Response body (raw): "$responseString"');
    
    if (responseString.isEmpty) {
      print('\n⚠️ WARNING: Response body is empty!');
    } else {
      print('\nTrying to parse as JSON...');
      try {
        final jsonData = json.decode(responseString);
        print('✅ Successfully parsed JSON');
        print('JSON structure:');
        _printJson(jsonData);
      } catch (e) {
        print('❌ Failed to parse JSON: $e');
      }
    }
    
  } catch (e, stackTrace) {
    print('\n❌ Exception: $e');
    print('Stack trace: $stackTrace');
  } finally {
    client.close();
  }
  
  print('\n=== Test completed ===');
}

void _printJson(dynamic data, [int indent = 0]) {
  final spaces = '  ' * indent;
  
  if (data is Map) {
    data.forEach((key, value) {
      if (value is Map || value is List) {
        print('$spaces$key:');
        _printJson(value, indent + 1);
      } else {
        print('$spaces$key: $value (${value.runtimeType})');
      }
    });
  } else if (data is List) {
    for (var i = 0; i < data.length; i++) {
      print('$spaces[$i]:');
      _printJson(data[i], indent + 1);
    }
  } else {
    print('$spaces$data (${data.runtimeType})');
  }
}