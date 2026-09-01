import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import '../theme/admin_theme.dart';

class LocationsQueuePage extends ConsumerWidget {
  const LocationsQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingLocationsProvider);
    final uid = ref.watch(adminAuthUserProvider).asData?.value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Location review queue')),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No pending locations.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final loc = list[index];
              final id = loc['id'] as String;
              final name = loc['name'] as String? ?? 'Unnamed';
              final region = loc['region'] as String? ?? '';
              final desc = loc['description'] as String? ?? '';
              final lat = loc['latitude'];
              final lng = loc['longitude'];
              final visibility = loc['visibility'] as String? ?? 'community';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      Text('$region · $visibility · $lat, $lng'),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(desc),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: uid == null
                                ? null
                                : () async {
                                    await ref
                                        .read(adminRepositoryProvider)
                                        .reviewLocation(
                                          locationId: id,
                                          status: 'approved',
                                          reviewerUid: uid,
                                          note: 'Approved',
                                        );
                                  },
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminColors.danger,
                            ),
                            onPressed: uid == null
                                ? null
                                : () async {
                                    final note = await _askNote(context);
                                    if (note == null) return;
                                    await ref
                                        .read(adminRepositoryProvider)
                                        .reviewLocation(
                                          locationId: id,
                                          status: 'rejected',
                                          reviewerUid: uid,
                                          note: note,
                                        );
                                  },
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _askNote(BuildContext context) async {
    final controller = TextEditingController(text: 'Does not meet guidelines');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection note'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
