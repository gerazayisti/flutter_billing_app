import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/features/auth/presentation/bloc/user_management_bloc.dart';
import 'package:billing_app/features/auth/data/models/user_model.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/utils/pin_hasher.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userManagement,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          if (state.status == UserManagementStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.users.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: state.users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildUserCard(context, state.users[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text(l10n.newUserBtn,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.addUserHint, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context)!;
    final isOwner = user.role == Role.owner;

    final (color, icon, label) = switch (user.role) {
      Role.owner => (Colors.amber, Icons.admin_panel_settings_rounded, l10n.owner),
      Role.stockManager => (Colors.green, Icons.inventory_2_rounded, l10n.stockManager),
      Role.cashier => (Colors.blue, Icons.point_of_sale_rounded, l10n.cashier),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        trailing: isOwner
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: () => _confirmDelete(context, user),
              ),
      ),
    );
  }

  void _showUserForm(BuildContext context, [UserModel? user]) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<UserManagementBloc>();
    final nameController = TextEditingController(text: user?.name);
    final pinController = TextEditingController();
    Role selectedRole = user?.role ?? Role.cashier;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                    Text(
                      user == null ? l10n.newUserBtn : l10n.edit,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                InputLabel(text: l10n.fullName),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Ex: Jean Kamga'),
                ),
                const SizedBox(height: 16),

                InputLabel(text: l10n.pinCode),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: user == null ? '4 chiffres' : 'Laisser vide pour ne pas changer',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),

                InputLabel(text: l10n.role),
                DropdownButtonFormField<Role>(
                  value: selectedRole,
                  items: [
                    DropdownMenuItem(
                        value: Role.cashier,
                        child: _roleDropdownItem(Icons.point_of_sale_rounded,
                            l10n.cashier, Colors.blue)),
                    DropdownMenuItem(
                        value: Role.stockManager,
                        child: _roleDropdownItem(Icons.inventory_2_rounded,
                            l10n.stockManager, Colors.green)),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedRole = val);
                  },
                  decoration: const InputDecoration(),
                ),

                // Role permissions hint
                const SizedBox(height: 12),
                _buildPermissionsHint(context, selectedRole),

                const SizedBox(height: 32),
                PrimaryButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final pin = pinController.text.trim();

                    if (name.isEmpty) return;
                    if (user == null && pin.length != 4) return;
                    if (pin.isNotEmpty && pin.length != 4) return;

                    final newPin = pin.isNotEmpty
                        ? PinHasher.hash(pin)
                        : (user?.pinCode ?? PinHasher.hash('0000'));

                    final newUser = UserModel(
                      id: user?.id ?? const Uuid().v4(),
                      name: name,
                      pinCode: newPin,
                      role: selectedRole,
                    );
                    bloc.add(AddUserEvent(newUser));
                    Navigator.pop(context);
                  },
                  label: user == null ? l10n.createAccount : l10n.updateAccount,
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
      Role.cashier => ['POS / Ventes', l10n.history],
      Role.stockManager => [l10n.inventory, 'Réceptions stock'],
      Role.owner => ['Tout'],
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
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...items.map((item) => Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(item, style: const TextStyle(fontSize: 12)),
                ],
              )),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<UserManagementBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text('${l10n.deleteConfirm} ${user.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              bloc.add(DeleteUserEvent(user.id));
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
