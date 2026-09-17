import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/language_controller.dart'; 

class CustomHeader extends StatefulWidget {
  const CustomHeader({super.key});

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  bool _playShimmer = false;

  void _changeLanguage(bool isEnglish) async {
    HapticFeedback.selectionClick();
    setState(() => _playShimmer = true);
    languageController.changeLanguage(isEnglish ? "ar" : "en");
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _playShimmer = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        final isEnglish = languageController.locale.languageCode == "en";
        final screenWidth = MediaQuery.of(context).size.width;

        final switchWidth = (screenWidth * .15).clamp(70.0, 85.0);
        final switchHeight = (screenWidth * .075).clamp(28.0, 38.0);

        final sliderWidth = switchWidth / 2 - 4;
        final sliderHeight = switchHeight - 4;
        final fontSize = (screenWidth * .032).clamp(11.0, 13.0);
        const primaryColor = Color(0xFFE26336);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/kasct.png',
                  height: 32, 
                  fit: BoxFit.contain,
                ),

                GestureDetector(
                  onTap: () => _changeLanguage(isEnglish),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(switchHeight),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: switchWidth,
                        height: switchHeight,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          // 🚀 التعديل الأول: لون فاتح زجاجي أنيق جداً 
                          color: Colors.white.withOpacity(0.12), 
                          borderRadius: BorderRadius.circular(switchHeight),
                          border: Border.all(
                            // 🚀 التعديل الثاني: صغرنا حجم الإطار وخففنا حدته
                            color: primaryColor.withOpacity(0.5),
                            width: 0.8, // كان 1.5
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.fastEaseInToSlowEaseOut,
                              alignment: isEnglish ? Alignment.centerLeft : Alignment.centerRight,
                              child: Stack(
                                children: [
                                  Container(
                                    width: sliderWidth,
                                    height: sliderHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(sliderHeight),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFF28557), Color(0xFFC74A20)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(.45),
                                          blurRadius: 12,
                                          spreadRadius: 1.5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_playShimmer)
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(sliderHeight),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: -1, end: 2),
                                          duration: const Duration(milliseconds: 650),
                                          builder: (context, value, _) {
                                            return Transform.translate(
                                              offset: Offset(value * sliderWidth, 0),
                                              child: Container(
                                                width: 14,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.white.withOpacity(.6),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 250),
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w700,
                                        color: isEnglish ? Colors.white : const Color(0xFFFCA5A5).withOpacity(0.9),
                                      ),
                                      child: const Text("EN"),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 250),
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w700,
                                        color: isEnglish ? const Color(0xFFFCA5A5).withOpacity(0.9) : Colors.white,
                                      ),
                                      child: const Text("AR"),
                                    ),
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
              ],
            ),
          ),
        );
      },
    );
  }
}