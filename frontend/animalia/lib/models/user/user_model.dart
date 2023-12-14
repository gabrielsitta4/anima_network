import 'dart:convert';
import 'package:intl/intl.dart';

class UserModel {
  final int userId;
  final String petName;
  final String? petPictureBase64;
  final String? description;
  final DateTime dateOfBirth;
  final String email;
  final String password;
  bool isFriend;

  UserModel({
    required this.userId,
    required this.petName,
    this.petPictureBase64,
    this.description,
    required this.dateOfBirth,
    required this.email,
    required this.password,
    this.isFriend = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final format = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz');
    return UserModel(
      userId: map['user_id'],
      petName: map['petname'],
      petPictureBase64: map['petpicture'],
      description: map['description'],
      dateOfBirth: format.parse(map['date_of_birth'], true).toLocal(),
      email: map['email'],
      password: map['password'],
      isFriend: map['isFriend'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'petname': petName,
      'petpicture': petPictureBase64,
      'description': description,
      'date_of_birth': DateFormat('yyyy-MM-dd').format(dateOfBirth),
      'email': email,
      'password': password,
      'isFriend': isFriend,
    };
  }

  factory UserModel.fromJson(String source) {
    return UserModel.fromMap(json.decode(source));
  }

  String toJson() {
    return json.encode(toMap());
  }
}
