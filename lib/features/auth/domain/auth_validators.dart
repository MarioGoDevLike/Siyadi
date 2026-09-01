import 'package:firebase_auth/firebase_auth.dart';

String mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account found for that email.',
      'wrong-password' => 'Incorrect password.',
      'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' => 'An account already exists for that email.',
      'weak-password' => 'Use a stronger password (at least 6 characters).',
      'too-many-requests' => 'Too many attempts. Try again later.',
      'network-request-failed' => 'Network error. Check your connection.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled in Firebase Console.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
  }
  return error.toString();
}

final usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

String? validateUsername(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'Username is required';
  if (!usernamePattern.hasMatch(trimmed)) {
    return '3–20 characters: letters, numbers, underscore';
  }
  return null;
}

String? validateEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'Email is required';
  if (!trimmed.contains('@') || !trimmed.contains('.')) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePassword(String? value, {bool isNew = false}) {
  final text = value ?? '';
  if (text.isEmpty) return 'Password is required';
  if (isNew && text.length < 6) return 'At least 6 characters';
  return null;
}

String? validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) return '$label is required';
  return null;
}
