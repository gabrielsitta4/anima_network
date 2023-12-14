import 'package:animalia/models/post/post_crud.dart';
import 'package:animalia/models/post/post_model.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animalia/models/user/user_crud.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserCRUD _userCRUD = UserCRUD();
  final PostCRUD _postCRUD = PostCRUD();
  Map<String, dynamic> _userData = {};
  int _numberOfFriends = 0;
  int _numberOfPosts = 0;
  List<PostModel> _userPosts = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = json.decode(prefs.getString('user_data') ?? '{}');
    final userId = userData['user_id'];
    if (userId != null) {
      final userPosts = await _postCRUD.getUserPosts(userId);
      setState(() {
        _userPosts = userPosts;
      });
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = json.decode(userDataString) as Map<String, dynamic>;
      final userId = userData['user_id'];

      if (userId != null) {
        final friendsCount = await _userCRUD.getNumberOfFriends(userId);
        final postsCount = await _userCRUD.getNumberOfPosts(userId);

        setState(() {
          _userData = userData;
          _numberOfFriends = friendsCount;
          _numberOfPosts = postsCount;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _userData['petname'] ?? 'Nome do Pet',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _userData['petpicture'] != null
                        ? MemoryImage(base64Decode(_userData['petpicture']))
                        : const AssetImage('assets/logo.png') as ImageProvider,
                  ),
                  Text(
                    '$_numberOfFriends',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text('Amigos'),
                  Text(
                    '$_numberOfPosts',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text('Posts'),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.grey),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userPosts.length,
                itemBuilder: (context, index) {
                  final post = _userPosts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      color: Colors.grey[850],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (post.imageData != null)
                            Image.memory(
                              post.imageData!,
                              fit: BoxFit.cover,
                              height: 200,
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    post.description ?? '',
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.white),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Text(
                                  'Likes: ${post.likes}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: post.comments?.length ?? 0,
                            itemBuilder: (context, commentIndex) {
                              final comment = post.comments?[commentIndex];
                              return ListTile(
                                leading: const Icon(Icons.comment),
                                title: Text(comment?.commentText ?? ''),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
