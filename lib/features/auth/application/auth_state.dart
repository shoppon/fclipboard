class AuthState {
  const AuthState({
    required this.initialized,
    required this.loading,
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.email,
  });

  final bool initialized;
  final bool loading;
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? email;

  bool get isAuthenticated => accessToken != null && userId != null;

  AuthState copyWith({
    bool? initialized,
    bool? loading,
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? email,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      email: email ?? this.email,
    );
  }

  factory AuthState.initial() => const AuthState(
        initialized: false,
        loading: false,
      );
}
