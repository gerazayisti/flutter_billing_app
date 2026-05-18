import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/theme/app_color_config.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:billing_app/core/cloud/supabase_auth_service.dart';
import 'package:billing_app/features/auth/presentation/bloc/auth_bloc.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String ownerName;
  final String shopName;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.ownerName,
    required this.shopName,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());
  
  bool _isLoading = false;
  String? _error;
  
  // Timer for resend code countdown
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;
    setState(() {
      _error = null;
    });
    final authService = context.read<SupabaseAuthService>();
    final errorMsg = await authService.resendOtp(widget.email);
    if (!mounted) return;

    if (errorMsg != null) {
      setState(() {
        _error = errorMsg;
      });
    } else {
      _startTimer();
      final isEn = Localizations.localeOf(context).languageCode == 'en';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'OTP code resent successfully.' : 'Code OTP renvoyé avec succès.'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final token = _controllers.map((c) => c.text.trim()).join();
    if (token.length < 8) {
      setState(() {
        _error = 'Veuillez saisir le code complet à 8 chiffres.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authService = context.read<SupabaseAuthService>();
    final result = await authService.verifyOtpAndCreateShop(
      email: widget.email,
      token: token,
      ownerName: widget.ownerName,
      shopName: widget.shopName,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _isLoading = false;
        _error = result.error ?? 'Une erreur est survenue lors de la vérification.';
      });
      return;
    }

    // Trigger AuthBloc to emit Authenticated state
    context.read<AuthBloc>().add(SignUpSuccessEvent(
      user: result.user!,
      shopId: result.shopId!,
      shopData: result.shopData!,
    ));

    // Owner redirigé vers le tableau de bord propriétaire
    context.go('/owner-dashboard');
  }

  void _onKeyChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 7) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _submit();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColorConfig.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Vérification', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: accent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 90,
                        height: 90,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gestock+',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Vérification de l\'e-mail',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                          children: [
                            const TextSpan(text: 'Nous avons envoyé un code de vérification OTP à l\'adresse :\n'),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // OTP Boxes Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(8, (index) {
                          return SizedBox(
                            width: 32,
                            height: 48,
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: accent, width: 2),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) => _onKeyChanged(index, value),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      // Error banner
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Submit button
                      PrimaryButton(
                        onPressed: _isLoading ? null : _submit,
                        label: 'Vérifier et créer ma boutique',
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Countdown & Resend Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _canResend ? 'Vous n\'avez pas reçu de code ? ' : 'Renvoyer le code dans ',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          _canResend
                              ? GestureDetector(
                                  onTap: _resendCode,
                                  child: Text(
                                    'Renvoyer',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                )
                              : Text(
                                  '$_secondsRemaining s',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
