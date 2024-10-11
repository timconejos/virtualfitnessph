import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtualfitnessph/models/race.dart';
import 'package:virtualfitnessph/models/rewards.dart';
import 'package:virtualfitnessph/models/user.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

import '../screens/points_history_screen.dart';

class AuthService {
  static const String baseUrl = 'http://97.74.90.63:8080';
  //static const String baseUrl = 'http://10.0.2.2:8080';

  Future<String> getBaseUrl() async {
    // If you plan to allow dynamic base URL updates in the future,
    // you could retrieve it from SharedPreferences or another source.
    // For now, we return the default.
    return baseUrl;
  }

  Future<List<Race>> fetchRaces() async {
    final response = await http.get(Uri.parse('$baseUrl/races'));
    if (response.statusCode == 200) {
      var racesJson = json.decode(response.body) as List;
      return racesJson.map((race) => Race.fromJson(race)).toList();
    } else {
      throw Exception('Failed to load races');
    }
  }

  Future<http.Response> register(User user) async {
    return await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
  }

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'username', username == "sample2" ? username : decryptData(username));
      await prefs.setString('userId', decodedData['id']);
      await prefs.setInt('loginTime', DateTime.now().millisecondsSinceEpoch);
      return true;
    } else {
      return false;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('loginTime');
    await prefs.remove('userId');
}

  Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    int? loginTime = prefs.getInt('loginTime');

    if (username != null && loginTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - loginTime < 86400000) {
        // 1 day in milliseconds
        return true;
      }
      await logout(); // Optional: clear prefs if expired
    }
    return false;
  }

  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<http.Response> getUserStats(String userId) async {
    return await http.get(
      Uri.parse('$baseUrl/getUserCurrentStats?id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<List<dynamic>> fetchFeedItems(int offset, int limit) async {
    final response =
        await http.get(Uri.parse('$baseUrl/feed?offset=$offset&limit=$limit'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load feed items');
    }
  }

  Future<List<dynamic>> fetchFeedItemsWithLikes(int offset, int limit) async {
    final response =
        await http.get(Uri.parse('$baseUrl/feed?offset=$offset&limit=$limit'));
    if (response.statusCode == 200) {
      List<dynamic> feedItems = json.decode(response.body);
      String? userId = await getUserId();

      for (var item in feedItems) {
        List<dynamic> likes = item['likes'];
        item['likedByUser'] = likes.contains(userId);
      }

      return feedItems;
    } else {
      throw Exception('Failed to load feed items');
    }
  }

  Future<bool> sendVerificationEmail(String email, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/send-verification-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'userId': userId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending verification email: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/userdetail/$userId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load user details');
        return null;
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> registerRace(
      Map<String, dynamic> registrationData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/registrations'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(registrationData),
      );
      return {
        'success': response.statusCode == 200,
        'status': response.statusCode,
        'body': response.body,
      };
    } catch (e) {
      print('Error occurred during registration: $e');
      return {
        'success': false,
        'status': 500,
        'body': e.toString(),
      };
    }
  }

  Future<String?> setProfilePicture(File imageFile, String userId) async {
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/profilepic'))
        ..fields['user_id'] = userId
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = json.decode(await response.stream.bytesToString());
        return responseData['imagePath'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error setting profile picture: $e');
      return null;
    }
  }

  Future<String?> getProfilePicture(String filename) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profiles/$filename'));
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      print('Error fetching profile picture: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> submitRaceData({
    required String userId,
    required List<String> raceIds,
    required double distanceKm,
    required int hours,
    required int minutes,
    required int seconds,
    required String location,
    required File image,
  }) async {
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/submissions/upload'))
        ..fields['userId'] = userId
        ..fields['raceIds'] = raceIds.join(',')
        ..fields['distanceKm'] = distanceKm.toString()
        ..fields['hours'] = hours.toString()
        ..fields['minutes'] = minutes.toString()
        ..fields['seconds'] = seconds.toString()
        ..fields['location'] = location
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        return json.decode(String.fromCharCodes(responseData));
      } else {
        throw Exception('Failed to submit race data');
      }
    } catch (e) {
      throw Exception('Error submitting race data: $e');
    }
  }

  Map<String, String> _encryptData({
    required String username,
    required String password,
  }) {
    final key = encrypt.Key.fromUtf8(
      sha256
          .convert(utf8.encode('my32lengthsupersecretnooneknows1'))
          .toString()
          .substring(0, 32),
    );
    final iv = encrypt.IV.fromUtf8('myivforvrphtimco');
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));

    return {
      'username': encrypter.encrypt(username, iv: iv).base64,
      'password': encrypter.encrypt(password, iv: iv).base64,
    };
  }

  String decryptData(String encryptedText) {
    if (encryptedText == "sample2") return encryptedText;

    final key = encrypt.Key.fromUtf8(
      sha256
          .convert(utf8.encode('my32lengthsupersecretnooneknows1'))
          .toString()
          .substring(0, 32),
    );
    final iv = encrypt.IV.fromUtf8('myivforvrphtimco');
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));

    return encrypter.decrypt64(encryptedText, iv: iv);
  }

  Future<List<dynamic>> fetchRaceDetails(String userId, int raceId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/submissions/userrace/$userId/$raceId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load submissions');
    }
  }

  Future<String> fetchRaceImage(String filename) async {
    final response =
        await http.head(Uri.parse('$baseUrl/races/images/$filename'));

    if (response.statusCode == 200) {
      return Uri.parse('$baseUrl/races/images/$filename').toString();
    } else {
      return 'assets/login.jpg'; // Default image
    }
  }

  Future<List<dynamic>> fetchBadges(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/registrations/badges/$userId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load badges');
    }
  }

  Future<bool> forgotPassword(String username, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot_password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'email': email}),
    );

    // Always return true, as we are always showing the dialog regardless of response
    return true;
  }

  Future<http.Response> verifyPassword(String userId, String password) async {
    return await http.post(
      Uri.parse('$baseUrl/verify_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'password': password}),
    );
  }

  Future<http.Response> changePassword(
      String userId, String oldPassword, String newPassword) async {
    return await http.post(
      Uri.parse('$baseUrl/change_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
  }

  Future<bool> reportFeed(String userId, int feedId, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feed/kelareport'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'feedId': feedId,
        'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      print('Feed reported successfully');
      return true;
    } else {
      print('Failed to report feed: ${response.body}');
      return false;
    }
  }

  Future<bool> blockUser(String userId, String blockedUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/block'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'blockedUserId': blockedUserId,
      }),
    );

    if (response.statusCode == 200) {
      print('User blocked successfully');
      return true;
    } else {
      print('Failed to block user: ${response.body}');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    final String url = '$baseUrl/deactivate';  // Update with actual API endpoint
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  Future<String> getCurrentPoints(String userId) async {
    final String url = '$baseUrl/api/user-points/total/$userId';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print('Failed to fetch current points: ${response.body}');
        return "0";
      }
    } catch (e) {
      print('Error fetching current points: $e');
      return "0";
    }
  }

  Future<bool> sharePoints(String sourceUserId, String targetUserId, double amount) async {
    final String url = '$baseUrl/api/user-points/share';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sourceUserId': sourceUserId,
          'targetUserId': targetUserId,
          'amount': amount,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to share points: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sharing points: $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchUserList(String listType, String userId) async {
    final String url = listType == 'Followers'
        ? '$baseUrl/followers/$userId'
        : '$baseUrl/following/$userId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load $listType');
      }
    } catch (e) {
      print('Error loading $listType: $e');
      return [];
    }
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final String url = '$baseUrl/search?q=$query';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to search users: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  Future<List<PointsTransaction>> getPointsHistory(String userId) async {
    final String url = '${await getBaseUrl()}/api/user-points/history/$userId';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Points History Response: $data'); // Debugging line

        // Check if 'content' exists and is a list
        if (data.containsKey('content') && data['content'] is List) {
          List<dynamic> transactionsJson = data['content'];
          return transactionsJson
              .map((json) => PointsTransaction.fromJson(json))
              .toList();
        } else {
          print('Unexpected JSON structure: ${response.body}');
          return [];
        }
      } else {
        print('Failed to fetch points history: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching points history: $e');
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> fetchRewards() async {
    return [
      // {rewardsId: 12, rewardsName: 'Rewards name', points: 33, rewardsPicture: 'assets/post1.jpg'},
      {'rewardsName': 'Rewards name 1', 'price': '33', 'description': 'description test test', 'rewardsPicture': 'assets/post1.jpg'},
      {'rewardsName': 'Rewards name 1', 'price': '33', 'description': 'description test test', 'rewardsPicture': 'assets/post1.jpg'},
    ];
  }

   Future<String> fetchRewardsImage(String filename) async {
      return 'assets/post1.jpg'; // Default image
  }



}
