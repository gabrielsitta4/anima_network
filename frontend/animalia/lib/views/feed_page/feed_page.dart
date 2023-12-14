import 'dart:convert';

import 'package:animalia/models/post/post_crud.dart';
import 'package:animalia/models/post/post_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageUtils {
  static ImageProvider<Object> decodeImage(String? base64String) {
    try {
      if (base64String == null || base64String.isEmpty) {
        throw Exception('No image data');
      }
      return MemoryImage(base64.decode(base64String));
    } catch (e) {
      print('Failed to load image: $e');
      return const AssetImage('assets/logo.png');
    }
  }
}

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final PostCRUD _postCRUD = PostCRUD();
  List<PostModel> _friendPosts = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriendPosts();
  }

  void _addComment(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = json.decode(prefs.getString('user_data') ?? '{}');
    final userId = userData['user_id'];

    if (userId == null) {
      print('User ID not found');
      return;
    }

    String commentText = _commentController.text;
    if (commentText.isNotEmpty) {
      bool success = await _postCRUD.addComment(postId, commentText, userId);
      if (success) {
        _commentController.clear();
      }
    }
  }

  Future<void> _loadFriendPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = json.decode(prefs.getString('user_data') ?? '{}')['user_id'];
    if (userId != null) {
      final friendPosts = await _postCRUD.getFriendPosts(userId);
      setState(() {
        _friendPosts = friendPosts;
      });
    }
  }

  void _likePost(int? postId) async {
    if (postId != null) {
      bool success = await _postCRUD.likePost(postId);
      if (success) {
        _loadFriendPosts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: _friendPosts.length,
        itemBuilder: (context, index) {
          final post = _friendPosts[index];

          ImageProvider? userImageProvider = (post.userImage != null &&
                  post.userImage!.isNotEmpty
              ? MemoryImage(base64Decode(post.userImage! as String))
              : const AssetImage('assets/logo.png')) as ImageProvider<Object>?;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: Colors.grey[850],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userImageProvider,
                    ),
                    title: Text(post.userName ?? 'Usuário Anônimo'),
                  ),
                  if (post.imageData != null)
                    Image.memory(post.imageData!, fit: BoxFit.cover),
                  const Divider(color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(post.description ?? ''),
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.thumb_up, color: Colors.white),
                        label: Text('${post.likes ?? 0} Likes',
                            style: const TextStyle(color: Colors.white)),
                        onPressed: () => _likePost(post.postId),
                      ),
                    ],
                  ),
                  Column(
                    children: post.comments!.map((comment) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(comment.commentText),
                      );
                    }).toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Escreva um comentário...',
                        hintStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: () => _addComment(post.postId!),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.black),
                      ),
                      child: const Text('Postar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
