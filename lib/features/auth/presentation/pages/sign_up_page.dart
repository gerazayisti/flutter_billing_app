import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/cloud/supabase_auth_service.dart';

import '../bloc/auth_bloc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameCtrl      = TextEditingController();
  final _shopCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _obscure        = true;
  bool _isLoading      = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shopCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;

    final name  = _nameCtrl.text.trim();
    final shop  = _shopCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pw    = _passwordCtrl.text;
    final conf  = _confirmCtrl.text;

    if (name.isEmpty || shop.isEmpty || email.isEmpty || pw.isEmpty) {
      setState(() => _error = l10n.requiredFields);
      return;
    }
    if (pw != conf) {
      setState(() => _error = l10n.passwordMismatch);
      return;
    }
    if (pw.length < 6) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final authService = context.read<SupabaseAuthService>();
    final errorMsg = await authService.initiateSignUp(
      email:     email,
      password:  pw,
    );

    if (!mounted) return;

    if (errorMsg != null) {
      setState(() { _isLoading = false; _error = errorMsg; });
      return;
    }

    setState(() { _isLoading = false; });

    // Navigate to OTP verification page
    context.push(
      '/verify-otp',
      extra: {
        'email': email,
        'ownerName': name,
        'shopName': shop,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go('/owner-dashboard');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF09090E),
        body: Stack(
          children: [
            // ── Background Image ─────────────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/onboarding_bg_2.png',
                fit: BoxFit.cover,
              ),
            ),
            // ── Overlay sombre 15% ───────────────────────────────────────────
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
            // ── Dégradé immersif transparent -> noir ─────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.35, 0.70, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xDD09090E),
                      Color(0xFF09090E),
                    ],
                  ),
                ),
              ),
            ),
            // ── Header / Back Button ──────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            // ── Contenu principal ────────────────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.createBoutique,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          l10n.ownerInfo,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _field(_nameCtrl, l10n.ownerName,
                            Icons.person_outline, TextInputType.name),
                        const SizedBox(height: 12),

                        _field(_emailCtrl, l10n.emailAddress,
                            Icons.email_outlined, TextInputType.emailAddress),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: false,
                            labelText: l10n.password,
                            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.6)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.6)),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _confirmCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: false,
                            labelText: l10n.confirmPassword,
                            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.6)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Divider(color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),

                        Text(
                          l10n.boutiqueInfo,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _field(_shopCtrl, l10n.shopName,
                            Icons.store_outlined, TextInputType.text),

                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : Text(
                                  l10n.createBoutique,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: false,
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}
