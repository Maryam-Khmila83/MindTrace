import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl = "http://YOUR_LOCAL_BACKEND_IP:8000";

  // Analyze text emotion
  static Future<Map<String, dynamic>> analyzeText(String text, String team) async {
    final response = await http.post(
      Uri.parse("$baseUrl/analyze"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text, "team": team}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to analyze");
    }
  }

  // Get history from backend with team filter
  static Future<List<dynamic>> getHistory({String? team}) async {
    String url = "$baseUrl/history";
    if (team != null && team.isNotEmpty) {
      url = "$baseUrl/history?team=${Uri.encodeComponent(team)}";
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load history");
    }
  }

  // Submit a letter (private or anonymous)
  static Future<Map<String, dynamic>> submitLetter({
    required String content,
    required bool isShared,  // false = private, true = anonymous
    required String team,    // ← ADD TEAM PARAMETER
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/letters"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "content": content,
        "is_shared": isShared,
        "team": team,  // ← ADD TEAM
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to submit letter");
    }
  }

  // Get shared letters (for HR view - optional)
  static Future<List<dynamic>> getSharedLetters() async {
    final response = await http.get(
      Uri.parse("$baseUrl/letters/shared"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load shared letters");
    }
  }

  // Get user's own letters (private + shared but not anonymous view)
  static Future<List<dynamic>> getUserLetters({String? team}) async {
    String url = "$baseUrl/letters/user";
    if (team != null && team.isNotEmpty) {
      url = "$baseUrl/letters/user?team=${Uri.encodeComponent(team)}";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load user letters");
    }
  }
  // Get all analyses for HR (no team filter)
  static Future<List<dynamic>> getHistoryAll() async {
    final response = await http.get(
      Uri.parse("$baseUrl/history/all"),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load all history");
    }
  }
}
