import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../reputation/application/engagement_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myNotificationsProvider);
    final uid = ref.watch(authUserProvider).asData?.value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => ref
                  .read(notificationRepositoryProvider)
                  .markAllRead(uid),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'No notifications yet.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.clay,
                      ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = items[index];
                return Material(
                  color: n.read
                      ? AppColors.snow.withValues(alpha: 0.7)
                      : AppColors.canopy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await ref
                          .read(notificationRepositoryProvider)
                          .markRead(n.id);
                      if (n.route != null && context.mounted) {
                        context.push(n.route!);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.mistDeep),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (n.body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              n.body,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.clay),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
