import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:billing_app/features/auth/presentation/bloc/user_management_bloc.dart';
import 'package:billing_app/features/auth/data/models/user_model.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:billing_app/core/widgets/input_label.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = state.users[index];
              return _buildUserCard(context, user);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Nouveau Caissier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucun utilisateur trouvé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ajoutez votre premier caissier pour commencer.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final isAdmin = user.role == Role.admin;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAdmin ? Colors.amber[50] : Colors.blue[50],
          child: Icon(
            isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
            color: isAdmin ? Colors.amber[700] : Colors.blue[700],
          ),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isAdmin ? 'Administrateur' : 'Caissier', 
          style: TextStyle(color: isAdmin ? Colors.amber[800] : Colors.blue[800], fontSize: 12)),
        trailing: isAdmin 
          ? null // Prevent deleting admin from this UI for safety
          : IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () => _confirmDelete(context, user),
            ),
      ),
    );
  }

  void _showUserForm(BuildContext context, [UserModel? user]) {
    final bloc = context.read<UserManagementBloc>();
    final nameController = TextEditingController(text: user?.name);
    final pinController = TextEditingController(text: user?.pinCode);
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
                const Text('Nouveau Caissier', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const InputLabel(text: 'Nom Complet'),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Ex: Jean Dupont'),
                ),
                const SizedBox(height: 16),
                const InputLabel(text: 'Code PIN (4 chiffres)'),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(hintText: '0000'),
                ),
                const SizedBox(height: 16),
                const InputLabel(text: 'Rôle'),
                DropdownButtonFormField<Role>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: Role.admin, child: Text('Administrateur')),
                    DropdownMenuItem(value: Role.cashier, child: Text('Caissier')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedRole = val);
                  },
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && pinController.text.length == 4) {
                      final newUser = UserModel(
                        id: user?.id ?? const Uuid().v4(),
                        name: nameController.text,
                        pinCode: pinController.text,
                        role: selectedRole,
                      );
                      bloc.add(AddUserEvent(newUser));
                      Navigator.pop(context);
                    }
                  },
                  label: user == null ? 'Créer le compte' : 'Mettre à jour',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    final bloc = context.read<UserManagementBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Voulez-vous vraiment supprimer ${user.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              bloc.add(DeleteUserEvent(user.id));
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
