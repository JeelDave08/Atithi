import 'dart:async';
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
  bool _loading = false;
  int? _bookingsCount;
  StreamSubscription<AuthState>? _supabaseAuthSubscription;
  StreamSubscription<firebase.User?>? _firebaseAuthSubscription;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _initImmediateProfile();
    _loadBackgroundData();
    _setupAuthListeners();
  }

  void _initImmediateProfile() {
    final suUser = Supabase.instance.client.auth.currentUser;
    final fbUser = firebase.FirebaseAuth.instance.currentUser;

    if (suUser == null && fbUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return;
    }

    _profile = _ProfileData.buildImmediate(
      supabaseUser: suUser,
      firebaseUser: fbUser,
    );
    _loading = false;
    _entranceController.forward();
  }

  void _setupAuthListeners() {
    try {
      _supabaseAuthSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (!mounted) return;
        if (data.session == null &&
            firebase.FirebaseAuth.instance.currentUser == null) {
          context.go('/login');
        } else {
          // Do not reset loading to true repeatedly.
          _loadBackgroundData();
        }
      });
    } catch (e) {
      debugPrint('Supabase onAuthStateChange error: $e');
    }

    try {
      _firebaseAuthSubscription =
          firebase.FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted) return;
        if (user == null &&
            Supabase.instance.client.auth.currentUser == null) {
          context.go('/login');
        } else {
          // Do not reset loading to true repeatedly.
          _loadBackgroundData();
        }
      });
    } catch (e) {
      debugPrint('Firebase authStateChanges error: $e');
    }
  }

  Future<void> _loadBackgroundData() async {
    final suUser = Supabase.instance.client.auth.currentUser;
    final fbUser = firebase.FirebaseAuth.instance.currentUser;
    final uid = suUser?.id ?? fbUser?.uid;

    if (suUser == null && fbUser == null) {
      if (mounted) context.go('/login');
      return;
    }

    // 1. Fetch profiles row with timeout and maybeSingle
    try {
      Map<String, dynamic>? row;
      if (fbUser != null) {
        try {
          row = await Supabase.instance.client
              .from('profiles')
              .select('full_name, phone')
              .eq('firebase_uid', fbUser.uid)
              .maybeSingle()
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint('Profile row fetch (firebase_uid) failed: $e');
        }
      }

      if (row == null && suUser != null) {
        try {
          row = await Supabase.instance.client
              .from('profiles')
              .select('full_name, phone')
              .eq('id', suUser.id)
              .maybeSingle()
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint('Profile row fetch (id) failed: $e');
        }
      }

      if (row != null && mounted) {
        final sName = _ProfileData._nonEmpty(row['full_name']);
        final sPhone = _ProfileData._nonEmpty(row['phone']);
        setState(() {
          _profile = _ProfileData.buildImmediate(
            supabaseUser: suUser,
            firebaseUser: fbUser,
            supabaseName: sName,
            supabasePhone: sPhone,
          );
        });
      }
    } catch (error) {
      debugPrint('Background profile fetch error: $error');
    }

    // 2. Fetch bookings count with timeout and error fallback to 0
    try {
      var count = 0;
      if (uid != null) {
        try {
          final rows = await Supabase.instance.client
              .from('bookings')
              .select('id')
              .eq('user_id', uid)
              .timeout(const Duration(seconds: 8));
          count = rows.length;
        } catch (e) {
          debugPrint('Bookings count (user_id) failed: $e');
          if (fbUser != null) {
            try {
              final fbRows = await Supabase.instance.client
                  .from('bookings')
                  .select('id')
                  .eq('firebase_uid', fbUser.uid)
                  .timeout(const Duration(seconds: 8));
              count = fbRows.length;
            } catch (e2) {
              debugPrint('Bookings count (firebase_uid) failed: $e2');
            }
          }
        }
      }
      if (mounted) {
        setState(() => _bookingsCount = count);
      }
    } catch (error) {
      debugPrint('Background bookings count error: $error');
      if (mounted) {
        setState(() => _bookingsCount = 0);
      }
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  Animation<double> _entrance(int step) => CurvedAnimation(
    parent: _entranceController,
    curve: Interval(step * .25, (step + 1) * .25, curve: Curves.easeOutCubic),
  );

  Future<bool> _signOut(BuildContext sheetContext) async {
    try {
      try {
        await Supabase.instance.client.auth
            .signOut()
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Supabase signOut error: $e');
      }
      try {
        await firebase.FirebaseAuth.instance
            .signOut()
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Firebase signOut error: $e');
      }
      if (!mounted) return false;
      context.go('/login');
      return true;
    } catch (e) {
      debugPrint('Logout failed: $e');
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

  void _showAddPhoneSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AddPhoneSheet(
        onSaved: () {
          if (!mounted) return;
          _loadBackgroundData();
        },
      ),
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
            child: _loading && _profile == null
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
                            name: _profile?.displayName ?? 'Guest',
                            isGuest: _profile?.displayName == null,
                            bookings: _bookingsCount?.toString() ?? '—',
                            favorites: ref.watch(wishlistProvider).loading
                                ? '—'
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
                            value: _profile?.displayName ?? 'Not provided',
                            hint: _profile?.nameIsFromEmail == true
                                ? '(from email)'
                                : null,
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
                        if (_profile?.phone == null)
                          Padding(
                            padding: const EdgeInsets.only(left: 14, top: 4),
                            child: TextButton(
                              onPressed: _showAddPhoneSheet,
                              style: TextButton.styleFrom(
                                foregroundColor: _profileGold,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '+ Add phone number',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
    this.isGuest = false,
    this.onFavoritesTap,
    super.key,
  });

  final String name;
  final String bookings;
  final String favorites;
  final String memberSince;
  final bool isGuest;
  final VoidCallback? onFavoritesTap;

  String get _initials {
    if (isGuest) return '';
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '';
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
        _Avatar(initials: _initials, isGuest: isGuest),
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
  const _Avatar({required this.initials, this.isGuest = false});
  final String initials;
  final bool isGuest;

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
      child: isGuest
          ? const Icon(Icons.person_rounded, color: _profileGold, size: 36)
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                initials,
                maxLines: 1,
                style: GoogleFonts.playfairDisplay(
                  color: _profileGold,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
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
    this.hint,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;

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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (hint != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          hint!,
                          style: GoogleFonts.dmSans(
                            color: _profileMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
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
    required this.displayName,
    required this.nameIsFromEmail,
    required this.email,
    required this.phone,
    required this.memberSince,
  });

  /// Resolved display name or null if truly no info at all.
  final String? displayName;

  /// True when the name was derived from the email prefix (no real name stored).
  final bool nameIsFromEmail;
  final String? email;
  final String? phone;
  final String? memberSince;

  factory _ProfileData.buildImmediate({
    User? supabaseUser,
    firebase.User? firebaseUser,
    String? supabaseName,
    String? supabasePhone,
  }) {
    final email = _nonEmpty(supabaseUser?.email) ?? _nonEmpty(firebaseUser?.email);
    DateTime? createdAt = firebaseUser?.metadata.creationTime;
    if (createdAt == null && supabaseUser?.createdAt != null) {
      try {
        createdAt = DateTime.tryParse(supabaseUser!.createdAt);
      } catch (_) {}
    }

    // Name resolution chain.
    String? resolvedName;
    bool fromEmail = false;

    // 1. Supabase profiles.full_name
    resolvedName = supabaseName;

    // 2. Supabase userMetadata (e.g. 'full_name', 'name', 'display_name')
    if (resolvedName == null && supabaseUser?.userMetadata != null) {
      for (final key in ['full_name', 'name', 'display_name']) {
        final v = _nonEmpty(supabaseUser!.userMetadata![key]);
        if (v != null) {
          resolvedName = v;
          break;
        }
      }
    }

    // 3. Firebase displayName
    resolvedName ??= _nonEmpty(firebaseUser?.displayName);

    // 4. Firebase userMetadata / providerData fields
    if (resolvedName == null && firebaseUser != null) {
      try {
        final meta = firebaseUser.providerData.isEmpty == true
            ? <String, dynamic>{}
            : (firebaseUser.providerData.first as dynamic)?.additionalUserInfo
                    ?.profile as Map<String, dynamic>? ??
                <String, dynamic>{};
        for (final key in ['full_name', 'name', 'display_name']) {
          final v = _nonEmpty(meta[key]);
          if (v != null) {
            resolvedName = v;
            break;
          }
        }
      } catch (_) {}
    }

    // 5. Email prefix -> capitalized words
    if (resolvedName == null && email != null) {
      final prefix = email.split('@').first;
      final parts = prefix.split(RegExp(r'[.\-_0-9]+'))
          .where((p) => p.isNotEmpty)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .toList();
      if (parts.isNotEmpty) {
        resolvedName = parts.join(' ');
        fromEmail = true;
      }
    }

    // Phone resolution: prefer Supabase profile, then Supabase auth, then Firebase.
    final phone = supabasePhone ??
        _nonEmpty(supabaseUser?.phone) ??
        _nonEmpty(firebaseUser?.phoneNumber);

    return _ProfileData(
      displayName: resolvedName,
      nameIsFromEmail: fromEmail,
      email: email,
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

// ---------------------------------------------------------------------------
// Add Phone Sheet
// ---------------------------------------------------------------------------

class _AddPhoneSheet extends StatefulWidget {
  const _AddPhoneSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<_AddPhoneSheet> createState() => _AddPhoneSheetState();
}

class _AddPhoneSheetState extends State<_AddPhoneSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final fbUser = firebase.FirebaseAuth.instance.currentUser;
      final suUser = Supabase.instance.client.auth.currentUser;
      if (fbUser == null && suUser == null) throw Exception('Not signed in');
      final phone = _controller.text.trim();

      if (fbUser != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'firebase_uid': fbUser.uid,
          'phone': phone,
        }, onConflict: 'firebase_uid').timeout(const Duration(seconds: 8));
      }
      if (suUser != null) {
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id': suUser.id,
            'phone': phone,
          }, onConflict: 'id').timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint('Supabase profile id phone upsert failed: $e');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved();
    } catch (e) {
      debugPrint('Add phone failed: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: const BoxDecoration(
          color: _profileCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Phone Number',
                style: GoogleFonts.playfairDisplay(
                  color: _profileNavy,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: '10-digit mobile number',
                  prefixText: '+91  ',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _profileNavy.withValues(alpha: .35),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _profileGold, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().length != 10) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: _profileRed,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _profileNavy,
                    foregroundColor: _profileCream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
