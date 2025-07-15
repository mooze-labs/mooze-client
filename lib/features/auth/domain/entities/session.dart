class Session {
  final String jwt;
  final String refreshToken;

  Session({required this.jwt, required this.refreshToken});

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(jwt: json['jwt'], refreshToken: json['refresh_token']);
  }
}
