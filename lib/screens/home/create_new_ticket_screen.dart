import 'dart:ui';

import 'package:flutter/material.dart';

import '../../widgets/custom_header.dart';
import '../../services/ticket_service.dart';
import '../../services/department_service.dart';
import '../reports/my_reports_screen.dart';

/// -----------------------------------------------------------------------
/// "Create New Ticket" screen.
///
/// Visual style matches the app's shared look (background image + navy
/// gradient overlay + frosted-glass blurred cards), with CustomHeader at
/// the top instead of a language switcher.
///
/// Fields: Title, Description, Department (fetched from the API),
/// Priority, then Submit / Cancel.
/// -----------------------------------------------------------------------
class CreateNewTicketScreen extends StatefulWidget {
  final List<String> detectedClasses;
  final String filePath;
  final bool isVideo;

  const CreateNewTicketScreen({
    super.key,
    required this.detectedClasses,
    required this.filePath,
    required this.isVideo,
  });

  @override
  State<CreateNewTicketScreen> createState() => _CreateNewTicketScreenState();
}

class _CreateNewTicketScreenState extends State<CreateNewTicketScreen> {
  static const _navy = Color(0xFF04102A);
  static const _accent = Color(0xFFE26336);
  static const _accent2 = Color(0xFFFF8A5C);
  static const _glassBg = Color(0x1AFFFFFF);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Adjust to match whatever values your backend's Priority field expects.
  final List<String> _priorities = const ['Low', 'Medium', 'High'];
  final Map<String, String> _priorityLabelsAr = const {
    'Low': 'منخفضة',
    'Medium': 'متوسطة',
    'High': 'عالية',
  };

  List<DepartmentModel> _departments = [];
  bool _loadingDepartments = true;
  String? _departmentsError;

  int? _selectedDepartmentId;
  String? _selectedPriority;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _loadingDepartments = true;
      _departmentsError = null;
    });

    try {
      final departments = await DepartmentService.getAllDepartments();
      if (!mounted) return;
      setState(() {
        _departments = departments;
        _loadingDepartments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _departmentsError = e.toString();
        _loadingDepartments = false;
      });
    }
  }

  Future<void> _submit(bool isArabic) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartmentId == null) {
      _showError(isArabic ? 'من فضلك اختر القسم' : 'Please select a department');
      return;
    }
    if (_selectedPriority == null) {
      _showError(isArabic ? 'من فضلك اختر الأولوية' : 'Please select a priority');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await TicketService.createTicket(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        departmentId: _selectedDepartmentId!,
        priority: _selectedPriority!,
        detectedClasses: widget.detectedClasses,
      );

      TicketsRefreshNotifier.notify();


      if (!mounted) return;
      Navigator.pop(context, true);

    } catch (e) {
      _showError(
        isArabic ? 'فشل إرسال البلاغ: $e' : 'Failed to submit ticket: $e',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Stack(
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

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _navy.withOpacity(.85),
                  _navy.withOpacity(.70),
                  _navy.withOpacity(.95),
                ],
              ),
            ),
          ),
        ),

        // ===================================================
        // CONTENT
        // ===================================================
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const CustomHeader(),

                    const SizedBox(height: 20),

                    const Icon(
                      Icons.confirmation_number_outlined,
                      color: _accent,
                      size: 40,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isArabic ? 'إنشاء بلاغ سلامة' : 'Create Safety Ticket',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isArabic
                          ? 'أبلغ عن مخالفات السلامة ومشاكل الالتزام'
                          : 'Report safety violations and compliance issues',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 30),

                    _buildTitleSection(isArabic),

                    const SizedBox(height: 25),

                    _buildDescriptionSection(isArabic),

                    const SizedBox(height: 25),

                    _buildDepartmentSection(isArabic),

                    const SizedBox(height: 25),

                    _buildPrioritySection(isArabic),

                    const SizedBox(height: 30),

                    _buildActionButtons(isArabic),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SECTION HEADER (icon + label, same pattern across sections)
  // =========================================================

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: _accent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _glassContainer({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // =========================================================
  // TITLE
  // =========================================================

  Widget _buildTitleSection(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          Icons.title_outlined,
          isArabic ? 'العنوان' : 'Title',
        ),
        const SizedBox(height: 10),
        _glassContainer(
          child: TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: isArabic ? 'أدخل عنوان البلاغ' : 'Enter ticket title',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? (isArabic ? 'من فضلك أدخل العنوان' : 'Please enter a title')
                : null,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DESCRIPTION
  // =========================================================

  Widget _buildDescriptionSection(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          Icons.description_outlined,
          isArabic ? 'الوصف' : 'Description',
        ),
        const SizedBox(height: 10),
        _glassContainer(
          child: TextFormField(
            controller: _descController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: isArabic ? 'اوصف المشكلة...' : 'Describe the issue...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? (isArabic ? 'من فضلك أدخل الوصف' : 'Please enter a description')
                : null,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DEPARTMENT
  // =========================================================

  Widget _buildDepartmentSection(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          Icons.apartment_outlined,
          isArabic ? 'القسم' : 'Department',
        ),
        const SizedBox(height: 10),
        _glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _buildDepartmentDropdown(isArabic),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown(bool isArabic) {
    if (_loadingDepartments) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
          ),
        ),
      );
    }

    if (_departmentsError != null) {
      return SizedBox(
        height: 50,
        child: Row(
          children: [
            Expanded(
              child: Text(
                isArabic ? 'تعذر تحميل الأقسام' : 'Failed to load departments',
                style: TextStyle(color: Colors.redAccent.shade100, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _loadDepartments,
              child: Text(
                isArabic ? 'إعادة المحاولة' : 'Retry',
                style: const TextStyle(color: _accent),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedDepartmentId,
      isExpanded: true,
      dropdownColor: _navy,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
      decoration: const InputDecoration(border: InputBorder.none),
      hint: Text(
        isArabic ? '-- اختر القسم --' : '-- Select Department --',
        style: TextStyle(color: Colors.white.withOpacity(0.4)),
      ),
      items: _departments
          .map(
            (d) => DropdownMenuItem<int>(
              value: d.id,
              child: Text(
                '${d.name}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedDepartmentId = value),
    );
  }

  // =========================================================
  // PRIORITY
  // =========================================================

  Widget _buildPrioritySection(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          Icons.priority_high_outlined,
          isArabic ? 'الأولوية' : 'Priority',
        ),
        const SizedBox(height: 10),
        _glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedPriority,
            isExpanded: true,
            dropdownColor: _navy,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            decoration: const InputDecoration(border: InputBorder.none),
            hint: Text(
              isArabic ? '-- اختر الأولوية --' : '-- Select Priority --',
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
            items: _priorities
                .map(
                  (p) => DropdownMenuItem<String>(
                    value: p,
                    child: Text(
                      isArabic ? _priorityLabelsAr[p]! : p,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedPriority = value),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ACTION BUTTONS
  // =========================================================

  Widget _buildActionButtons(bool isArabic) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: InkWell(
            onTap: _isSubmitting ? null : () => _submit(isArabic),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [_accent, _accent2]),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      isArabic ? 'إرسال البلاغ' : 'Submit Ticket',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: _isSubmitting ? null : () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                isArabic ? 'إلغاء' : 'Cancel',
                style: TextStyle(
                  color: _isSubmitting ? Colors.white54 : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}