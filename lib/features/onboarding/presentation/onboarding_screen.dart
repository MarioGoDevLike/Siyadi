import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/auth_validators.dart';
import '../../auth/presentation/widgets/auth_scaffold.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();

  String _country = AppConstants.defaultCountry;
  String? _region;
  File? _photo;
  bool _busy = false;
  String? _usernameError;

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _photo = File(file.path));
  }

  Future<void> _submit() async {
    setState(() => _usernameError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_region == null || _region!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your region')),
      );
      return;
    }

    final user = ref.read(authUserProvider).asData?.value;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      final available =
          await repo.isUsernameAvailable(_username.text.trim());
      if (!available) {
        setState(() => _usernameError = 'That username is already taken');
        return;
      }

      String? photoUrl;
      if (_photo != null) {
        photoUrl = await repo.uploadAvatar(uid: user.uid, file: _photo!);
      }

      await repo.completeOnboarding(
        uid: user.uid,
        displayName: _displayName.text,
        username: _username.text,
        country: _country,
        region: _region!,
        photoUrl: photoUrl,
        bio: _bio.text,
      );
    } on UserRepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Set up your profile',
      subtitle:
          'Country and region power local feeds and maps. Username is unique.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _busy ? null : _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.canopy.withValues(alpha: 0.12),
                      backgroundImage:
                          _photo != null ? FileImage(_photo!) : null,
                      child: _photo == null
                          ? const Icon(
                              Icons.person_outline_rounded,
                              size: 40,
                              color: AppColors.canopySoft,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.brass,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                          color: AppColors.bark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optional photo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.clay,
                  ),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              controller: _displayName,
              label: 'Display name',
              textInputAction: TextInputAction.next,
              validator: (v) => validateRequired(v, 'Display name'),
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _username,
              label: 'Username',
              textInputAction: TextInputAction.next,
              validator: (value) => _usernameError ?? validateUsername(value),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _country,
              decoration: const InputDecoration(labelText: 'Country'),
              items: const [
                DropdownMenuItem(
                  value: AppConstants.defaultCountry,
                  child: Text(AppConstants.defaultCountry),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _country = value;
                        _region = null;
                      });
                    },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _region,
              decoration: const InputDecoration(labelText: 'Region'),
              items: AppConstants.lebanonRegions
                  .map(
                    (region) => DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _region = value),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Region is required' : null,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _bio,
              label: 'Bio (optional)',
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enter SIYADI'),
            ),
            TextButton(
              onPressed: _busy ? null : _signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
