/// Profile Screen
/// Profil ve ayarlar ekranı

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/duty_planner_theme.dart';

/// Profil ve ayarlar ekranı
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _schoolController;
  late TextEditingController _newEmailController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _isChangingEmail = false;
  bool _isUploadingPhoto = false;
  String? _successMessage;
  String? _errorMessage;
  String? _emailErrorMessage;
  String? _profilePhotoUrl;
  Uint8List? _profilePhotoBytes;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _nameController = TextEditingController(
      text: user?.userMetadata?['display_name'] ?? '',
    );
    _schoolController = TextEditingController(
      text: user?.userMetadata?['school_name'] ?? '',
    );
    _newEmailController = TextEditingController(text: user?.email ?? '');
    _profilePhotoUrl = user?.userMetadata?['avatar_url'];

    // Base64 encoded photo check
    final photoData = user?.userMetadata?['profile_photo'];
    if (photoData != null && photoData is String && photoData.isNotEmpty) {
      try {
        _profilePhotoBytes = base64Decode(photoData);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil ve Ayarlar'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profil kartı
                _buildProfileCard(user),
                const SizedBox(height: 24),

                // Bilgileri düzenle
                _buildEditInfoCard(),
                const SizedBox(height: 24),

                // E-posta değiştir
                _buildEmailCard(),
                const SizedBox(height: 24),

                // Şifre değiştir
                _buildPasswordCard(),
                const SizedBox(height: 24),

                // Hesap işlemleri
                _buildAccountActionsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(User? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profil fotoğrafı
            Stack(
              children: [
                GestureDetector(
                  onTap: _pickProfilePhoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DutyPlannerColors.primaryLight,
                      border: Border.all(
                        color: DutyPlannerColors.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      image: _profilePhotoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_profilePhotoBytes!),
                              fit: BoxFit.cover,
                            )
                          : _profilePhotoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_profilePhotoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        (_profilePhotoBytes == null && _profilePhotoUrl == null)
                        ? Center(
                            child: Text(
                              (user?.userMetadata?['display_name'] ??
                                      user?.email ??
                                      'U')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: DutyPlannerColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                // Kamera ikonu
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: DutyPlannerColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _isUploadingPhoto
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickProfilePhoto,
              child: const Text('Fotoğraf Değiştir'),
            ),
            const SizedBox(height: 8),
            Text(
              user?.userMetadata?['display_name'] ?? 'Kullanıcı',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: DutyPlannerColors.textSecondary),
            ),
            if (user?.userMetadata?['school_name'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DutyPlannerColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school,
                      size: 16,
                      color: DutyPlannerColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user!.userMetadata!['school_name'],
                      style: const TextStyle(
                        color: DutyPlannerColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit, color: DutyPlannerColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Bilgileri Düzenle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ad Soyad
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Okul Adı
              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(
                  labelText: 'Okul Adı',
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DutyPlannerColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: DutyPlannerColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: DutyPlannerColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Bilgileri Güncelle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _emailFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.email, color: DutyPlannerColors.info),
                  SizedBox(width: 8),
                  Text(
                    'E-posta Değiştir',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Yeni E-posta
              TextFormField(
                controller: _newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Yeni E-posta Adresi',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  helperText:
                      'Değişiklik için doğrulama e-postası gönderilecek',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta gerekli';
                  }
                  if (!value.contains('@')) {
                    return 'Geçerli bir e-posta girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_emailErrorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DutyPlannerColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: DutyPlannerColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _emailErrorMessage!,
                          style: const TextStyle(
                            color: DutyPlannerColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isChangingEmail ? null : _changeEmail,
                  child: _isChangingEmail
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('E-postayı Değiştir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock, color: DutyPlannerColors.warning),
                SizedBox(width: 8),
                Text(
                  'Şifre Değiştir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Yeni Şifre
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(),
                helperText: 'En az 6 karakter',
              ),
            ),
            const SizedBox(height: 16),

            // Şifre Tekrar
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre Tekrar',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DutyPlannerColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: DutyPlannerColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: DutyPlannerColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isChangingPassword ? null : _changePassword,
                child: _isChangingPassword
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Şifreyi Değiştir'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: DutyPlannerColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Hesap İşlemleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Çıkış yap
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
            const Divider(),

            // Hesabı sil
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Hesabı Sil',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Bu işlem geri alınamaz'),
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      // Read image bytes
      final bytes = await image.readAsBytes();

      // Convert to base64 for storage in user metadata
      final base64Image = base64Encode(bytes);

      // Update user metadata with the photo
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'profile_photo': base64Image}),
      );

      setState(() {
        _profilePhotoBytes = bytes;
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil fotoğrafı güncellendi'),
            backgroundColor: DutyPlannerColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingPhoto = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yüklenemedi: $e'),
            backgroundColor: DutyPlannerColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _successMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': _nameController.text.trim(),
            'school_name': _schoolController.text.trim(),
          },
        ),
      );

      setState(() {
        _successMessage = 'Bilgiler başarıyla güncellendi';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Güncelleme başarısız: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final newEmail = _newEmailController.text.trim();
    final currentEmail = _authService.currentUser?.email;

    if (newEmail == currentEmail) {
      setState(() {
        _emailErrorMessage = 'Yeni e-posta mevcut e-posta ile aynı';
      });
      return;
    }

    setState(() {
      _isChangingEmail = true;
      _emailErrorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Doğrulama e-postası gönderildi. Lütfen yeni e-posta adresinizi doğrulayın.',
            ),
            backgroundColor: DutyPlannerColors.success,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _emailErrorMessage = 'E-posta değiştirilemedi: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChangingEmail = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Yeni şifre gerekli';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _errorMessage = 'Şifre en az 6 karakter olmalı';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = 'Şifreler eşleşmiyor';
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre başarıyla değiştirildi'),
            backgroundColor: DutyPlannerColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Şifre değiştirilemedi: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Not: Supabase Admin API gerektirir, şimdilik sadece çıkış yapıyoruz
              await _authService.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Hesap silme işlemi için lütfen yönetici ile iletişime geçin',
                    ),
                  ),
                );
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }
}
