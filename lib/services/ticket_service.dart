import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const Map<String, String> _classNameToDbFormat = {
  'NO_GLOVES': 'NO-Gloves',
  'NO_GOGGLES': 'NO-Goggles',
  'NO_HARDHAT': 'NO-Hardhat',
  'NO_MASK': 'NO-Mask',
  'NO_SAFETY_VEST': 'NO-Safety Vest',
  'FALL_DETECTED': 'Fall-Detected',
};

class TicketService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://91.108.112.27:5205';

  // =========================================================
  // GET MY TICKETS
  // =========================================================

  static Future<List<dynamic>> getMyTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. User might not be logged in.');
    }

    final Uri url = Uri.parse('$_baseUrl/Ticket/mytickets');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }

      return [];
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Token might be invalid or expired.');
    } else {
      throw Exception(
        'Failed to load tickets. Status code: ${response.statusCode}',
      );
    }
  }

  // =========================================================
  // GET ALL TICKETS (Admin only)
  // =========================================================

  static Future<List<dynamic>> getAllTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. User might not be logged in.');
    }

    final Uri url = Uri.parse('$_baseUrl/Ticket/alltickets');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden. Admin role required.');
    } else {
      throw Exception(
        'Failed to load all tickets. Status code: ${response.statusCode}',
      );
    }
  }

  // =========================================================
  // DELETE TICKET
  // =========================================================

  static Future<void> deleteTicket(int ticketId) async {
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');

  if (token == null || token.isEmpty) {
    throw Exception('No auth token found. User might not be logged in.');
  }

  final response = await http.delete(
    Uri.parse('$_baseUrl/Ticket/$ticketId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 204 && response.statusCode != 200) {
    throw Exception('Failed to delete ticket: ${response.statusCode} ${response.body}');
  }
}

static Future<void> toggleManualDetection({
    required int ticketId,
    required String className,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. User might not be logged in.');
    }

    final String dbClassName = _classNameToDbFormat[className] ?? className;

    final response = await http.post(
      Uri.parse('$_baseUrl/Ticket/manual-add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'TicketId': ticketId,
        'ClassName': dbClassName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update detection: ${response.statusCode} ${response.body}');
    }
  }

  static Future<bool> createTicket({
    required String title,
    required String description,
    required int departmentId,
    required String priority,
    List<String> detectedClasses = const [],
    double? latitude,
    double? longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    final String? sessionCookie = prefs.getString('session_cookie');

    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. User might not be logged in.');
    }

    final Uri url = Uri.parse('$_baseUrl/Ticket/create');

    final Map<String, dynamic> body = {
      'title': title,
      'description': description,
      'departmentId': departmentId,
      'priority': priority,
      if (detectedClasses.isNotEmpty) 'detectedClasses': detectedClasses,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        // Links this request to the session created during detection, so
        // the backend can find the already-uploaded file.
        if (sessionCookie != null && sessionCookie.isNotEmpty)
          'Cookie': sessionCookie,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }

    throw Exception(
      'Failed to create ticket. Status code: ${response.statusCode}, '
      'body: ${response.body}',
    );
  }

  static Future<void> deleteAccount() async {
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');

  if (token == null || token.isEmpty) {
    throw Exception('No auth token found. User might not be logged in.');
  }

  final response = await http.delete(
    Uri.parse('$_baseUrl/Auth/delete-account'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to delete account: '
      '${response.statusCode} ${response.body}',
    );
  }

  await prefs.remove('jwt_token');
  await prefs.remove('username');
  await prefs.remove('session_cookie');
}

}
