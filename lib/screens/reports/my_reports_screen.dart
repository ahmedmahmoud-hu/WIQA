import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';

import 'package:wiqa/l10n/app_localizations.dart';
import '../../services/ticket_service.dart';
import '../../widgets/custom_header.dart';


import '../home/create_ticket_screen.dart'
    show
        ppeClassLabel,
        ppeClassColor,
        ppeClassIcon,
        normalizePpeClassName,
        ppeClassesEn;


const Map<String, String> ppeClassIconAssets = {
  // 'FALL_DETECTED': 'assets/images/fall.png',
  'NO_GLOVES': 'assets/images/gloves.png',
  'NO_GOGGLES': 'assets/images/goggles.png',
  'NO_HARDHAT': 'assets/images/hardhat.png',
  'NO_MASK': 'assets/images/mask.png',
  'NO_SAFETY_VEST': 'assets/images/vest.png',
};

class TicketsRefreshNotifier {
  static final ValueNotifier<int> ticker = ValueNotifier<int>(0);

  static void notify() {
    ticker.value++;
  }
}


class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  // 🎨 Same palette as CreateTicketScreen (Navy + Orange).
  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xFFFF8A3D);
  static const Color _accent2 = Color(0xFFFF6A00);
  static const Color _success = Color(0xFF00E676);
  static const Color _warning = Color(0xFFFFB74D);
  static const Color _glassBg = Color(0x1AFFFFFF);
  static const Color _glassBorder = Color(0x26FFFFFF);

  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _error;

  String _selectedStatus = 'all';
  String _selectedPriority = 'all';

  @override
  void initState() {
    super.initState();
    _loadTickets();
    TicketsRefreshNotifier.ticker.addListener(_onExternalRefresh);
  }

  @override
void dispose() {
  TicketsRefreshNotifier.ticker.removeListener(_onExternalRefresh);
  super.dispose();
}

void _onExternalRefresh() {
  if (mounted) _loadTickets();
}

  Future<void> _loadTickets() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final List<dynamic> tickets = await TicketService.getMyTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('MY REPORTS ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _getMediaUrl(dynamic originalUrl) {
    if (originalUrl == null || originalUrl.toString().trim().isEmpty) {
      return '';
    }

    String url = originalUrl.toString().trim();

    final markdownMatch = RegExp(r'\]\((.*?)\)').firstMatch(url);
    if (markdownMatch != null) {
      url = markdownMatch.group(1) ?? '';
    }

    url = url.replaceFirst(
      'http://localhost:5021',
      'http://91.108.112.27:5021',
    );

    return url;
  }

  bool _isVideo(dynamic ticket) {
    final String url = ticket['originalUrl']?.toString().toLowerCase() ?? '';
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        ticket['type']?.toString().toLowerCase() == 'video';
  }

  String _formatDate(dynamic createdAt, bool isArabic) {
    if (createdAt == null) {
      return isArabic ? 'تاريخ غير معروف' : 'Unknown date';
    }
    try {
      final DateTime date = DateTime.parse(createdAt.toString()).toLocal();
      final String day = date.day.toString().padLeft(2, '0');
      final String month = date.month.toString().padLeft(2, '0');
      final String year = date.year.toString();
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year • $hour:$minute';
    } catch (_) {
      return createdAt.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
      case 'resolved':
        return _success;
      case 'rejected':
        return Colors.redAccent;
      case 'in progress':
      case 'in-progress':
        return _warning;
      case 'open':
      default:
        return _accent;
    }
  }

  String _getDisplayStatus(String status, bool isArabic, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'closed':
      case 'resolved':
        return l10n.resolved;
      case 'rejected':
        return l10n.rejected;
      case 'in progress':
      case 'in-progress':
        return l10n.inProgress;
      case 'open':
        return isArabic ? 'مفتوح' : 'Open';
      default:
        return status;
    }
  }

  // Priority values used by this backend: Low / Medium / High only.
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return _warning;
      case 'low':
        return _success;
      default:
        return Colors.white70;
    }
  }

  String _getDisplayPriority(String priority, bool isArabic) {
    switch (priority.toLowerCase()) {
      case 'high':
        return isArabic ? 'عالية' : 'High';
      case 'medium':
        return isArabic ? 'متوسطة' : 'Medium';
      case 'low':
        return isArabic ? 'منخفضة' : 'Low';
      default:
        return priority;
    }
  }

  List<dynamic> _getFilteredTickets() {
    return _tickets.where((ticket) {
      final String status = ticket['status']?.toString().toLowerCase() ?? '';
      final String priority =
          ticket['priority']?.toString().toLowerCase() ?? '';

      bool matchesStatus = true;
      if (_selectedStatus != 'all') {
        switch (_selectedStatus) {
          case 'open':
            matchesStatus = status == 'open';
            break;
          case 'progress':
            matchesStatus = status == 'in progress' || status == 'in-progress';
            break;
          case 'resolved':
            matchesStatus = status == 'resolved' || status == 'closed';
            break;
          case 'rejected':
            matchesStatus = status == 'rejected';
            break;
        }
      }

      bool matchesPriority = true;
      if (_selectedPriority != 'all') {
        matchesPriority = priority == _selectedPriority.toLowerCase();
      }

      return matchesStatus && matchesPriority;
    }).toList();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/ob_bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _navy.withOpacity(0.82),
                    _navy.withOpacity(0.66),
                    _navy.withOpacity(0.96),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(isArabic),
                _buildFilterToolbar(isArabic),
                const SizedBox(height: 14),
                Expanded(child: _buildBody(isArabic, l10n)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          const CustomHeader(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.12),
                  border: Border.all(color: _accent.withOpacity(0.28)),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: _accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isArabic ? 'بلاغاتي' : 'My Reports',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              value: _selectedStatus,
              icon: Icons.tune_rounded,
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(isArabic ? 'الحالة' : 'Status'),
                ),
                DropdownMenuItem(
                  value: 'open',
                  child: Text(isArabic ? 'مفتوح' : 'Open'),
                ),
                DropdownMenuItem(
                  value: 'progress',
                  child: Text(isArabic ? 'قيد التنفيذ' : 'In Progress'),
                ),
                DropdownMenuItem(
                  value: 'resolved',
                  child: Text(isArabic ? 'تم الحل' : 'Resolved'),
                ),
                DropdownMenuItem(
                  value: 'rejected',
                  child: Text(isArabic ? 'مرفوض' : 'Rejected'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedStatus = value);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildDropdown(
              value: _selectedPriority,
              icon: Icons.flag_outlined,
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(isArabic ? 'الأولوية' : 'Priority'),
                ),
                DropdownMenuItem(
                  value: 'high',
                  child: Text(isArabic ? 'عالية' : 'High'),
                ),
                DropdownMenuItem(
                  value: 'medium',
                  child: Text(isArabic ? 'متوسطة' : 'Medium'),
                ),
                DropdownMenuItem(
                  value: 'low',
                  child: Text(isArabic ? 'منخفضة' : 'Low'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedPriority = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isActive = value != 'all';
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: isActive ? _accent.withOpacity(0.10) : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? _accent.withOpacity(0.35) : Colors.white.withOpacity(0.12),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0B1B3A),
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withOpacity(0.55),
            size: 18,
          ),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item.value,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isActive ? _accent : Colors.white.withOpacity(0.55),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      child: item.child,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(bool isArabic, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_error != null) {
      return _buildErrorState(isArabic);
    }

    final List<dynamic> filteredTickets = _getFilteredTickets();
    if (filteredTickets.isEmpty) {
      return _buildEmptyState(isArabic);
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _navy,
      onRefresh: _loadTickets,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        itemCount: filteredTickets.length,
        itemBuilder: (context, index) {
          final ticket = filteredTickets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildReportCard(ticket, isArabic, l10n),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(dynamic ticket, bool isArabic, AppLocalizations l10n) {
    final String ticketNumber = ticket['ticketNumber']?.toString() ?? '#--------';
    final String title = ticket['title']?.toString().trim() ?? '';
    final String date = _formatDate(ticket['createdAt'], isArabic);
    final String status = ticket['status']?.toString() ?? 'Open';
    final String priority = ticket['priority']?.toString() ?? 'Low';
    final String imageUrl = _getMediaUrl(ticket['originalUrl']);
    final bool isVideo = _isVideo(ticket);
    final Color statusColor = _getStatusColor(status);
    final Color priorityColor = _getPriorityColor(priority);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TicketDetailsScreen(ticket: ticket)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _glassBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(imageUrl: imageUrl, isVideo: isVideo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticketNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusBadge(
                            text: _getDisplayStatus(status, isArabic, l10n),
                            color: statusColor,
                          ),
                        ],
                      ),
                      if (title.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _accent.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white.withOpacity(0.42),
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.52),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, color: priorityColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _getDisplayPriority(priority, isArabic),
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(color: Colors.white.withOpacity(0.10)),
                            ),
                            child: Icon(
                              isArabic ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.65),
                              size: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail({required String imageUrl, required bool isVideo}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 90,
        height: 110,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              isVideo
                  ? _VideoThumbnail(videoUrl: imageUrl)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _mediaError(isVideo),
                    )
            else
              _mediaError(isVideo),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.30)],
                  ),
                ),
              ),
            ),
            if (isVideo)
              Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.45),
                    border: Border.all(color: Colors.white.withOpacity(0.65)),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
              ),
              child: const Icon(Icons.cloud_off_outlined, color: Colors.redAccent, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              isArabic ? 'حدث خطأ أثناء تحميل البلاغات' : 'Failed to load reports',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadTickets,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
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

  Widget _buildEmptyState(bool isArabic) {
    final bool hasFilter = _selectedStatus != 'all' || _selectedPriority != 'all';
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _navy,
      onRefresh: _loadTickets,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.20),
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.08),
                border: Border.all(color: _accent.withOpacity(0.18)),
              ),
              child: Icon(
                hasFilter ? Icons.filter_alt_off_outlined : Icons.description_outlined,
                color: Colors.white.withOpacity(0.40),
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              hasFilter
                  ? (isArabic ? 'لا توجد بلاغات مطابقة' : 'No matching reports')
                  : (isArabic ? 'لا توجد بلاغات حتى الآن' : 'No reports yet'),
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          if (!hasFilter)
            Center(
              child: Text(
                isArabic ? 'ستظهر البلاغات التي ترسلها هنا' : 'Your submitted reports will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mediaError(bool isVideo) {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: Colors.white38,
        size: 26,
      ),
    );
  }
}

// =========================================================
// VIDEO THUMBNAIL
// =========================================================
class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  const _VideoThumbnail({required this.videoUrl});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  Uint8List? _thumbnailData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final Uint8List? data = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        maxWidth: 250,
        quality: 40,
      );
      if (mounted) {
        setState(() {
          _thumbnailData = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Video thumbnail error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: Colors.white.withOpacity(0.05),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8A3D)),
          ),
        ),
      );
    }
    if (_thumbnailData != null) {
      return Image.memory(_thumbnailData!, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: const Icon(Icons.videocam_outlined, color: Colors.white38, size: 26),
    );
  }
}

/// -----------------------------------------------------------------------
/// Ticket details screen — header info, PPE detections (with color-coded
/// bounding boxes reusing the same palette as CreateTicketScreen), and
/// location.
/// -----------------------------------------------------------------------
class TicketDetailsScreen extends StatefulWidget {
  final dynamic ticket;
  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xFFFF8A3D);
  static const Color _success = Color(0xFF00E676);
  static const Color _warning = Color(0xFFFFB74D);
  static const Color _glassBg = Color(0x1AFFFFFF);
  static const Color _glassBorder = Color(0x26FFFFFF);

  late Map<String, dynamic> _ticket;
  late List<dynamic> _detections;
  final Set<String> _addingClasses = {};
  final Set<String> _manuallyAddedClasses = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _ticket = Map<String, dynamic>.from(widget.ticket as Map);
    final raw = _ticket['detections'];
    _detections = raw is List ? List<dynamic>.from(raw) : [];
  }

  String _cleanUrl(dynamic originalUrl) {
    if (originalUrl == null || originalUrl.toString().trim().isEmpty) return '';
    String url = originalUrl.toString().trim();
    final markdownMatch = RegExp(r'\]\((.*?)\)').firstMatch(url);
    if (markdownMatch != null) url = markdownMatch.group(1) ?? '';
    url = url.replaceFirst('http://localhost:5021', 'http://91.108.112.27:5021');
    return url;
  }

  bool _isVideo() {
    final String url = _ticket['originalUrl']?.toString().toLowerCase() ?? '';
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        _ticket['type']?.toString().toLowerCase() == 'video';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
      case 'resolved':
        return _success;
      case 'rejected':
        return Colors.redAccent;
      case 'in progress':
      case 'in-progress':
        return _warning;
      case 'open':
      default:
        return _accent;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return _warning;
      case 'low':
        return _success;
      default:
        return Colors.white70;
    }
  }

  String _getStatusText(String status, bool isArabic) {
    switch (status.toLowerCase()) {
      case 'closed':
      case 'resolved':
        return isArabic ? 'تم الحل' : 'Resolved';
      case 'rejected':
        return isArabic ? 'مرفوض' : 'Rejected';
      case 'in progress':
      case 'in-progress':
        return isArabic ? 'قيد التنفيذ' : 'In Progress';
      case 'open':
      default:
        return isArabic ? 'مفتوح' : 'Open';
    }
  }

  String _getPriorityText(String priority, bool isArabic) {
    switch (priority.toLowerCase()) {
      case 'high':
        return isArabic ? 'عالية' : 'High';
      case 'medium':
        return isArabic ? 'متوسطة' : 'Medium';
      case 'low':
        return isArabic ? 'منخفضة' : 'Low';
      default:
        return priority;
    }
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return 'Unknown date';
    try {
      final DateTime date = DateTime.parse(createdAt.toString()).toLocal();
      final String day = date.day.toString().padLeft(2, '0');
      final String month = date.month.toString().padLeft(2, '0');
      final String year = date.year.toString();
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year • $hour:$minute';
    } catch (_) {
      return createdAt.toString();
    }
  }

  double _getDetectionConfidence(dynamic detection) {
    if (detection is! Map) return 0;
    final dynamic value = detection['confidence'];
    if (value == null) return 0;
    double result = double.tryParse(value.toString()) ?? 0;
    if (result <= 1) result *= 100;
    return result.clamp(0, 100);
  }

  double _getOverallConfidence() {
    if (_detections.isEmpty) return 0;
    double sum = 0;
    for (final d in _detections) {
      sum += _getDetectionConfidence(d);
    }
    return (sum / _detections.length).clamp(0, 100);
  }

  List<Map<String, dynamic>> _groupDetections() {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final detection in _detections) {
      final String rawClassName = detection['className']?.toString() ?? 'Unknown';
      final String className = normalizePpeClassName(rawClassName);
      final double confidence = _getDetectionConfidence(detection);

      if (!grouped.containsKey(className)) {
        grouped[className] = {'className': className, 'confidence': confidence, 'count': 1};
      } else {
        grouped[className]!['count'] = (grouped[className]!['count'] as int) + 1;
        final double oldConfidence = grouped[className]!['confidence'] as double;
        if (confidence > oldConfidence) grouped[className]!['confidence'] = confidence;
      }
    }
    return grouped.values.toList();
  }

  /// الكلاسات اللي المفروض متكتشفتش لسه (مش موجودة في الـ detections الحالية).
  List<String> _missedClasses() {
    final Set<String> detectedKeys =
        _detections.map((d) => normalizePpeClassName(d['className']?.toString() ?? '')).toSet();
    return ppeClassesEn.keys.where((k) => !detectedKeys.contains(k)).toList();
  }

  Future<void> _toggleClass(String classKey, bool isArabic, {required bool isAdding}) async {
    if (_addingClasses.contains(classKey)) return;
    setState(() => _addingClasses.add(classKey));

    try {
      final int ticketId = _ticket['id'] is int
          ? _ticket['id'] as int
          : int.parse(_ticket['id'].toString());

      await TicketService.toggleManualDetection(
        ticketId: ticketId,
        className: classKey,
      );

      if (!mounted) return;

      setState(() {
        if (isAdding) {
          _detections.add({'className': classKey, 'confidence': 0});
          _manuallyAddedClasses.add(normalizePpeClassName(classKey)); // 🆕
        } else {
          final normalizedKey = normalizePpeClassName(classKey);
          final idx = _detections.indexWhere(
            (d) => normalizePpeClassName(d['className']?.toString() ?? '') == normalizedKey,
          );
          if (idx != -1) _detections.removeAt(idx);
          _manuallyAddedClasses.remove(normalizedKey); // 🆕
        }
        _addingClasses.remove(classKey);
      });

      TicketsRefreshNotifier.notify();
    } catch (e) {
      if (!mounted) return;
      setState(() => _addingClasses.remove(classKey));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'فشل تحديث المخالفة' : 'Failed to update detection'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future _confirmAndDelete(bool isArabic) async {
    final bool? confirmed = await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.40), // تعتيم خفيف للشاشة ورا الـ Dialog
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), // تأثير الزجاج
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  // 🔴 التعديل هنا: استخدام اللون الكحلي مع شفافية 55% عشان يكون فاتح وزجاجي
                  color: _navy.withOpacity(0.55), 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.25), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withOpacity(0.10),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 38),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic ? 'حذف البلاغ؟' : 'Delete this report?',
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'لن تتمكن من التراجع عن هذا الإجراء وسيتم مسح البلاغ نهائياً.'
                          : 'This action cannot be undone. The report will be permanently deleted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(.70), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withOpacity(.20)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              isArabic ? 'إلغاء' : 'Cancel',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              isArabic ? 'حذف' : 'Delete',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final int ticketId = _ticket['id'] is int
          ? _ticket['id'] as int
          : int.parse(_ticket['id'].toString());

      await TicketService.deleteTicket(ticketId);

      TicketsRefreshNotifier.notify();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'فشل حذف البلاغ' : 'Failed to delete report'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final String ticketNumber = _ticket['ticketNumber']?.toString() ?? '#--------';
    final String departmentName = _ticket['departmentName']?.toString() ?? '';
    final String status = _ticket['status']?.toString() ?? 'Open';
    final String priority = _ticket['priority']?.toString() ?? 'Low';
    final String description = _ticket['description']?.toString() ?? '';
    final String originalUrl = _cleanUrl(_ticket['originalUrl']);
    final String processedUrl = _cleanUrl(_ticket['processedUrl']);
    final bool isVideo = _isVideo();
    final String displayMediaUrl = processedUrl.isNotEmpty ? processedUrl : originalUrl;

    final List<Map<String, dynamic>> groupedDetections = _groupDetections();
    final double overallConfidence = _getOverallConfidence();
    final List<String> missedClasses = _missedClasses();

    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/ob_bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _navy.withOpacity(0.80),
                    _navy.withOpacity(0.60),
                    _navy.withOpacity(0.94),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 17),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isArabic ? 'تفاصيل البلاغ' : 'Report Details',
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withOpacity(0.10),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                          ),
                          child: _isDeleting
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                )
                              : IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 19),
                                  onPressed: () => _confirmAndDelete(isArabic),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    children: [
                      _buildTicketHeader(ticketNumber, departmentName, status, priority, isArabic),
                      const SizedBox(height: 14),
                      _buildAIAnalysisContainer(
                        groupedDetections,
                        overallConfidence,
                        displayMediaUrl,
                        isVideo,
                        isArabic,
                      ),
                      if (missedClasses.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildMissedClassesCard(missedClasses, isArabic),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildDescriptionCard(description, isArabic),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHeader(
    String ticketNumber,
    String departmentName,
    String status,
    String priority,
    bool isArabic,
  ) {
    final Color statusColor = _getStatusColor(status);
    final Color priorityColor = _getPriorityColor(priority);

    return _buildGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.10),
                  border: Border.all(color: _accent.withOpacity(0.25)),
                ),
                child: const Icon(Icons.confirmation_number_outlined, color: _accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticketNumber,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      departmentName.isNotEmpty
                          ? departmentName
                          : (isArabic ? 'معلومات البلاغ' : 'Report Information'),
                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10),
                    ),
                  ],
                ),
              ),
              _buildSmallBadge(_getStatusText(status, isArabic), statusColor),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInfoBar(
                  icon: Icons.flag_outlined,
                  title: isArabic ? 'الأولوية' : 'Priority',
                  value: _getPriorityText(priority, isArabic),
                  color: priorityColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoBar(
                  icon: Icons.access_time,
                  title: isArabic ? 'التاريخ' : 'Date',
                  value: _formatDate(_ticket['createdAt']),
                  color: _accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisContainer(
    List<Map<String, dynamic>> groupedDetections,
    double overallConfidence,
    String mediaUrl,
    bool isVideo,
    bool isArabic,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _accent.withOpacity(0.22), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withOpacity(0.10),
                      border: Border.all(color: _accent.withOpacity(0.25)),
                    ),
                    child: const Icon(Icons.auto_awesome, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic ? 'نتائج تحليل الذكاء الاصطناعي' : 'AI Analysis Results',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(
                icon: isVideo ? Icons.video_library_outlined : Icons.auto_awesome,
                title: isVideo
                    ? (isArabic ? 'الفيديو المعالج' : 'Processed Video')
                    : (isArabic ? 'الصورة المعالجة' : 'Processed Image'),
              ),
              const SizedBox(height: 10),
              _buildProcessedMedia(mediaUrl, isVideo, isArabic),
              const SizedBox(height: 22),
              _buildSectionTitle(
                icon: Icons.warning_amber_rounded,
                title: isArabic ? 'المخالفات المكتشفة' : 'Detected Violations',
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildConfidenceCircle(overallConfidence, isArabic),
                  const SizedBox(width: 18),
                  Expanded(
                    child: groupedDetections.isEmpty
                        ? Text(
                            isArabic ? 'لم يتم اكتشاف مخالفات' : 'No violations detected',
                            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                          )
                        : Column(
                            children: groupedDetections
                                .map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildDetectionItem(item, isArabic),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessedMedia(String mediaUrl, bool isVideo, bool isArabic) {
    if (mediaUrl.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 40)),
      );
    }
    if (isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoThumbnail(videoUrl: mediaUrl),
              Container(color: Colors.black.withOpacity(0.15)),
              const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 54)),
            ],
          ),
        ),
      );
    }
    return BoundingBoxImage(imageUrl: mediaUrl, detections: _detections, isArabic: isArabic);
  }

  Widget _buildConfidenceCircle(double confidence, bool isArabic) {
    return SizedBox(
      width: 125,
      height: 125,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: confidence / 100,
              strokeWidth: 9,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${confidence.round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                isArabic ? 'الثقة الكلية' : 'Overall\nConfidence',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.48), fontSize: 9, height: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionItem(Map<String, dynamic> item, bool isArabic) {
  final String className = item['className']?.toString() ?? 'Unknown';
  final double confidence = (item['confidence'] as num?)?.toDouble() ?? 0;
  final int count = item['count'] as int? ?? 0;
  final Color color = ppeClassColor(className);
  final String displayName = ppeClassLabel(className, isArabic);
  final bool isManual = _manuallyAddedClasses.contains(className);
  final bool isRemoving = _addingClasses.contains(className);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.20)),
            ),
            child: Image.asset(
              ppeClassIconAssets[className] ?? 'assets/images/default.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${isArabic ? 'اكتشاف' : 'detections'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 9),
                ),
              ],
            ),
          ),
          Text(
            '${confidence.round()}%',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          if (isManual) ...[
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isRemoving
                  ? null
                  : () => _toggleClass(className, isArabic, isAdding: false),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
                ),
                child: isRemoving
                    ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.redAccent),
                      )
                    : const Icon(Icons.close, color: Colors.redAccent, size: 13),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.only(left: 42),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: confidence / 100,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    ],
  );
}

  /// كارت "Missed Classes" — الكلاسات اللي لسه متضافتش، بالشكل اللي في الصورة.
  Widget _buildMissedClassesCard(List<String> missedClasses, bool isArabic) {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.add_circle_outline,
            title: isArabic ? 'العناصر المفقودة' : 'Missed Classes',
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'اضغط على العنصر لإضافته لو كان مفقودًا فعليًا'
                : 'Tap an item to add it if it was actually missed',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: missedClasses.map((key) {
              final bool isAdding = _addingClasses.contains(key);
              return InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: isAdding ? null : () => _toggleClass(key, isArabic, isAdding: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _accent, width: 1.4),
                  ),
                  child: isAdding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                        )
                      : Text(
                          ppeClassLabel(key, isArabic),
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description, bool isArabic) {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.description_outlined,
            title: isArabic ? 'الوصف' : 'Description',
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 12.5, height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoBar({required IconData icon, required String title, required String value, Color? color}) {
    final Color itemColor = color ?? _accent;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: itemColor, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 8)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: itemColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, required EdgeInsets padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 7)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// class BoundingBoxImage extends StatefulWidget {
//   final String imageUrl;
//   final List<dynamic> detections;
//   final bool isArabic;

//   const BoundingBoxImage({super.key, required this.imageUrl, required this.detections, required this.isArabic,});

//   @override
//   State<BoundingBoxImage> createState() => _BoundingBoxImageState();
// }

class BoundingBoxImage extends StatefulWidget {
  final String imageUrl;
  final List<dynamic> detections;
  final bool isArabic;

  const BoundingBoxImage({
    super.key,
    required this.imageUrl,
    required this.detections,
    required this.isArabic,
  });

  @override
  State<BoundingBoxImage> createState() => _BoundingBoxImageState();
}

class _BoundingBoxImageState extends State<BoundingBoxImage> {
  dynamic _rawImage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    final ImageStream stream = NetworkImage(widget.imageUrl).resolve(
      ImageConfiguration.empty,
    );

    stream.addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          if (mounted) {
            setState(() {
              _rawImage = info.image;
            });
          }
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white38,
            size: 40,
          ),
        ),
      );
    }

    if (_rawImage == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF8A3D),
          ),
        ),
      );
    }

    final double imageWidth = _rawImage!.width.toDouble();
    final double imageHeight = _rawImage!.height.toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        color: Colors.black.withOpacity(0.18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double containerWidth = constraints.maxWidth;

            // نحسب الارتفاع المناسب للصورة مع الحفاظ على الـ aspect ratio
            final double imageAspectRatio =
                imageWidth / imageHeight;

            final double displayWidth = containerWidth;
            final double displayHeight =
                displayWidth / imageAspectRatio;

            // لو الصورة أطول من المساحة المتاحة، نحدد ارتفاع أقصى
            const double maxHeight = 500;

            final double finalWidth;
            final double finalHeight;

            if (displayHeight > maxHeight) {
              finalHeight = maxHeight;
              finalWidth = finalHeight * imageAspectRatio;
            } else {
              finalWidth = displayWidth;
              finalHeight = displayHeight;
            }

            final double scale = finalWidth / imageWidth;

            return SizedBox(
              width: containerWidth,
              height: finalHeight,
              child: Center(
                child: SizedBox(
                  width: finalWidth,
                  height: finalHeight,
                  child: Stack(
                    children: [
                      // =========================
                      // FULL PROCESSED IMAGE
                      // =========================
                      Positioned.fill(
                        child: RawImage(
                          image: _rawImage,
                          fit: BoxFit.fill,
                        ),
                      ),

                      // =========================
                      // BOUNDING BOXES
                      // =========================
                      ...widget.detections.map((d) {
                        if (d['x'] == null ||
                            d['y'] == null ||
                            d['width'] == null ||
                            d['height'] == null) {
                          return const SizedBox.shrink();
                        }

                        final String rawClassName =
                            d['className']?.toString() ?? 'Unknown';

                        final String className =
                            normalizePpeClassName(rawClassName);

                        final String displayLabel =
                            ppeClassLabel(
                          className,
                          widget.isArabic,
                        );

                        final Color color =
                            ppeClassColor(className);

                        double rawConf =
                            (d['confidence'] as num?)?.toDouble() ?? 0;

                        if (rawConf <= 1 && rawConf > 0) {
                          rawConf *= 100;
                        }

                        final String confidenceText =
                            '${rawConf.round()}%';

                        final double x =
                            (d['x'] as num).toDouble() * scale;

                        final double y =
                            (d['y'] as num).toDouble() * scale;

                        final double width =
                            (d['width'] as num).toDouble() * scale;

                        final double height =
                            (d['height'] as num).toDouble() * scale;

                        return Positioned(
                          left: x,
                          top: y,
                          width: width,
                          height: height,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // =========================
                              // Bounding box (المربع)
                              // =========================
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: color,
                                      // سُمك ثابت بغض النظر عن حجم الصورة الأصلي
                                      width: 2.5, 
                                    ),
                                  ),
                                ),
                              ),

                              // =========================
                              // Label (النص)
                              // =========================
                              Positioned(
                                top: 0,
                                left: -20,
                                child: Container(
                                  color: color,
                                  // هوامش ثابتة
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2.0,
                                    vertical: 0.2,
                                  ),
                                  child: Text(
                                    '$displayLabel $confidenceText',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      // حجم خط ثابت ومقروء
                                      fontSize: 10.0, 
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

