import 'package:flutter/material.dart';

import '../../../../shared/widgets/module_placeholder.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      icon: Icons.group_rounded,
      message: 'Usuarios',
    );
  }
}
