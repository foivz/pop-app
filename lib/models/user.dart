import 'dart:convert';

import 'package:pop_app/models/store.dart';
import 'package:pop_app/secure_storage.dart';

class User {
  late String firstName;
  late String lastName;
  late String username;
  late String email;
  late String password;
  late Store store;
  UserRole? _role;
  bool registered = false;

  static final List<UserRole> roles = List.from([UserRole(3, "seller"), UserRole(1, "buyer")]);
  static void storeUserData(userData, username, password) {
    SecureStorage.setUserData(json.encode(userData));
    SecureStorage.setUsername(username);
    SecureStorage.setPassword(password);
  }

  static get loggedIn async => json.decode(await SecureStorage.getUserData());

  UserRole? getRole() => _role;

  void setRole(UserRole role) {
    if (roles.contains(role)) {
      _role = role;
    }
  }

  User.empty();

  User.loginInfo(this.username, this.password) {
    User("", "", username, "", password);
  }

  User(this.firstName, this.lastName, this.username, this.email, this.password);
  User.withUsername({required this.username});

  User.full(this.firstName, this.lastName, this.username, this.email, this.password, UserRole role,
      this.store) {
    setRole(role);
  }
}

class UserRole {
  late int roleId;
  late String roleName;

  UserRole(this.roleId, this.roleName);
}
