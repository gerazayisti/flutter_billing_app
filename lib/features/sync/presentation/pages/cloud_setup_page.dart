import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/widgets/app_drawer.dart';
import 'package:intl/intl.dart';

import '../bloc/sync_bloc.dart';

class CloudSetupPage extends StatefulWidget {
  const CloudSetupPage({super.key});

  @override
  State<CloudSetupPage> createState() => _CloudSetupPageState();
}

class _CloudSetupPageState extends State<CloudSetupPage> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    context.read<SyncBloc>().add(LoadSyncStatusEvent());
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cloudSync,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: BlocConsumer<SyncBloc, SyncState>(
        listener: (context, state) {
          if (state.successMessage == 'synced') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.syncSuccess),
              backgroundColor: Colors.green,
            ));
          } else if (state.successMessage == 'configured') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.cloudConfigSaved),
              backgroundColor: Colors.green,
            ));
          } else if (state.successMessage == 'signed_in') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.cloudConnected),
              backgroundColor: Colors.green,
            ));
          } else if (state.successMessage == 'pulled') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.syncSuccess),
              backgroundColor: Colors.green,
            ));
          }
          if (state.error != null) {
            final msg = state.error == 'auth_error'
                ? l10n.cloudAuthError
                : '${l10n.syncError}: ${state.error}';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg),
              backgroundColor: Colors.red,
            ));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusCard(state: state, l10n: l10n),
                const SizedBox(height: 16),
                _CredentialsSection(
                  urlCtrl: _urlCtrl,
                  keyCtrl: _keyCtrl,
                  obscureKey: _obscureKey,
                  onToggleKey: () =>
                      setState(() => _obscureKey = !_obscureKey),
                  state: state,
                  l10n: l10n,
                ),
                const SizedBox(height: 16),
                if (state.isConfigured) ...[
                  _AuthSection(
                    emailCtrl: _emailCtrl,
                    passwordCtrl: _passwordCtrl,
                    obscurePassword: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    state: state,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 16),
                  _SyncActionsSection(state: state, l10n: l10n),
                  const SizedBox(height: 16),
                  _SqlSchemaCard(l10n: l10n),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final SyncState state;
  final AppLocalizations l10n;

  const _StatusCard({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isOk = state.isConfigured;
    final color = isOk ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOk ? l10n.cloudConnected : l10n.cloudDisconnected,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15),
                ),
                if (state.userEmail != null)
                  Text(state.userEmail!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                if (state.lastSyncedAt != null)
                  Text(
                    '${l10n.lastSynced}: ${DateFormat('dd/MM/yyyy HH:mm').format(state.lastSyncedAt!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.autoSync,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Switch.adaptive(
                value: state.autoSync,
                onChanged: (_) =>
                    context.read<SyncBloc>().add(ToggleAutoSyncEvent()),
                activeThumbColor: AppTheme.primaryColor,
                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Credentials section ───────────────────────────────────────────────────

class _CredentialsSection extends StatelessWidget {
  final TextEditingController urlCtrl;
  final TextEditingController keyCtrl;
  final bool obscureKey;
  final VoidCallback onToggleKey;
  final SyncState state;
  final AppLocalizations l10n;

  const _CredentialsSection({
    required this.urlCtrl,
    required this.keyCtrl,
    required this.obscureKey,
    required this.onToggleKey,
    required this.state,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded, size: 18, color: Colors.teal),
              const SizedBox(width: 8),
              Text(l10n.setupSupabase,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.supabaseHint,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 14),
          TextField(
            controller: urlCtrl,
            decoration: InputDecoration(
              labelText: l10n.cloudUrl,
              hintText: 'https://xxxx.supabase.co',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: keyCtrl,
            obscureText: obscureKey,
            decoration: InputDecoration(
              labelText: l10n.anonKey,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                    obscureKey ? Icons.visibility_off : Icons.visibility,
                    size: 18),
                onPressed: onToggleKey,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: state.isSyncing
                ? null
                : () {
                    final url = urlCtrl.text.trim();
                    final key = keyCtrl.text.trim();
                    if (url.isEmpty || key.isEmpty) return;
                    context
                        .read<SyncBloc>()
                        .add(ConfigureCloudEvent(url, key));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

// ── Auth section ──────────────────────────────────────────────────────────

class _AuthSection extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggle;
  final SyncState state;
  final AppLocalizations l10n;

  const _AuthSection({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggle,
    required this.state,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user_rounded,
                color: Colors.green, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(state.userEmail ?? '',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600))),
            TextButton(
              onPressed: () =>
                  context.read<SyncBloc>().add(SignOutCloudEvent()),
              child: Text(l10n.signOut,
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 18),
              const SizedBox(width: 8),
              Text(l10n.ownerSignIn,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Text(l10n.ownerSignInHint,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 14),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.ownerEmail,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passwordCtrl,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.ownerPassword,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 18),
                onPressed: onToggle,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: state.isSyncing
                ? null
                : () {
                    final email = emailCtrl.text.trim();
                    final pw = passwordCtrl.text;
                    if (email.isEmpty || pw.isEmpty) return;
                    context
                        .read<SyncBloc>()
                        .add(SignInCloudEvent(email, pw));
                  },
            icon: const Icon(Icons.login_rounded),
            label: Text(l10n.signIn),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sync actions ──────────────────────────────────────────────────────────

class _SyncActionsSection extends StatelessWidget {
  final SyncState state;
  final AppLocalizations l10n;

  const _SyncActionsSection({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.isSyncing
                ? null
                : () => context.read<SyncBloc>().add(SyncNowEvent()),
            icon: state.isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload_rounded),
            label: Text(l10n.syncNow),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: state.isPulling
                ? null
                : () =>
                    context.read<SyncBloc>().add(PullFromCloudEvent()),
            icon: state.isPulling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_download_rounded),
            label: Text(l10n.pullFromCloud),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── SQL schema helper ─────────────────────────────────────────────────────

class _SqlSchemaCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _SqlSchemaCard({required this.l10n});

  static const String _schema = '''CREATE TABLE gestock_sync (
  id          TEXT PRIMARY KEY,
  shop_id     TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  payload     JSONB NOT NULL,
  synced_at   TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE gestock_sync ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_access" ON gestock_sync
  FOR ALL USING (true) WITH CHECK (true);''';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.sqlSchema,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    color: Colors.white54, size: 18),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: _schema));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.copied),
                    duration: const Duration(seconds: 1),
                  ));
                },
              ),
            ],
          ),
          const Text(
            _schema,
            style: TextStyle(
                color: Color(0xFF89DCEB),
                fontSize: 11,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
