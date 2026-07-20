import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PinLoginPage extends StatefulWidget {
  const PinLoginPage({super.key});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  final List<String> _pin = [];
  String _error = '';

  void _onKeyPress(String val) {
    setState(() {
      _error = '';
      if (_pin.length < 4) {
        _pin.add(val);
      }

      if (_pin.length == 4) {
        _verifyPin();
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_pin.isNotEmpty) {
        _pin.removeLast();
      }
    });
  }

  void _verifyPin() {
    final s = HiveDatabase.settingsBox;
    final savedPin = s.get('user_pin', defaultValue: '') as String;

    if (_pin.join() == savedPin) {
      // PIN Correct! Mettre à jour la date d'activité
      s.put('last_active_time', DateTime.now().toIso8601String());

      // Rediriger vers l'accueil ou le dashboard selon le rôle
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
      // Erreur, réinitialiser
      setState(() {
        _pin.clear();
        _error = 'Code PIN incorrect. Réessayez.';
      });
    }
  }

  Future<void> _switchToEmail() async {
    // Déconnecter Supabase pour forcer une nouvelle connexion propre par email
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    // Effacer le PIN actuel
    final s = HiveDatabase.settingsBox;
    s.delete('user_pin');
    s.delete('last_active_time');

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
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

                const Text(
                  'Saisissez votre code PIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Indicateurs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _pin.length;
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

                _buildKeyboard(),
                const SizedBox(height: 20),

                // Bouton Switch compte / Connexion email
                TextButton(
                  onPressed: _switchToEmail,
                  child: const Text(
                    'Se connecter avec un autre compte',
                    style: TextStyle(color: Colors.white54, fontSize: 13, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 20),
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
              const SizedBox(width: 70, height: 70),
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
