import 'package:flutter/material.dart';

import 'package:wiqa/l10n/app_localizations.dart';
import 'package:wiqa/widgets/custom_header.dart'; 
import 'package:wiqa/screens/onboarding/onboarding_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const primaryColor = Color(0xFFE26336);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/welcome.png", 
            fit: BoxFit.cover,
            alignment: const Alignment(-0.6, -1.0), 
          ),

          ///==========================
          /// 5. التدرج (Smooth Gradient)
          ///==========================
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,                           // شفاف تماماً لفترة أطول
                  const Color(0xFF0F172A).withOpacity(0.15),    // خفيف في المنتصف
                  const Color(0xFF0F172A).withOpacity(0.75),    // متوسط عند العنوان
                  const Color(0xFF0F172A).withOpacity(0.95),    // داكن كفاية عند الزرار
                ],
                stops: const [0.0, 0.5, 0.8, 1.0], // توزيع تدريجي ناعم جداً
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  CustomHeader(), 

                  const Spacer(),

                  ///==========================
                  /// 1. Title (Welcome to WIQA)
                  ///==========================
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFCA5A5), 
                          Color(0xFFF28557), 
                          Color(0xFFC74A20), 
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "${l10n.welcomeTo}${l10n.appName}",
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 32, // الحجم الجديد
                          fontWeight: FontWeight.bold, // الوزن Bold
                          height: 1,
                        ),
                      ),
                    ),
                  ),

                  // المسافة بين العنوان والوصف (10 px)
                  const SizedBox(height: 10),

                  ///==========================
                  /// 2. Subtitle (Detect. Protect. Prevent.)
                  ///==========================
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: "${l10n.detect} ",
                            style: const TextStyle(color: Colors.white), // أبيض
                          ),
                          TextSpan(
                            text: "${l10n.protect} ",
                            style: TextStyle(color: primaryColor.withOpacity(0.75)), // برتقالي
                          ),
                          TextSpan(
                            text: l10n.prevent,
                            style: const TextStyle(color: Color(0xFF9BE7FF)), // أزرق فاتح
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  ///==========================
                  /// 3. Get Started Button 
                  ///==========================
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Container(
                      width: double.infinity,
                      height: 62, // الارتفاع الجديد
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF28557),
                            Color(0xFFC74A20),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20), // الحواف الجديدة
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 600),
                              pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                // حركة دخول الشاشة من اليمين بخفة مع ظهور تدريجي
                                const begin = Offset(0.05, 0.0); 
                                const end = Offset.zero;
                                const curve = Curves.easeInOutCubic;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.getStartedBtn, 
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600, // SemiBold
                                color: Colors.white,
                              ),
                            ),
                            // مسافة قريبة بين النص والسهم
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}