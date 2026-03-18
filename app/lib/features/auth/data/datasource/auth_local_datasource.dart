import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../dto/user_dto.dart';

class AuthLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.auth);

  void saveToken(String token) => _box.put('token', token);
  String? getToken() => _box.get('token') as String?;

  void saveUser(UserDto user) => _box.put('user', user.toJson());
  UserDto? getUser() {
    final raw = _box.get('user');
    if (raw == null) return null;
    return UserDto.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  void clear() {
    _box.delete('token');
    _box.delete('user');
  }
}
