import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/data/hive_database.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _isConfirming = false;
  String _error = '';

  void _onKeyPress(String val) {
    setState(() {
      _error = '';
      final target = _isConfirming ? _confirmPin : _pin;
      if (target.length < 4) {
        target.add(val);
      }

      if (target.length == 4) {
        if (!_isConfirming) {
          // Passer à la confirmation
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() {
              _isConfirming = true;
            });
          });
        } else {
          // Valider la confirmation
          _validateAndSave();
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      final target = _isConfirming ? _confirmPin : _pin;
      if (target.isNotEmpty) {
        target.removeLast();
      }
    });
  }

  void _validateAndSave() {
    final pinStr = _pin.join();
    final confirmStr = _confirmPin.join();

    if (pinStr == confirmStr) {
      // Sauvegarder le PIN et la date d'activité
      final s = HiveDatabase.settingsBox;
      s.put('user_pin', pinStr);
      s.put('last_active_time', DateTime.now().toIso8601String());

      // Aller à la page d'accueil ou dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Code PIN configuré avec succès.'),
          backgroundColor: Colors.green,
        ),
      );

      final userModel = HiveDatabase.usersBox.values.isNotEmpty
          ? HiveDatabase.usersBox.values.first
          : null;

      if (userModel != null) {
        if (userModel.role.name.toLowerCase() == 'owner') {
          context.go('/owner-dashboard');
        } else if (userModel.role.name.toLowerCase() == 'stockmanager') {
          context.go('/stock-manager-dashboard');
        } else {
          context.go('/home');
        }
      } else {
        context.go('/home');
      }
    } else {
      // Erreur, réinitialiser la confirmation
      setState(() {
        _confirmPin.clear();
        _error = 'Les codes PIN ne correspondent pas. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: const Color(0xFF09090E),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/onboarding_bg_1.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.65)),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo / Titre
                const Text(
                  'GESTOCK+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const Spacer(),

                // Instructions
                Text(
                  _isConfirming ? 'Confirmez votre code PIN' : 'Créez votre code PIN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Ce code à 4 chiffres sécurise votre application et permet une connexion rapide.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 30),

                // Ronds indicateurs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < target.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppTheme.primaryColor : Colors.white12,
                        border: Border.all(
                          color: isFilled ? AppTheme.primaryColor : Colors.white30,
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),
                if (_error.isNotEmpty)
                  Text(
                    _error,
                    style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                  ),

                const Spacer(),

                // Pavé numérique
                _buildKeyboard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['1', '2', '3'].map((n) => _buildKey(n)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['4', '5', '6'].map((n) => _buildKey(n)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['7', '8', '9'].map((n) => _buildKey(n)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 70, height: 70), // Espace vide
              _buildKey('0'),
              _buildBackspaceKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String number) {
    return InkWell(
      onTap: () => _onKeyPress(number),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        child: const Center(
          child: Icon(Icons.backspace_outlined, color: Colors.white70, size: 24),
        ),
      ),
    );
  }
}
