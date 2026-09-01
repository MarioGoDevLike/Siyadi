import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import '../theme/admin_theme.dart';

class BadgesPage extends ConsumerStatefulWidget {
  const BadgesPage({super.key});

  @override
  ConsumerState<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends ConsumerState<BadgesPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _criteria = TextEditingController();
  final _points = TextEditingController(text: '0');

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _criteria.dispose();
    _points.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    await ref.read(adminRepositoryProvider).upsertBadge(
          name: _name.text.trim(),
          description: _description.text.trim(),
          criteria: _criteria.text.trim(),
          pointsHint: int.tryParse(_points.text.trim()) ?? 0,
        );
    _name.clear();
    _description.clear();
    _criteria.clear();
    _points.text = '0';
  }

  @override
  Widget build(BuildContext context) {
    final badges = ref.watch(badgesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Badges & reputation config')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create badge definition',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reputation levels stay Beginner → Active → Trusted → Field Expert (points thresholds live in the mobile app). Badges are admin-managed awards.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _criteria,
                    decoration: const InputDecoration(
                      labelText: 'Criteria',
                      hintText: 'e.g. 10 field reports filed',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _points,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Suggested points hint',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: _create,
                      child: const Text('Save badge'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Existing badges', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          badges.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) {
              if (list.isEmpty) {
                return const Text('No badges yet.');
              }
              return Column(
                children: [
                  for (final b in list)
                    Card(
                      child: ListTile(
                        title: Text(b['name'] as String? ?? ''),
                        subtitle: Text(
                          '${b['description'] ?? ''}\nCriteria: ${b['criteria'] ?? ''} · hint ${b['pointsHint'] ?? 0}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          onPressed: () => ref
                              .read(adminRepositoryProvider)
                              .deleteBadge(b['id'] as String),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AdminColors.danger,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
