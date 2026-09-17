import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // 🚀 قراءة الرابط من ملف .env مع إضافة /Auth للوصول للـ Controller
  static String get baseUrl {
    final String apiBase = dotenv.env['API_BASE_URL'] ?? 'http://91.108.112.27:5021/api';
    return '$apiBase/Auth';
  }

  /// هيدرز الطلبات اللي محتاجة تسجيل دخول (Authorize). بيبعت التوكن
  /// المحفوظ في SharedPreferences ('jwt_token') كـ Cookie header يدوي،
  /// لأن مكتبة http مش بتبعت الكوكيز تلقائي زي المتصفح.
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Cookie': 'jwt=$token',
    };
  }

  /// دالة إنشاء الحساب
  static Future<Map<String, dynamic>> signUp(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'), // http://.../api/Auth/signup
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Username': username,
          'Email': email,
          'Password': password,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        var data = jsonDecode(response.body);
        return {
          'success': false,
          'error': data['error'] ?? 'حدث خطأ أثناء إنشاء الحساب',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'تعذر الاتصال بالخادم. تأكد من الإنترنت.'};
    }
  }

  /// دالة تسجيل الدخول
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'), // http://.../api/Auth/login
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': email,
          'Password': password,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // 🚨 استخراج الـ Token من الـ Cookies (كما هو مبرمج في C#)
        String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          int index = rawCookie.indexOf(';');
          String tokenStr = (index == -1) ? rawCookie : rawCookie.substring(0, index);
          String token = tokenStr.replaceFirst('jwt=', '');

          // حفظ التوكن وبيانات المستخدم محلياً
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('username', data['username'] ?? 'User');
        }

        return {'success': true, 'username': data['username']};
      } else if (response.statusCode == 401) {
        var data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'بيانات الدخول غير صحيحة'};
      } else {
        return {'success': false, 'error': 'خطأ غير معروف في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'error': 'تعذر الاتصال بالخادم. تأكد من الإنترنت.'};
    }
  }

  /// جلب بيانات المستخدم الحالي — GET /Auth/me
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse('$baseUrl/me'), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': 'Failed to load profile (${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'error': 'تعذر الاتصال بالخادم. تأكد من الإنترنت.'};
    }
  }

  /// تحديث اليوزرنيم و/أو كلمة المرور — PUT /Auth/update-profile
  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? newPassword,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = <String, dynamic>{};
      if (username != null && username.trim().isNotEmpty) {
        body['Username'] = username.trim();
      }
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        body['NewPassword'] = newPassword.trim();
      }

      final response = await http.put(
        Uri.parse('$baseUrl/update-profile'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // خلّي اليوزرنيم المحفوظ محلياً متزامن لو اتغيّر
        if (username != null && username.trim().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username.trim());
        }
        return {'success': true};
      }
      return {'success': false, 'error': 'Update failed (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'error': 'تعذر الاتصال بالخادم. تأكد من الإنترنت.'};
    }
  }

  /// دالة تسجيل الخروج — POST /Auth/logout
  static Future<void> logout() async {
    try {
      final headers = await _authHeaders();
      await http.post(Uri.parse('$baseUrl/logout'), headers: headers);
    } catch (e) {
      // تجاهل أخطاء الشبكة أثناء تسجيل الخروج
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('username');
    }
  }

  /// حذف الحساب نهائياً — DELETE /Auth/delete-account
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-account'),
        headers: headers,
      );

      // نمسح البيانات المحلية في كل الأحوال بعد محاولة الحذف
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('username');

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Delete failed (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'error': 'تعذر الاتصال بالخادم. تأكد من الإنترنت.'};
    }
  }
}