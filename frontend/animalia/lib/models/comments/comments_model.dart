class CommentModel {
  final int commentId;
  final int postId;
  final int userId;
  final String commentText;

  CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.commentText,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      commentId: map['comment_id'],
      postId: map['post_id'],
      userId: map['user_id'],
      commentText: map['comment_text'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comment_id': commentId,
      'post_id': postId,
      'user_id': userId,
      'comment_text': commentText,
    };
  }
}
