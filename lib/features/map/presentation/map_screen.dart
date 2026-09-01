import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/hunting_location.dart';
import '../../auth/application/auth_providers.dart';
import '../application/location_providers.dart';

/// Default camera over central Lebanon.
const _lebanonCenter = CameraPosition(
  target: LatLng(33.8938, 35.5018),
  zoom: 8.2,
);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _seeding = false;

  Set<Marker> _markersFor(List<HuntingLocation> locations) {
    return locations.map((loc) {
      return Marker(
        markerId: MarkerId(loc.id),
        position: LatLng(loc.latitude, loc.longitude),
        infoWindow: InfoWindow(
          title: loc.name,
          snippet: loc.region,
          onTap: () => context.push(AppRoutes.locationDetail(loc.id)),
        ),
        onTap: () => context.push(AppRoutes.locationDetail(loc.id)),
      );
    }).toSet();
  }

  Future<void> _seedIfAdmin() async {
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    if (profile == null || !profile.isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Set users/{uid}.isAdmin = true in Firestore, then seed.',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _seeding = true);
    try {
      final count = await ref
          .read(locationRepositoryProvider)
          .seedApprovedDemoLocations(adminUid: profile.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 0
                  ? 'Approved spots already exist.'
                  : 'Seeded $count approved locations.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Widget _header({
    required bool usingDemo,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.snow.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mistDeep),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: AppColors.canopy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hunting map',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  usingDemo
                      ? 'Showing demo spots — seed or propose real ones'
                      : '$count approved spots',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.clay,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'My proposals',
            onPressed: () => context.push(AppRoutes.myLocationProposals),
            icon: const Icon(Icons.playlist_add_check_rounded),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(mapLocationsProvider);
    final firestoreAsync = ref.watch(approvedLocationsProvider);
    final usingDemo = firestoreAsync.asData?.value.isEmpty ?? true;
    final useListFallback = Firebase.apps.isEmpty;

    return Scaffold(
      body: locationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (locations) {
          if (useListFallback) {
            return Container(
              decoration: const BoxDecoration(gradient: AppColors.dawnWash),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _header(usingDemo: true, count: locations.length),
                    const SizedBox(height: 12),
                    for (final loc in locations) ...[
                      ListTile(
                        tileColor: AppColors.snow.withValues(alpha: 0.85),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.mistDeep),
                        ),
                        title: Text(loc.name),
                        subtitle: Text(loc.region),
                        onTap: () =>
                            context.push(AppRoutes.locationDetail(loc.id)),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _lebanonCenter,
                markers: _markersFor(locations),
                myLocationButtonEnabled: false,
                compassEnabled: true,
                mapToolbarEnabled: false,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(
                        usingDemo: usingDemo,
                        count: locations.length,
                      ),
                      if (usingDemo) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonal(
                            onPressed: _seeding ? null : _seedIfAdmin,
                            child: _seeding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Seed approved (admin)'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 24,
                child: FloatingActionButton.extended(
                  onPressed: () => context.push(AppRoutes.proposeLocation),
                  backgroundColor: AppColors.canopy,
                  foregroundColor: AppColors.fog,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Propose'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
