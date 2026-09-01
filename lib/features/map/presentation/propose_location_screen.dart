import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/hunting_location.dart';
import '../../auth/application/auth_providers.dart';
import '../application/location_providers.dart';
import '../data/location_repository.dart';

class ProposeLocationScreen extends ConsumerStatefulWidget {
  const ProposeLocationScreen({super.key});

  @override
  ConsumerState<ProposeLocationScreen> createState() =>
      _ProposeLocationScreenState();
}

class _ProposeLocationScreenState extends ConsumerState<ProposeLocationScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  final _images = <XFile>[];

  String? _region;
  LatLng _pin = const LatLng(33.8938, 35.5018);
  LocationVisibility _visibility = LocationVisibility.community;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(currentUserProfileProvider).asData?.value;
      if (profile != null) {
        setState(() => _region = profile.region);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (files.isEmpty) return;
    setState(() {
      _images
        ..clear()
        ..addAll(files.take(4));
    });
  }

  Future<void> _submit() async {
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    if (profile == null) return;
    if (_region == null || _region!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a region.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final tags = _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      await ref.read(locationRepositoryProvider).proposeLocation(
            proposer: profile,
            name: _name.text,
            description: _description.text,
            region: _region!,
            latitude: _pin.latitude,
            longitude: _pin.longitude,
            visibility: _visibility,
            tags: tags,
            imageFiles: _images.map((f) => File(f.path)).toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submitted for admin review (pending).'),
          ),
        );
        context.pop();
      }
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propose location'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'Pin the spot, then submit for admin approval. It stays private until approved.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.clay,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _pin, zoom: 9),
                  markers: {
                    Marker(
                      markerId: const MarkerId('pin'),
                      position: _pin,
                      draggable: true,
                      onDragEnd: (pos) => setState(() => _pin = pos),
                    ),
                  },
                  onTap: (pos) => setState(() => _pin = pos),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lat ${_pin.latitude.toStringAsFixed(5)}, Lng ${_pin.longitude.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.clay,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Spot name',
                hintText: 'e.g. North ridge access',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_region ?? 'region'),
              initialValue: _region,
              decoration: const InputDecoration(labelText: 'Region'),
              items: AppConstants.lebanonRegions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _region = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Access notes, terrain, privacy considerations…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'ridge, water, cover',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show to community after approval'),
              subtitle: Text(
                _visibility == LocationVisibility.community
                    ? 'Community visibility once an admin approves.'
                    : 'Kept private to you even after approval.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.clay,
                    ),
              ),
              value: _visibility == LocationVisibility.community,
              onChanged: _busy
                  ? null
                  : (v) => setState(
                        () => _visibility = v
                            ? LocationVisibility.community
                            : LocationVisibility.private,
                      ),
            ),
            const SizedBox(height: 8),
            if (_images.isNotEmpty)
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_images[i].path),
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Add photos (optional)'),
            ),
          ],
        ),
      ),
    );
  }
}
