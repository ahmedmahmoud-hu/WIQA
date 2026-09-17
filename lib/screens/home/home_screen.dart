import 'dart:ui';
import 'dart:typed_data';

import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wiqa/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/ticket_service.dart';
import '../../widgets/custom_header.dart';

import 'create_ticket_screen.dart';
import '../reports/my_reports_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAllReports;

  const HomeScreen({
    super.key,
    this.onViewAllReports,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _userName = "";
  List<dynamic> _myTickets = [];
  bool _isLoading = true;

  // 🎨 ألوان PPE Detection (Navy + Orange)
  static const Color _navy = Color(0xFF0F172A);
  static const Color _accent = Color(0xFFE26336); // Primary - Orange
  static const Color _accentLight = Color(0xFFFF8A5C);
  static const Color _success = Color(0xFF27D89B);
  static const Color _warning = Color(0xFFFF9D42);
  static const Color _danger = Color(0xFFFF5C61);
  static const Color _secondaryText = Color(0xFFC8D0DC);
  static const Color _glassBg = Color(0x1AFFFFFF);
  static const Color _glassBorder = Color(0x26FFFFFF);

  late AnimationController _animController;

  @override
void initState() {
  super.initState();

  _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  _loadUserDataAndTickets();

  TicketsRefreshNotifier.ticker.addListener(_onTicketsChanged);
}

void _onTicketsChanged() {
  if (mounted) {
    _loadUserDataAndTickets();
  }
}
  // =========================================================
  // NOTE on refreshing:
  // -----------------------------------------------------------
  // This screen used to subscribe to a RouteObserver and refresh on
  // every `didPopNext()` (i.e. whenever ANY route above HomeScreen
  // closed). That included the "choose camera/gallery" bottom sheet
  // itself — closing that sheet counts as a route pop too, so picking
  // any of the three options triggered an immediate refresh before the
  // camera/gallery even opened.
  //
  // Now we refresh explicitly, only when we know a ticket was actually
  // created — see `_handleSelectedFile` below.
  // =========================================================

  @override
void dispose() {
  TicketsRefreshNotifier.ticker.removeListener(_onTicketsChanged);

  _animController.dispose();

  super.dispose();
}

  // =========================================================
  // LOAD USER DATA + TICKETS
  // =========================================================

  Future<void> _loadUserDataAndTickets() async {
    final prefs = await SharedPreferences.getInstance();

    final String savedName =
        prefs.getString('username') ?? "User";

    if (mounted) {
      setState(() {
        _userName = savedName;
        _isLoading = false;
      });

      _animController.forward(from: 0);
    }

    try {
      final List<dynamic> fetchedTickets =
          await TicketService.getMyTickets();

      debugPrint(
        "GET MY TICKETS RESULT: $fetchedTickets",
      );

      debugPrint(
        "TICKETS COUNT: ${fetchedTickets.length}",
      );

      if (mounted) {
        setState(() {
          _myTickets = fetchedTickets;
        });
      }
    } catch (e) {
      debugPrint(
        "Error fetching tickets: $e",
      );
    }
  }

  // =========================================================
  // GET IMAGE URL
  // =========================================================

  String _getImageUrl(dynamic originalUrl) {
    if (originalUrl == null ||
        originalUrl.toString().trim().isEmpty) {
      return '';
    }

    String url =
        originalUrl.toString().trim();

    // API may return Markdown:
    // [image](http://localhost:5021/...)
    final markdownMatch =
        RegExp(r'\]\((.*?)\)').firstMatch(url);

    if (markdownMatch != null) {
      url = markdownMatch.group(1) ?? '';
    }

    // Replace localhost with real server
    url = url.replaceFirst(
      'http://localhost:5021',
      'http://91.108.112.27:5021',
    );

    return url;
  }

  // =========================================================
  // GET LOCALIZED ADDRESS
  // =========================================================

  String _getLocalizedAddress(
    dynamic address,
    bool isArabic,
  ) {
    if (address == null ||
        address.toString().trim().isEmpty) {
      return '';
    }

    final String addressText =
        address.toString().trim();

    final List<String> parts =
        addressText.split(' - ');

    if (parts.length < 2) {
      return addressText;
    }

    final String arabicAddress =
        parts.first.trim();

    final String englishAddress =
        parts.sublist(1).join(' - ').trim();

    return isArabic
        ? arabicAddress
        : englishAddress;
  }

  // =========================================================
  // MEDIA SOURCE BOTTOM SHEET
  // =========================================================

  void _showMediaSourceBottomSheet(
    AppLocalizations l10n,
    bool isArabic,
  ) {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 15,
                    sigmaY: 15,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _glassBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _glassBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // CAMERA
                        _buildPremiumActionSheetItem(
                          icon: Icons.camera_alt_outlined,
                          title: isArabic
                              ? "فتح الكاميرا"
                              : "Open Camera",
                          onTap: () async {
                            Navigator.pop(context);
                            final XFile? media =
                                await picker.pickImage(
                              source: ImageSource.camera,
                            );

                            if (media != null) {
                              _handleSelectedFile(
                                media.path,
                                isVideo: false,
                              );
                            }
                          },
                        ),

                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.1),
                        ),

                        // IMAGE
                        _buildPremiumActionSheetItem(
                          icon: Icons.image_outlined,
                          title: isArabic
                              ? "اختيار صورة من المعرض"
                              : "Choose Image From Library",
                          onTap: () async {
                            Navigator.pop(context);
                            final XFile? image =
                                await picker.pickImage(
                              source: ImageSource.gallery,
                            );

                            if (image != null) {
                              _handleSelectedFile(
                                image.path,
                                isVideo: false,
                              );
                            }
                          },
                        ),

                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.1),
                        ),

                        // VIDEO
                        _buildPremiumActionSheetItem(
                          icon: Icons.videocam_outlined,
                          title: isArabic
                              ? "اختيار فيديو من المعرض"
                              : "Choose Video From Library",
                          onTap: () async {
                            Navigator.pop(context);
                            final XFile? video =
                                await picker.pickVideo(
                              source: ImageSource.gallery,
                            );

                            if (video != null) {
                              _handleSelectedFile(
                                video.path,
                                isVideo: true,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // CANCEL
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 15,
                    sigmaY: 15,
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _glassBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _glassBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isArabic ? "إلغاء" : "Cancel",
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  // =========================================================
  // ACTION SHEET ITEM
  // =========================================================

  Widget _buildPremiumActionSheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 24,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: _accent,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HANDLE SELECTED FILE
  // =========================================================
  //
  // Pushes CreateTicketScreen and waits for it to close. It only
  // refreshes the ticket list if CreateTicketScreen reports back that a
  // ticket was actually created (result == true) — not on every pop, so
  // cancelling out of the flow at any point does nothing extra.
  Future<void> _handleSelectedFile(
    String filePath, {
    required bool isVideo,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTicketScreen(
          filePath: filePath,
          isVideo: isVideo,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadUserDataAndTickets();
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          // ===================================================
          // BACKGROUND
          // ===================================================

          Positioned.fill(
            child: Image.asset(
                'assets/images/ob_bg.png',
                fit: BoxFit.cover,
            ),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _navy.withOpacity(0.8),
                  _navy.withOpacity(0.6),
                  _navy.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // ===================================================
          // CONTENT
          // ===================================================

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                    ),
                  )
                : Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: RefreshIndicator(
                          color: _accent,
                          backgroundColor: _navy,
                          strokeWidth: 2.5,
                          displacement: 15,
                          edgeOffset: 0,
                          onRefresh: () async {
                            await _loadUserDataAndTickets();
                          },
                          child: SingleChildScrollView(
                            physics:
                                const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 20,
                              bottom: 80,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // WELCOME
                                _buildAnimatedItem(
                                  _buildWelcomeText(l10n),
                                  0,
                                ),

                                const SizedBox(height: 24),

                                // MAIN ACTION
                                _buildAnimatedItem(
                                  Hero(
                                    tag: 'main_action_card',
                                    child: Material(
                                      type: MaterialType
                                          .transparency,
                                      child: _buildMainActionCard(
                                        l10n,
                                        isArabic,
                                      ),
                                    ),
                                  ),
                                  1,
                                ),

                                const SizedBox(height: 20),

                                // SUMMARY
                                _buildAnimatedItem(
                                  _buildSummaryCard(l10n),
                                  2,
                                ),

                                const SizedBox(height: 20),

                                // RECENT REPORTS
                                _buildAnimatedItem(
                                  _buildRecentReportsList(
                                    l10n,
                                    isArabic,
                                  ),
                                  3,
                                ),

                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ANIMATION
  // =========================================================

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(
          0.1 * index,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // =========================================================
  // HELPER WIDGETS
  // =========================================================

 Widget _buildTopBar() {
    return const Padding(
      padding: EdgeInsets.only(
        top: 16.0,    // مسافة من فوق
        left: 20.0,   // مسافة من الشمال
        right: 20.0,  // مسافة من اليمين
        bottom: 8.0,  // مسافة من تحت
      ),
      child: CustomHeader(),
    );
  }

  Widget _buildWelcomeText(AppLocalizations l10n) {
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';
    final String comma = isArabic ? '،' : ',';

    return Transform.translate(
      offset: const Offset(0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${l10n.welcomeBack}$comma',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _userName,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionCard(
    AppLocalizations l10n,
    bool isArabic,
  ) {
    return GestureDetector(
      onTap: () => _showMediaSourceBottomSheet(l10n, isArabic),
      child: _buildGlassCard(
        padding: const EdgeInsets.all(20),
        borderColor: _accent.withOpacity(0.5),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: _accent,
                size: 35,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reportPollutionTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.reportPollutionSub,
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Icon(
                isArabic ? Icons.arrow_back : Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n) {
    final int total = _myTickets.length;

    final int resolved = _myTickets
        .where((t) =>
            t['status']?.toString().toLowerCase() == 'closed')
        .length;

    final int inProgress = _myTickets
        .where((t) => ['in-progress', 'open']
            .contains(t['status']?.toString().toLowerCase()))
        .length;

    final int rejected = _myTickets
        .where((t) =>
            t['status']?.toString().toLowerCase() == 'rejected')
        .length;

    return _buildGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reportsSummary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                l10n.total,
                total.toString(),
                Icons.description_outlined,
                _accent,
              ),
              _buildDivider(),
              _buildStatItem(
                l10n.resolved,
                resolved.toString(),
                Icons.check_circle_outline,
                _success,
              ),
              _buildDivider(),
              _buildStatItem(
                l10n.inProgress,
                inProgress.toString(),
                Icons.access_time,
                _warning,
              ),
              _buildDivider(),
              _buildStatItem(
                l10n.rejected,
                rejected.toString(),
                Icons.cancel_outlined,
                _danger,
              ),
            ],
          ),
        ],
      ),
    );



  }

  Widget _buildRecentReportsList(
  AppLocalizations l10n,
  bool isArabic,
) {
  final List<dynamic> recentTickets =
      _myTickets.take(3).toList();

  return _buildGlassCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentReports,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            // =========================
            // VIEW ALL
            // =========================
            
            if (_myTickets.length > 3)
              GestureDetector(
                onTap: () {
                  widget.onViewAllReports?.call();
                },
                child: Text(
                  isArabic ? 'عرض الكل' : 'View All',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ],
        ),

        const SizedBox(height: 16),

        if (recentTickets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.noReports,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...recentTickets.asMap().entries.map((entry) {
            final int idx = entry.key;
            final dynamic ticket = entry.value;

            final String ticketNumber =
                ticket['ticketNumber']?.toString() ??
                    '#---------';

            final String title =
                ticket['title']?.toString().trim() ?? '';

            final String imageUrl = _getImageUrl(
              ticket['originalUrl'],
            );

            final String rawStatus =
                ticket['status']?.toString().toLowerCase() ??
                    'open';

            Color statusColor;
            String displayStatus;

            if (rawStatus == 'closed') {
              statusColor = _success;
              displayStatus = l10n.resolved;
            } else if (rawStatus == 'rejected') {
              statusColor = _danger;
              displayStatus = l10n.rejected;
            } else {
              statusColor = _warning;
              displayStatus = l10n.inProgress;
            }

            final bool isVideo =
                ticket['originalUrl']
                        ?.toString()
                        .toLowerCase()
                        .contains('.mp4') ==
                    true ||
                ticket['type']
                        ?.toString()
                        .toLowerCase() ==
                    'video';

            return Hero(
              tag: 'report_hero_${ticket['id'] ?? idx}',
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TicketDetailsScreen(ticket: ticket),
                    ),
                    );
                  },
                  child: _buildReportTile(
                    title: ticketNumber,
                    subtitle: title,
                    status: displayStatus,
                    statusColor: statusColor,
                    imageUrl: imageUrl,
                    isArabic: isArabic,
                    showBorder:
                        idx != recentTickets.length - 1,
                    isVideo: isVideo,
                  ),
                ),
              ),
            );
          }),
      ],
    ),
  );
}

  Widget _buildReportTile({
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required String imageUrl,
    required bool isArabic,
    bool showBorder = true,
    bool isVideo = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            )
          : null,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    isVideo
                        ? _VideoThumbnailHelper(videoUrl: imageUrl)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child,
                                loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Container(
                                color: Colors.white
                                    .withOpacity(0.05),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _accent,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) {
                              return Container(
                                color: Colors.white
                                    .withOpacity(0.05),
                                child: const Icon(
                                  Icons
                                      .image_not_supported_outlined,
                                  color: Colors.white38,
                                  size: 24,
                                ),
                              );
                            },
                          )
                  else
                    Container(
                      color: Colors.white.withOpacity(0.05),
                      child: Icon(
                        isVideo
                            ? Icons.videocam_outlined
                            : Icons.image_outlined,
                        color: Colors.white38,
                        size: 24,
                      ),
                    ),
                  if (isVideo)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: _secondaryText,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle.isNotEmpty
                            ? subtitle
                            : (isArabic
                                ? 'بدون عنوان'
                                : 'Untitled'),
                        style: TextStyle(
                          color: _secondaryText,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                isArabic
                    ? Icons.arrow_back
                    : Icons.arrow_forward,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    required EdgeInsets padding,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor ?? _glassBorder,
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.15),
    );
  }
}

// =========================================================
// VIDEO THUMBNAIL HELPER WIDGET
// =========================================================
class _VideoThumbnailHelper extends StatefulWidget {
  final String videoUrl;

  const _VideoThumbnailHelper({required this.videoUrl});

  @override
  State<_VideoThumbnailHelper> createState() =>
      _VideoThumbnailHelperState();
}

class _VideoThumbnailHelperState
    extends State<_VideoThumbnailHelper> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        maxWidth: 150,
        quality: 30,
      );

      if (mounted) {
        setState(() {
          _thumbnailData = uint8list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Thumbnail Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white.withOpacity(0.05),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFE26336),
            ),
          ),
        ),
      );
    }

    if (_thumbnailData != null) {
      return Image.memory(
        _thumbnailData!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Container(
      color: Colors.white.withOpacity(0.05),
      child: const Icon(
        Icons.videocam_outlined,
        color: Colors.white38,
        size: 24,
      ),
    );
  }
}