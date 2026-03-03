class TokenPair {
  final String access;
  final String refresh;

  TokenPair({required this.access, required this.refresh});

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      access: json['accessToken'],
      refresh: json['refreshToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': access,
      'refreshToken': refresh,
    };
  }
}