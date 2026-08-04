import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/features/auth/data/models/user_model.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart' as app;
import 'package:billing_app/core/services/error_logger_service.dart';

/// Result returned after sign-in or sign-up.
class AuthResult {
  final bool success;
  final app.User? user;
  final String? shopId;
  final Map<String, dynamic>? shopData;
  final String? error;

  const AuthResult.ok({required this.user, required this.shopId, required this.shopData})
      : success = true, error = null;
  const AuthResult.fail(this.error)
      : success = false, user = null, shopId = null, shopData = null;
}

class SupabaseAuthService {
  SupabaseClient get _client => Supabase.instance.client;

  SupabaseAuthService();

  // ── State ─────────────────────────────────────────────────

  bool get isSignedIn => _client.auth.currentUser != null;
  String? get currentUserId => _client.auth.currentUser?.id;

  // ── Sign in ───────────────────────────────────────────────

  Future<AuthResult> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) return const AuthResult.fail('Connexion échouée');
      return _loadMembership(res.user!.id);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return const AuthResult.fail('Email ou mot de passe incorrect.');
      }
      _logAuthError(e.toString(), email, 'Sign In (AuthException)');
      return const AuthResult.fail(
          'Une erreur s\'est produite. Veuillez vérifier votre connexion et réessayer plus tard.');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') || msg.contains('network') ||
          msg.contains('connection') || msg.contains('timeout')) {
        return const AuthResult.fail(
            'Pas de connexion Internet.\nConnectez-vous une première fois avec le réseau, puis l\'app fonctionnera hors ligne.');
      }
      _logAuthError(e.toString(), email, 'Sign In (Generic Catch)');
      return const AuthResult.fail(
          'Une erreur s\'est produite. Veuillez vérifier votre connexion et réessayer plus tard.');
    }
  }

  void _logAuthError(String error, String email, String action) {
    ErrorLoggerService.sendErrorLog(
      error: error,
      userEmail: email,
      action: action,
    );
  }

  // ── Sign up (owner creates a new boutique via OTP verification) ────

  /// Step 1: Register the user with Supabase. This triggers Supabase to send a 6-digit OTP code to their email.
  Future<String?> initiateSignUp({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user == null) return 'Inscription échouée';
      return null; // Success, no error
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('user already exists')) {
        return 'Cette adresse e-mail est déjà utilisée.';
      }
      _logAuthError(e.toString(), email, 'Initiate Sign Up (AuthException)');
      return 'Une erreur s\'est produite. Veuillez vérifier votre connexion et réessayer plus tard.';
    } catch (e) {
      _logAuthError(e.toString(), email, 'Initiate Sign Up (Generic Catch)');
      return 'Une erreur s\'est produite. Veuillez vérifier votre connexion et réessayer plus tard.';
    }
  }

  /// Step 2: Verify the 6-digit OTP code.
  /// If valid, creates the boutique (shops) and adds the owner to shop_members.
  Future<AuthResult> verifyOtpAndCreateShop({
    required String email,
    required String token,
    required String ownerName,
    required String shopName,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );

      if (res.user == null) {
        return const AuthResult.fail('Code OTP incorrect ou expiré.');
      }

      final uid = res.user!.id;

      // Create boutique
      final shopRow = await _client.from('shops').insert({
        'owner_uid': uid,
        'name': shopName,
      }).select().single();

      final shopId = shopRow['id'] as String;

      // Add owner to shop_members
      await _client.from('shop_members').insert({
        'shop_id': shopId,
        'user_id': uid,
        'role':    'owner',
        'name':    ownerName,
        'email':   email,
      });

      // Créer automatiquement la ligne d'essai (30 jours) dans la BD Supabase 'subscriptions'
      try {
        final now = DateTime.now();
        final expiry = now.add(const Duration(days: 30));
        await _client.from('subscriptions').upsert({
          'shop_id': shopId,
          'tier': 'pro',
          'billing_cycle': 'trial',
          'status': 'active',
          'start_date': now.toIso8601String(),
          'expiry_date': expiry.toIso8601String(),
          'freemopay_reference': 'TRIAL_30_DAYS',
          'updated_at': now.toIso8601String(),
        }, onConflict: 'shop_id');
      } catch (_) {}

      final user = app.User(
        id: uid, name: ownerName, email: email,
        role: app.Role.owner, shopId: shopId,
      );

      _cacheUser(user);

      return AuthResult.ok(
        user: user,
        shopId: shopId,
        shopData: shopRow,
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid flow state') || msg.contains('otp') || msg.contains('token')) {
        return const AuthResult.fail('Code OTP incorrect ou expiré.');
      }
      _logAuthError(e.toString(), email, 'Verify OTP & Create Shop (AuthException)');
      return const AuthResult.fail(
          'Une erreur s\'est produite. Veuillez vérifier votre connexion et réessayer plus tard.');
    } catch (e) {
      _logAuthError(e.toString(), email, 'Verify OTP & Create Shop (Generic Catch)');
      return const AuthResult.fail(
          'Une erreur s\'est produite. Veuillez vérifier votre connexion et réessayer plus tard.');
    }
  }

  /// Resends the signup OTP to the specified email.
  Future<String?> resendOtp(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return null;
    } on AuthException catch (e) {
      _logAuthError(e.toString(), email, 'Resend OTP (AuthException)');
      return 'Une erreur s\'est produite. Veuillez vérifier votre connexion et réessayer plus tard.';
    } catch (e) {
      _logAuthError(e.toString(), email, 'Resend OTP (Generic Catch)');
      return 'Une erreur s\'est produite. Veuillez vérifier votre connexion et réessayer plus tard.';
    }
  }

  // ── Sign out ──────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  // ── Check existing session (called at app start) ──────────

  Future<AuthResult?> restoreSession() async {
    final session = _client.auth.currentSession;
    if (session == null || session.isExpired) return null;
    try {
      return await _loadMembership(session.user.id);
    } catch (_) {
      // Offline fallback: use the user cached in Hive from the last successful login.
      return _loadCachedAuth(session.user.id);
    }
  }

  // ── Employee management (via Edge Function manage-employee) ──

  Future<String?> createEmployee({
    required String shopId,
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _client.functions.invoke(
        'manage-employee',
        body: {
          'action':   'create',
          'shop_id':  shopId,
          'name':     name,
          'email':    email,
          'password': password,
          'role':     role,
        },
      );
      return null;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map) return details['error'] as String? ?? 'Erreur création employé';
      return 'Erreur création employé';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteEmployee(String userId, String shopId) async {
    try {
      await _client.functions.invoke(
        'manage-employee',
        body: {
          'action':  'delete',
          'shop_id': shopId,
          'user_id': userId,
        },
      );
      return null;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map) return details['error'] as String? ?? 'Erreur suppression employé';
      return 'Erreur suppression employé';
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getShopMembers(String shopId) async {
    try {
      final rows = await _client
          .from('shop_members')
          .select()
          .eq('shop_id', shopId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  // ── Owner's boutiques (for multi-shop selector) ───────────

  Future<List<Map<String, dynamic>>> getOwnerShops() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client.from('shops').select().eq('owner_uid', uid).order('created_at'),
      );
    } catch (_) {
      return [];
    }
  }

  Future<String?> createShop(String ownerUid, String shopName) async {
    try {
      final row = await _client.from('shops').insert({
        'owner_uid': ownerUid,
        'name': shopName,
      }).select().single();

      final shopId = row['id'] as String;

      await _client.from('shop_members').insert({
        'shop_id': shopId,
        'user_id': ownerUid,
        'role':    'owner',
        'name':    _client.auth.currentUser?.email ?? '',
        'email':   _client.auth.currentUser?.email ?? '',
      });

      return shopId;
    } catch (_) {
      return null;
    }
  }

  // ── Update shop info (syncs settings to Supabase) ─────────

  Future<void> updateShop(String shopId, Map<String, dynamic> data) async {
    try {
      await _client.from('shops').update(data).eq('id', shopId);
    } catch (_) {}
  }

  // ── Private ───────────────────────────────────────────────

  Future<AuthResult> _loadMembership(String uid) async {
    final rows = await _client
        .from('shop_members')
        .select('*, shops(*)')
        .eq('user_id', uid)
        .order('created_at');

    if (rows.isEmpty) {
      return const AuthResult.fail('Aucune boutique associée à ce compte.\nContactez le propriétaire.');
    }

    final m = rows.first;
    final shopMap = m['shops'] as Map<String, dynamic>;
    final shopId = m['shop_id'] as String;

    final user = app.User(
      id:     uid,
      name:   m['name'] as String? ?? '',
      email:  m['email'] as String? ?? '',
      role:   app.Role.fromString(m['role'] as String),
      shopId: shopId,
    );

    _cacheUser(user); // persist for offline restore
    return AuthResult.ok(user: user, shopId: shopId, shopData: shopMap);
  }

  /// Saves the authenticated user to Hive so the app can start offline
  /// on subsequent launches (as long as the Supabase session is still valid).
  void _cacheUser(app.User user) {
    try {
      final model = UserModel(
        id:     user.id,
        name:   user.name,
        email:  user.email,
        role:   user.role,
        shopId: user.shopId,
      );
      HiveDatabase.usersBox.put(user.id, model);
    } catch (_) {}
  }

  /// Rebuilds an [AuthResult] from the Hive-cached user + shop data.
  /// Used when the device is offline and the Supabase session is still valid.
  AuthResult? _loadCachedAuth(String uid) {
    final cached = HiveDatabase.usersBox.get(uid);
    if (cached == null) return null;

    final shopId = cached.shopId;

    // Rebuild shopData from cached ShopModel so AuthBloc._syncShopToHive
    // doesn't overwrite local data with empty strings.
    final shop = HiveDatabase.shopBox.values.isNotEmpty
        ? HiveDatabase.shopBox.values.first
        : null;
    final shopData = shop != null
        ? {
            'id':             shopId,
            'name':           shop.name,
            'address1':       shop.addressLine1,
            'address2':       shop.addressLine2,
            'phone':          shop.phoneNumber,
            'receipt_footer': shop.footerText,
            'orange_merchant': shop.orangeMoneyMerchant,
            'mtn_merchant':   shop.mtnMomoMerchant,
            'city':           shop.city,
            'district':       shop.district,
            'shop_type':      shop.shopType,
            'tax_id':         shop.taxId,
          }
        : <String, dynamic>{};

    return AuthResult.ok(
      user:     cached,
      shopId:   shopId,
      shopData: shopData,
    );
  }
}
