import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:animalia/models/user/user_crud.dart';
import 'package:animalia/models/user/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserCRUD _userCRUD = UserCRUD();
  List<UserModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_search);
  }

  @override
  void dispose() {
    _searchController.removeListener(_search);
    _searchController.dispose();
    super.dispose();
  }

  void _search() async {
    String searchTerm = _searchController.text;
    if (searchTerm.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      List<UserModel> results = await _userCRUD.searchByPetName(searchTerm);

      for (var user in results) {
        bool isFriend = await _checkFriendshipStatus(user.userId);
        user.isFriend = isFriend;
      }
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search: $e')),
      );
    }
  }

  Future<bool> _checkFriendshipStatus(int friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = json.decode(prefs.getString('user_data') ?? '{}');
    final currentUserId = userData['user_id'];

    if (currentUserId == null) {
      return false;
    }

    return await _userCRUD.isFriend(currentUserId, friendId);
  }

  void _addFriend(int friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user_data') ?? '{}');
      final userId = userData['user_id'];

      if (userId == null) throw Exception('User ID not found');

      bool success = await _userCRUD.addFriend(userId, friendId);
      if (success) {
        setState(() {
          for (var user in _searchResults) {
            if (user.userId == friendId) {
              user.isFriend = true;
              break;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add friend: $e')),
      );
    }
  }

  ImageProvider<Object> _decodeImage(String? base64String) {
    try {
      if (base64String == null || base64String.isEmpty) {
        throw Exception('No image data');
      }
      return MemoryImage(const Base64Decoder().convert(base64String));
    } catch (e) {
      print('Failed to load image: $e');
      return const AssetImage('assets/logo.png');
    }
  }

  void _removeFriend(int friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user_data') ?? '{}');
      final userId = userData['user_id'];

      if (userId == null) throw Exception('User ID not found');

      bool success = await _userCRUD.removeFriend(userId, friendId);
      if (success) {
        setState(() {
          for (var user in _searchResults) {
            if (user.userId == friendId) {
              user.isFriend = false;
              break;
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend removed successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove friend: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar por nome do pet',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: _search,
                  ),
                  fillColor: const Color.fromARGB(255, 32, 32, 32),
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: (value) => _search(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  UserModel user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _decodeImage(user.petPictureBase64),
                    ),
                    title: Text(user.petName),
                    trailing: IconButton(
                      icon:
                          Icon(user.isFriend ? Icons.check : Icons.person_add),
                      onPressed: () => user.isFriend
                          ? _removeFriend(user.userId)
                          : _addFriend(user.userId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
