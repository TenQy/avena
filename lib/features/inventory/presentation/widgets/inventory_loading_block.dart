import 'package:flutter/material.dart';

class InventoryLoadingBlock extends StatelessWidget {
  const InventoryLoadingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 96,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
