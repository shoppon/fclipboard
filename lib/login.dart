import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  String _accessToken = "";
  Map<String, dynamic> _userInfo = {};

  Future<void> _loginWithGoogle() async {
    final authorizationEndpoint =
        Uri.parse('https://accounts.google.com/o/oauth2/v2/auth');
    final redirectUri = Uri.parse('http://localhost:8000');
    const clientId =
        '605059586369-et8rg4k80c70flk7tevcblmt4kadg89g.apps.googleusercontent.com';
    final scopes = ['openid', 'email', 'profile'];

    // Step 1: Obtain authorization code
    final authUrl = Uri.https(
      authorizationEndpoint.authority,
      authorizationEndpoint.path,
      {
        'client_id': clientId,
        'redirect_uri': redirectUri.toString(),
        'response_type': 'code',
        'scope': scopes.join(' '),
      },
    );
    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: redirectUri.scheme,
    );
    final code = Uri.parse(result).queryParameters['code'];

    // Step 2: Exchange authorization code for access token
    final url = Uri.https('www.googleapis.com', 'oauth2/v4/token');
    final tokenResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': clientId,
        'redirect_uri': redirectUri.toString(),
        'grant_type': 'authorization_code',
      },
    );
    final tokenJson = jsonDecode(tokenResponse.body);
    _accessToken = tokenJson['access_token'];

    // Step 3: Use access token to get user info
    final userInfoEndpoint = Uri.parse(
        'https://www.googleapis.com/oauth2/v3/userinfo?access_token=$_accessToken');
    final userInfoResponse = await http.get(userInfoEndpoint);
    _userInfo = jsonDecode(userInfoResponse.body);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Email:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              _userInfo['email']?.toString() ?? "Unknown",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginWithGoogle,
              child: const Text('Login with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
