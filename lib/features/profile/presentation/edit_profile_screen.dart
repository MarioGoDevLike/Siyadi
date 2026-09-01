import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/auth_validators.dart';
import '../../auth/presentation/widgets/auth_scaffold.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _bio = TextEditingController();

  String _country = AppConstants.defaultCountry;
  String? _region;
  bool _showLocationSubmissions = true;
  bool _allowMessagesFromAnyone = true;
  bool _pushNotificationsEnabled = true;
  File? _newPhoto;
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _seed(UserProfile profile) {
    if (_seeded) return;
    _displayName.text = profile.displayName;
    _bio.text = profile.bio ?? '';
    _country = profile.country;
    _region = profile.region;
    _showLocationSubmissions = profile.privacy.showLocationSubmissions;
    _allowMessagesFromAnyone = profile.privacy.allowMessagesFromAnyone;
    _pushNotificationsEnabled = profile.privacy.pushNotificationsEnabled;
    _seeded = true;
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _newPhoto = File(file.path));
  }

  Future<void> _save(UserProfile profile) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_region == null || _region!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your region')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      String? photoUrl;
      if (_newPhoto != null) {
        photoUrl = await repo.uploadAvatar(uid: profile.uid, file: _newPhoto!);
      }

      await repo.updateProfile(
        uid: profile.uid,
        displayName: _displayName.text,
        country: _country,
        region: _region!,
        bio: _bio.text,
        photoUrl: photoUrl,
        privacy: UserPrivacy(
          showLocationSubmissions: _showLocationSubmissions,
          allowMessagesFromAnyone: _allowMessagesFromAnyone,
          pushNotificationsEnabled: _pushNotificationsEnabled,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        context.pop();
      }
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('No profile')),
          );
        }
        _seed(profile);

        return Scaffold(
          appBar: AppBar(title: const Text('Edit profile')),
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.dawnWash),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _busy ? null : _pickPhoto,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor:
                              AppColors.canopy.withValues(alpha: 0.12),
                          backgroundImage: _newPhoto != null
                              ? FileImage(_newPhoto!)
                              : (profile.photoUrl != null
                                  ? NetworkImage(profile.photoUrl!)
                                      as ImageProvider
                                  : null),
                          child: _newPhoto == null && profile.photoUrl == null
                              ? const Icon(Icons.camera_alt_outlined,
                                  color: AppColors.canopySoft)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      controller: _displayName,
                      label: 'Display name',
                      validator: (v) => validateRequired(v, 'Display name'),
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _bio,
                      label: 'Bio',
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
                      validator: (value) => value == null || value.isEmpty
                          ? 'Region is required'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show my location submissions'),
                      value: _showLocationSubmissions,
                      onChanged: _busy
                          ? null
                          : (v) =>
                              setState(() => _showLocationSubmissions = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow messages from anyone'),
                      value: _allowMessagesFromAnyone,
                      onChanged: _busy
                          ? null
                          : (v) =>
                              setState(() => _allowMessagesFromAnyone = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Push notifications'),
                      subtitle: const Text(
                        'Store device token for alerts (in-app inbox always on)',
                      ),
                      value: _pushNotificationsEnabled,
                      onChanged: _busy
                          ? null
                          : (v) =>
                              setState(() => _pushNotificationsEnabled = v),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : () => _save(profile),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
