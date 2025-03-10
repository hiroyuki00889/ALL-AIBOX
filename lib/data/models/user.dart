class User {
  final String id;
  final String email;
  final String? buddyPrefix;

  User({
    required this.id,
    required this.email,
    this.buddyPrefix,
  });

  // Factory constructor to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      buddyPrefix: json['buddyPrefix'] as String?,
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'buddyPrefix': buddyPrefix,
    };
  }
}