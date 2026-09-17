import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

// تأكد من مسارات الاستدعاء دي حسب هيكل مشروعك
import 'package:wiqa/l10n/app_localizations.dart';
import 'package:wiqa/widgets/custom_header.dart';

// فك الكومنت عن الشاشات دي لما تجهزها
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  late VideoPlayerController _videoController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // خلفيات مواقع البناء (تأكد من إضافتها في مجلد assets)
  final List<String> _bgImages = [
    'assets/images/ob_bg.png',
    'assets/images/ob_bg.png',
    'assets/images/ob_bg.png',
  ];

  final Color primaryColor = const Color(0xFFE26336);

  /// بيانات عناصر السلامة (الـ 6 كلاسات المطابقة لـ allowed_classes)
  /// isSafe = true  -> علامة صح خضرا (عنصر معدات سلامة عادي)
  /// isSafe = false -> علامة غلط حمرا (حالة خطر متكشفة، زي السقوط)
  final List<Map<String, dynamic>> _ppeClasses = const [
    {
      'icon': Icons.engineering_outlined,
      'label': 'عدم ارتداء الخوذة',
      'isSafe': true,
    },
    {
      'icon': Icons.checkroom_outlined,
      'label': 'عدم ارتداء السترة العاكسة',
      'isSafe': true,
    },
    {
      'icon': Icons.back_hand_outlined,
      'label': 'عدم ارتداء القفازات',
      'isSafe': true,
    },
    {
      'icon': Icons.remove_red_eye_outlined,
      'label': 'عدم ارتداء النظارات الواقية',
      'isSafe': true,
    },
    {
      'icon': Icons.masks_outlined,
      'label': 'عدم ارتداء الكمامة',
      'isSafe': true,
    },
    {
      'icon': Icons.personal_injury_outlined,
      'label': 'السقوط المرصود',
      'isSafe': false,
    },
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);
    _pageController.addListener(() {
      setState(() {});
    });

    // الأنيميشن الخاص بزرار "Next"
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // إعدادات الفيديو
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse("https://wiqaksa.com/videos/WIQA.mp4"),
    );

    _videoController.initialize().then((_) async {
      await _videoController.setLooping(true);
      await _videoController.setVolume(1.0);
      await _videoController.play();
      if (mounted) setState(() {});
    }).catchError((e) {
      debugPrint("Video Error: $e");
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _playPause() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
    setState(() {});
  }

  void _onNextPressed() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding(Widget nextScreen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // استدعاء ملفات الترجمة
    final l10n = AppLocalizations.of(context)!;

    // 🚀 التعديل هنا: إجبار الشاشة بالكامل إنها تفضل Left-To-Right (من الشمال لليمين)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            /// 1. Dynamic Background Image
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                _bgImages[_currentPage],
                key: ValueKey<int>(_currentPage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            /// 2. Premium Dark Navy Overlay (Depth & Contrast)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F172A).withOpacity(0.0), // شفاف تماماً في الأعلى
                    const Color(0xFF0F172A).withOpacity(0.2), // تعتيم خفيف جداً
                    const Color(0xFF0F172A).withOpacity(0.75), // داكن خلف النصوص والفيديو
                    const Color(0xFF0F172A).withOpacity(0.25), // كحلي صريح أسفل الشاشة
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    /// 3. Header (Logo + Switcher)
                    const CustomHeader(),

                    const SizedBox(height: 12),

                    /// 4. PageView Content
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                          if (index != 0) _videoController.pause();
                        },
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          Widget page;
                          if (index == 0) {
                            page = _buildVideoPage(l10n);
                          } else if (index == 1) {
                            page = _buildStepsPage(context, l10n);
                          } else {
                            page = _buildWhyWiqaPage(context, l10n);
                          }
                          return _buildTransitionWrapper(index: index, child: page);
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 5. Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(index: 0),
                        const SizedBox(width: 6),
                        _buildDot(index: 1),
                        const SizedBox(width: 6),
                        _buildDot(index: 2),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// 6. Bottom Buttons
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _currentPage < 2
                          ? _buildNextAndSkipSection(l10n)
                          : _buildAuthButtonsSection(l10n),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================================
  /// Transitions & Dots
  /// =========================================
  Widget _buildTransitionWrapper({required int index, required Widget child}) {
    double page = _currentPage.toDouble();
    if (_pageController.position.haveDimensions) {
      page = _pageController.page ?? _currentPage.toDouble();
    }
    final double value = (page - index);
    final double clamped = value.clamp(-1.0, 1.0);
    final double opacity = (1 - clamped.abs()).clamp(0.0, 1.0);
    final double dx = clamped * 60;
    final double scale = (1 - (clamped.abs() * 0.08)).clamp(0.85, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        // 🚀 التعديل: رجعنا الـ offset لطبيعته (dx) عشان يناسب الـ LTR
        offset: Offset(dx, 0),
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }

  Widget _buildDot({required int index}) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// =========================================
  /// Page 1: Video Page
  /// =========================================
  Widget _buildVideoPage(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// 1. Logo
        const SizedBox(height: 20),
        Image.asset(
          'assets/images/logo1.png',
          height: 70,
          fit: BoxFit.contain,
          color: const Color(0xFFC74A20),
        ),
        const SizedBox(height: 20),

        /// 2. Word WIQA
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFCA5A5), Color(0xFFF28557), Color(0xFFC74A20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            l10n.onboarding1Title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 12),

        /// 3. Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            l10n.onboarding1Description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),

        /// 4. Video
        _buildVideoCard(),
      ],
    );
  }

  /// =========================================
  /// Page 2: How It Works
  /// =========================================
  Widget _buildStepsPage(BuildContext context, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxHeight < 480;

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildTitleSection(l10n.onboarding2Title, l10n.onboarding2Description, compact: isSmallScreen),
            _buildStepCard(
              context,
              number: "1",
              icon: Icons.camera_alt_outlined,
              title: l10n.step1Title,
              description: l10n.step1Desc,
              compact: isSmallScreen,
            ),
            _buildStepCard(
              context,
              number: "2",
              icon: Icons.psychology_outlined,
              title: l10n.step2Title,
              description: l10n.step2Desc,
              compact: isSmallScreen,
            ),
            _buildStepCard(
              context,
              number: "3",
              icon: Icons.security_rounded,
              title: l10n.step3Title,
              description: l10n.step3Desc,
              compact: isSmallScreen,
            ),
          ],
        );
      },
    );
  }

  /// =========================================
  /// Page 3: Why WIQA?
  /// =========================================
  Widget _buildWhyWiqaPage(BuildContext context, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxHeight < 480;

        final titleParts = l10n.onboarding3Title.split('\n');
        final String firstLine = titleParts.isNotEmpty ? titleParts[0] : '';
        final String secondLine = titleParts.length > 1 ? titleParts[1] : '';

        final List<Map<String, dynamic>> ppeClasses = [
          {
            'image': 'assets/images/hardhat.png',
            'label': l10n.ppeHelmet,
            'isSafe': true,
          },
          {
            'image': 'assets/images/vest.png',
            'label': l10n.ppeVest,
            'isSafe': true,
          },
          {
            'image': 'assets/images/gloves.png',
            'label': l10n.ppeGloves,
            'isSafe': true,
          },
          {
            'image': 'assets/images/goggles.png',
            'label': l10n.ppeGoggles,
            'isSafe': true,
          },
          {
            'image': 'assets/images/mask.png',
            'label': l10n.ppeMask,
            'isSafe': true,
          },
          // {
          //   'image': 'assets/images/fall.png',
          //   'label': l10n.ppeFall,
          //   'isSafe': false,
          // },
        ];

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              'assets/images/logo1.png',
              height: 70,
              fit: BoxFit.contain,
              color: primaryColor,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  firstLine,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 24 : 29,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secondLine,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: isSmallScreen ? 24 : 29,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.onboarding3Description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: isSmallScreen ? 13 : 15,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: isSmallScreen ? 10 : 16,
              runSpacing: isSmallScreen ? 10 : 14,
              children: ppeClasses.map((item) {
                return _buildPpeItem(
                  imagePath: item['image'] as String, // تم التعديل هنا لاستخدام imagePath بدلاً من icon
                  label: item['label'] as String,
                  isSafe: item['isSafe'] as bool,
                  compact: isSmallScreen,
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPpeItem({
    required String imagePath,
    required String label,
    required bool isSafe,
    bool compact = false,
  }) {
    final double circleSize = compact ? 52 : 62;
    final double badgeSize = compact ? 18 : 20;
    final Color badgeColor = isSafe ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return SizedBox(
      width: compact ? 78 : 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: circleSize,
                height: circleSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isSafe ? primaryColor.withOpacity(0.7) : Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                // 🚀 استخدام الصورة هنا مع تظبيط الحجم والحشو لجعلها متناسقة
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    // لو الصور لونها أسود أو أبيض وعايز توحد لونها مع التصميم، ممكن تفعيل الـ color
                    // color: Colors.white, 
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor,
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                  ),
                  child: Icon(
                    isSafe ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: compact ? 11 : 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: compact ? 10.5 : 12,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(String title, String desc, {bool compact = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// العنوان - خط كبير + تدرج برتقالي
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFCA5A5), Color(0xFFF28557), Color(0xFFC74A20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // لازم تفضل white عشان الـ ShaderMask يشتغل صح
              fontSize: compact ? 30 : 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 12),

        /// الوصف
        Text(
          desc,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// =========================================
  /// Step Card Widget (Badge + Card, RTL support)
  /// =========================================
  Widget _buildStepCard(
    BuildContext context, {
    required String number,
    required IconData icon,
    required String title,
    required String description,
    bool compact = false,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    final double iconBoxSize = compact ? 44 : 52;
    final double badgeSize = compact ? 22 : 26;
    final double vPad = compact ? 12 : 18;

    return Directionality(
      textDirection: cardDirection,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsetsDirectional.only(top: 8, start: 8),
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: vPad),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                    border: Border.all(color: primaryColor.withOpacity(0.6), width: 1.5),
                  ),
                  child: Icon(icon, color: Colors.white, size: compact ? 20 : 26),
                ),
                SizedBox(width: compact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 15 : 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: compact ? 13 : 14.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// الرقم (Badge) فوق ركن الكارت
          PositionedDirectional(
            top: 0,
            start: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF28557), Color(0xFFC74A20)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 11 : 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required int stepNumber,
    required IconData icon,
    required String title,
    required String description,
    required bool isLast,
    bool compact = false,
  }) {
    final double iconSize = compact ? 44 : 52;
    final double badgeSize = compact ? 22 : 26;

    return IntrinsicHeight(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// عمود الرقم + الأيقونة + الخط الرابط
            Column(
              children: [
                /// الرقم (Badge)
                Container(
                  width: badgeSize,
                  height: badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFF28557), Color(0xFFC74A20)]),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                    boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 6)],
                  ),
                  child: Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),

                /// دائرة الأيقونة
                Container(
                  width: iconSize,
                  height: iconSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: primaryColor.withOpacity(0.7), width: 1.5),
                  ),
                  child: Icon(icon, color: primaryColor, size: compact ? 20 : 24),
                ),

                /// الخط الرابط بين الخطوات
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
                      color: primaryColor.withOpacity(0.35),
                    ),
                  ),
              ],
            ),

            SizedBox(width: compact ? 14 : 18),

            /// النص
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: compact ? 2 : 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: compact ? 12 : 14,
                        height: 1.35,
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

  /// =========================================
  /// Video Component
  /// =========================================
  Widget _buildVideoCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: _videoController.value.isInitialized ? _playPause : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                /// 1. Video Poster (يظهر دائماً في الخلفية قبل وأثناء التحميل)
                Image.asset(
                  'assets/images/video_poster.png',
                  fit: BoxFit.cover,
                ),

                /// 2. Video Player & Controls
                if (_videoController.value.isInitialized) ...[
                  // بمجرد ما الفيديو يجهز، هيغطي صورة الـ Poster
                  VideoPlayer(_videoController),
                  
                  // شريط التقدم (Progress Indicator)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: VideoProgressIndicator(
                        _videoController,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: primaryColor,
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                    ),
                  ),
                  
                  // زر التشغيل والإيقاف
                  Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _videoController.value.isPlaying ? 0 : 1,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(.5),
                          border: Border.all(color: Colors.white.withOpacity(.5)),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ] else ...[
                  /// 3. Loading State (طبقة تعتيم خفيفة فوق الـ Poster مع مؤشر التحميل)
                  Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  /// =========================================
  /// Bottom Buttons Sections
  /// =========================================
  Widget _buildNextAndSkipSection(AppLocalizations l10n) {
    return Column(
      key: const ValueKey('next_skip'),
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF28557), Color(0xFFC74A20)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _onNextPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.next,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(width: 8),
                  // السهم دلوقتي ثابت دايماً باصص لليمين
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _completeOnboarding(LoginScreen()),
          child: Text(
            l10n.skip,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

Widget _buildAuthButtonsSection(AppLocalizations l10n) {
    return Column(
      key: const ValueKey('auth_buttons'),
      children: [
        Container(
          width: double.infinity,
          height: 57,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF28557), Color(0xFFC74A20)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () => _completeOnboarding(const SignupScreen()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(l10n.createAccount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 57,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => _completeOnboarding(const LoginScreen()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(l10n.signIn, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}