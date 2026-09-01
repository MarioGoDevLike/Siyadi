import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/field_report.dart';
import '../../auth/application/auth_providers.dart';
import '../../reputation/application/engagement_providers.dart';
import '../application/field_report_providers.dart';
import '../data/field_report_repository.dart';

class CreateFieldReportScreen extends ConsumerStatefulWidget {
  const CreateFieldReportScreen({super.key});

  @override
  ConsumerState<CreateFieldReportScreen> createState() =>
      _CreateFieldReportScreenState();
}

class _CreateFieldReportScreenState
    extends ConsumerState<CreateFieldReportScreen> {
  final _area = TextEditingController();
  final _conditions = TextEditingController();
  final _weather = TextEditingController();
  final _locationRef = TextEditingController();
  final _images = <XFile>[];

  DateTime _reportDate = DateTime.now();
  BirdActivityLevel _activity = BirdActivityLevel.moderate;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(currentUserProfileProvider).asData?.value;
      if (profile != null && _area.text.isEmpty) {
        _area.text = profile.region;
      }
    });
  }

  @override
  void dispose() {
    _area.dispose();
    _conditions.dispose();
    _weather.dispose();
    _locationRef.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _reportDate = picked);
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

    setState(() => _busy = true);
    try {
      await ref.read(fieldReportRepositoryProvider).createReport(
            author: profile,
            area: _area.text,
            reportDate: _reportDate,
            birdActivity: _activity,
            conditions: _conditions.text,
            weatherNotes: _weather.text,
            locationId: _locationRef.text.trim().isEmpty
                ? null
                : _locationRef.text.trim(),
            imageFiles: _images.map((f) => File(f.path)).toList(),
          );
      await ref.read(engagementFanoutProvider).onFieldReportCreated(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field report filed')),
        );
        context.pop();
      }
    } on FieldReportException catch (e) {
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
    final profile = ref.watch(currentUserProfileProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field report'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('File'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'Quick field note for ${profile?.region ?? 'your region'}, ${profile?.country ?? AppConstants.defaultCountry}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.clay,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _area,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Area',
                hintText: 'e.g. Akkar hills, Chouf ridge',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Report date'),
              subtitle: Text(
                '${_reportDate.year}-${_reportDate.month.toString().padLeft(2, '0')}-${_reportDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _busy ? null : _pickDate,
            ),
            const SizedBox(height: 8),
            Text('Bird activity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BirdActivityLevel.values.map((level) {
                final selected = _activity == level;
                return ChoiceChip(
                  label: Text(level.label),
                  selected: selected,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _activity = level),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _conditions,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Conditions',
                hintText: 'Cover, pressure, access…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weather,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Weather notes',
                hintText: 'Wind, visibility, temp…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationRef,
              decoration: const InputDecoration(
                labelText: 'Location reference (optional)',
                hintText: 'Paste hunting location id from Map detail',
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
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
