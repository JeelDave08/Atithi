import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/sunset_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController();
  final _phone = TextEditingController(), _password = TextEditingController();
  bool _signup = false, _busy = false, _show = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.navy,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 390)
              .clamp(.86, 1.08)
              .toDouble();
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 30 * scale,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Form(
                  key: _form,
                  child: Column(
                    children: [
                      Container(
                        width: 138 * scale,
                        height: 174 * scale,
                        decoration: BoxDecoration(
                          border: Border.all(color: Palette.gold, width: 1.3),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(70 * scale),
                            bottom: const Radius.circular(18),
                          ),
                        ),
                        child: const Icon(
                          Icons.wb_sunny_outlined,
                          color: Palette.gold,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _signup ? 'Create your account' : 'Welcome back',
                        style: serif(30 * scale, italic: true),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Palette.slate,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            _toggle('Sign In', !_signup),
                            _toggle('Create Account', _signup),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_signup) ...[
                        _field(_name, 'Name', Icons.person_outline),
                        const SizedBox(height: 12),
                      ],
                      _field(_email, 'Email', Icons.mail_outline),
                      const SizedBox(height: 12),
                      _field(
                        _password,
                        'Password',
                        Icons.lock_outline,
                        password: true,
                      ),
                      if (_signup) ...[
                        const SizedBox(height: 12),
                        _field(_phone, 'Phone', Icons.phone_outlined),
                      ],
                      const SizedBox(height: 20),
                      GoldButton(
                        label: _busy
                            ? 'Please wait…'
                            : (_signup ? 'Create Account' : 'Sign In'),
                        onPressed: _busy ? () {} : _submit,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Golden hour stays, thoughtfully chosen.',
                        style: TextStyle(
                          color: Palette.cream.withOpacity(.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _toggle(String label, bool active) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _signup = label == 'Create Account'),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Palette.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Palette.navy : Palette.cream,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool password = false,
  }) => CreamPill(
    child: TextFormField(
      controller: controller,
      obscureText: password && !_show,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Please enter $label' : null,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: label,
        icon: Icon(icon, color: Palette.darkGold, size: 20),
        suffixIcon: password
            ? IconButton(
                onPressed: () => setState(() => _show = !_show),
                icon: Icon(
                  _show ? Icons.visibility_off : Icons.visibility,
                  color: Palette.darkGold,
                  size: 20,
                ),
              )
            : null,
      ),
      style: const TextStyle(color: Palette.body, fontSize: 14),
    ),
  );

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_signup) {
        await repo.signUp(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
        );
      } else {
        await repo.signIn(email: _email.text, password: _password.text);
      }
      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to continue: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
