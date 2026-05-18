import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/l10n/app_localizations.dart';

class PinLoginPage extends StatefulWidget {
  const PinLoginPage({super.key});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  String _pin = '';
  final int _pinLength = 4;
  bool _isLocked = false;
  int _lockCountdown = 0;
  Timer? _lockTimer;

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  void _startLockCountdown(DateTime lockoutUntil) {
    _lockTimer?.cancel();
    setState(() {
      _isLocked = true;
      _lockCountdown = lockoutUntil.difference(DateTime.now()).inSeconds;
    });
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        timer.cancel();
        if (mounted) setState(() { _isLocked = false; _lockCountdown = 0; });
      } else {
        if (mounted) setState(() => _lockCountdown = remaining);
      }
    });
  }

  void _onKeyPressed(String key) {
    if (_isLocked) return;
    setState(() {
      if (key == 'delete') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_pin.length < _pinLength) _pin += key;
      }
    });

    if (_pin.length == _pinLength) {
      context.read<AuthBloc>().add(LoginWithPinEvent(_pin));
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _pin = '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          final msg = state.attemptsLeft != null
              ? '${state.message} (${state.attemptsLeft} ${l10n.attemptsLeft})'
              : state.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        } else if (state is AuthLocked) {
          _startLockCountdown(state.lockoutUntil);
        } else if (state is AuthAuthenticated) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              Text(
                l10n.appTitle,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez votre code PIN',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Lock message
              if (_isLocked) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${l10n.pinLocked.split('.').first} ($_lockCountdown s)',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  final isFilled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLocked
                          ? Colors.red[200]
                          : isFilled
                              ? AppTheme.primaryColor
                              : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),

              // Numpad
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index == 9) return const SizedBox();
                      if (index == 11) {
                        return _buildKey('delete', Icons.backspace_outlined);
                      }
                      final keyLabel = index == 10 ? '0' : '${index + 1}';
                      return _buildKey(keyLabel, null);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label, IconData? icon) {
    return InkWell(
      onTap: _isLocked ? null : () => _onKeyPressed(label),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        decoration: BoxDecoration(
          color: _isLocked ? Colors.grey[200] : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 28, color: _isLocked ? Colors.grey[400] : Colors.black87)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: _isLocked ? Colors.grey[400] : Colors.black87,
                  ),
                ),
        ),
      ),
    );
  }
}
