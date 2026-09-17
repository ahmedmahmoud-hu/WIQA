import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wiqa/l10n/app_localizations.dart';

import '../home/home_screen.dart';
import '../reports/my_reports_screen.dart';
import '../statistics/statistics_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final List<dynamic> tickets;

  const MainNavigationScreen({
    super.key,
    this.tickets = const [],
  });

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 🎨 ألوان PPE Detection (كحلي + برتقالي)
  static const Color _navy = Color(0xFF0F172A);
  static const Color _accent = Color(0xFFE26336); // برتقالي أساسي
  static const Color _accent2 = Color(0xFFFF8A5C); // برتقالي فاتح للتدرج
  static const Color _inactiveIcon = Color(0xFF9CA3AF);

  // =========================================================
  // SCREENS
  // =========================================================

  List<Widget> get _screens {
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return [
      HomeScreen(
        onViewAllReports: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),

      // MyReportsScreen لا يستقبل tickets حالياً
      const MyReportsScreen(),

      // StatisticsScreen يحتاج tickets + isArabic
      StatisticsScreen(
        tickets: widget.tickets,
        isArabic: isArabic,
      ),

      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _navy,
      extendBody: true,
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(l10n),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION BAR
  // =========================================================

  Widget _buildBottomNavigationBar(
    AppLocalizations l10n,
  ) {
    final double screenWidth =
        MediaQuery.of(context).size.width;

    const double horizontalPadding = 20.0;
    const double gap = 8.0; // مسافة ثابتة بين كل عنصر وعنصر

    final double barWidth = screenWidth - 40;

    final double innerWidth =
        barWidth - (horizontalPadding * 2);

    // 4 عناصر و3 فجوات بينهم
    final double itemWidth =
        (innerWidth - (gap * 3)) / 4;

    final double targetX =
        horizontalPadding +
        (_currentIndex * (itemWidth + gap)) +
        (itemWidth / 2);

    const double circleSize = 44.0;
    const double barRadius = 16.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 12,
        ),
        child: SizedBox(
          height: 90,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: targetX),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // =====================================================
                  // GLASS BAR
                  // =====================================================

                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Stack(
                      children: [
                        ClipPath(
                          clipper: _CurvedBottomBarClipper(
                            value,
                            barRadius,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 18,
                              sigmaY: 18,
                            ),
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),

                        CustomPaint(
                          painter: _CurvedBottomBarPainter(
                            value,
                            barRadius,
                          ),
                          child: Container(),
                        ),
                      ],
                    ),
                  ),

                  // =====================================================
                  // ICONS + TEXT (بفجوات ثابتة بينهم)
                  // =====================================================

                  Positioned(
                    top: 20,
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: 0,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: _buildNavItem(
                              0,
                              Icons.home_outlined,
                              l10n.navHome,
                            ),
                          ),
                          SizedBox(width: gap),
                          SizedBox(
                            width: itemWidth,
                            child: _buildNavItem(
                              1,
                              Icons.assignment_outlined,
                              l10n.navMyReports,
                            ),
                          ),
                          SizedBox(width: gap),
                          SizedBox(
                            width: itemWidth,
                            child: _buildNavItem(
                              2,
                              Icons.bar_chart_outlined,
                              l10n.navStatistics,
                            ),
                          ),
                          SizedBox(width: gap),
                          SizedBox(
                            width: itemWidth,
                            child: _buildNavItem(
                              3,
                              Icons.person_outline,
                              l10n.navProfile,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // =====================================================
                  // FLOATING CIRCLE
                  // =====================================================

                  Positioned(
                    left: value - (circleSize / 2),
                    top: 5,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {}, // هو أصلاً محدد، مفيش داعي يعمل حاجة
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              _accent2,
                              _accent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration:
                                const Duration(milliseconds: 250),
                            transitionBuilder:
                                (child, anim) {
                              return ScaleTransition(
                                scale: anim,
                                child: child,
                              );
                            },
                            child: Icon(
                              _getFilledIcon(_currentIndex),
                              key: ValueKey(_currentIndex),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================================================
  // NAV ITEM
  // =========================================================

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    String label,
  ) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            duration:
                const Duration(milliseconds: 300),
            opacity: isSelected ? 0.0 : 1.0,
            child: Icon(
              outlineIcon,
              color: _inactiveIcon,
              size: 22,
            ),
          ),

          const SizedBox(height: 6),

          AnimatedDefaultTextStyle(
            duration:
                const Duration(milliseconds: 300),
            style: TextStyle(
              color:
                  isSelected ? _accent : _inactiveIcon,
              fontSize: 11,
              fontWeight:
                  isSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // =========================================================
  // FILLED ICON
  // =========================================================

  IconData _getFilledIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;

      case 1:
        return Icons.assignment;

      case 2:
        return Icons.bar_chart;

      case 3:
        return Icons.person;

      default:
        return Icons.home;
    }
  }
}

// =========================================================
// CUSTOM NAV PATH
// =========================================================

Path _getNavPath(
  Size size,
  double position,
  double radius,
) {
  final RRect baseRect =
      RRect.fromRectAndRadius(
    Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ),
    Radius.circular(radius),
  );

  final Path basePath =
      Path()..addRRect(baseRect);

  final CircularNotchedRectangle notch =
      CircularNotchedRectangle();

  final Rect host =
      Rect.fromLTWH(
    0,
    0,
    size.width,
    size.height,
  );

  final Rect guest =
      Rect.fromCenter(
    center: Offset(position, 8),
    width: 56,
    height: 56,
  );

  final Path notchedPath =
      notch.getOuterPath(
    host,
    guest,
  );

  return Path.combine(
    PathOperation.intersect,
    basePath,
    notchedPath,
  );
}

// =========================================================
// CLIPPER
// =========================================================

class _CurvedBottomBarClipper
    extends CustomClipper<Path> {
  final double position;
  final double radius;

  _CurvedBottomBarClipper(
    this.position,
    this.radius,
  );

  @override
  Path getClip(Size size) {
    return _getNavPath(
      size,
      position,
      radius,
    );
  }

  @override
  bool shouldReclip(
    _CurvedBottomBarClipper old,
  ) {
    return old.position != position ||
        old.radius != radius;
  }
}

// =========================================================
// PAINTER
// =========================================================

class _CurvedBottomBarPainter
    extends CustomPainter {
  final double position;
  final double radius;

  _CurvedBottomBarPainter(
    this.position,
    this.radius,
  );

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Path path =
        _getNavPath(
      size,
      position,
      radius,
    );

    // Shadow
    final Path canvasPath =
        Path()
          ..addRect(
            Rect.fromLTWH(
              -100,
              -100,
              size.width + 200,
              size.height + 200,
            ),
          );

    final Path shadowClipPath =
        Path.combine(
      PathOperation.difference,
      canvasPath,
      path,
    );

    canvas.save();

    canvas.clipPath(shadowClipPath);

    canvas.translate(0, 8);

    final Paint shadowPaint =
        Paint()
          ..color =
              Colors.black.withOpacity(0.3)
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            12,
          );

    canvas.drawPath(
      path,
      shadowPaint,
    );

    canvas.restore();

    // Fill
    final Paint fillPaint =
        Paint()
          ..color =
              Colors.white.withOpacity(0.08)
          ..style =
              PaintingStyle.fill;

    canvas.drawPath(
      path,
      fillPaint,
    );

    // Border
    final Paint strokePaint =
        Paint()
          ..color =
              Colors.white.withOpacity(0.20)
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1.2;

    canvas.drawPath(
      path,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(
    _CurvedBottomBarPainter old,
  ) {
    return old.position != position ||
        old.radius != radius;
  }
}