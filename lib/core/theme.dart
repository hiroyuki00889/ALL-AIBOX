import 'package:flutter/material.dart';

class AppTheme {
  // App colors
  static const Color primaryGreen = Color(0xFF4CD964);
  static const Color secondaryYellow = Color(0xFFF6E58D);
  static const Color chatBubbleGreen = Color(0xFF4CD964);
  static const Color chatBubbleBeige = Color(0xFFF9DEC9);
  static const Color textBlack = Color(0xFF000000);
  static const Color backgroundColor = Color(0xFFFFFFFF);

  // Button styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.black,
    backgroundColor: primaryGreen,
    minimumSize: const Size(double.infinity, 40),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
    ),
  );

  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.black,
    backgroundColor: secondaryYellow,
    minimumSize: const Size(double.infinity, 40),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
    ),
  );

  // Input decoration
  static InputDecoration textFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: primaryGreen),
      ),
    );
  }
}