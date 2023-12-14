import 'dart:convert';
import 'package:animalia/models/database.dart';
import 'package:animalia/models/user/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserCRUD {
  final ApiConfig _apiConfig = ApiConfig();

  Future<Map<String, dynamic>> register(UserModel user) async {
    final response = await http
        .post(
          Uri.parse('${_apiConfig.api()}/register'),
          headers: {'Content-Type': 'application/json'},
          body: user.toJson(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'User registered successfully'};
    } else if (response.statusCode == 409) {
      return {'success': false, 'message': 'Email already exists'};
    } else {
      return {'success': false, 'message': 'Failed to register user'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('${_apiConfig.api()}/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs
            .setString('user_data', json.encode(responseData['user']))
            .timeout(const Duration(seconds: 30));
        return {
          'success': true,
          'message': 'Login successful',
          'data': responseData['user']
        };
      } else {
        return {
          'success': false,
          'message': 'Dados do usuário não encontrados na resposta.'
        };
      }
    } else {
      return {'success': false, 'message': 'Invalid email or password'};
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      return json.decode(userDataString) as Map<String, dynamic>;
    } else {
      print(
          'Nenhum dado de usuário foi encontrado nas preferências compartilhadas.');
      return {};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  Future<List<UserModel>> searchByPetName(String petName) async {
    try {
      final response = await http.get(
        Uri.parse('${_apiConfig.api()}/search?petname=$petName'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> usersJson = json.decode(response.body);
        List<UserModel> users =
            usersJson.map((userJson) => UserModel.fromMap(userJson)).toList();
        return users;
      } else {
        throw Exception(
            'Failed to load users with status code: ${response.statusCode}');
      }
    } on http.ClientException {
      throw Exception('Failed to connect to the server');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<int> getNumberOfFriends(int userId) async {
    final response = await http.get(
      Uri.parse('${_apiConfig.api()}/friends_count/$userId'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final count = data['count'];
      return count;
    } else {
      throw Exception(
          'Failed to get friends count with status code: ${response.statusCode}');
    }
  }

  Future<int> getNumberOfPosts(int userId) async {
    final response = await http.get(
      Uri.parse('${_apiConfig.api()}/user_posts_count/$userId'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to load number of posts');
    }
  }

  Future<bool> addFriend(int userId, int friendId) async {
    final response = await http
        .post(
          Uri.parse('${_apiConfig.api()}/add_friend'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: json.encode({'user_id': userId, 'friend_id': friendId}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to add friend');
    }
  }

  Future<bool> removeFriend(int userId, int friendId) async {
    final response = await http.delete(
      Uri.parse('${_apiConfig.api()}/remove_friend/$userId/$friendId'),
      headers: {'Content-Type': 'application/json'},
    );

    return response.statusCode == 200;
  }

  Future<bool> isFriend(int currentUserId, int friendId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${_apiConfig.api()}/check_friendship?currentUserId=$currentUserId&friendId=$friendId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        var isFriendResponse = json.decode(response.body)['isFriend'];
        return isFriendResponse == true || isFriendResponse == 1;
      } else {
        throw Exception('Failed to check friendship status');
      }
    } catch (e) {
      throw Exception('An error occurred while checking friendship status: $e');
    }
  }
}
