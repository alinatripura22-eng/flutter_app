import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BusinessAdsService {
  static const String baseUrl = 'https://vibbeo-backend.onrender.com/api/business-ads';
  
  // Get ads for feed
  static Future<List<Map<String, dynamic>>> getFeedAds({
    required String userLocation,
    required int userAge,
    required String userGender,
    required List<String> userInterests,
    int limit = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/serve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'placement': 'feed',
          'userLocation': userLocation,
          'userAge': userAge,
          'userGender': userGender,
          'userInterests': userInterests,
          'limit': limit,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['ads'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching feed ads: $e');
      return [];
    }
  }
  
  // Get ads for shorts
  static Future<List<Map<String, dynamic>>> getShortsAds({
    required String userLocation,
    required int userAge,
    required String userGender,
    required List<String> userInterests,
    int limit = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/serve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'placement': 'shorts',
          'userLocation': userLocation,
          'userAge': userAge,
          'userGender': userGender,
          'userInterests': userInterests,
          'limit': limit,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['ads'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching shorts ads: $e');
      return [];
    }
  }
  
  // Get ads for search results
  static Future<List<Map<String, dynamic>>> getSearchAds({
    required String userLocation,
    required int userAge,
    required String userGender,
    required List<String> userInterests,
    String? category,
    int limit = 2,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/serve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'placement': 'search',
          'userLocation': userLocation,
          'userAge': userAge,
          'userGender': userGender,
          'userInterests': userInterests,
          'category': category,
          'limit': limit,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['ads'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching search ads: $e');
      return [];
    }
  }
  
  // Record ad click
  static Future<void> recordClick(String adId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/$adId/click'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error recording click: $e');
    }
  }
  
  // Record ad conversion
  static Future<void> recordConversion(String adId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/$adId/conversion'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error recording conversion: $e');
    }
  }
  
  // Insert ads into feed
  static List<dynamic> insertAdsIntoFeed(
    List<dynamic> videos,
    List<Map<String, dynamic>> ads, {
    int interval = 4, // Show ad every 4 videos
  }) {
    if (ads.isEmpty) return videos;
    
    final List<dynamic> result = [];
    int adIndex = 0;
    
    for (int i = 0; i < videos.length; i++) {
      result.add(videos[i]);
      
      // Insert ad after every 'interval' videos
      if ((i + 1) % interval == 0 && adIndex < ads.length) {
        result.add({
          'isAd': true,
          'adData': ads[adIndex],
        });
        adIndex++;
      }
    }
    
    return result;
  }
  
  // Insert ads into shorts
  static List<dynamic> insertAdsIntoShorts(
    List<dynamic> shorts,
    List<Map<String, dynamic>> ads, {
    int interval = 5, // Show ad every 5 shorts
  }) {
    if (ads.isEmpty) return shorts;
    
    final List<dynamic> result = [];
    int adIndex = 0;
    
    for (int i = 0; i < shorts.length; i++) {
      result.add(shorts[i]);
      
      // Insert ad after every 'interval' shorts
      if ((i + 1) % interval == 0 && adIndex < ads.length) {
        result.add({
          'isAd': true,
          'adData': ads[adIndex],
        });
        adIndex++;
      }
    }
    
    return result;
  }
  
  // Get user profile for targeting
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'location': prefs.getString('userCity') ?? 'Unknown',
        'age': prefs.getInt('userAge') ?? 25,
        'gender': prefs.getString('userGender') ?? 'all',
        'interests': prefs.getStringList('userInterests') ?? [],
      };
    } catch (e) {
      print('Error getting user profile: $e');
      return {
        'location': 'Unknown',
        'age': 25,
        'gender': 'all',
        'interests': [],
      };
    }
  }
}
