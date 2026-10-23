import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_shell.dart';
import '../../core/responsive/app_container.dart';
import '../../theme/app_colors.dart';
import '../../providers/wishlist_provider.dart';

import 'package:intl/intl.dart';

const _profileNavy = AppColors.navy;
const _profileCream = AppColors.cream;
const _profileGold = AppColors.gold;
const _profileRed = Color(0xFFD9534F);
const _profileMuted = Color(0xFFB9B9B5);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  _ProfileData? _profile;
  bool _loading = true;
  int? _bookingsCount;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _loadProfile();
    _loadBookingsCount();
  }

  Future<void> _loadProfile() async {
    await Future<void>.delayed(Duration.zero);
    final user = firebase.FirebaseAuth.instance.currentUser;
    final supabaseAuth = Supabase.instance.client.auth;
    debugPrint(
      'AUTH CHECK: firebaseUser=${user != null}, '
      'supabaseSession=${supabaseAuth.currentSession != null}, '
      'supabaseUser=${supabaseAuth.currentUser?.id ?? 'none'}',
    );
    if (!mounted) return;
    setState(() {
      _profile = _ProfileData.fromFirebaseUser(user);
      _loading = false;
    });
    _entranceController.forward();
  }

  Future<void> _loadBookingsCount() async {
    final uid = firebase.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _bookingsCount = 0);
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('bookings')
          .select('id')
          .eq('user_id', uid);
      if (mounted) setState(() => _bookingsCount = rows.length);
    } catch (error) {
      debugPrint('Profile booking count failed: $error');
      if (mounted) setState(() => _bookingsCount = 0);
    }
  }

  Animation<double> _entrance(int step) => CurvedAnimation(
    parent: _entranceController,
    curve: Interval(step * .25, (step + 1) * .25, curve: Curves.easeOutCubic),
  );

  Future<bool> _signOut(BuildContext sheetContext) async {
    try {
      await Supabase.instance.client.auth.signOut();
      await firebase.FirebaseAuth.instance.signOut();
      if (!mounted) return false;
      context.go('/auth');
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
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
    activeRoute: '/profile',
    backgroundColor: _profileNavy,
    wrapInContainer: false,
    body: AppContainer(
      maxWidthOverride: 720,
      padding: EdgeInsets.zero,
      backgroundColor: _profileNavy,
      child: Stack(
        children: [
          const _ProfileGlows(),
          SafeArea(
            bottom: false,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _profileGold),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      22,
                      22,
                      MediaQuery.paddingOf(context).bottom + 104,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 32,
                            fontStyle: FontStyle.italic,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _Entrance(
                          animation: _entrance(0),
                          child: ProfileHeader(
                            name: _profile?.name ?? 'Not provided',
                            bookings: _bookingsCount?.toString() ?? '…',
                            favorites: ref.watch(wishlistProvider).loading
                                ? '…'
                                : ref.watch(wishlistProvider).count.toString(),
                            onFavoritesTap: () => context.push('/wishlist'),
                            memberSince: _profile?.memberSince ?? '—',
                          ),
                        ),
                        const SizedBox(height: 27),
                        Text(
                          'PERSONAL DETAILS',
                          style: GoogleFonts.dmSans(
                            color: _profileGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 13),
                        _Entrance(
                          animation: _entrance(1),
                          child: InfoTile(
                            icon: Icons.person_outline_rounded,
                            label: 'Name',
                            value: _profile?.name ?? 'Not provided',
                          ),
                        ),
                        const SizedBox(height: 11),
                        _Entrance(
                          animation: _entrance(2),
                          child: InfoTile(
                            icon: Icons.mail_outline_rounded,
                            label: 'Email',
                            value: _profile?.email ?? 'Not provided',
                          ),
                        ),
                        const SizedBox(height: 11),
                        _Entrance(
                          animation: _entrance(3),
                          child: InfoTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: _profile?.phone ?? 'Not provided',
                          ),
                        ),
                        const SizedBox(height: 20),
                        _WishlistMenuTile(
                          count: ref.watch(wishlistProvider).count,
                          onTap: () => context.push('/wishlist'),
                        ),
                        const SizedBox(height: 16),
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
                              backgroundColor: _profileCream,
                              foregroundColor: _profileRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
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

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.bookings,
    required this.favorites,
    required this.memberSince,
    this.onFavoritesTap,
    super.key,
  });

  final String name;
  final String bookings;
  final String favorites;
  final String memberSince;
  final VoidCallback? onFavoritesTap;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return 'AT';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 61, 18, 17),
            decoration: BoxDecoration(
              color: _profileCream,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 25,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: _profileNavy,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0D38D), _profileGold],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '★  ATITHI GUEST',
                    style: GoogleFonts.dmSans(
                      color: _profileNavy,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: StatItem(label: 'Bookings', value: bookings),
                    ),
                    _statDivider,
                    Expanded(
                      child: StatItem(
                        label: 'Favorites',
                        value: favorites,
                        onTap: onFavoritesTap,
                      ),
                    ),
                    _statDivider,
                    Expanded(
                      child: StatItem(
                        label: 'Member since',
                        value: memberSince,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _Avatar(initials: _initials),
      ],
    ),
  );

  static Widget get _statDivider => Container(
    width: 1,
    height: 35,
    color: _profileGold.withValues(alpha: .45),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 96,
    height: 96,
    padding: const EdgeInsets.all(3),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: SweepGradient(
        colors: [
          Color(0xFFA97926),
          Color(0xFFFFE7A3),
          _profileGold,
          Color(0xFFA97926),
        ],
      ),
    ),
    child: Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _profileNavy,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.playfairDisplay(
          color: _profileGold,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class StatItem extends StatelessWidget {
  const StatItem({
    required this.label,
    required this.value,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              color: _profileNavy,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              color: _profileNavy.withValues(alpha: .68),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _profileGold.withValues(alpha: .28)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _profileGold.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: _profileGold, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: _profileMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
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

class _ProfileGlows extends StatelessWidget {
  const _ProfileGlows();

  @override
  Widget build(BuildContext context) => const Stack(
    children: [
      Positioned(top: -130, right: -115, child: _GlowCircle(size: 290)),
      Positioned(bottom: 60, left: -175, child: _GlowCircle(size: 340)),
    ],
  );
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          _profileGold.withValues(alpha: .19),
          _profileGold.withValues(alpha: .06),
          Colors.transparent,
        ],
        stops: const [0, .45, 1],
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

  factory _ProfileData.fromFirebaseUser(firebase.User? user) {
    final name = _nonEmpty(user?.displayName);
    final phone = _nonEmpty(user?.phoneNumber);
    final createdAt = user?.metadata.creationTime;
    return _ProfileData(
      name: name,
      email: _nonEmpty(user?.email),
      phone: phone,
      memberSince: createdAt == null
          ? null
          : DateFormat('MMM yyyy').format(createdAt),
    );
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class _WishlistMenuTile extends StatelessWidget {
  const _WishlistMenuTile({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .07),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _profileGold.withValues(alpha: .28)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _profileGold.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: _profileGold,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                'My Wishlist',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _profileGold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: _profileNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _profileGold),
          ],
        ),
      ),
    ),
  );
}
