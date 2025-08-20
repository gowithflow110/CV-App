class PigeonUserDetails {
  final String id;
  final String name;
  final String email;

  PigeonUserDetails({
    required this.id,
    required this.name,
    required this.email,
  });

  /// Optional: factory to create from Firestore map
  factory PigeonUserDetails.fromMap(Map<String, dynamic> data) {
    return PigeonUserDetails(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }
}
