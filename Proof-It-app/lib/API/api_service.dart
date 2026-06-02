import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';

class ApiService {
  static String get baseUrl => '${AppConfig.baseUrl}/projects';
  // 1. GET PROJECTS
  static Future<List<dynamic>> getProjects() async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // If backend returns an object with a list inside, try to extract it
        if (decoded is List) return decoded;
        if (decoded is Map) {
          if (decoded['data'] is List) return decoded['data'];
          if (decoded['projects'] is List) return decoded['projects'];
          // If it's a single object, wrap into list
          return [decoded];
        }
        return [];
      } else {
        print('getProjects error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('getProjects exception: $e');
      return [];
    }
  }

  // 2. ADD PROJECT
  static Future<bool> addProject(
    String title,
    String desc,
    String status,
    String location,
    String startDate,
    String endDate,
  ) async {
    try {
      final uri = Uri.parse(baseUrl);
      final body = jsonEncode({
        "title": title,
        "description": desc,
        "status": status,
        "location": location,
        "start_date": startDate,
        "end_date": endDate,
      });

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: body,
      );

      if (response.statusCode == 201) return true;

      print('addProject failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print("Error Add: $e");
      return false;
    }
  }

  // 3. DELETE PROJECT
  static Future<bool> deleteProject(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) return true;
      print('deleteProject failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print("Error Delete: $e");
      return false;
    }
  }
}
