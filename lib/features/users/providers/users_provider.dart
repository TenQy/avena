import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(databaseProvider));
});

final usersProvider = StreamProvider<List<User>>((ref) {
  return ref.watch(usersRepositoryProvider).watchActiveUsers();
});
