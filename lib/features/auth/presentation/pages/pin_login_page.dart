import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:billing_app/core/theme/app_theme.dart';

class PinLoginPage extends StatefulWidget {
  const PinLoginPage({super.key});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  String _pin = '';
  final int _pinLength = 4;

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'delete') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_pin.length < _pinLength) _pin += key;
      }
    });

    if (_pin.length == _pinLength) {
      // Trigger login
      context.read<AuthBloc>().add(LoginWithPinEvent(_pin));
      // Reset after tiny delay to let user see 4 dots
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _pin = '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is AuthAuthenticated) {
          context.go('/home'); // We'll redefine routes to match the new flow
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
              const Text(
                'Entrez votre code PIN',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Admin (Défaut) : 0000', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 48),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  final isFilled = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppTheme.primaryColor : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 64),
              // Numpad
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
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
                      if (index == 9) return const SizedBox(); // Empty bottom left
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
      onTap: () => _onKeyPressed(label),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 28, color: Colors.black87)
              : Text(
                  label,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
