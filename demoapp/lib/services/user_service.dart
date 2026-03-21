import '../models/user_model.dart';

class UserService {
  static final List<UserModel> _users = [];

  static void addUser(UserModel user) {
    _users.add(user);
  }

  static List<UserModel> getUsers() {
    return _users;
  }

  static void deleteUser(int index) {
    _users.removeAt(index);
  }

  static void updateUser(int index, UserModel user) {
    _users[index] = user;
  }
}