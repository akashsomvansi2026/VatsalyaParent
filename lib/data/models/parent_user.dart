/// Parent account as returned by the backend.
class ParentUser {
  const ParentUser({
    required this.id,
    required this.name,
    required this.email,
    this.permissions = const {},
  });

  final int id;
  final String name;
  final String email;
  final Set<String> permissions;
  bool can(String key) =>
      permissions.contains(key.startsWith('parent.') ? key : 'parent.$key');

  factory ParentUser.fromJson(Map<String, dynamic> json) {
    return ParentUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      permissions: (json['permissions'] as List? ?? [])
          .map(
            (p) => p is Map
                ? (p['key'] ?? '${p['module']}.${p['action']}').toString()
                : p.toString(),
          )
          .toSet(),
    );
  }
}
