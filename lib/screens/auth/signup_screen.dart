import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:wiqa/widgets/custom_header.dart'; 
import 'package:wiqa/l10n/app_localizations.dart'; 
import 'package:wiqa/services/auth_service.dart'; // 🚀 1. فكينا الكومنت من هنا
import 'login_screen.dart'; 
import 'auth_choice_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  static const Color _navyOverlay = Color(0xFF0F172A);
  static const Color primaryColor = Color(0xFFE26336);
  static const Color primaryGradientStart = Color(0xFFF28557);
  static const Color primaryGradientEnd = Color(0xFFC74A20);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 🚀 2. تعديل دالة إنشاء الحساب لربطها بالخادم
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // استدعاء الـ API الحقيقي
      final result = await AuthService.signUp(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      if (result['success'] == true) {
        _showCustomPopup(
          isSuccess: true,
          title: l10n.signupSuccessTitle,
          message: l10n.signupSuccessMsg,
          buttonText: l10n.btnContinue,
          onPressed: () {
            Navigator.pop(context); 
            // بعد النجاح وديه على صفحة تسجيل الدخول عشان يدخل بايميله الجديد
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          },
        );
      } else {
        _showCustomPopup(
          isSuccess: false,
          title: l10n.signupFailedTitle,
          message: result['error'] ?? l10n.authFailedMsg, // عرض خطأ السيرفر
          buttonText: l10n.btnTryAgain,
          onPressed: () => Navigator.pop(context), 
        );
      }
    } catch (e) {
      debugPrint("Signup UI Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // void _showCustomPopup({
  //   required bool isSuccess,
  //   required String title,
  //   required String message,
  //   required String buttonText,
  //   required VoidCallback onPressed,
  // }) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => Dialog(
  //       backgroundColor: Colors.transparent,
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(28),
  //         child: BackdropFilter(
  //           filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
  //           child: Container(
  //             padding: const EdgeInsets.all(24),
  //             decoration: BoxDecoration(
  //               color: _navyOverlay.withOpacity(0.7),
  //               borderRadius: BorderRadius.circular(28),
  //               border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
  //               boxShadow: [
  //                 BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25, spreadRadius: 5),
  //               ],
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const SizedBox(height: 10),
  //                 Container(
  //                   width: 75, height: 75,
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     color: isSuccess ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: (isSuccess ? Colors.green : Colors.redAccent).withOpacity(0.4),
  //                         blurRadius: 20,
  //                       ),
  //                     ],
  //                   ),
  //                   child: Center(
  //                     child: Icon(
  //                       isSuccess ? Icons.check : Icons.close,
  //                       color: Colors.white, size: 40,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 Text(
  //                   title,
  //                   style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
  //                   textAlign: TextAlign.center,
  //                 ),
  //                 const SizedBox(height: 10),
  //                 Text(
  //                   message,
  //                   style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
  //                   textAlign: TextAlign.center,
  //                 ),
  //                 const SizedBox(height: 28),
  //                 Container(
  //                   width: double.infinity, height: 50,
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(16),
  //                     gradient: LinearGradient(
  //                       colors: isSuccess 
  //                           ? [primaryGradientStart, primaryGradientEnd] 
  //                           : [const Color(0xFFFF5E62), const Color(0xFFFF9966)], 
  //                     ),
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: (isSuccess ? primaryGradientEnd : Colors.redAccent).withOpacity(0.4),
  //                         blurRadius: 12, offset: const Offset(0, 6),
  //                       ),
  //                     ],
  //                   ),
  //                   child: ElevatedButton(
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.transparent,
  //                       shadowColor: Colors.transparent,
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                     ),
  //                     onPressed: onPressed,
  //                     child: Text(
  //                       buttonText,
  //                       style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
      // درجة تعتيم الشاشة الخلفية خفيفة في كل الحالات
      barrierColor: Colors.black.withOpacity(0.25), 
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // لون خلفية النافذة أخف وأكثر شفافية
                color: _navyOverlay.withOpacity(0.4),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    // تخفيف ظل النافذة
                    color: Colors.black.withOpacity(0.15), 
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
                      // ألوان أيقونة النجاح والخطأ كما هي
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
                              height: 1.2,
                              letterSpacing: 1.0,
                            ),
                            children: [
                              TextSpan(text: l10n.createAccountPart1, style: const TextStyle(color: Colors.white)),
                              TextSpan(text: l10n.createAccountPart2, style: const TextStyle(color: primaryColor)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: const SizedBox(), 
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                border: Border(
                                  top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                                  left: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.0),
                                  right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.0),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                32, 
                                30, 
                                32, 
                                20 + MediaQuery.of(context).viewInsets.bottom
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildUnderlineTextField(
                                      controller: _fullNameController,
                                      hintText: l10n.fullNameLabel,
                                      icon: Icons.person_outline,
                                      validator: (val) => val!.isEmpty ? l10n.validationRequired : null,
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    _buildUnderlineTextField(
                                      controller: _emailController,
                                      hintText: l10n.emailLabel,
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
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
                                    const SizedBox(height: 24),
                                    
                                    _buildUnderlineTextField(
                                      controller: _confirmPasswordController,
                                      hintText: l10n.confirmPasswordLabel,
                                      icon: Icons.lock_reset_outlined,
                                      isPassword: true,
                                      obscureText: _obscureConfirmPassword,
                                      onTogglePassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return l10n.validationRequired;
                                        if (val != _passwordController.text) return l10n.validationNotMatched;
                                        return null;
                                      },
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
                                        onPressed: _isLoading ? null : _signup,
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 24, width: 24,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                              )
                                            : Text(
                                                l10n.btnSignUp,
                                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                              ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 24),

                                    Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                                          );
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            text: l10n.alreadyHaveAccount,
                                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w500),
                                            children: [
                                              TextSpan(
                                                text: l10n.signInLink,
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
          padding: const EdgeInsetsDirectional.only(end: 12.0),
          child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 22),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
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