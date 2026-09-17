import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple model for a department, including how many reports/tickets
/// are currently assigned to it (comes straight from the API's
/// `ReportsCount` field).
class DepartmentModel {
  final int id;
  final String name;
  final int reportsCount;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.reportsCount,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['departmentId'] ?? json['DepartmentId'] ?? 0,
      name: (json['departmentName'] ?? json['DepartmentName'] ?? '')
          .toString(),
      reportsCount:
          json['reportsCount'] ?? json['ReportsCount'] ?? 0,
    );
  }
}

class DepartmentService {
  // Same base-url pattern used in TicketService, so both services stay
  // in sync if the API host ever changes.
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://91.108.112.27:5205';

  /// Calls GET /api/Department/all
  ///
  /// NOTE: adjust the route below ("Department") if your controller name
  /// is different — ASP.NET's [Route("api/[controller]")] means the
  /// route segment matches the controller class name minus "Controller"
  /// (e.g. DepartmentController -> api/Department).
  static Future<List<DepartmentModel>> getAllDepartments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    final Uri url = Uri.parse('$_baseUrl/Auth/all');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load departments. Status code: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    // Expected shape: { success, message, data: [ {...}, {...} ] }
    final List<dynamic> data = decoded is Map && decoded['data'] is List
        ? decoded['data'] as List<dynamic>
        : (decoded is List ? decoded : []);

    return data
        .map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}