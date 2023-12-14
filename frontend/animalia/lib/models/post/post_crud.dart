import 'dart:async';
import 'dart:convert';

import 'package:animalia/models/database.dart';
import 'package:http/http.dart' as http;
import 'package:animalia/models/post/post_model.dart';

class PostCRUD {
  final ApiConfig _apiConfig = ApiConfig();

  Future<http.Response> makeRequestWithRetry(
    Future<http.Response> Function() requestFunction, {
    int maxAttempts = 10,
  }) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        final response = await requestFunction();
        if (response.statusCode == 200) {
          return response;
        }
        attempts++;
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;
      }
    }
    throw Exception('Request failed after $maxAttempts attempts');
  }

  Future<bool> createPost(PostModel post) async {
    final response = await http
        .post(
          Uri.parse('${_apiConfig.api()}/post'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: post.toJson(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to create post');
    }
  }

  Future<List<PostModel>> getUserPosts(int userId) async {
    try {
      final response = await makeRequestWithRetry(() => http.get(
            Uri.parse('${_apiConfig.api()}/user_posts/$userId'),
            headers: {'Content-Type': 'application/json'},
          ));

      if (response.statusCode == 200) {
        List<dynamic> postListJson = json.decode(response.body);
        return postListJson
            .map((postJson) => PostModel.fromMap(postJson))
            .toList();
      } else {
        throw Exception(
            'Failed to load posts with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error occurred while fetching user posts');
    }
  }

  Future<List<PostModel>> getFriendPosts(int userId) async {
    try {
      final response = await makeRequestWithRetry(() => http.get(
            Uri.parse('${_apiConfig.api()}/friend_posts/$userId'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 30)));

      if (response.statusCode == 200) {
        List<dynamic> postListJson = json.decode(response.body);
        return postListJson
            .map((postJson) => PostModel.fromMap(postJson))
            .toList();
      } else {
        throw Exception(
            'Failed to load friend posts with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error occurred while fetching friend posts: $e');
    }
  }

  Future<bool> likePost(int postId) async {
    final response = await http.post(
      Uri.parse('${_apiConfig.api()}/like_post/$postId'),
      headers: {'Content-Type': 'application/json'},
    );

    return response.statusCode == 200;
  }

  Future<bool> addComment(int postId, String commentText, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('${_apiConfig.api()}/add_comment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'post_id': postId,
          'user_id': userId,
          'comment_text': commentText,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment');
    }
  }
}
