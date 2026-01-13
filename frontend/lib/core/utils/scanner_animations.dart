// lib/core/utils/scanner_animations.dart
import 'package:flutter/material.dart';

class ScannerAnimations {
  // Animation de scan
  static Widget buildScanLineAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Positioned(
          top: 120 + (240 * value),
          left: MediaQuery.of(context).size.width / 2 - 125,
          child: Container(
            width: 250,
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.green.withOpacity(0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  // Animation de succès
  static void showSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Validé !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Fermer après 1 seconde
    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
