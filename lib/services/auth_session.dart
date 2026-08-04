class AuthSession {
  static int? id;
  static String? email;
  static String? role;

  static bool get isLoggedIn => id != null;

  static void set({
    required int id,
    required String email,
    required String role,
  }) {
    AuthSession.id = id;
    AuthSession.email = email;
    AuthSession.role = role;
  }

  static void clear() {
    id = null;
    email = null;
    role = null;
  }
}
