import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:wiqa/l10n/app_localizations.dart';
import '../../widgets/custom_header.dart';

import '../auth/auth_choice_screen.dart';


class UserService {
  static String get baseUrl {
    final String apiBase =
        dotenv.env['API_BASE_URL'] ?? 'http://91.108.112.27:5021/api';
    return '$apiBase/Auth';
  }

  static Future<Map<String, String>> _authHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  return {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty)
      'Authorization': 'Bearer $token',
  };
}

  /// GET /Auth/me
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse('$baseUrl/me'), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to load profile (${response.statusCode})'};
    } catch (_) {
      return {'success': false, 'error': 'connection_error'};
    }
  }

  /// PUT /Auth/update-profile
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
        // لو اليوزرنيم اتغيّر، خليه متزامن مع اللي متخزن محلي
        if (username != null && username.trim().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username.trim());
        }
        return {'success': true};
      }
      return {'success': false, 'error': 'Update failed (${response.statusCode})'};
    } catch (_) {
      return {'success': false, 'error': 'connection_error'};
    }
  }

  /// POST /Auth/logout
  static Future<void> logout() async {
    try {
      final headers = await _authHeaders();
      await http.post(Uri.parse('$baseUrl/logout'), headers: headers);
    } catch (_) {
      // تجاهل أخطاء الشبكة أثناء تسجيل الخروج
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('username');
    }
  }

  /// DELETE /Auth/delete-account
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final headers = await _authHeaders();
      final response =
          await http.delete(Uri.parse('$baseUrl/delete-account'), headers: headers);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('username');

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Delete failed (${response.statusCode})'};
    } catch (_) {
      return {'success': false, 'error': 'connection_error'};
    }
  }
}

/// -----------------------------------------------------------------------
/// ProfileScreen
/// -----------------------------------------------------------------------
class ProfileScreen extends StatefulWidget {
  /// بيتنفّذ بعد تسجيل الخروج أو حذف الحساب بنجاح. لو مش متبعت، الشاشة
  /// هتروح تلقائيًا لـ route اسمه '/login'.
  /// لو الـ route عندك مسمّى بشكل مختلف، أو بتفتح شاشة اللوجين بـ
  /// MaterialPageRoute بدل named route، غيّر _handleLoggedOut تحت.
  final VoidCallback? onLoggedOut;

  const ProfileScreen({super.key, this.onLoggedOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xFFFF8A3D);
  static const Color _accent2 = Color(0xFFFF6A00);
  static const Color _danger = Color(0xFFFF5252);
  static const Color _glassBg = Color(0x1AFFFFFF);
  static const Color _glassBorder = Color(0x22FFFFFF);

  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;

  String _username = '';
  String _email = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final result = await UserService.getMe();

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _username = data['username']?.toString() ?? '';
        _email = data['email']?.toString() ?? '';
        _role = data['role']?.toString() ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result['error']?.toString();
      });
    }
  }

  /// بعد تسجيل الخروج أو حذف الحساب: لو فيه onLoggedOut متبعت، بينفّذه.
  /// لو مش متبعت، بيروح تلقائي لصفحة اللوجين عن طريق named route '/login'.
  void _handleLoggedOut() {
  if (widget.onLoggedOut != null) {
    widget.onLoggedOut!();
  } else if (mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
      (route) => false,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            width: screenWidth,
            height: screenHeight,
            child: const Image(
              image: AssetImage('assets/images/ob_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            width: screenWidth,
            height: screenHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _navy.withOpacity(0.85),
                    _navy.withOpacity(0.70),
                    _navy.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _navy,
                onRefresh: _loadProfile,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  children: [
                    _buildTopBar(isArabic),
                    const SizedBox(height: 10),
                    if (_isLoading)
                      _buildLoading()
                    else if (_error != null)
                      _buildErrorState(isArabic)
                    else ...[
                      _buildProfileHeaderCard(isArabic),
                      const SizedBox(height: 16),
                      _buildActionsCard(isArabic),
                      const SizedBox(height: 16),
                      _buildDangerZoneCard(isArabic),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isArabic) {
    return const Column(
      children: [
        CustomHeader(),
        SizedBox(height: 30),
      ],
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.only(top: 100),
      child: Center(child: CircularProgressIndicator(color: _accent)),
    );
  }

  Widget _buildErrorState(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _danger.withOpacity(0.10),
                border: Border.all(color: _danger.withOpacity(0.25)),
              ),
              child: const Icon(Icons.cloud_off_outlined, color: _danger, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              isArabic ? 'تعذر تحميل بيانات الحساب' : 'Failed to load your profile',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _navy,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(bool isArabic) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_accent, _accent2]),
                  boxShadow: [
                    BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 18),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 14),
              Text(
                _username.isEmpty ? (isArabic ? 'مستخدم' : 'User') : _username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  _email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (_role.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildRoleBadge(_role, isArabic),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_outlined, color: _accent, size: 13),
          const SizedBox(width: 5),
          Text(
            role,
            style: const TextStyle(
              color: _accent,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(bool isArabic) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glassBorder),
          ),
          child: Column(
            children: [
              _buildActionTile(
                icon: Icons.edit_outlined,
                iconColor: _accent,
                title: isArabic ? 'تعديل البيانات' : 'Edit Profile',
                subtitle: isArabic
                    ? 'تغيير اسم المستخدم أو كلمة المرور'
                    : 'Change your username or password',
                onTap: () => _openEditProfileDialog(isArabic),
                isArabic: isArabic,
              ),
              Divider(color: Colors.white.withOpacity(0.08), height: 1, indent: 60),
              _buildActionTile(
                icon: Icons.logout_rounded,
                iconColor: Colors.white70,
                title: isArabic ? 'تسجيل الخروج' : 'Log Out',
                subtitle: isArabic
                    ? 'الخروج من حسابك على هذا الجهاز'
                    : 'Sign out of your account on this device',
                onTap: () => _confirmLogout(isArabic),
                isArabic: isArabic,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard(bool isArabic) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _danger.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _danger.withOpacity(0.22)),
          ),
          child: _buildActionTile(
            icon: Icons.delete_forever_outlined,
            iconColor: _danger,
            title: isArabic ? 'حذف الحساب' : 'Delete Account',
            subtitle: isArabic
                ? 'هذا الإجراء نهائي ولا يمكن التراجع عنه'
                : 'This action is permanent and cannot be undone',
            titleColor: _danger,
            onTap: () => _confirmDeleteAccount(isArabic),
            isArabic: isArabic,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isArabic,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: _isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.25)),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.42),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isArabic ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.30),
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Edit profile dialog
  // ------------------------------------------------------------------
  Future _openEditProfileDialog(bool isArabic) async {
    final usernameController = TextEditingController(text: _username);
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController(); 
    
    bool obscure = true;
    bool obscureConfirm = true; 
    String? localError;

    await showDialog(
      context: context,
      barrierDismissible: !_isBusy,
      barrierColor: Colors.black.withOpacity(.55),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24), // أضفنا مسافة رأسية لضمان عدم التصاقها
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF182848).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(.12)),
                    ),
                    // 👇 تم إضافة SingleChildScrollView هنا لمنع مشكلة الكيبورد
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: _isBusy ? null : () => Navigator.pop(dialogContext),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(.08),
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accent.withOpacity(.12),
                              boxShadow: [
                                BoxShadow(color: _accent.withOpacity(.35), blurRadius: 20, spreadRadius: 2),
                              ],
                            ),
                            child: const Icon(Icons.edit, color: _accent, size: 26),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isArabic ? 'تعديل البيانات' : 'Edit Profile',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _accent,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArabic
                                ? 'اترك حقل كلمة المرور فارغًا إذا كنت لا ترغب في تغييرها.'
                                : 'Leave the password field empty to keep it unchanged',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(.60),
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildDialogField(
                            controller: usernameController,
                            icon: Icons.person_outline,
                            hint: isArabic ? 'اسم المستخدم' : 'Username',
                          ),
                          const SizedBox(height: 12),
                          _buildDialogField(
                            controller: passwordController,
                            icon: Icons.lock_outline,
                            hint: isArabic ? 'كلمة مرور جديدة (اختياري)' : 'New password (optional)',
                            obscureText: obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () => setDialogState(() => obscure = !obscure),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          _buildDialogField(
                            controller: confirmPasswordController,
                            icon: Icons.lock_reset_outlined,
                            hint: isArabic ? 'تأكيد كلمة المرور' : 'Confirm new password',
                            obscureText: obscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                            ),
                          ),

                          if (localError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              localError!,
                              style: const TextStyle(color: _danger, fontSize: 11.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: _DialogActionButton(
                              label: isArabic ? 'حفظ التغييرات' : 'Save Changes',
                              icon: Icons.check,
                              isBusy: _isBusy,
                              onTap: () async {
                                if (usernameController.text.trim().isEmpty) {
                                  setDialogState(() {
                                    localError = isArabic
                                        ? 'اسم المستخدم مطلوب'
                                        : 'Username is required';
                                  });
                                  return;
                                }

                                if (passwordController.text.isNotEmpty) {
                                  if (passwordController.text != confirmPasswordController.text) {
                                    setDialogState(() {
                                      localError = isArabic
                                          ? 'كلمتا المرور غير متطابقتين'
                                          : 'Passwords do not match';
                                    });
                                    return;
                                  }
                                }

                                setDialogState(() => _isBusy = true);
                                setState(() => _isBusy = true);

                                final result = await UserService.updateProfile(
                                  username: usernameController.text,
                                  newPassword: passwordController.text,
                                );

                                setDialogState(() => _isBusy = false);
                                setState(() => _isBusy = false);

                                if (result['success'] == true) {
                                  if (mounted) Navigator.pop(dialogContext); // إغلاق نافذة التعديل

                                  // التحقق مما إذا كان المستخدم قد قام بتغيير كلمة المرور فعلياً
                                  if (passwordController.text.isNotEmpty) {
                                    // تحديث الاسم وتجميد الشاشة لمنع أي تفاعل أثناء العد التنازلي
                                    setState(() {
                                      _username = usernameController.text.trim();
                                      _isBusy = true; 
                                    });

                                    _showSnack(
                                      isArabic 
                                          ? 'تم تغيير كلمة المرور. سيتم تسجيل الخروج خلال 5 ثوانٍ...' 
                                          : 'Password changed. Logging out in 5 seconds...',
                                      isError: false,
                                    );

                                    // الانتظار لمدة 5 ثوانٍ
                                    await Future.delayed(const Duration(seconds: 5));

                                    // التأكد أن الـ Widget ما زال موجوداً في الشجرة قبل إكمال العمليات
                                    if (!mounted) return;
                                    
                                    await UserService.logout();
                                    
                                    if (!mounted) return;
                                    setState(() => _isBusy = false);
                                    _handleLoggedOut();
                                    
                                  } else {
                                    // في حال تغيير اسم المستخدم فقط بدون كلمة المرور
                                    _showSnack(
                                      isArabic ? 'تم تحديث البيانات بنجاح' : 'Profile updated successfully',
                                      isError: false,
                                    );
                                    setState(() {
                                      _username = usernameController.text.trim();
                                    });
                                  }
                                } else {
                                  setDialogState(() {
                                    localError = isArabic
                                        ? 'حدث خطأ أثناء التحديث'
                                        : 'Something went wrong while updating';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(.35), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(.45), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.4),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Logout confirmation
  // ------------------------------------------------------------------
Future<void> _confirmLogout(bool isArabic) async {
  bool isLoggingOut = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> performLogout() async {
            setDialogState(() {
              isLoggingOut = true;
            });

            await UserService.logout();

            if (!mounted) return;

            Navigator.of(dialogContext).pop();
            _handleLoggedOut();
          }

          return PopScope(
            canPop: !isLoggingOut,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 18,
                    sigmaY: 18,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      20,
                    ),
                    decoration: BoxDecoration(
                      // نفس خلفية Edit Profile
                      color: const Color(0xFF182848).withOpacity(.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _accent.withOpacity(.20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // =========================
                        // ICON / LOADING
                        // =========================
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accent.withOpacity(.12),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(.20),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: isLoggingOut
                              ? const Padding(
                                  padding: EdgeInsets.all(15),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _accent,
                                  ),
                                )
                              : const Icon(
                                  Icons.logout_rounded,
                                  color: _accent,
                                  size: 26,
                                ),
                        ),

                        const SizedBox(height: 14),

                        // =========================
                        // TITLE
                        // =========================
                        Text(
                          isLoggingOut
                              ? (isArabic
                                  ? 'جاري تسجيل الخروج...'
                                  : 'Logging out...')
                              : (isArabic
                                  ? 'تسجيل الخروج'
                                  : 'Log Out'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // =========================
                        // MESSAGE
                        // =========================
                        Text(
                          isLoggingOut
                              ? (isArabic
                                  ? 'يرجى الانتظار'
                                  : 'Please wait')
                              : (isArabic
                                  ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟'
                                  : 'Are you sure you want to log out?'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.70),
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // =========================
                        // BUTTONS
                        // =========================
                        if (!isLoggingOut)
                          Row(
                            children: [
                              Expanded(
                                child: _DialogActionButton(
                                  label: isArabic
                                      ? 'إلغاء'
                                      : 'Cancel',
                                  filled: false,
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                  },
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: _DialogActionButton(
                                  label: isArabic
                                      ? 'تسجيل الخروج'
                                      : 'Log Out',
                                  color: _accent,
                                  onTap: performLogout,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  // ------------------------------------------------------------------
  // Delete account confirmation
  // ------------------------------------------------------------------
  Future<void> _confirmDeleteAccount(bool isArabic) async {
  final confirmed = await _showConfirmDialog(
    isArabic: isArabic,
    icon: Icons.delete_forever_outlined,
    iconColor: _danger,
    title: isArabic ? 'حذف الحساب' : 'Delete Account',
    message: isArabic
        ? 'هذا الإجراء نهائي ولا يمكن التراجع عنه. سيتم حذف حسابك بشكل كامل. هل تريد المتابعة؟'
        : 'This action is permanent and cannot be undone. Your account will be deleted entirely. Continue?',
    confirmLabel: isArabic ? 'حذف نهائي' : 'Delete Permanently',
    confirmColor: _danger,
  );

  if (confirmed != true) return;

  setState(() => _isBusy = true);

  try {
    await UserService.deleteAccount();

    if (!mounted) return;

    setState(() => _isBusy = false);
    _handleLoggedOut();
  } catch (_) {
    if (!mounted) return;

    setState(() => _isBusy = false);

    _showSnack(
      isArabic
          ? 'تعذر حذف الحساب، حاول مرة أخرى'
          : 'Could not delete account, please try again',
      isError: true,
    );
  }
}

  Future<bool?> _showConfirmDialog({
  required bool isArabic,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String message,
  required String confirmLabel,
  required Color confirmColor,
}) {
  bool isLoggingOut = false;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(.55),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return PopScope(
            canPop: !isLoggingOut,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 18,
                    sigmaY: 18,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      20,
                    ),
                    decoration: BoxDecoration(
                      // نفس خلفية Edit Profile
                      color: const Color(0xFF182848).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: iconColor.withOpacity(.20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconColor.withOpacity(.12),
                          ),
                          child: isLoggingOut
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _accent,
                                  ),
                                )
                              : Icon(
                                  icon,
                                  color: iconColor,
                                  size: 26,
                                ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          isLoggingOut
                              ? (isArabic
                                  ? 'جاري تسجيل الخروج'
                                  : 'Logging out')
                              : title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          isLoggingOut
                              ? (isArabic
                                  ? 'يرجى الانتظار...'
                                  : 'Please wait...')
                              : message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.70),
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (isLoggingOut)
                          const SizedBox(
                            height: 48,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _accent,
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _DialogActionButton(
                                  label: isArabic
                                      ? 'إلغاء'
                                      : 'Cancel',
                                  filled: false,
                                  onTap: () {
                                    Navigator.pop(
                                      dialogContext,
                                      false,
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: _DialogActionButton(
                                  label: confirmLabel,
                                  color: confirmColor,
                                  onTap: () {
                                    setDialogState(() {
                                      isLoggingOut = true;
                                    });

                                    // نقفل الـ dialog ونرجع true
                                    // بعد ظهور الـ loading مباشرة
                                    Future.delayed(
                                      const Duration(milliseconds: 250),
                                      () {
                                        if (dialogContext.mounted) {
                                          Navigator.pop(
                                            dialogContext,
                                            true,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _danger : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Small reusable pill button used inside dialogs.
class _DialogActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool filled;
  final bool isBusy;
  final Color? color;

  const _DialogActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    this.isBusy = false,
    this.color,
  });

  static const Color _accent = Color(0xFFFF8A3D);
  static const Color _accent2 = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    final Color base = color ?? _accent;

    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: filled ? LinearGradient(colors: [base, base.withOpacity(0.75)]) : null,
          color: filled ? null : Colors.white.withOpacity(.06),
          border: Border.all(
            color: filled ? Colors.transparent : Colors.white.withOpacity(.15),
          ),
        ),
        child: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}