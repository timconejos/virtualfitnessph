import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtualfitnessph/models/race.dart';
import 'package:virtualfitnessph/models/rewards_items.dart';
import 'package:virtualfitnessph/models/user.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

import '../screens/points_history_screen.dart';

class AuthService {
  static const String baseUrl = 'http://97.74.90.63:8080';
  static const String cartKey = 'user_cart';
  // static const String baseUrl = 'http://10.0.2.2:8080';

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


  //TODO: empty parameter is for testing only, remove param
  Future<List<RewardsItems>> fetchRewards(bool empty) async {
    if (empty) {
      return [];
    }

    final String url = '$baseUrl/rewards';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => RewardsItems.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load rewards');
    }
  }

   Future<String> fetchRewardsImage(String filename) async {
     final response = await http.head(Uri.parse('$baseUrl/rewards/images/$filename'));

     if (response.statusCode == 200) {
       return Uri.parse('$baseUrl/rewards/images/$filename').toString();
     } else {
       return 'assets/login.jpg'; // Default image
     }
  }

  Future<List<dynamic>> searchRewards(String query) async {

    // TODO: Delete
    List<RewardsItems> items = [];
    items.add(RewardsItems(rewardsId: 3, rewardsName: 'The T-Shirt Spot [S-XL]', description: 'Discover the latest in t-shirt fashion with our Tee Trendsetters collection. From bold graphic prints to minimalist designs, we’ve curated a selection of tees that set the style standard. Whether you\'re looking for everyday comfort or a standout statement piece, these must-have tees combine quality, comfort, and cutting-edge style. Find your new favorite shirt today and lead the trend!', rewardsPicture: 'assets/post1.jpg', amount:  43.31,dateAdded: 'Nov 1' ));
    items.add(RewardsItems(rewardsId: 4, rewardsName: 'The TPrint Perfect Tees', description: 'Discover the latest in t-shirt fashion with our Tee Trendsetters collection. From bold graphic prints to minimalist designs, we’ve curated a selection of tees that set the style standard. Whether you\'re looking for everyday comfort or a standout statement piece, these must-have tees combine quality, comfort, and cutting-edge style. Find your new favorite shirt today and lead the trend!', rewardsPicture: 'assets/post1.jpg', amount:  643.31,dateAdded: 'Nov 1' ));
    items.add(RewardsItems(rewardsId: 5, rewardsName: 'Fresh Fits Tee Trendsetters collection | Bold style standard | [sm - xxl]', description: 'Discover the latest in t-shirt fashion with our Tee Trendsetters collection. From bold graphic prints to minimalist designs, we’ve curated a selection of tees that set the style standard. Whether you\'re looking for everyday comfort or a standout statement piece, these must-have tees combine quality, comfort, and cutting-edge style. Find your new favorite shirt today and lead the trend!', rewardsPicture: 'assets/post1.jpg', amount:  9743.31,dateAdded: 'Nov 1' ));

    try {
      if (query == 'test') {
        return items;
      } else {
        print('Failed to search reward: ');
        return [];
      }
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  //TODO: empty parameter is for testing only, remove param
  Future<List<RewardsItems>> fetchCart(bool empty) async {

    // TODO: Delete
    List<RewardsItems> items = [];
    items.add(RewardsItems(rewardsId: 3, rewardsName: 'The T-Shirt Spot [S-XL]', description: 'Discover the latest in t-shirt fashion with our Tee Trendsetters collection. From bold graphic prints to minimalist designs, we’ve curated a selection of tees that set the style standard. Whether you\'re looking for everyday comfort or a standout statement piece, these must-have tees combine quality, comfort, and cutting-edge style. Find your new favorite shirt today and lead the trend!', rewardsPicture: 'assets/post1.jpg', amount:  43.31,dateAdded: 'Nov 1' ));
    items.add(RewardsItems(rewardsId: 4, rewardsName: 'The TPrint Perfect Tees', description: 'Discover the latest in t-shirt fashion with our Tee Trendsetters collection. From bold graphic prints to minimalist designs, we’ve curated a selection of tees that set the style standard. Whether you\'re looking for everyday comfort or a standout statement piece, these must-have tees combine quality, comfort, and cutting-edge style. Find your new favorite shirt today and lead the trend!', rewardsPicture: 'assets/post1.jpg', amount:  643.31,dateAdded: 'Nov 1' ));
    items.add(RewardsItems(rewardsId: 5, rewardsName: 'Fresh Fits Tee Trendsetters collection | Bold style standard | [sm - xxl]', description: 'Discover the latest in t-shirt fashion with our Tee Trendsetters collection. From bold graphic prints to minimalist designs, we’ve curated a selection of tees that set the style standard. Whether you\'re looking for everyday comfort or a standout statement piece, these must-have tees combine quality, comfort, and cutting-edge style. Find your new favorite shirt today and lead the trend! Discover the latest in t-shirt fashion with our Tee Trendsetters collection. From bold graphic prints to minimalist designs, we’ve curated a selection of tees that set the style standard. Whether you\'re looking for everyday comfort or a standout statement piece, these must-have tees combine quality, comfort, and cutting-edge style. Find your new favorite shirt today and lead the trend', rewardsPicture: 'assets/post1.jpg', amount:  9743.31,dateAdded: 'Nov 1' ));

    try {
      if (!empty) {
        return items;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching cart: $e');
      return [];
    }
  }

  // Add item to cart
  Future<void> addToCart(RewardsItems rewardItem) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList(cartKey) ?? [];

    cartItems.add(jsonEncode(rewardItem.toJson()));

    await prefs.setStringList(cartKey, cartItems);
  }

  // Get all cart items
  Future<List<RewardsItems>> getCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList(cartKey) ?? [];

    return cartItems.map((item) => RewardsItems.fromJson(jsonDecode(item))).toList();
  }

  // Clear the cart
  Future<void> clearCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(cartKey);
  }

  // Remove a specific item from cart
  Future<void> removeFromCart(RewardsItems rewardItem) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList(cartKey) ?? [];

    // Find the first instance of the item and remove it
    final index = cartItems.indexWhere((item) => jsonDecode(item)['id'] == rewardItem.rewardsId);

    if (index != -1) {
      cartItems.removeAt(index); // Remove only the first found instance
    }

    await prefs.setStringList(cartKey, cartItems);
  }

  Future<bool> createShopItem({
    required String userId,
    required String username,
    required String name,
    required String email,
    required String contactNumber,
    required double totalAmount,
    required List<int> purchasedItems,
  }) async {
    try {
      // Join the list of purchased item IDs into a comma-separated string
      String itemIds = purchasedItems.join(',');

      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse('$baseUrl/shop/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'username': username,
          'name': name,
          'email': email,
          'contactNumber': contactNumber,
          'totalAmount': totalAmount,
          'itemIds': itemIds,  // Sending itemIds as a comma-separated string
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error creating shop item: $e');
      return false;
    }
  }



}

