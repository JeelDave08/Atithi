import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/room.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../room_details/room_details_constants.dart';
import 'booking_success_screen.dart';
import 'widgets/booking_header.dart';
import 'widgets/booking_room_summary.dart';
import 'widgets/booking_section_card.dart';
import 'widgets/booking_sticky_bar.dart';
import 'widgets/booking_summary_card.dart';
import 'widgets/booking_trust_strip.dart';
import 'widgets/guest_count_stepper.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    required this.room,
    this.checkIn,
    this.checkOut,
    this.adults = 2,
    this.children = 0,
    super.key,
  });

  final Room room;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _phoneKey = GlobalKey<FormFieldState<String>>();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _guestAnchor = GlobalKey();
  final _idAnchor = GlobalKey();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _requestsController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _picker = ImagePicker();
  final _service = BookingService();

  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _adults;
  late int _children;
  String _idType = 'Aadhaar Card';
  Uint8List? _guestPhoto;
  Uint8List? _idProof;
  bool _submitting = false;
  bool _autoValidate = false;
  String? _idError;
  String? _submissionError;
  String? _debugSubmissionError;

  static const _idTypes = [
    'Aadhaar Card',
    'Passport',
    'Driving Licence',
    'Voter ID',
  ];
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  int get _nights => _checkOut.difference(_checkIn).inDays;
  int get _capacity => (widget.room.capacity ?? 12).clamp(1, 99).toInt();
  bool get _overCapacity =>
      widget.room.capacity != null &&
      _adults + _children > widget.room.capacity!;
  double get _roomPrice => (widget.room.pricePerNight ?? 0) * _nights;
  double get _total => _roomPrice * (1 + kTaxRate);

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _checkIn = _dateOnly(widget.checkIn ?? today);
    _checkOut = _dateOnly(
      widget.checkOut ?? _checkIn.add(const Duration(days: 1)),
    );
    if (!_checkOut.isAfter(_checkIn)) {
      _checkOut = _checkIn.add(const Duration(days: 1));
    }
    _adults = widget.adults.clamp(1, _capacity).toInt();
    _children = widget.children.clamp(0, 20).toInt();
    _prefillGuest();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _requestsController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _prefillGuest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _nameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted || !doc.exists) return;
      final data = doc.data() ?? const <String, dynamic>{};
      final name = data['name']?.toString().trim() ?? '';
      final email = data['email']?.toString().trim() ?? '';
      final phone =
          data['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
      if (_nameController.text.trim().isEmpty && name.isNotEmpty) {
        _nameController.text = name;
      }
      if (_emailController.text.trim().isEmpty && email.isNotEmpty) {
        _emailController.text = email;
      }
      if (phone.length >= 10) {
        _phoneController.text = phone.substring(phone.length - 10);
      }
      if (mounted) setState(() {});
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Guest profile prefill failed: $error\n$stack');
      }
    }
  }

  Future<void> _chooseImage({required bool forId}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.darkGold,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: AppColors.navy),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.darkGold,
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: AppColors.navy),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      if (forId && compressed.length > 5 * 1024 * 1024) {
        if (mounted) {
          setState(() => _idError = 'Please choose an ID image under 5 MB.');
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        if (forId) {
          _idProof = compressed;
          _idError = null;
        } else {
          _guestPhoto = compressed;
        }
      });
    } on PlatformException catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Image selection failed: $error\n$stack');
      }
      if (mounted) {
        _showMessage('We could not open that image. Please try again.');
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Image processing failed: $error\n$stack');
      }
      if (mounted) {
        _showMessage('We could not process that image. Please choose another.');
      }
    }
  }

  Future<void> _pickDate({required bool checkIn}) async {
    final today = _dateOnly(DateTime.now());
    final first = checkIn ? today : _checkIn.add(const Duration(days: 1));
    final current = checkIn ? _checkIn : _checkOut;
    final selected = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: checkIn
          ? today.add(const Duration(days: 730))
          : _checkIn.add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.navy,
            secondary: AppColors.gold,
            surface: AppColors.cream,
            onSurface: AppColors.navy,
            onPrimary: AppColors.cream,
          ),
        ),
        child: child!,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (checkIn) {
        _checkIn = _dateOnly(selected);
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        _checkOut = _dateOnly(selected);
      }
    });
  }

  Future<void> _confirm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please log in to complete your booking.');
      if (mounted) context.go('/auth');
      return;
    }
    setState(() {
      _autoValidate = true;
      _submissionError = null;
      _debugSubmissionError = null;
      _idError = _idProof == null ? 'Please upload an ID proof.' : null;
    });
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      await _focusFirstInvalid();
      return;
    }
    if (_idProof == null) {
      await _scrollTo(_idAnchor);
      return;
    }
    if (_overCapacity) {
      await _scrollTo(_guestAnchor);
      _showMessage('This room fits up to ${widget.room.capacity} guests.');
      return;
    }
    if (widget.room.status != 'available') {
      _showMessage('This room is not available for booking.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final conflict = await _service.hasConflict(
        roomId: widget.room.id,
        checkIn: _checkIn,
        checkOut: _checkOut,
      );
      if (conflict) throw const BookingConflictException();

      await _service.createBooking(
        room: widget.room,
        guestName: _nameController.text,
        guestEmail: _emailController.text,
        guestPhone: '+91${_phoneController.text.trim()}',
        checkIn: _checkIn,
        checkOut: _checkOut,
        adults: _adults,
        children: _children,
        specialRequests: _requestsController.text,
        idProofType: _idType,
        idProofBytes: _idProof!,
        guestPhotoBytes: _guestPhoto,
      );
      if (!mounted) return;
      context.go(
        '/booking-success',
        extra: BookingSuccessData(
          roomName: widget.room.roomName ?? 'Room',
          roomType: widget.room.roomType ?? 'Room',
          checkIn: _checkIn,
          checkOut: _checkOut,
          adults: _adults,
          children: _children,
          total: _total,
        ),
      );
    } catch (error, stack) {
      debugPrint('Booking submit error: $error\n$stack');
      if (!mounted) return;
      final message = switch (error) {
        BookingConflictException() =>
          'This room is not available for the selected dates.',
        BookingStageException(stage: BookingFailureStage.storage) =>
          'We could not upload your documents. Please retry your booking.',
        BookingStageException(stage: BookingFailureStage.database) =>
          'Your booking could not be saved. Please retry your booking.',
        _ => 'We could not complete your booking. Please check your connection and retry.',
      };
      setState(() {
        _submissionError = message;
        if (kDebugMode) _debugSubmissionError = '$error';
      });
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _focusFirstInvalid() async {
    final fields = [
      (_nameKey, _nameFocus),
      (_phoneKey, _phoneFocus),
      (_emailKey, _emailFocus),
    ];
    for (final field in fields) {
      if (field.$1.currentState?.hasError == true) {
        await _scrollTo(field.$1);
        field.$2.requestFocus();
        return;
      }
    }
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      alignment: .2,
    );
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          content: Text(
            message,
            style: const TextStyle(color: AppColors.cream),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.textScaler.scale(1).clamp(1.0, 1.15).toDouble();
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(scale)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final contentWidth = width > 700 ? 640.0 : width;
          return Scaffold(
            backgroundColor: AppColors.cream,
            resizeToAvoidBottomInset: true,
            body: Form(
              key: _formKey,
              autovalidateMode: _autoValidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: BookingHeader(
                      onBack: () => Navigator.maybePop(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _section(width, contentWidth, _guestInformation()),
                  ),
                  SliverToBoxAdapter(
                    child: _section(width, contentWidth, _guestPhotoCard()),
                  ),
                  SliverToBoxAdapter(
                    child: _section(width, contentWidth, _idProofCard()),
                  ),
                  SliverToBoxAdapter(
                    child: _section(width, contentWidth, _guestCountCard()),
                  ),
                  SliverToBoxAdapter(
                    child: _section(width, contentWidth, _datesCard()),
                  ),
                  SliverToBoxAdapter(
                    child: _section(
                      width,
                      contentWidth,
                      _specialRequestsCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _section(
                      width,
                      contentWidth,
                      BookingRoomSummary(room: widget.room),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _section(
                      width,
                      contentWidth,
                      BookingSummaryCard(
                        room: widget.room,
                        checkIn: _checkIn,
                        checkOut: _checkOut,
                        adults: _adults,
                        children: _children,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _section(width, contentWidth, _bottomFormActions()),
                  ),
                  SliverToBoxAdapter(
                    child: _section(
                      width,
                      contentWidth,
                      const BookingTrustStrip(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          media.padding.bottom + (width < 390 ? 152 : 84) + 16,
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BookingStickyBar(
              total: _total,
              enabled: !_overCapacity && widget.room.status == 'available',
              submitting: _submitting,
              onConfirm: _confirm,
            ),
          );
        },
      ),
    );
  }

  Widget _section(double width, double maxWidth, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width > 700 ? 0 : 16),
          child: child,
        ),
      ),
    ),
  );

  Widget _guestInformation() => BookingSectionCard(
    title: 'Guest Information',
    child: Column(
      children: [
        _field(
          label: 'Full Name',
          hint: 'Enter your full name',
          controller: _nameController,
          fieldKey: _nameKey,
          focusNode: _nameFocus,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.person_outline,
          validator: (value) => (value?.trim().length ?? 0) < 2
              ? 'Enter at least 2 characters.'
              : null,
          onSubmitted: (_) => _phoneFocus.requestFocus(),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                '+91',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _field(
                label: 'Mobile Number',
                hint: '10-digit mobile number',
                controller: _phoneController,
                fieldKey: _phoneKey,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.phone_outlined,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) =>
                    RegExp(r'^[6-9][0-9]{9}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter a valid 10-digit mobile number.',
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _field(
          label: 'Email Address',
          hint: 'Enter your email address',
          controller: _emailController,
          fieldKey: _emailKey,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.email_outlined,
          validator: (value) => _emailPattern.hasMatch(value?.trim() ?? '')
              ? null
              : 'Enter a valid email address.',
        ),
      ],
    ),
  );

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    GlobalKey<FormFieldState<String>>? fieldKey,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    IconData? prefixIcon,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onSubmitted,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 7),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      TextFormField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        style: const TextStyle(color: AppColors.navy, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.greyText, fontSize: 14),
          prefixIcon: prefixIcon == null
              ? null
              : Icon(prefixIcon, color: AppColors.navy),
          filled: true,
          fillColor: AppColors.cream,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          errorMaxLines: 2,
          errorStyle: const TextStyle(color: AppColors.navy, fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.darkGold, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.darkGold),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.darkGold, width: 1.4),
          ),
        ),
      ),
    ],
  );

  Widget _guestPhotoCard() => BookingSectionCard(
    title: 'Guest Photo (Optional)',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.gold.withValues(alpha: .22),
              backgroundImage: _guestPhoto == null
                  ? null
                  : MemoryImage(_guestPhoto!),
              child: _guestPhoto == null
                  ? const Icon(
                      Icons.person_outline,
                      color: AppColors.darkGold,
                      size: 30,
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.darkGold,
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.cream,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: CustomPaint(
            foregroundPainter: _DashedRoundedBorderPainter(AppColors.gold),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _chooseImage(forId: false),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.darkGold,
                        size: 19,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          _guestPhoto == null
                              ? 'Upload Photo (JPG, PNG)'
                              : 'Change Photo',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _idProofCard() => BookingSectionCard(
    keyAnchor: _idAnchor,
    title: 'ID Proof',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _idType,
          decoration: InputDecoration(
            labelText: 'Proof Type',
            labelStyle: const TextStyle(color: AppColors.navy),
            filled: true,
            fillColor: AppColors.cream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          dropdownColor: AppColors.cream,
          items: _idTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: const TextStyle(color: AppColors.navy),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _idType = value ?? _idType),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_idProof != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  _idProof!,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.darkGold,
                size: 18,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Uploaded',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.darkGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _chooseImage(forId: true),
                child: const Text(
                  'Change',
                  style: TextStyle(color: AppColors.navy),
                ),
              ),
            ] else
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _chooseImage(forId: true),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text(
                    'Upload ID Image',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.gold),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
          ],
        ),
        if (_idError != null) ...[
          const SizedBox(height: 5),
          Text(
            _idError!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.navy, fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Your ID is stored securely and used only for check-in.',
          style: TextStyle(
            color: AppColors.greyText,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _guestCountCard() => BookingSectionCard(
    title: 'Guest Count',
    keyAnchor: _guestAnchor,
    child: Column(
      children: [
        GuestCountStepper(
          label: 'Adults',
          count: _adults,
          minimum: 1,
          maximum: _capacity,
          onChanged: (value) =>
              setState(() => _adults = value.clamp(1, _capacity).toInt()),
        ),
        const Divider(height: 1, color: AppColors.border),
        GuestCountStepper(
          label: 'Children',
          count: _children,
          minimum: 0,
          maximum: null,
          onChanged: (value) =>
              setState(() => _children = value.clamp(0, 20).toInt()),
        ),
        if (_overCapacity) ...[
          const SizedBox(height: 8),
          Text(
            'This room fits up to ${widget.room.capacity} guests',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _datesCard() => BookingSectionCard(
    title: 'Stay Dates',
    child: Column(
      children: [
        _dateTile('Check-in', _checkIn, onTap: () => _pickDate(checkIn: true)),
        const SizedBox(height: 10),
        _dateTile(
          'Check-out',
          _checkOut,
          onTap: () => _pickDate(checkIn: false),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_nights ${_nights == 1 ? 'Night' : 'Nights'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.darkGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _dateTile(
    String label,
    DateTime date, {
    required VoidCallback onTap,
  }) => Material(
    color: AppColors.cream,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.darkGold,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.navy,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${DateFormat('MMM yyyy').format(date)} · ${DateFormat('EEEE').format(date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.navy, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.navy,
              size: 19,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _specialRequestsCard() => BookingSectionCard(
    title: 'Special Requests (Optional)',
    child: TextFormField(
      controller: _requestsController,
      maxLength: 300,
      maxLines: 4,
      minLines: 3,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(color: AppColors.navy),
      decoration: InputDecoration(
        hintText: 'Let us know if you have any special requests',
        hintStyle: const TextStyle(color: AppColors.greyText, fontSize: 13),
        filled: true,
        fillColor: AppColors.cream,
        alignLabelWithHint: true,
        counterStyle: const TextStyle(color: AppColors.greyText, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.darkGold),
        ),
      ),
    ),
  );

  Widget _bottomFormActions() => Column(
    children: [
      if (_submissionError != null) ...[
        Text(
          _submissionError!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.navy, fontSize: 13),
        ),
        if (kDebugMode && _debugSubmissionError != null)
          SelectableText(
            _debugSubmissionError!,
            maxLines: 3,
            style: const TextStyle(color: AppColors.greyText, fontSize: 10),
          ),
        const SizedBox(height: 8),
      ],
      OutlinedButton.icon(
        onPressed: _submitting ? null : () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_outlined),
        label: const Text('Back'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.gold),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    ],
  );
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(16)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 6).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
