import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_settings/app_settings.dart';
import 'package:billing_app/l10n/app_localizations.dart';

import '../../../../core/data/hive_database.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/printer_bloc.dart';
import '../bloc/printer_event.dart';
import '../bloc/printer_state.dart';
import '../bloc/locale_bloc.dart';
import '../../../../core/utils/backup_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PrinterBloc>().add(InitPrinterEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.role == Role.owner;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: BlocBuilder<ShopBloc, ShopState>(
                builder: (context, state) {
                  String shopName = 'Elite Groceries';
                  String initials = 'EG';
                  if (state is ShopLoaded && state.shop.name.isNotEmpty) {
                    shopName = state.shop.name;
                    final parts = shopName.split(' ');
                    initials = parts
                        .take(2)
                        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
                        .join('');
                    if (initials.isEmpty) initials = 'S';
                  }

                  return Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 5,
                              )
                            ]),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1)),
                      ),
                      const SizedBox(height: 16),
                      Text(shopName.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Management Section
            _buildSectionHeader(l10n.userManagement),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.qr_code_scanner,
                  title: l10n.inventory,
                  subtitle: l10n.tapToOpenScanner,
                  onTap: () => context.push('/products'),
                ),
                if (isAdmin) ...[
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.people_outline_rounded,
                    title: l10n.userManagement,
                    subtitle: l10n.newUser,
                    onTap: () => context.push('/users'),
                  ),
                ],
                _buildDivider(),
                _buildListItem(
                  icon: Icons.storefront,
                  title: l10n.shopInfo,
                  subtitle: '',
                  onTap: () => context.push('/shop'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Hardware Section
            _buildSectionHeader(l10n.hardware),
            BlocConsumer<PrinterBloc, PrinterState>(
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: Colors.red));
                } else if (state.status == PrinterStatus.connected) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.connected),
                      backgroundColor: Colors.green));
                }
              },
              builder: (context, state) {
                return _buildListGroup(
                  children: [
                    _buildListItem(
                      icon: Icons.print,
                      title: l10n.printer,
                      subtitleWidget: Row(
                        children: [
                          Text(
                            state.connectedMac != null
                                ? (state.connectedName ?? l10n.connected)
                                : l10n.disconnected,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                          if (state.connectedMac != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.teal[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.teal[200]!)),
                              child: Text(
                                l10n.connected.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[700]),
                              ),
                            ),
                          ]
                        ],
                      ),
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.status == PrinterStatus.scanning ||
                              state.status == PrinterStatus.connecting)
                            const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () => context
                                  .read<PrinterBloc>()
                                  .add(RefreshPrinterEvent()),
                              color: AppTheme.primaryColor,
                            ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              AppSettings.openAppSettings(
                                  type: AppSettingsType.bluetooth);
                            },
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Language Section
            _buildSectionHeader(l10n.language),
            BlocBuilder<LocaleBloc, LocaleState>(
              builder: (context, state) {
                return _buildListGroup(
                  children: [
                    _buildListItem(
                      icon: Icons.language,
                      title: l10n.language,
                      subtitle: state.locale.languageCode == 'fr' ? l10n.french : l10n.english,
                      trailingWidget: PopupMenuButton<Locale>(
                        icon: const Icon(Icons.chevron_right, color: Colors.grey),
                        onSelected: (Locale locale) {
                          context.read<LocaleBloc>().add(ChangeLocaleEvent(locale));
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: const Locale('fr'),
                            child: Text(l10n.french),
                          ),
                          PopupMenuItem(
                            value: const Locale('en'),
                            child: Text(l10n.english),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            if (isAdmin) ...[
              const SizedBox(height: 24),
              // Data & Backup Section
              _buildSectionHeader(l10n.backup),
              _buildListGroup(
                children: [
                  _buildListItem(
                    icon: Icons.upload_file,
                    title: l10n.exportJson,
                    subtitle: '',
                    trailingIcon: Icons.share,
                    onTap: () {
                      BackupService.exportData(context);
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.download_rounded,
                    title: l10n.importJson,
                    subtitle: '',
                    trailingIcon: Icons.warning_amber_rounded,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text(l10n.warning),
                          content: Text(l10n.overwriteWarning),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () {
                                Navigator.pop(c);
                                BackupService.importData(context);
                              }, 
                              child: Text(l10n.confirm)
                            ),
                          ],
                        )
                      );
                    },
                  ),
                ],
              ),
            ],

            if (isAdmin) ...[
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.mtnApiConfig),
              _MtnApiConfigSection(),
            ],

            const SizedBox(height: 24),

            // Appearance Section
            _buildSectionHeader(l10n.appearance),
            _ColorPickerSection(
              onColorChanged: () => setState(() {}),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildListGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[50], indent: 64);
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailingWidget,
    IconData? trailingIcon = Icons.chevron_right,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 4),
                    subtitleWidget,
                  ]
                ],
              ),
            ),
            if (trailingWidget != null)
              trailingWidget
            else if (trailingIcon != null)
              Icon(trailingIcon, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}

class _MtnApiConfigSection extends StatefulWidget {
  @override
  State<_MtnApiConfigSection> createState() => _MtnApiConfigSectionState();
}

class _MtnApiConfigSectionState extends State<_MtnApiConfigSection> {
  late TextEditingController _subKeyCtrl;
  late TextEditingController _userIdCtrl;
  late TextEditingController _apiKeyCtrl;
  bool _isSandbox = true;

  @override
  void initState() {
    super.initState();
    final s = HiveDatabase.settingsBox;
    _subKeyCtrl = TextEditingController(
        text: s.get('mtn_subscription_key', defaultValue: '') as String);
    _userIdCtrl = TextEditingController(
        text: s.get('mtn_api_user', defaultValue: '') as String);
    _apiKeyCtrl = TextEditingController(
        text: s.get('mtn_api_key', defaultValue: '') as String);
    _isSandbox =
        (s.get('mtn_target_env', defaultValue: 'sandbox') as String) == 'sandbox';
  }

  @override
  void dispose() {
    _subKeyCtrl.dispose();
    _userIdCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.yellow[700]!.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.api_rounded, color: Colors.yellow[800], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.mtnApiConfig,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subKeyCtrl,
            decoration: InputDecoration(
              labelText: l10n.subscriptionKeyLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userIdCtrl,
            decoration: InputDecoration(
              labelText: l10n.apiUserIdLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.apiKeyLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(l10n.targetEnvironment,
                    style: const TextStyle(fontSize: 13)),
              ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l10n.sandboxMode)),
                  ButtonSegment(value: false, label: Text(l10n.productionMode)),
                ],
                selected: {_isSandbox},
                onSelectionChanged: (v) => setState(() => _isSandbox = v.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final s = HiveDatabase.settingsBox;
              await s.put('mtn_subscription_key', _subKeyCtrl.text.trim());
              await s.put('mtn_api_user', _userIdCtrl.text.trim());
              await s.put('mtn_api_key', _apiKeyCtrl.text.trim());
              await s.put(
                  'mtn_target_env', _isSandbox ? 'sandbox' : 'production');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.apiConfigSaved),
                  backgroundColor: Colors.green,
                ));
              }
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(l10n.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerSection extends StatefulWidget {
  final VoidCallback onColorChanged;
  const _ColorPickerSection({required this.onColorChanged});

  @override
  State<_ColorPickerSection> createState() => _ColorPickerSectionState();
}

class _ColorPickerSectionState extends State<_ColorPickerSection> {
  Color _selected = AppColorConfig.accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selected.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.palette_outlined,
                    color: _selected, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.themeColor,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(l10n.selectAccentColor,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppColorConfig.palette.map((color) {
              final isSelected = _selected.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () async {
                  await AppColorConfig.setAccentColor(color);
                  setState(() => _selected = color);
                  widget.onColorChanged();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: isSelected ? 0.5 : 0.2),
                        blurRadius: isSelected ? 8 : 4,
                        spreadRadius: isSelected ? 2 : 0,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
