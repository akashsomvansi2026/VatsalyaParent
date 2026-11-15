import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Password strength evaluation levels
enum PasswordStrength {
  none,
  weak,
  medium,
  strong,
}

extension PasswordStrengthX on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Weak password';
      case PasswordStrength.medium:
        return 'Medium strength';
      case PasswordStrength.strong:
        return 'Strong password';
    }
  }

  double get percent {
    switch (this) {
      case PasswordStrength.none:
        return 0.0;
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}

/// Sign Up state class that preserves entered details across screen transitions
/// (e.g. going to Terms & Conditions and coming back)
class SignUpState {
  const SignUpState({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.isTermsAccepted = false,
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final String fullName;
  final String email;
  final String password;
  final bool isTermsAccepted;
  final bool isPasswordVisible;
  final bool isLoading;
  final String? errorMessage;

  PasswordStrength get passwordStrength {
    if (password.isEmpty) return PasswordStrength.none;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password) ||
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score++;
    }
    if (score == 1) return PasswordStrength.weak;
    if (score == 2) return PasswordStrength.medium;
    if (score >= 3) return PasswordStrength.strong;
    return PasswordStrength.weak;
  }

  bool get isValid {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return fullName.trim().length >= 2 &&
        emailRegex.hasMatch(email.trim()) &&
        password.length >= 6 &&
        isTermsAccepted;
  }

  SignUpState copyWith({
    String? fullName,
    String? email,
    String? password,
    bool? isTermsAccepted,
    bool? isPasswordVisible,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SignUpState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      isTermsAccepted: isTermsAccepted ?? this.isTermsAccepted,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SignUpNotifier extends Notifier<SignUpState> {
  @override
  SignUpState build() => const SignUpState();

  void updateFullName(String value) {
    state = state.copyWith(fullName: value, errorMessage: null);
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value, errorMessage: null);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value, errorMessage: null);
  }

  void setTermsAccepted(bool accepted) {
    state = state.copyWith(isTermsAccepted: accepted, errorMessage: null);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  void reset() {
    state = const SignUpState();
  }
}

final signUpProvider =
    NotifierProvider<SignUpNotifier, SignUpState>(SignUpNotifier.new);

/// Sign In state
class SignInState {
  const SignInState({
    this.email = '',
    this.password = '',
    this.rememberMe = true,
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final String email;
  final String password;
  final bool rememberMe;
  final bool isPasswordVisible;
  final bool isLoading;
  final String? errorMessage;

  bool get isValid {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email.trim()) && password.isNotEmpty;
  }

  SignInState copyWith({
    String? email,
    String? password,
    bool? rememberMe,
    bool? isPasswordVisible,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SignInState(
      email: email ?? this.email,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SignInNotifier extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  void updateEmail(String value) {
    state = state.copyWith(email: value, errorMessage: null);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value, errorMessage: null);
  }

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }
}

final signInProvider =
    NotifierProvider<SignInNotifier, SignInState>(SignInNotifier.new);

/// Forgot Password state
class ForgotPasswordState {
  const ForgotPasswordState({
    this.email = '',
    this.isLoading = false,
    this.isSubmitted = false,
    this.errorMessage,
  });

  final String email;
  final bool isLoading;
  final bool isSubmitted;
  final String? errorMessage;

  bool get isValid {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  ForgotPasswordState copyWith({
    String? email,
    bool? isLoading,
    bool? isSubmitted,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: errorMessage,
    );
  }
}

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  void updateEmail(String value) {
    state = state.copyWith(email: value, errorMessage: null);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setSubmitted(bool submitted) {
    state = state.copyWith(isSubmitted: submitted, isLoading: false);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  void reset() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordProvider =
    NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
  ForgotPasswordNotifier.new,
);
