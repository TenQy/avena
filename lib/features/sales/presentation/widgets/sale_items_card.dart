import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_products.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../models/sale_draft_item.dart';

class SaleItemsCard extends StatelessWidget {
  const SaleItemsCard({
    super.key,
    required this.items,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onUpdateUnitQuantity,
    required this.onEditBulkItem,
    required this.onApplyBulkPortion,
    required this.onRemoveItem,
  });

  final List<SaleDraftItem> items;
  final ValueChanged<SaleDraftItem> onIncreaseQuantity;
  final ValueChanged<SaleDraftItem> onDecreaseQuantity;
  final void Function(SaleDraftItem item, int quantity) onUpdateUnitQuantity;
  final ValueChanged<SaleDraftItem> onEditBulkItem;
  final void Function(SaleDraftItem item, AppBulkPortion portion)
  onApplyBulkPortion;
  final ValueChanged<SaleDraftItem> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Productos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              const _EmptySaleItems()
            else
              for (final item in items) ...[
                _SaleItemTile(
                  item: item,
                  onIncreaseQuantity: onIncreaseQuantity,
                  onDecreaseQuantity: onDecreaseQuantity,
                  onUpdateUnitQuantity: onUpdateUnitQuantity,
                  onEditBulkItem: onEditBulkItem,
                  onApplyBulkPortion: onApplyBulkPortion,
                  onRemoveItem: onRemoveItem,
                ),
                if (item != items.last)
                  Divider(
                    height: AppSpacing.lg,
                    color: AppColors.borderFor(context),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _SaleItemTile extends StatelessWidget {
  const _SaleItemTile({
    required this.item,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onUpdateUnitQuantity,
    required this.onEditBulkItem,
    required this.onApplyBulkPortion,
    required this.onRemoveItem,
  });

  final SaleDraftItem item;
  final ValueChanged<SaleDraftItem> onIncreaseQuantity;
  final ValueChanged<SaleDraftItem> onDecreaseQuantity;
  final void Function(SaleDraftItem item, int quantity) onUpdateUnitQuantity;
  final ValueChanged<SaleDraftItem> onEditBulkItem;
  final void Function(SaleDraftItem item, AppBulkPortion portion)
  onApplyBulkPortion;
  final ValueChanged<SaleDraftItem> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final isBulk = product.productType == AppProductTypes.bulk;
    final unitLabel = isBulk ? 'kg' : 'pz';
    final stockQuantity = product.stockQuantity ?? 0;
    final stockLabel = isBulk ? 'kg disponibles' : 'pz disponibles';
    final canAddUnit = !product.trackStock || item.quantity < stockQuantity;
    final canDecreaseUnit = !isBulk && item.quantity > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              _money(item.subtotal),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_quantity(item.quantity)} $unitLabel x ${_money(product.price)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        if (product.trackStock) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Stock: ${_quantity(stockQuantity)} $stockLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: item.quantity > stockQuantity
                  ? Theme.of(context).colorScheme.error
                  : AppColors.textSecondaryFor(context),
              fontWeight: item.quantity > stockQuantity
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (isBulk)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final portion in AppBulkPortions.salesQuick)
                    ActionChip(
                      label: Text(portion.label),
                      backgroundColor: AppColors.bodyBgFor(context),
                      side: BorderSide(
                        color: AppColors.borderFor(context),
                        width: 0.5,
                      ),
                      onPressed:
                          !product.trackStock ||
                              portion.kilogramFactor <= stockQuantity
                          ? () => onApplyBulkPortion(item, portion)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => onEditBulkItem(item),
                    child: const _ButtonContent(
                      label: 'Modificar',
                      icon: Icons.scale_rounded,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Quitar',
                    onPressed: () => onRemoveItem(item),
                    icon: Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          )
        else
          Row(
            children: [
              SizedBox(
                width: 48,
                child: canDecreaseUnit
                    ? IconButton(
                        tooltip: 'Restar',
                        onPressed: () => onDecreaseQuantity(item),
                        icon: Icon(Icons.remove_circle_outline_rounded),
                      )
                    : null,
              ),
              SizedBox(
                width: 74,
                child: _UnitQuantityInput(
                  item: item,
                  onChanged: (quantity) {
                    onUpdateUnitQuantity(item, quantity);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Sumar',
                onPressed: canAddUnit ? () => onIncreaseQuantity(item) : null,
                icon: Icon(Icons.add_circle_outline_rounded),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Quitar',
                onPressed: () => onRemoveItem(item),
                icon: Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
      ],
    );
  }
}

class _UnitQuantityInput extends StatefulWidget {
  const _UnitQuantityInput({required this.item, required this.onChanged});

  final SaleDraftItem item;
  final ValueChanged<int> onChanged;

  @override
  State<_UnitQuantityInput> createState() => _UnitQuantityInputState();
}

class _UnitQuantityInputState extends State<_UnitQuantityInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _quantity(widget.item.quantity));
    _focusNode = FocusNode()..addListener(_syncWhenFocusLeaves);
  }

  @override
  void didUpdateWidget(covariant _UnitQuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity &&
        !_focusNode.hasFocus) {
      _syncController();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_syncWhenFocusLeaves);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncWhenFocusLeaves() {
    if (!_focusNode.hasFocus) {
      _syncController();
    }
  }

  void _syncController() {
    final nextText = _quantity(widget.item.quantity);
    if (_controller.text == nextText) {
      return;
    }

    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  void _handleChanged(String value) {
    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) {
      return;
    }

    widget.onChanged(quantity);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      ),
      onChanged: _handleChanged,
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        const SizedBox(width: AppSpacing.sm),
        Icon(icon),
      ],
    );
  }
}

class _EmptySaleItems extends StatelessWidget {
  const _EmptySaleItems();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bodyBgFor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderFor(context), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: AppColors.iconInactiveFor(context),
            size: 36,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sin productos agregados.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

String _quantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(3);
}
