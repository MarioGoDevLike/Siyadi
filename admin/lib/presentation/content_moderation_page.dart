import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import '../theme/admin_theme.dart';

class ContentModerationPage extends ConsumerWidget {
  const ContentModerationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(recentPostsProvider);
    final reports = ref.watch(recentFieldReportsProvider);
    final listings = ref.watch(listingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Content moderation')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Recent posts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          posts.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) => Column(
              children: [
                for (final p in list)
                  Card(
                    child: ListTile(
                      title: Text(
                        (p['caption'] as String?)?.isNotEmpty == true
                            ? p['caption'] as String
                            : '(media post)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '@${p['authorUsername'] ?? ''} · deleted=${p['isDeleted'] == true}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Soft-delete',
                        onPressed: p['isDeleted'] == true
                            ? null
                            : () => ref
                                .read(adminRepositoryProvider)
                                .softDeletePost(p['id'] as String),
                        icon: const Icon(Icons.delete_outline,
                            color: AdminColors.danger),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent field reports',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          reports.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) => Column(
              children: [
                for (final r in list)
                  Card(
                    child: ListTile(
                      title: Text('${r['area'] ?? ''} · ${r['region'] ?? ''}'),
                      subtitle: Text(
                        '${r['authorDisplayName'] ?? ''} · activity ${r['birdActivity'] ?? ''}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Archive',
                        onPressed: () => ref
                            .read(adminRepositoryProvider)
                            .archiveFieldReport(r['id'] as String),
                        icon: const Icon(Icons.archive_outlined),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Marketplace listings',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          listings.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) => Column(
              children: [
                for (final l in list)
                  Card(
                    child: ListTile(
                      title: Text(l['title'] as String? ?? 'Listing'),
                      subtitle: Text(
                        'removed=${l['isRemoved'] == true} · ${l['price'] ?? ''}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        onPressed: l['isRemoved'] == true
                            ? null
                            : () => ref
                                .read(adminRepositoryProvider)
                                .removeListing(l['id'] as String),
                        icon: const Icon(Icons.block,
                            color: AdminColors.danger),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
