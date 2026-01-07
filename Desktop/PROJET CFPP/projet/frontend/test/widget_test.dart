//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'package:frontend/data/api/dio_client.dart';
import 'package:frontend/data/repositories/auth_repository_impl.dart';
import 'package:frontend/services/storage_service.dart';

void main() {
  testWidgets('MyApp se lance sans erreur', (WidgetTester tester) async {
    // Crée des objets nécessaires
    final storage = StorageService();
    final dioClient = DioClient(storage: storage);
    final authRepo = AuthRepositoryImpl(client: dioClient, storage: storage);

    // Build the app with required authRepo
    await tester.pumpWidget(MyApp(authRepo: authRepo));

    // Vérifie que la page login est affichée
    expect(find.text('Connexion'), findsOneWidget);
  });
}
