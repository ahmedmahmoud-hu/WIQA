import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:wiqa/widgets/custom_header.dart';
import 'package:wiqa/l10n/app_localizations.dart'; 
import 'package:wiqa/services/auth_service.dart'; // 🚀 1. فكينا الكومنت من هنا
import 'signup_screen.dart';
import '../main/main_navigation_screen.dart';
import 'auth_choice_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color _navyOverlay = Color(0xFF0F172A);
  static const Color primaryColor = Color(0xFFE26336);
  static const Color primaryGradientStart = Color(0xFFF28557);
  static const Color primaryGradientEnd = Color(0xFFC74A20);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🚀 2. تعديل دالة تسجيل الدخول لربطها بالخادم
  // Future<void> _login() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => _isLoading = true);

  //   try {
  //     // استدعاء הـ API الحقيقي
  //     final result = await AuthService.login(
  //       _emailController.text.trim(),
  //       _passwordController.text.trim(),
  //     );

  //     if (!mounted) return;

  //     final l10n = AppLocalizations.of(context)!;

  //     if (result['success'] == true) {
  //       _showCustomPopup(
  //         isSuccess: true,
  //         title: l10n.loginSuccessTitle,
  //         message: l10n.loginSuccessMsg,
  //         buttonText: l10n.btnContinue,
  //         onPressed: () {
  //           Navigator.pop(context);
  //           // 🚀 هنا تحط مسار الصفحة الرئيسية بتاعتك بعد النجاح
  //           // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));

  //           Navigator.pushReplacement(
  //             context, 
  //             MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
  //           );

  //         },
  //       );
  //     } else {
  //       _showCustomPopup(
  //         isSuccess: false,
  //         title: l10n.loginFailedTitle,
  //         message: result['error'] ?? l10n.authFailedMsg, // عرض خطأ السيرفر
  //         buttonText: l10n.btnTryAgain,
  //         onPressed: () => Navigator.pop(context),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint("Login UI Error: $e");
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  // 🚀 2. تعديل دالة تسجيل الدخول لربطها بالخادم
  Future _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // استدعاء الـ API الحقيقي
      final result = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      if (result['success'] == true) {
        // الانتقال المباشر للصفحة الرئيسية بدون إظهار نافذة النجاح
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        // إظهار نافذة الخطأ فقط
        _showCustomPopup(
          isSuccess: false,
          title: l10n.loginFailedTitle,
          message: result['error'] ?? l10n.authFailedMsg, // عرض خطأ السيرفر
          buttonText: l10n.btnTryAgain,
          onPressed: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      debugPrint("Login UI Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  

  void _showCustomPopup({
    required bool isSuccess,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // تقليل تعتيم الشاشة الخلفية للـ Dialog في حالة الخطأ
      barrierColor: Colors.black.withOpacity(isSuccess ? 0.5 : 0.25), 
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // تقليل شفافية لون النافذة نفسها (0.4 للخطأ بدلاً من 0.7)
                color: _navyOverlay.withOpacity(isSuccess ? 0.7 : 0.4),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(isSuccess ? 0.15 : 0.08), 
                  width: 1.5
                ),
                boxShadow: [
                  BoxShadow(
                    // تقليل قوة الظل خلف النافذة في حالة الخطأ
                    color: Colors.black.withOpacity(isSuccess ? 0.3 : 0.15), 
                    blurRadius: 25, 
                    spreadRadius: 5
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 75, height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSuccess ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: (isSuccess ? Colors.green : Colors.redAccent).withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isSuccess ? Icons.check : Icons.close,
                        color: Colors.white, size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity, height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isSuccess 
                            ? [primaryGradientStart, primaryGradientEnd] 
                            : [const Color(0xFFFF5E62), const Color(0xFFFF9966)], 
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSuccess ? primaryGradientEnd : Colors.redAccent).withOpacity(0.4),
                          blurRadius: 12, offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: onPressed,
                      child: Text(
                        buttonText,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
        );
      },
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/ob_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _navyOverlay.withOpacity(0.4),
                    _navyOverlay.withOpacity(0.2),
                    _navyOverlay.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: CustomHeader(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              height: 1.05,
                              letterSpacing: 0.5,
                            ),
                            children: [
                              TextSpan(text: l10n.welcomePart1, style: const TextStyle(color: Colors.white)),
                              TextSpan(text: l10n.welcomePart2, style: const TextStyle(color: primaryColor)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6.5, sigmaY: 6.5),
                              child: const SizedBox(),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.11),
                                    Colors.white.withOpacity(0.06),
                                  ],
                                ),
                                border: Border(
                                  top: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2),
                                  left: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.0),
                                  right: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.0),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                32,
                                28,
                                32,
                                20 + MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildUnderlineTextField(
                                      controller: _emailController,
                                      hintText: l10n.emailLabel,
                                      icon: Icons.email_outlined,
                                      validator: (val) => val!.isEmpty ? l10n.validationRequired : null,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildUnderlineTextField(
                                      controller: _passwordController,
                                      hintText: l10n.passwordLabel,
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscureText: _obscurePassword,
                                      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                                      validator: (val) => val!.isEmpty ? l10n.validationRequired : null,
                                    ),
                                    const SizedBox(height: 14),
                                    Align(
                                      alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                                      child: GestureDetector(
                                        onTap: () {},
                                        child: Text(
                                          l10n.forgotPassword,
                                          style: const TextStyle(
                                            color: primaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    Container(
                                      width: double.infinity, height: 55,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          colors: [primaryGradientStart, primaryGradientEnd],
                                        ),
                                        boxShadow: [
                                          BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5)),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        onPressed: _isLoading ? null : _login,
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 24, width: 24,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                              )
                                            : Text(
                                                l10n.btnSignIn,
                                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                                          );
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            text: l10n.dontHaveAccount,
                                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w500),
                                            children: [
                                              TextSpan(
                                                text: l10n.signUpLink,
                                                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      validator: validator,
      cursorColor: primaryColor,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15, fontWeight: FontWeight.w500),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 10.0),
          child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                color: Colors.white.withOpacity(0.6),
                iconSize: 20,
                onPressed: onTogglePassword,
              )
            : null,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
        ),
      ),
    );
  }
}