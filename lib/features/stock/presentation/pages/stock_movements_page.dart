import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/core/utils/xaf_formatter.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/widgets/app_drawer.dart';
import 'package:billing_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/supplier.dart';
import '../bloc/stock_bloc.dart';

class StockMovementsPage extends StatefulWidget {
  const StockMovementsPage({super.key});

  @override
  State<StockMovementsPage> createState() => _StockMovementsPageState();
}

class _StockMovementsPageState extends State<StockMovementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stockMovements,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(icon: const Icon(Icons.swap_vert_rounded), text: l10n.movementsHistory),
            Tab(icon: const Icon(Icons.business_rounded), text: l10n.suppliers),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddMovementDialog(context, l10n),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addRestock),
            backgroundColor: AppTheme.primaryColor,
          );
        },
      ),
      body: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          return TabBarView(
            controller: _tabs,
            children: [
              _MovementsTab(movements: state.movements, l10n: l10n),
              _SuppliersTab(suppliers: state.suppliers, l10n: l10n),
            ],
          );
        },
      ),
    );
  }

  void _showAddMovementDialog(BuildContext context, AppLocalizations l10n) {
    final products = context.read<ProductBloc>().state.products;
    final authState = context.read<AuthBloc>().state;
    final operatorId =
        authState is AuthAuthenticated ? authState.user.id : 'unknown';
    final suppliers = context.read<StockBloc>().state.suppliers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StockBloc>(),
        child: _AddMovementSheet(
          l10n: l10n,
          products: products,
          suppliers: suppliers,
          operatorId: operatorId,
        ),
      ),
    );
  }
}

// ── Movements tab ─────────────────────────────────────────────────────────

class _MovementsTab extends StatelessWidget {
  final List<StockMovement> movements;
  final AppLocalizations l10n;

  const _MovementsTab({required this.movements, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(l10n.noMovements,
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: movements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _MovementTile(movement: movements[i], l10n: l10n),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovement movement;
  final AppLocalizations l10n;

  const _MovementTile({required this.movement, required this.l10n});

  Color get _typeColor => movement.type.isIn ? Colors.green : Colors.red;
  IconData get _typeIcon => movement.type.isIn
      ? Icons.arrow_downward_rounded
      : Icons.arrow_upward_rounded;

  String _typeName(AppLocalizations l10n) => switch (movement.type) {
        MovementType.saleOut => l10n.moveSaleOut,
        MovementType.manualOut => l10n.moveManualOut,
        MovementType.restockIn => l10n.moveRestockIn,
        MovementType.adjustmentIn => l10n.moveAdjustIn,
        MovementType.adjustmentOut => l10n.moveAdjustOut,
        MovementType.returnIn => l10n.moveReturnIn,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_typeName(l10n),
                          style: TextStyle(
                              fontSize: 11,
                              color: _typeColor,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (movement.supplierName != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('· ${movement.supplierName}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
                if (movement.note != null && movement.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(movement.note!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${movement.type.isIn ? '+' : '−'}${movement.quantity}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _typeColor),
              ),
              Text(
                DateFormat('dd/MM HH:mm').format(movement.date),
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
              if (movement.unitCost != null)
                Text(
                  XafFormatter.format(movement.unitCost!),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Suppliers tab ─────────────────────────────────────────────────────────

class _SuppliersTab extends StatelessWidget {
  final List<Supplier> suppliers;
  final AppLocalizations l10n;

  const _SuppliersTab({required this.suppliers, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: OutlinedButton.icon(
            onPressed: () => _showSupplierDialog(context, null),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addSupplier),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: AppTheme.primaryColor),
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
        Expanded(
          child: suppliers.isEmpty
              ? Center(
                  child: Text(l10n.noMovements,
                      style: TextStyle(color: Colors.grey[500])))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: suppliers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _SupplierTile(supplier: suppliers[i], l10n: l10n),
                ),
        ),
      ],
    );
  }

  void _showSupplierDialog(BuildContext context, Supplier? existing) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<StockBloc>(),
        child: _SupplierDialog(existing: existing, l10n: l10n),
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final Supplier supplier;
  final AppLocalizations l10n;

  const _SupplierTile({required this.supplier, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
        child: Text(supplier.name[0].toUpperCase(),
            style: TextStyle(
                color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
      ),
      title: Text(supplier.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: supplier.phone != null ? Text(supplier.phone!) : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => context
            .read<StockBloc>()
            .add(DeleteSupplierEvent(supplier.id)),
      ),
      onTap: () => showDialog(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<StockBloc>(),
          child: _SupplierDialog(existing: supplier, l10n: l10n),
        ),
      ),
    );
  }
}

// ── Add Movement Bottom Sheet ─────────────────────────────────────────────

class _AddMovementSheet extends StatefulWidget {
  final AppLocalizations l10n;
  final List<Product> products;
  final List<Supplier> suppliers;
  final String operatorId;

  const _AddMovementSheet({
    required this.l10n,
    required this.products,
    required this.suppliers,
    required this.operatorId,
  });

  @override
  State<_AddMovementSheet> createState() => _AddMovementSheetState();
}

class _AddMovementSheetState extends State<_AddMovementSheet> {
  MovementType _type = MovementType.restockIn;
  String? _selectedProductId;
  String _selectedProductName = '';
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  final _qtyCtrl = TextEditingController(text: '1');
  final _costCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final products = widget.products;
    final suppliers = widget.suppliers;
    final operatorId = widget.operatorId;

    final types = [
      MovementType.restockIn,
      MovementType.adjustmentIn,
      MovementType.adjustmentOut,
      MovementType.manualOut,
      MovementType.returnIn,
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(l10n.addRestock,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),

              // Type selector
              Text(l10n.movementType,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((t) {
                  final isIn = t.isIn;
                  final color = isIn ? Colors.green : Colors.red;
                  final isSelected = _type == t;
                  return ChoiceChip(
                    label: Text(_typeLabel(t, l10n)),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12),
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Product selector
              Text(l10n.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                hint: Text(l10n.productName),
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    isDense: true),
                items: products
                    .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (stock: ${p.stock})',
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedProductId = v;
                    _selectedProductName =
                        products.firstWhere((p) => p.id == v).name;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Quantity
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.quantity,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true),
                        ),
                      ],
                    ),
                  ),
                  if (_type == MovementType.restockIn) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.unitCost,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                suffixText: 'FCFA',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                isDense: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Supplier (for restockIn)
              if (_type == MovementType.restockIn && suppliers.isNotEmpty) ...[
                Text(l10n.supplier,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedSupplierId,
                  hint: Text(l10n.supplier),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.noData)),
                    ...suppliers.map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedSupplierId = v;
                      _selectedSupplierName = v != null
                          ? suppliers.firstWhere((s) => s.id == v).name
                          : null;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Note
              Text(l10n.note,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                    hintText: l10n.note,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    isDense: true),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _selectedProductId == null
                    ? null
                    : () {
                        final qty = int.tryParse(_qtyCtrl.text) ?? 0;
                        if (qty <= 0) return;
                        context.read<StockBloc>().add(AddStockMovementEvent(
                              productId: _selectedProductId!,
                              productName: _selectedProductName,
                              type: _type,
                              quantity: qty,
                              operatorId: operatorId,
                              supplierId: _selectedSupplierId,
                              supplierName: _selectedSupplierName,
                              note: _noteCtrl.text.trim().isNotEmpty
                                  ? _noteCtrl.text.trim()
                                  : null,
                              unitCost: double.tryParse(_costCtrl.text),
                            ));
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.save,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(MovementType t, AppLocalizations l10n) => switch (t) {
        MovementType.restockIn => l10n.moveRestockIn,
        MovementType.adjustmentIn => l10n.moveAdjustIn,
        MovementType.adjustmentOut => l10n.moveAdjustOut,
        MovementType.manualOut => l10n.moveManualOut,
        MovementType.returnIn => l10n.moveReturnIn,
        _ => t.name,
      };
}

// ── Supplier dialog ───────────────────────────────────────────────────────

class _SupplierDialog extends StatefulWidget {
  final Supplier? existing;
  final AppLocalizations l10n;

  const _SupplierDialog({required this.existing, required this.l10n});

  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.existing?.address ?? '');
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.addSupplier : l10n.supplier),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              autofocus: true,
            ),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phoneNumber),
            ),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(labelText: l10n.addressLine1),
            ),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: l10n.note),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final supplier = Supplier(
              id: widget.existing?.id ?? const Uuid().v4(),
              name: name,
              phone: _phoneCtrl.text.trim().isNotEmpty
                  ? _phoneCtrl.text.trim()
                  : null,
              address: _addressCtrl.text.trim().isNotEmpty
                  ? _addressCtrl.text.trim()
                  : null,
              notes: _notesCtrl.text.trim().isNotEmpty
                  ? _notesCtrl.text.trim()
                  : null,
            );
            context.read<StockBloc>().add(SaveSupplierEvent(supplier));
            Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
