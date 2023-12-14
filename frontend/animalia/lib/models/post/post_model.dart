import 'dart:convert';
import 'dart:typed_data';
import 'package:animalia/models/comments/comments_model.dart';
import 'package:intl/intl.dart';

class PostModel {
  int? postId;
  final int userId;
  final String? description;
  final DateTime? postDate;
  final int? likes;
  final Uint8List? imageData;
  final String? userName;
  final Uint8List? userImage;
  List<CommentModel>? comments;

  PostModel({
    this.postId,
    required this.userId,
    this.description,
    this.postDate,
    this.likes = 0,
    this.imageData,
    this.userName,
    this.userImage,
    this.comments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'user_id': userId,
      'description': description,
      'post_date': postDate?.toIso8601String(),
      'likes': likes,
      'image_data': imageData != null ? base64Encode(imageData!) : null,
      'user_name': userName,
      'user_image': userImage != null ? base64Encode(userImage!) : null,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    DateTime? parsedPostDate;
    try {
      parsedPostDate = map['post_date'] != null
          ? DateFormat('E, d MMM yyyy HH:mm:ss z').parse(map['post_date'])
          : null;
    } catch (e) {}

    return PostModel(
      postId: map['post_id'],
      userId: map['user_id'],
      description: map['description'],
      postDate: parsedPostDate,
      likes: map['likes'],
      userName: map['user_name'],
      comments: (map['comments'] as List<dynamic>?)
              ?.map((comment) => CommentModel.fromMap(comment))
              .toList() ??
          [],
      userImage:
          map['user_image'] != null ? base64Decode(map['user_image']) : null,
      imageData:
          map['image_data'] != null ? base64Decode(map['image_data']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PostModel.fromJson(String source) =>
      PostModel.fromMap(json.decode(source));
}
