class DestinationEmail {
  const DestinationEmail({
    required this.id,
    required this.email,
    required this.isVerified,
  });

  final String id;
  final String email;
  final bool isVerified;

  factory DestinationEmail.fromApi(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final verified = json['verified'];

    if (id is! String || id.isEmpty || email is! String || email.isEmpty) {
      throw const FormatException('Destination email payload is invalid.');
    }

    return DestinationEmail(
      id: id,
      email: email,
      isVerified: verified is bool ? verified : false,
    );
  }
}
