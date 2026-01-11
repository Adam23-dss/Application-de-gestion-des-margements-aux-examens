import 'package:frontend1/data/models/user_model.dart';
import 'package:frontend1/data/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;
  
  LoginUseCase(this._authRepository);
  
  Future<UserModel> execute({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    
    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email');
    }
    
    return await _authRepository.login(
      email: email,
      password: password,
    );
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}