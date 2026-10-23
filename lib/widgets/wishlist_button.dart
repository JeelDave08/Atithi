import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/wishlist_provider.dart';
import '../theme/app_colors.dart';

class WishlistButton extends StatefulWidget {
  const WishlistButton({
    required this.roomId,
    this.size = 40,
    this.onDarkBackground = false,
    super.key,
  });

  final String roomId;
  final double size;
  final bool onDarkBackground;

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> {
  bool _busy = false;
  bool _pressed = false;
  WishlistNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WishlistNotifier? next;
    try {
      next = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(wishlistProvider);
    } on StateError {
      // Standalone previews and widget tests can render the control without app state.
    }
    if (identical(next, _notifier)) return;
    _notifier?.removeListener(_onWishlistChanged);
    _notifier = next;
    _notifier?.addListener(_onWishlistChanged);
  }

  void _onWishlistChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onWishlistChanged);
    super.dispose();
  }

  Future<void> _tap() async {
    if (_busy) return;
    final wishlist = _notifier;
    if (wishlist == null) return;
    if (wishlist.currentUserId == null) {
      await _showLoginSheet(wishlist);
      return;
    }
    setState(() {
      _busy = true;
      _pressed = true;
    });
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _pressed = false);
    final saved = await wishlist.toggle(widget.roomId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved == null) {
      final error = wishlist.lastError;
      final message = wishlist.lastErrorIsNetwork
          ? 'No internet connection'
          : kDebugMode && error is PostgrestException
          ? "Couldn't update wishlist: ${error.message}"
          : "Couldn't update wishlist";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Added to wishlist' : 'Removed from wishlist'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => wishlist.toggle(widget.roomId),
        ),
      ),
    );
  }

  Future<void> _showLoginSheet(WishlistNotifier wishlist) async {
    final login = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_border_rounded,
                size: 38,
                color: AppColors.gold,
              ),
              const SizedBox(height: 12),
              const Text(
                'Login to save rooms',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (login != true || !mounted) return;
    await wishlist.rememberAfterLogin(widget.roomId);
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final saved = _notifier?.isWishlisted(widget.roomId) ?? false;
    final color = saved ? const Color(0xFFC94747) : AppColors.navy;
    final label = saved ? 'Remove from wishlist' : 'Add to wishlist';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Tooltip(
            message: label,
            child: Semantics(
              button: true,
              label: label,
              child: Material(
                color: Colors.white.withValues(alpha: .94),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _busy ? null : _tap,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Center(
                      child: AnimatedScale(
                        scale: _pressed ? .82 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
