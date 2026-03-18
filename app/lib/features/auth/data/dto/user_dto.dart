import '../../domain/entities/user_entity.dart';

class UserDto {
  final String id;
  final String email;
  final String? name;

  const UserDto({required this.id, required this.email, this.name});

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};

  UserEntity toEntity() => UserEntity(id: id, email: email, name: name);

  factory UserDto.fromEntity(UserEntity e) =>
      UserDto(id: e.id, email: e.email, name: e.name);
}
