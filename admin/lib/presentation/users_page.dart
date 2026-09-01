import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import '../theme/admin_theme.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final u = list[index];
              final id = u['id'] as String;
              final name = u['displayName'] as String? ?? '';
              final username = u['username'] as String? ?? '';
              final isAdmin = u['isAdmin'] == true;
              final disabled = u['isDisabled'] == true;

              return Card(
                child: ListTile(
                  title: Text('$name @$username'),
                  subtitle: Text(
                    '$id · admin=$isAdmin · disabled=$disabled · ${u['region'] ?? ''}',
                  ),
                  trailing: disabled
                      ? TextButton(
                          onPressed: () => ref
                              .read(adminRepositoryProvider)
                              .setUserDisabled(uid: id, disabled: false),
                          child: const Text('Enable'),
                        )
                      : TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AdminColors.danger,
                          ),
                          onPressed: isAdmin
                              ? null
                              : () => ref
                                  .read(adminRepositoryProvider)
                                  .setUserDisabled(uid: id, disabled: true),
                          child: const Text('Disable'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
