import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/features/auth/presentation/bloc/user_management_bloc.dart';
import 'package:billing_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/theme/app_color_config.dart';

import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:billing_app/core/widgets/input_label.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(l10n.userManagement,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          if (state.status == UserMgmtStatus.loading &&
              state.members.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.members.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: state.members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildMemberCard(context, state.members[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddForm(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text(l10n.newUserBtn,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(l10n.noUsersFound,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.addUserHint, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
      BuildContext context, Map<String, dynamic> member) {
    final l10n = AppLocalizations.of(context)!;
    final role = Role.fromString(member['role'] as String? ?? 'cashier');
    final isOwner = role == Role.owner;
    final name = member['name'] as String? ?? '';
    final email = member['email'] as String? ?? '';
    final userId = member['user_id'] as String? ?? '';

    final (color, icon, label) = switch (role) {
      Role.owner =>
        (AppTheme.primaryColor, Icons.admin_panel_settings_rounded, l10n.owner),
      Role.stockManager =>
        (AppTheme.primaryDark, Icons.inventory_2_rounded, l10n.stockManager),
      Role.cashier =>
        (AppTheme.textPrimary, Icons.point_of_sale_rounded, l10n.cashier),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            if (email.isNotEmpty)
              Text(email,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 11)),
          ],
        ),
        trailing: isOwner
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.errorColor),
                onPressed: () =>
                    _confirmDelete(context, userId, name),
              ),
      ),
    );
  }

  void _showAddForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<UserManagementBloc>();
    final authState = context.read<AuthBloc>().state;
    final shopId =
        authState is AuthAuthenticated ? authState.shopId : '';

    final nameCtrl     = TextEditingController();
    final emailCtrl    = TextEditingController();
    final passwordCtrl = TextEditingController();
    Role selectedRole  = Role.cashier;
    bool obscure       = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_rounded),
                    const SizedBox(width: 8),
                    Text(l10n.newUserBtn,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),

                InputLabel(text: l10n.fullName),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      hintText: 'Ex: Jean Kamga'),
                ),
                const SizedBox(height: 16),

                InputLabel(text: l10n.employeeEmail),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      hintText: 'employe@email.com'),
                ),
                const SizedBox(height: 16),

                InputLabel(text: l10n.tempPassword),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: '••••••',
                    suffixIcon: IconButton(
                      icon: Icon(obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                InputLabel(text: l10n.role),
                DropdownButtonFormField<Role>(
                  value: selectedRole,
                  items: [
                    DropdownMenuItem(
                        value: Role.cashier,
                        child: _roleDropdownItem(
                            Icons.point_of_sale_rounded,
                            l10n.cashier,
                            AppTheme.textPrimary)),
                    DropdownMenuItem(
                        value: Role.stockManager,
                        child: _roleDropdownItem(
                            Icons.inventory_2_rounded,
                            l10n.stockManager,
                            AppTheme.primaryDark)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedRole = val);
                    }
                  },
                  decoration: const InputDecoration(),
                ),

                const SizedBox(height: 12),
                _buildPermissionsHint(sheetCtx, selectedRole),
                const SizedBox(height: 32),

                // Error from bloc
                BlocBuilder<UserManagementBloc, UserManagementState>(
                  bloc: bloc,
                  builder: (_, s) {
                    if (s.status == UserMgmtStatus.error &&
                        s.message != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(s.message!,
                              style: const TextStyle(
                                  color: AppTheme.errorColor, fontSize: 13)),
                        ),
                      );
                    }
                    if (s.status == UserMgmtStatus.loading) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Center(
                            child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                PrimaryButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final pw = passwordCtrl.text;
                    if (name.isEmpty || email.isEmpty || pw.isEmpty) {
                      return;
                    }
                    bloc.add(AddEmployeeEvent(
                      shopId:   shopId,
                      name:     name,
                      email:    email,
                      password: pw,
                      role:     selectedRole.value,
                    ));
                    Navigator.pop(sheetCtx);
                  },
                  label: l10n.createEmployee,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleDropdownItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildPermissionsHint(BuildContext context, Role role) {
    final l10n = AppLocalizations.of(context)!;
    final items = switch (role) {
      Role.cashier      => ['POS / ${l10n.pos}', l10n.history],
      Role.stockManager => [l10n.inventory, l10n.stockMovements],
      Role.owner        => ['Tout'],
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accès autorisés :',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...items.map((item) => Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 14, color: AppColorConfig.accentColor),
                  const SizedBox(width: 6),
                  Text(item, style: const TextStyle(fontSize: 12)),
                ],
              )),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String userId, String name) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<UserManagementBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(l10n.deleteEmployeeConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              bloc.add(DeleteEmployeeEvent(userId));
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete,
                style: const TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
