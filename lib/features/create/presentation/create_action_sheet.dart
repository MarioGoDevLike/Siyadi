import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum CreateAction { post, fieldReport, proposeLocation }

/// Central Create (+) sheet — Post, Field Report, Propose Location.
Future<CreateAction?> showCreateActionSheet(BuildContext context) {
  return showModalBottomSheet<CreateAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return const _CreateActionSheet();
    },
  );
}

class _CreateActionSheet extends StatelessWidget {
  const _CreateActionSheet();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      decoration: BoxDecoration(
        color: AppColors.fog,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.mistDeep),
        boxShadow: [
          BoxShadow(
            color: AppColors.bark.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mistDeep,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Create', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Share with the community or contribute field knowledge.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.clay,
                ),
          ),
          const SizedBox(height: 20),
          _CreateTile(
            icon: Icons.photo_library_outlined,
            title: 'Social post',
            subtitle: 'Text, photos, or video for the feed',
            onTap: () => Navigator.of(context).pop(CreateAction.post),
          ),
          const SizedBox(height: 10),
          _CreateTile(
            icon: Icons.article_outlined,
            title: 'Field report',
            subtitle: 'Area, conditions, bird activity — fast',
            accent: true,
            onTap: () => Navigator.of(context).pop(CreateAction.fieldReport),
          ),
          const SizedBox(height: 10),
          _CreateTile(
            icon: Icons.add_location_alt_outlined,
            title: 'Propose location',
            subtitle: 'Submit a spot for admin review',
            onTap: () => Navigator.of(context).pop(CreateAction.proposeLocation),
          ),
        ],
      ),
    );
  }
}

class _CreateTile extends StatelessWidget {
  const _CreateTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final bg = accent
        ? AppColors.canopy.withValues(alpha: 0.08)
        : AppColors.snow.withValues(alpha: 0.9);
    final border = accent
        ? AppColors.canopy.withValues(alpha: 0.22)
        : AppColors.mistDeep;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent
                      ? AppColors.canopy.withValues(alpha: 0.14)
                      : AppColors.mist,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accent ? AppColors.canopy : AppColors.canopySoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.clay,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.clay.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
