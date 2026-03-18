/// Represents the authenticated user.
class UserEntity {
  final String id;
  final String email;
  final String? name;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
  });
}
