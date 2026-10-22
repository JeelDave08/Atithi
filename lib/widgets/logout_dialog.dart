import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_repository.dart';
import '../screens/auth_screen.dart';
import '../theme/app_colors.dart';

Future<void> showLogoutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LogoutDialog(parentContext: context),
  );
}

class _LogoutDialog extends StatefulWidget {
  const _LogoutDialog({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
  bool _isLoggingOut = false;

  Future<void> _logOut() async {
    setState(() => _isLoggingOut = true);
    try {
      await const AuthService().signOut();
      if (!widget.parentContext.mounted) return;

      Navigator.of(
        widget.parentContext,
        rootNavigator: true,
      ).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => const AuthScreen(authRepository: AuthService()),
        ),
        (_) => false,
      );
    } catch (error) {
      debugPrint('Logout failed: $error');
      if (!widget.parentContext.mounted) return;
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(widget.parentContext)
          .showSnackBar(SnackBar(content: Text('Unable to log out: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.cream,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: Text(
      'Log out?',
      style: GoogleFonts.playfairDisplay(
        color: AppColors.navy,
        fontSize: 24,
        fontStyle: FontStyle.italic,
      ),
    ),
    content: const Text(
      'Are you sure you want to log out?',
      style: TextStyle(color: AppColors.navy),
    ),
    actions: [
      TextButton(
        onPressed: _isLoggingOut ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel', style: TextStyle(color: AppColors.navy)),
      ),
      FilledButton(
        onPressed: _isLoggingOut ? null : _logOut,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
              )
            : const Text('Log out'),
      ),
    ],
  );
}
