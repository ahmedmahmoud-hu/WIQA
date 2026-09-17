import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wiqa/l10n/app_localizations.dart';
import '../../widgets/custom_header.dart';
import 'create_new_ticket_screen.dart';

/// -----------------------------------------------------------------------
/// PPE classes (English keys used with the backend, Arabic/English labels
/// used purely for the UI).
/// -----------------------------------------------------------------------
const Map<String, String> ppeClassesEn = {
  'NO_GLOVES': 'NO-Gloves',
  'NO_GOGGLES': 'NO-Goggles',
  'NO_HARDHAT': 'NO-Hardhat',
  'NO_MASK': 'NO-Mask',
  'NO_SAFETY_VEST': 'NO-Safety Vest',
};

const Map<String, String> ppeClassesAr = {
  'FALL_DETECTED': 'السقوط المرصود',
  'NO_GLOVES': 'عدم ارتداء القفازات',
  'NO_GOGGLES': 'عدم ارتداء النظارات الواقية',
  'NO_HARDHAT': 'عدم ارتداء الخوذة',
  'NO_MASK': 'عدم ارتداء الكمامة',
  'NO_SAFETY_VEST': 'عدم ارتداء السترة العاكسة',
};

/// Normalizes a class name coming from the backend/model (which may use
/// different casing or separators, e.g. "no-hardhat", "No Hardhat", or
/// "no_hardhat") into the canonical key format used by [ppeClassesEn] and
/// [ppeClassesAr] (e.g. "NO_HARDHAT").
///
/// Without this, a lookup that doesn't exactly match falls back to the
/// raw backend string — which is always in English — so violation labels
/// can appear untranslated even while the rest of the app is in Arabic.
String normalizePpeClassName(String raw) {
  return raw
      .trim()
      .toUpperCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
}

/// Looks up the localized label for [rawClassName], normalizing it first.
/// Logs a warning (debug only) when the class isn't recognized, so a
/// mismatch between the backend's class names and [ppeClassesEn]/[ppeClassesAr]
/// is easy to spot instead of silently showing an English fallback.
String ppeClassLabel(String rawClassName, bool isArabic) {
  final key = normalizePpeClassName(rawClassName);
  final map = isArabic ? ppeClassesAr : ppeClassesEn;
  final label = map[key];

  if (label == null) {
    debugPrint(
      '⚠️ Unrecognized PPE class name "$rawClassName" (normalized: "$key"). '
      'Add it to ppeClassesEn/ppeClassesAr or check the backend class naming.',
    );
    return rawClassName;
  }

  return label;
}

IconData ppeClassIcon(String className) {
  switch (normalizePpeClassName(className)) {
    case 'FALL_DETECTED':
      return Icons.personal_injury_outlined;
    case 'NO_GLOVES':
      return Icons.back_hand_outlined;
    case 'NO_GOGGLES':
      return Icons.visibility_off_outlined;
    case 'NO_HARDHAT':
      return Icons.engineering_outlined;
    case 'NO_MASK':
      return Icons.masks_outlined;
    case 'NO_SAFETY_VEST':
      return Icons.checkroom_outlined;
    default:
      return Icons.warning_amber_rounded;
  }
}

/// Custom PNG icon per PPE class, shown in "Detected Violations" instead
/// of a generic warning icon. Place these files under `assets/icons/` and
/// register the folder in pubspec.yaml (see note below).
const Map<String, String> ppeClassIconAssets = {
  'FALL_DETECTED': 'assets/images/fall.png',
  'NO_GLOVES': 'assets/images/gloves.png',
  'NO_GOGGLES': 'assets/images/goggles.png',
  'NO_HARDHAT': 'assets/images/hardhat.png',
  'NO_MASK': 'assets/images/mask.png',
  'NO_SAFETY_VEST': 'assets/images/vest.png',
};

/// Returns the icon asset path for [className] (already normalized or
/// raw — this normalizes internally), or null if there's no custom asset
/// for that class, in which case callers should fall back to
/// [ppeClassIcon].
String? ppeClassIconAsset(String className) {
  return ppeClassIconAssets[normalizePpeClassName(className)];
}

Color ppeClassColor(String className) {
  switch (normalizePpeClassName(className)) {
    case 'FALL_DETECTED':
      return const Color(0xFFFF5252);
    case 'NO_HARDHAT':
      return const Color(0xFFFF7043);
    case 'NO_SAFETY_VEST':
      return const Color(0xFFFFB74D);
    case 'NO_GOGGLES':
      return const Color(0xFFFFD54F);
    case 'NO_GLOVES':
      return const Color(0xFF4DD0E1);
    case 'NO_MASK':
      return const Color(0xFFBA68C8);
    default:
      return const Color(0xFFFFB74D);
  }
}

/// -----------------------------------------------------------------------
/// Elements-selection dialog (matches the two reference screenshots).
/// Returns the chosen set of class keys, or null if dismissed without
/// applying anything.
/// -----------------------------------------------------------------------
Future<Set<String>?> showSelectPpeElementsDialog(
  BuildContext context, {
  required Set<String> initiallySelected,
  required bool isArabic,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<Set<String>>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(.55),
    builder: (dialogContext) {
      final temp = Set<String>.from(initiallySelected);

      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF04102A).withOpacity(.96),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withOpacity(.08),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(dialogContext, null),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(.08),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Funnel icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF19C6FF).withOpacity(.12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF19C6FF).withOpacity(.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.filter_alt,
                          color: Color(0xFF19C6FF),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        l10n.selectElementsToDetect,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64D8FF),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.chooseSafetyElements,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFFFA657).withOpacity(.95),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Grid of PPE classes
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.5,
                        children: ppeClassesEn.keys.map((key) {
                          final selected = temp.contains(key);
                          final label =
                              isArabic ? ppeClassesAr[key]! : ppeClassesEn[key]!;

                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                if (selected) {
                                  temp.remove(key);
                                } else {
                                  temp.add(key);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: selected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFFF8A3D),
                                          Color(0xFFFF6A00),
                                        ],
                                      )
                                    : null,
                                color: selected
                                    ? null
                                    : Colors.white.withOpacity(.05),
                                border: Border.all(
                                  color: selected
                                      ? Colors.transparent
                                      : Colors.white.withOpacity(.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: selected
                                          ? Colors.white.withOpacity(.25)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white.withOpacity(.35),
                                        width: 1.4,
                                      ),
                                    ),
                                    child: selected
                                        ? const Icon(
                                            Icons.check,
                                            size: 13,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.start,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white.withOpacity(.75),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // Select All / Clear All / Apply Selection
                      Row(
                        children: [
                          Expanded(
                            child: _DialogSmallButton(
                              label: l10n.selectAll,
                              icon: Icons.check_box_outlined,
                              filled: false,
                              onTap: () {
                                setDialogState(() {
                                  temp
                                    ..clear()
                                    ..addAll(ppeClassesEn.keys);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DialogSmallButton(
                              label: l10n.clearAll,
                              icon: Icons.check_box_outline_blank,
                              filled: false,
                              onTap: () {
                                setDialogState(() => temp.clear());
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: _DialogSmallButton(
                          label: l10n.applySelection,
                          icon: Icons.check,
                          filled: true,
                          onTap: () =>
                              Navigator.pop(dialogContext, Set<String>.from(temp)),
                        ),
                      ),
                    ],
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

class _DialogSmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _DialogSmallButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xFFFF8A3D), Color(0xFFFF6A00)],
                )
              : null,
          color: filled ? null : Colors.white.withOpacity(.06),
          border: Border.all(
            color: filled ? Colors.transparent : Colors.white.withOpacity(.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
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

/// -----------------------------------------------------------------------
/// Main screen
/// -----------------------------------------------------------------------
class CreateTicketScreen extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const CreateTicketScreen({
    super.key,
    required this.filePath,
    required this.isVideo,
  });

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF04102A);
  static const _accent = Color(0xFFFF8A3D);
  static const _accent2 = Color(0xFFFF6A00);
  static const _success = Color(0xFF00E676);
  static const _glassBg = Color(0x1AFFFFFF);

  // All classes selected by default, matching the reference screenshots.
  Set<String> _selectedClasses = Set<String>.from(ppeClassesEn.keys);

  bool _isProcessed = false;
  bool _isDetecting = false;

  // Full, untouched detection list exactly as returned by the last
  // successful API call. Never mutated when the user deselects a class
  // in the Edit dialog — that only affects what's *shown* (see
  // _visibleDetections below), so re-selecting a class always brings its
  // detections back without needing to re-run detection.
  List<dynamic> _allDetections = [];
  List<Map<String, dynamic>> _groupedResults = [];

  /// The subset of [_allDetections] currently selected for display.
  List<dynamic> get _visibleDetections {
    return _allDetections.where((d) {
      final className = normalizePpeClassName(d['className'].toString());
      return _selectedClasses.contains(className);
    }).toList();
  }

  double _imageOriginalWidth = 0;
  double _imageOriginalHeight = 0;

  String? _processedVideoUrl;

  VideoPlayerController? _originalVideoController;
  VideoPlayerController? _processedVideoController;

  late AnimationController _animationController;
  late Animation<double> _analysisAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _analysisAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    if (widget.isVideo) {
      _initializeOriginalVideo();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _originalVideoController?.dispose();
    _processedVideoController?.dispose();
    super.dispose();
  }

  double _getOverallConfidence() {
    final visible = _visibleDetections;
    if (visible.isEmpty) return 0;

    double total = 0;
    int count = 0;

    for (final detection in visible) {
      try {
        total += (detection['confidence'] as num).toDouble();
        count++;
      } catch (_) {}
    }

    return count == 0 ? 0 : (total / count).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _navy,
      body: Stack(
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
                    _navy.withOpacity(.80),
                    _navy.withOpacity(.60),
                    _navy.withOpacity(.92),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildHeader(l10n, isArabic),
                  const SizedBox(height: 35),

                  _buildSection(
                    title: widget.isVideo ? l10n.originalVideo : l10n.originalImage,
                    icon: widget.isVideo
                        ? Icons.videocam_outlined
                        : Icons.image_outlined,
                    iconColor: _accent,
                    borderColor: _accent.withOpacity(.35),
                    child: widget.isVideo
                        ? _buildOriginalVideo()
                        : _buildImagePreview(false, isArabic),
                  ),

                  const SizedBox(height: 20),
                  _buildElementsSelector(l10n, isArabic),

                  if (_isProcessed) ...[
                    const SizedBox(height: 24),
                    _buildAnimated(child: _buildAIAnalysis(l10n, isArabic)),
                  ],

                  const SizedBox(height: 28),
                  _buildDetectionButtons(l10n, isArabic),

                  if (_isProcessed) ...[
                    const SizedBox(height: 14),
                    _buildAnimated(child: _buildOpenTicketButton(l10n, isArabic)),
                  ],

                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isArabic) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const CustomHeader(),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Text(
            l10n.createTicket,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: iconColor.withOpacity(.25)),
                    ),
                    child: Icon(icon, color: iconColor, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }

  /// Card showing which PPE elements are currently selected + a button
  /// to open the selection dialog (matches the funnel-icon dialog).
  Widget _buildElementsSelector(AppLocalizations l10n, bool isArabic) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _selectedClasses.isEmpty
                  ? Colors.redAccent.withOpacity(.45)
                  : Colors.white.withOpacity(.12),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A3D).withOpacity(.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF8A3D).withOpacity(.30),
                  ),
                ),
                child: const Icon(
                  Icons.filter_alt,
                  color: Color(0xFFFF8A3D),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedSafetyElements,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _selectedClasses.isEmpty
                          ? l10n.noElementsSelected
                          : _selectedClasses
                              .map((k) =>
                                  isArabic ? ppeClassesAr[k]! : ppeClassesEn[k]!)
                              .join('، '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedClasses.isEmpty
                            ? Colors.redAccent.withOpacity(.85)
                            : Colors.white.withOpacity(.65),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openElementsDialog(isArabic),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [_accent, _accent2],
                    ),
                  ),
                  child: Text(
                    l10n.edit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
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

  Future<void> _openElementsDialog(bool isArabic) async {
    final result = await showSelectPpeElementsDialog(
      context,
      initiallySelected: _selectedClasses,
      isArabic: isArabic,
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedClasses = result;

      // Original behavior (kept as-is): _selectedClasses is used as the
      // filter for the *next* "Detect PPE" / "Re-analyze" call.
      //
      // Additional behavior: if detection has already run, deselecting a
      // class immediately hides its violations here — its bounding
      // box(es) disappear from the image and its card disappears from
      // "Detected Violations" — without needing to re-run detection.
      // Re-selecting it brings them right back, since _allDetections
      // (the original API result) is never touched, only filtered for
      // display via _visibleDetections.
      if (_isProcessed) {
        _processResultsForCards();
      }
    });
  }

  Widget _buildAnimated({required Widget child}) {
    final slide = Tween<Offset>(
      begin: const Offset(0, .05),
      end: Offset.zero,
    ).animate(_analysisAnimation);

    final scale = Tween<double>(begin: .97, end: 1).animate(_analysisAnimation);

    return FadeTransition(
      opacity: _analysisAnimation,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(scale: scale, child: child),
      ),
    );
  }

  Widget _buildImagePreview(bool processed, bool isArabic) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: processed
              ? _success.withOpacity(.25)
              : Colors.white.withOpacity(.10),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildImageWithDetection(processed, isArabic),
    );
  }

  Widget _buildImageWithDetection(bool processed, bool isArabic) {
    if (!processed || _imageOriginalWidth <= 0 || _imageOriginalHeight <= 0) {
      return Image.file(File(widget.filePath), fit: BoxFit.contain);
    }

    return AspectRatio(
      aspectRatio: _imageOriginalWidth / _imageOriginalHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(widget.filePath), fit: BoxFit.contain),
          if (_visibleDetections.isNotEmpty)
            CustomPaint(
              painter: PpeBoundingBoxPainter(
                detections: _visibleDetections,
                imageOriginalWidth: _imageOriginalWidth,
                imageOriginalHeight: _imageOriginalHeight,
                isArabic: isArabic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOriginalVideo() {
    if (_originalVideoController == null ||
        !_originalVideoController!.value.isInitialized) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return _buildVideoPlayer(_originalVideoController!);
  }

  Widget _buildProcessedVideo() {
    if (_processedVideoController == null ||
        !_processedVideoController!.value.isInitialized) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator(color: _success)),
      );
    }

    final ratio = _originalVideoController != null &&
            _originalVideoController!.value.isInitialized &&
            _originalVideoController!.value.aspectRatio > 0
        ? _originalVideoController!.value.aspectRatio
        : _processedVideoController!.value.aspectRatio > 0
            ? _processedVideoController!.value.aspectRatio
            : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _processedVideoController!.value.size.width > 0
                      ? _processedVideoController!.value.size.width
                      : 1920,
                  height: _processedVideoController!.value.size.height > 0
                      ? _processedVideoController!.value.size.height
                      : 1080,
                  child: VideoPlayer(_processedVideoController!),
                ),
              ),
              _VideoPlayButton(controller: _processedVideoController!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController controller) {
    final ratio = controller.value.aspectRatio > 0
        ? controller.value.aspectRatio
        : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: controller.value.size.width > 0
                      ? controller.value.size.width
                      : 1920,
                  height: controller.value.size.height > 0
                      ? controller.value.size.height
                      : 1080,
                  child: VideoPlayer(controller),
                ),
              ),
              _VideoPlayButton(controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIAnalysis(AppLocalizations l10n, bool isArabic) {
    final confidence = _getOverallConfidence();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _success.withOpacity(.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalysisHeader(l10n, isArabic),
              const SizedBox(height: 18),
              _buildProcessedMedia(l10n, isArabic),
              const SizedBox(height: 22),
              _buildDivider(),
              const SizedBox(height: 20),
              _buildConfidenceAndIssues(confidence, l10n, isArabic),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisHeader(AppLocalizations l10n, bool isArabic) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _success.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _success.withOpacity(.25)),
          ),
          child: const Icon(Icons.analytics_outlined, color: _success, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.aiAnalysisResults,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _success.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _success.withOpacity(.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: _success, size: 12),
              const SizedBox(width: 3),
              Text(
                l10n.completed,
                style: const TextStyle(
                  color: _success,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessedMedia(AppLocalizations l10n, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.isVideo ? Icons.auto_awesome_motion : Icons.auto_awesome,
              color: _success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.isVideo ? l10n.processedVideo : l10n.processedImage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.40),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _success.withOpacity(.22)),
          ),
          clipBehavior: Clip.hardEdge,
          child: widget.isVideo
              ? _buildProcessedVideo()
              : _buildImagePreview(true, isArabic),
        ),
      ],
    );
  }

  Widget _buildConfidenceAndIssues(
    double confidence,
    AppLocalizations l10n,
    bool isArabic,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: _accent, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.detectedViolations,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 115,
              height: 115,
              child: CustomPaint(
                painter: OverallConfidencePainter(
                  confidence: confidence,
                  progressColor: _accent,
                  secondaryColor: const Color(0xFF6C4DFF),
                  backgroundColor: Colors.white.withOpacity(.08),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(confidence * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.overallConfidence,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.75),
                          fontSize: 9,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _groupedResults.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        l10n.noPpeViolations,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.70),
                          fontSize: 13,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._groupedResults
                            .map((item) => _buildResultItem(item, l10n, isArabic)),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultIcon(String className, Color color) {
    final assetPath = ppeClassIconAsset(className);

    if (assetPath == null) {
      return Icon(ppeClassIcon(className), color: color, size: 16);
    }

    return Image.asset(
      assetPath,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
      // Falls back to the Material icon if the PNG isn't bundled yet
      // (e.g. asset not added to pubspec.yaml or file missing).
      errorBuilder: (context, error, stackTrace) {
        return Icon(ppeClassIcon(className), color: color, size: 16);
      },
    );
  }

  Widget _buildResultItem(
    Map<String, dynamic> item,
    AppLocalizations l10n,
    bool isArabic,
  ) {
    final confidence = item['confidence'] as double;
    final color = item['color'] as Color;
    final className = normalizePpeClassName(item['label'].toString());
    final count = item['count'] as int;

    final label = ppeClassLabel(className, isArabic);

    final countLabel =
        '$count ${count == 1 ? l10n.detectionSingular : l10n.detectionPlural}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(5),
                child: _buildResultIcon(className, color),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      countLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.50),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(confidence * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: Colors.white.withOpacity(.08),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.white.withOpacity(.08));
  }

  Widget _buildDetectionButtons(AppLocalizations l10n, bool isArabic) {
    final label = _isProcessed ? l10n.reAnalyze : l10n.detectPpe;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _buildButton(
            label: label,
            icon: _isProcessed ? Icons.refresh : Icons.auto_awesome,
            isPrimary: !_isProcessed,
            backgroundColor: _isProcessed ? Colors.white.withOpacity(.10) : null,
            isLoading: _isDetecting,
            onTap: _isDetecting ? () {} : () => _startDetection(l10n, isArabic),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildButton(
            label: l10n.clear,
            icon: Icons.delete_outline,
            isPrimary: false,
            textColor: Colors.black87,
            backgroundColor: Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenTicketButton(AppLocalizations l10n, bool isArabic) {
    return _buildButton(
      label: l10n.openTicket,
      icon: Icons.confirmation_number_outlined,
      isPrimary: true,
      onTap: () async {
        final detectedClasses = _visibleDetections
            .map((d) => normalizePpeClassName(d['className'].toString()))
            .toSet()
            .toList();

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateNewTicketScreen(
              detectedClasses: detectedClasses,
              filePath: widget.filePath,
              isVideo: widget.isVideo,
            ),
          ),
        );

        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      },
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
    Color? textColor,
    Color? backgroundColor,
    bool isLoading = false,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isPrimary ? const LinearGradient(colors: [_accent, _accent2]) : null,
          color: backgroundColor,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: _accent.withOpacity(.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isLoading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.isVideo
                            ? l10n.analyzingVideoStatus
                            : l10n.analyzingStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: ValueKey('$label-$icon'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: textColor ?? Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: textColor ?? Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _startDetection(AppLocalizations l10n, bool isArabic) async {
    if (_isDetecting) return;

    // Must select at least one PPE element before sending.
    if (_selectedClasses.isEmpty) {
      _showError(l10n.selectOneElementError);
      await _openElementsDialog(isArabic);
      return;
    }

    setState(() => _isDetecting = true);
    _animationController.reset();
    _showAnalyzingDialog(l10n);

    try {
      final file = File(widget.filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      if (!widget.isVideo) {
        final bytes = await file.readAsBytes();
        final image = await decodeImageFromList(bytes);

        _imageOriginalWidth = image.width.toDouble();
        _imageOriginalHeight = image.height.toDouble();
      }

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.100:5021/api';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/TestDetection/test'),
      );

      final ext = widget.filePath.split('.').last.toLowerCase();
      final mediaType = switch (ext) {
        'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
        'png' => MediaType('image', 'png'),
        'mp4' => MediaType('video', 'mp4'),
        _ => MediaType('application', 'octet-stream'),
      };

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          widget.filePath,
          contentType: mediaType,
        ),
      );

      // Send the selected PPE classes to the backend.
      // NOTE: adjust the field name below ("elements") to whatever key
      // the ITestDetectionService/DetectAsync endpoint actually expects.
      request.fields['elements'] = _selectedClasses.join(',');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final setCookie = response.headers['set-cookie'];
      if (setCookie != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_cookie', setCookie);
        debugPrint('✅ Session Cookie Saved: $setCookie');
      }

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _showError('API Error: ${response.statusCode}');
        return;
      }

      final jsonData = jsonDecode(responseData);

      if (jsonData is Map && jsonData.containsKey('error')) {
        _showError(jsonData['error'].toString());
        return;
      }

      final responseType =
          jsonData is Map ? jsonData['type']?.toString().toLowerCase() : null;

      if (widget.isVideo || responseType == 'video') {
        await _handleVideoResponse(jsonData);
      } else {
        _handleImageResponse(jsonData);
      }

      if (!mounted) return;

      setState(() {
        _isProcessed = true;
        _isDetecting = false;
      });

      _animationController.forward(from: 0);
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isDetecting = false);
        _showError(l10n.connectionError);
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  void _handleImageResponse(dynamic jsonData) {
    final raw = jsonData['detections'];
    _allDetections = raw is List ? List<dynamic>.from(raw) : [];
    _processResultsForCards();
  }

  Future<void> _handleVideoResponse(dynamic jsonData) async {
    final processedUrl = jsonData['processedVideoUrl']?.toString();
    final raw = jsonData['detections'];

    _allDetections = raw is List ? List<dynamic>.from(raw) : [];
    _processResultsForCards();

    if (processedUrl != null && processedUrl.isNotEmpty) {
      _processedVideoUrl = _normalizeMediaUrl(processedUrl);
      await _initializeProcessedVideo();
    }
  }

  String _normalizeMediaUrl(String url) {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.100:5021/api';
    final uri = Uri.parse(url);

    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      final baseUri = Uri.parse(baseUrl);
      return Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : 80,
        path: uri.path,
        query: uri.query,
      ).toString();
    }

    return url;
  }

  Future<void> _initializeOriginalVideo() async {
    await _originalVideoController?.dispose();

    final controller = VideoPlayerController.file(File(widget.filePath));
    _originalVideoController = controller;

    try {
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Original video initialization error: $e');
    }
  }

  Future<void> _initializeProcessedVideo() async {
    if (_processedVideoUrl == null) return;

    await _processedVideoController?.dispose();

    final controller = VideoPlayerController.networkUrl(Uri.parse(_processedVideoUrl!));
    _processedVideoController = controller;
    await controller.initialize();

    if (mounted) setState(() {});
  }

  void _processResultsForCards() {
    final confidence = <String, double>{};
    final count = <String, int>{};

    for (final detection in _visibleDetections) {
      try {
        final name = normalizePpeClassName(detection['className'].toString());
        final value = (detection['confidence'] as num).toDouble();

        count[name] = (count[name] ?? 0) + 1;

        if (!confidence.containsKey(name) || value > confidence[name]!) {
          confidence[name] = value;
        }
      } catch (_) {}
    }

    _groupedResults = confidence.entries.map((entry) {
      return {
        'label': entry.key,
        'confidence': entry.value,
        'count': count[entry.key] ?? 0,
        'color': ppeClassColor(entry.key),
      };
    }).toList();

    _groupedResults.sort(
      (a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double),
    );
  }

  void _showAnalyzingDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withOpacity(.30), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: _accent),
                    const SizedBox(height: 20),
                    Text(
                      widget.isVideo
                          ? l10n.analyzingVideoDialog
                          : l10n.analyzingImageDialog,
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isVideo
                          ? l10n.detectingVideoDialog
                          : l10n.detectingImageDialog,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.70),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _VideoPlayButton extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoPlayButton({required this.controller});

  @override
  State<_VideoPlayButton> createState() => _VideoPlayButtonState();
}

class _VideoPlayButtonState extends State<_VideoPlayButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.controller.value.isPlaying;

    return GestureDetector(
      onTap: () {
        if (playing) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }
        setState(() {});
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: playing ? 0 : 1,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(.60),
            border: Border.all(color: Colors.white.withOpacity(.25)),
          ),
          child: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }
}

class OverallConfidencePainter extends CustomPainter {
  final double confidence;
  final Color progressColor;
  final Color secondaryColor;
  final Color backgroundColor;

  OverallConfidencePainter({
    required this.confidence,
    required this.progressColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 9.0;

    final bg = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - stroke / 2, bg);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final progress = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2,
        colors: [progressColor, secondaryColor, progressColor],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      -math.pi / 2,
      math.pi * 2 * confidence,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant OverallConfidencePainter oldDelegate) {
    return oldDelegate.confidence != confidence ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class PpeBoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  final double imageOriginalWidth;
  final double imageOriginalHeight;
  final bool isArabic;

  PpeBoundingBoxPainter({
    required this.detections,
    required this.imageOriginalWidth,
    required this.imageOriginalHeight,
    required this.isArabic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageOriginalWidth <= 0 || imageOriginalHeight <= 0 || detections.isEmpty) {
      return;
    }

    final imageRatio = imageOriginalWidth / imageOriginalHeight;
    final canvasRatio = size.width / size.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (canvasRatio > imageRatio) {
      scale = size.height / imageOriginalHeight;
      offsetX = (size.width - imageOriginalWidth * scale) / 2;
    } else {
      scale = size.width / imageOriginalWidth;
      offsetY = (size.height - imageOriginalHeight * scale) / 2;
    }

    for (final detection in detections) {
      try {
        final x = (detection['x'] as num).toDouble();
        final y = (detection['y'] as num).toDouble();
        final width = (detection['width'] as num).toDouble();
        final height = (detection['height'] as num).toDouble();
        final confidence = (detection['confidence'] as num).toDouble();

        final className = normalizePpeClassName(detection['className'].toString());

        final label = ppeClassLabel(className, isArabic);

        // Per-class color, distinguishing violation types on the image.
        final boxColor = ppeClassColor(className);

        final rect = Rect.fromLTWH(
          offsetX + x * scale,
          offsetY + y * scale,
          width * scale,
          height * scale,
        );

        final boxPaint = Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

        canvas.drawRect(rect, boxPaint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$label ${(confidence * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        )..layout();

        final labelWidth = textPainter.width + 10;
        final labelHeight = textPainter.height + 6;

        double labelX = rect.left;
        double labelY = rect.top - labelHeight;

        if (labelY < 0) labelY = rect.top;
        if (labelX < 0) labelX = 0;
        if (labelX + labelWidth > size.width) {
          labelX = size.width - labelWidth;
        }

        canvas.drawRect(
          Rect.fromLTWH(labelX, labelY, labelWidth, labelHeight),
          Paint()..color = boxColor.withOpacity(.90),
        );

        textPainter.paint(canvas, Offset(labelX + 5, labelY + 3));
      } catch (_) {}
    }
  }

  @override
  bool shouldRepaint(covariant PpeBoundingBoxPainter oldDelegate) => true;
}