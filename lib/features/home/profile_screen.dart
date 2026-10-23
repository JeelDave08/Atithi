import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/login_screen.dart';
import '../../shared/widgets/sunset_widgets.dart';
import '../../theme/app_colors.dart';

const _profileNavy = AppColors.navy;
const _profileCream = AppColors.cream;
const _profileCard = AppColors.surface;
const _profileGold = AppColors.gold;
const _profileRed = Color(0xFFD9534F);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  StreamSubscription<dynamic>? _supabaseAuthSubscription;
  StreamSubscription<firebase.User?>? _firebaseAuthSubscription;
  _ProfileData? _profile;
  // Kept populated by the existing profile stats fetch; the redesigned UI omits stats.
  // ignore: unused_field
  int? _bookings;
  // ignore: unused_field
  int? _favorites;
  bool _profileLoading = true;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _supabaseAuthSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => _loadProfile());
    _firebaseAuthSubscription = firebase.FirebaseAuth.instance
        .authStateChanges()
        .listen((_) => _loadProfile());
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final generation = ++_loadGeneration;
    final supabase = Supabase.instance.client;
    final supabaseUser = supabase.auth.currentUser;
    final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
    final initial = _ProfileData.fromAuth(supabaseUser, firebaseUser);
    if (!mounted) return;
    setState(() {
      _profile = initial;
      _bookings = null;
      _favorites = null;
      _profileLoading = supabaseUser != null || firebaseUser != null;
    });
    if (!_entranceController.isAnimating && _entranceController.value == 0) {
      _entranceController.forward();
    }

    if (supabaseUser == null && firebaseUser == null) {
      if (mounted) setState(() => _profileLoading = false);
      return;
    }

    final userId = supabaseUser?.id ?? firebaseUser!.uid;
    final profileFuture = _loadProfileRow(
      supabaseUser: supabaseUser,
      firebaseUser: firebaseUser,
      userId: userId,
    );
    final statsFuture = _loadStats(
      userId: userId,
      isSupabaseUser: supabaseUser != null,
      generation: generation,
    );
    final row = await profileFuture;
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _profile = initial.withProfileRow(row);
      _profileLoading = false;
    });
    await statsFuture;
  }

  Future<Map<String, dynamic>?> _loadProfileRow({
    required User? supabaseUser,
    required firebase.User? firebaseUser,
    required String userId,
  }) async {
    try {
      if (supabaseUser != null) {
        return await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return snapshot.data();
    } catch (error, stack) {
      debugPrint('Profile fetch failed: $error\n$stack');
      return null;
    }
  }

  Future<void> _loadStats({
    required String userId,
    required bool isSupabaseUser,
    required int generation,
  }) async {
    final bookingColumn = isSupabaseUser ? 'user_id' : 'firebase_uid';
    Future<int> count(String table, String column) async {
      try {
        final rows = await Supabase.instance.client
            .from(table)
            .select()
            .eq(column, userId);
        return rows.length;
      } catch (error, stack) {
        debugPrint('$table count failed: $error\n$stack');
        return 0;
      }
    }

    final counts = await Future.wait([
      count('bookings', bookingColumn),
      count('favorites', 'user_id'),
    ]);
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _bookings = counts[0];
      _favorites = counts[1];
    });
  }

  Animation<double> _entrance(int step) => CurvedAnimation(
    parent: _entranceController,
    curve: Interval(step * .25, (step + 1) * .25, curve: Curves.easeOutCubic),
  );

  Future<bool> _signOut(BuildContext sheetContext) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (firebase.FirebaseAuth.instance.currentUser != null) {
        await firebase.FirebaseAuth.instance.signOut();
      }
      if (!mounted) return false;
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not log out. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  void _showLogoutSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogoutSheet(onConfirm: _signOut),
    );
  }

  @override
  void dispose() {
    _supabaseAuthSubscription?.cancel();
    _firebaseAuthSubscription?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? _ProfileData.empty();
    final namePending = _profileLoading && profile.name == null;
    final phonePending = _profileLoading && profile.phone == null;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileSectionHeading('Profile', titleStyle: true),
                  const SizedBox(height: 24),
                  _Entrance(
                    animation: _entrance(0),
                    child: ProfileIdentity(
                      name: profile.name ?? 'Not provided',
                      email: profile.email ?? 'Not provided',
                      initials: _profileInitials(profile.name),
                      nameLoading: namePending,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _ProfileSectionHeading('Personal Details'),
                  const SizedBox(height: 16),
                  _Entrance(
                    animation: _entrance(1),
                    child: InfoTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Name',
                      value: profile.name ?? 'Not provided',
                      isLoading: namePending,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Entrance(
                    animation: _entrance(2),
                    child: InfoTile(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      value: profile.email ?? 'Not provided',
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Entrance(
                    animation: _entrance(3),
                    child: InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: profile.phone ?? 'Not provided',
                      isLoading: phonePending,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _showLogoutSheet,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        'Log out',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _profileNavy,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: FloatingBottomNav(selected: 4),
          ),
        ],
      ),
    );
  }
}

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    required this.name,
    required this.email,
    required this.initials,
    this.nameLoading = false,
    super.key,
  });

  final String name;
  final String email;
  final String initials;
  final bool nameLoading;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: _profileNavy,
          shape: BoxShape.circle,
          border: Border.all(color: _profileGold, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          maxLines: 1,
          style: GoogleFonts.playfairDisplay(
            color: _profileGold,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: nameLoading
            ? const Center(child: _ProfileFieldShimmer(width: 150, height: 22))
            : Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: _profileNavy,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      const SizedBox(height: 3),
      SizedBox(
        width: double.infinity,
        child: Text(
          email,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            color: AppColors.secondaryText,
            fontSize: 14,
          ),
        ),
      ),
    ],
  );
}

String _profileInitials(String? name) {
  final value = name?.trim() ?? '';
  if (value.isEmpty || value.toLowerCase() == 'not provided') return 'A';
  final parts = value.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

class _ProfileSectionHeading extends StatelessWidget {
  const _ProfileSectionHeading(this.title, {this.titleStyle = false});

  final String title;
  final bool titleStyle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.playfairDisplay(
          color: _profileNavy,
          fontSize: titleStyle ? 28 : 23,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      Container(
        width: 66,
        height: 3,
        decoration: BoxDecoration(
          color: _profileGold,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ],
  );
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLoading = false,
    this.maxLines = 1,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLoading;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Card(
    color: _profileCard,
    elevation: 2,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: _profileGold, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                if (isLoading)
                  const _ProfileFieldShimmer(width: 120, height: 14)
                else
                  Text(
                    value,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: _profileNavy,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class LogoutSheet extends StatefulWidget {
  const LogoutSheet({required this.onConfirm, super.key});

  final Future<bool> Function(BuildContext sheetContext) onConfirm;

  @override
  State<LogoutSheet> createState() => _LogoutSheetState();
}

class _LogoutSheetState extends State<LogoutSheet> {
  bool _submitting = false;

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    final success = await widget.onConfirm(context);
    if (!mounted || success) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: const BoxDecoration(
        color: _profileCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log out?',
            style: GoogleFonts.playfairDisplay(
              color: _profileNavy,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to log out of your ATITHI account?',
            style: GoogleFonts.dmSans(
              color: _profileNavy.withValues(alpha: .72),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: _profileNavy,
                    side: BorderSide(
                      color: _profileNavy.withValues(alpha: .35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Cancel', style: GoogleFonts.dmSans()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _confirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: _profileRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Yes, Log out',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: animation.drive(
        Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero),
      ),
      child: child,
    ),
  );
}

class _ProfileFieldShimmer extends StatelessWidget {
  const _ProfileFieldShimmer({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.white.withValues(alpha: .10),
    highlightColor: _profileGold.withValues(alpha: .42),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    ),
  );
}

class _ProfileData {
  const _ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.memberSince,
  });

  final String? name;
  final String? email;
  final String? phone;
  final String? memberSince;

  factory _ProfileData.empty() => const _ProfileData(
    name: null,
    email: null,
    phone: null,
    memberSince: null,
  );

  factory _ProfileData.fromAuth(
    User? supabaseUser,
    firebase.User? firebaseUser,
  ) {
    final metadata = supabaseUser?.userMetadata ?? const <String, dynamic>{};
    final email =
        _nonEmpty(supabaseUser?.email) ?? _nonEmpty(firebaseUser?.email);
    final name = supabaseUser != null
        ? _nonEmpty(metadata['full_name']) ??
              _nonEmpty(metadata['name']) ??
              _nonEmpty(metadata['display_name']) ??
              _nonEmpty(metadata['fullName']) ??
              _emailName(email)
        : _nonEmpty(firebaseUser?.displayName) ?? _emailName(email);
    final phone =
        _nonEmpty(supabaseUser?.phone) ??
        _nonEmpty(metadata['phone']) ??
        _nonEmpty(firebaseUser?.phoneNumber);
    final createdAt =
        DateTime.tryParse(supabaseUser?.createdAt ?? '') ??
        firebaseUser?.metadata.creationTime;
    return _ProfileData(
      name: name,
      email: email,
      phone: phone,
      memberSince: createdAt?.year.toString(),
    );
  }

  _ProfileData withProfileRow(Map<String, dynamic>? data) {
    if (data == null) return this;
    return _ProfileData(
      name: _nonEmpty(data['full_name']) ?? _nonEmpty(data['name']) ?? name,
      email: email,
      phone: _nonEmpty(data['phone']) ?? phone,
      memberSince: memberSince,
    );
  }

  static String? _emailName(String? email) {
    if (email == null) return null;
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return null;
    return '${localPart[0].toUpperCase()}${localPart.substring(1)}';
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
