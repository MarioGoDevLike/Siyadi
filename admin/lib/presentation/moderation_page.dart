import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';

class ModerationPage extends ConsumerWidget {
  const ModerationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(openReportsProvider);
    final uid = ref.watch(adminAuthUserProvider).asData?.value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('User reports')),
      body: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No open reports.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = list[index];
              final id = r['id'] as String;
              final type = r['targetType'] as String? ?? 'unknown';
              final targetId = r['targetId'] as String? ?? '';
              final reason = r['reason'] as String? ?? '';
              final reporter = r['reporterId'] as String? ?? '';

              return Card(
                child: ListTile(
                  title: Text('$type · $targetId'),
                  subtitle: Text('Reason: $reason\nReporter: $reporter'),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      if (type == 'post')
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(adminRepositoryProvider)
                                .softDeletePost(targetId);
                          },
                          child: const Text('Hide post'),
                        ),
                      FilledButton.tonal(
                        onPressed: uid == null
                            ? null
                            : () async {
                                await ref
                                    .read(adminRepositoryProvider)
                                    .resolveReport(
                                      reportId: id,
                                      resolverUid: uid,
                                    );
                              },
                        child: const Text('Resolve'),
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
}
