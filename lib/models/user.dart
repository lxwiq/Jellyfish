/// Modèle utilisateur Jellyfin simple
class User {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final bool isAdmin;
  final bool isDisabled;
  final DateTime? lastLoginDate;
  final DateTime? lastActivityDate;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.isAdmin = false,
    this.isDisabled = false,
    this.lastLoginDate,
    this.lastActivityDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isDisabled: json['isDisabled'] as bool? ?? false,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'] as String)
          : null,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.parse(json['lastActivityDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'isAdmin': isAdmin,
      'isDisabled': isDisabled,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'lastActivityDate': lastActivityDate?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isAdmin,
    bool? isDisabled,
    DateTime? lastLoginDate,
    DateTime? lastActivityDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isDisabled: isDisabled ?? this.isDisabled,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.avatarUrl == avatarUrl &&
        other.isAdmin == isAdmin &&
        other.isDisabled == isDisabled &&
        other.lastLoginDate == lastLoginDate &&
        other.lastActivityDate == lastActivityDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      avatarUrl,
      isAdmin,
      isDisabled,
      lastLoginDate,
      lastActivityDate,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, avatarUrl: $avatarUrl, '
        'isAdmin: $isAdmin, isDisabled: $isDisabled, '
        'lastLoginDate: $lastLoginDate, lastActivityDate: $lastActivityDate)';
  }
}

/// États d'authentification possibles
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

/// État d'authentification avec utilisateur et token
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.error,
  });

  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  factory AuthState.loading() {
    return const AuthState(status: AuthStatus.loading);
  }

  factory AuthState.authenticated(User user, String token) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: token,
    );
  }

  factory AuthState.unauthenticated([String? error]) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      error: error,
    );
  }

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.user == user &&
        other.token == token &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(status, user, token, error);
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: $user, token: $token, error: $error)';
  }
}
