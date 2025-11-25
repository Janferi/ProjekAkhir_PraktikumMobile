import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tugasakhir/screens/auth/login_page.dart';
import 'package:tugasakhir/screens/order_list_page.dart';

const Color kPrimary = Color(0xFF2563EB);
const Color kBg = Color(0xFFF3F4F6);
const Color kCard = Colors.white;
const Color kTextMain = Color(0xFF0F172A);
const Color kTextMuted = Color(0xFF6B7280);

class ProfilPage extends StatefulWidget {
  final String username;
  const ProfilPage({super.key, required this.username});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'profile_image_${widget.username}';
      final savedPath = prefs.getString(key);

      print('Loading profile image for ${widget.username}');
      print('Saved path: $savedPath');

      if (savedPath != null && savedPath.isNotEmpty) {
        final file = File(savedPath);
        final exists = await file.exists();
        print('File exists: $exists');

        if (exists) {
          if (mounted) {
            setState(() {
              _profileImagePath = savedPath;
            });
          }
          print('Profile image loaded successfully');
        } else {
          print('File does not exist, clearing saved path');
          await prefs.remove(key);
          if (mounted) {
            setState(() {
              _profileImagePath = null;
            });
          }
        }
      } else {
        print('No saved path found');
        if (mounted) {
          setState(() {
            _profileImagePath = null;
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
      if (mounted) {
        setState(() {
          _profileImagePath = null;
        });
      }
    }
  }

  Future<void> _saveProfileImage(String path) async {
    try {
      print('Saving image from path: $path');

      // Dapatkan direktori aplikasi permanent
      final directory = await getApplicationDocumentsDirectory();
      print('App directory: ${directory.path}');

      final fileName =
          'profile_${widget.username}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentPath = '${directory.path}/$fileName';
      print('Permanent path: $permanentPath');

      // Copy file ke lokasi permanent
      final File sourceFile = File(path);

      // Cek apakah file source ada
      if (!await sourceFile.exists()) {
        print('Source file does not exist!');
        throw Exception('Source file does not exist');
      }

      await sourceFile.copy(permanentPath);
      print('File copied successfully');

      // Simpan path permanent ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = 'profile_image_${widget.username}';
      await prefs.setString(key, permanentPath);
      print('Path saved to SharedPreferences with key: $key');

      if (mounted) {
        setState(() {
          _profileImagePath = permanentPath;
        });
        print('State updated with new path');
      }
    } catch (e) {
      print('Error saving profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        await _saveProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Foto profil berhasil diperbarui'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        await _saveProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Foto profil berhasil diperbarui'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih sumber foto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextMain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSourceOption(
                icon: Icons.camera_alt_rounded,
                title: 'Kamera',
                subtitle: 'Ambil foto menggunakan kamera',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              const SizedBox(height: 8),
              _buildSourceOption(
                icon: Icons.photo_library_rounded,
                title: 'Galeri',
                subtitle: 'Pilih foto dari galeri',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              if (_profileImagePath != null) ...[
                const SizedBox(height: 8),
                _buildSourceOption(
                  icon: Icons.delete_rounded,
                  title: 'Hapus foto',
                  subtitle: 'Kembali ke avatar default',
                  color: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('profile_image');
                    setState(() {
                      _profileImagePath = null;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Foto profil dihapus'),
                          backgroundColor: kPrimary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final Color iconColor = color ?? kPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color ?? kTextMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: kTextMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Simpan data yang perlu dipertahankan sebelum clear
    final allKeys = prefs.getKeys();
    final Map<String, dynamic> dataToKeep = {};

    for (var key in allKeys) {
      // Simpan foto profil
      if (key.startsWith('profile_image_')) {
        final value = prefs.getString(key);
        if (value != null) {
          dataToKeep[key] = value;
        }
      }
      // Simpan jadwal
      else if (key == 'saved_jadwal') {
        final value = prefs.getStringList(key);
        if (value != null) {
          dataToKeep[key] = value;
        }
      }
      // Simpan status minum obat
      else if (key.startsWith('last_taken_')) {
        final value = prefs.getString(key);
        if (value != null) {
          dataToKeep[key] = value;
        }
      }
    }

    // Clear semua data
    await prefs.clear();

    // Restore data yang perlu dipertahankan
    for (var entry in dataToKeep.entries) {
      if (entry.value is String) {
        await prefs.setString(entry.key, entry.value);
      } else if (entry.value is List<String>) {
        await prefs.setStringList(entry.key, entry.value);
      }
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        title: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: kPrimary),
            SizedBox(width: 8),
            Text(
              'Tentang aplikasi',
              style: TextStyle(fontWeight: FontWeight.w600, color: kTextMain),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Remedify',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your Smart Medication Companion',
              style: TextStyle(color: kTextMuted, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'Aplikasi untuk membantu Anda mengelola informasi obat, jadwal minum obat, dan menemukan apotek terdekat.',
              style: TextStyle(color: kTextMuted, height: 1.5, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              'Versi 1.0.0',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: kPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ===== HEADER PROFIL (CLEAN) =====
              _buildProfileHeader(),

              const SizedBox(height: 20),

              // ===== MENU CARD =====
              _buildMenuCard(),

              const SizedBox(height: 24),

              // ===== LOGOUT =====
              _buildLogoutButton(),

              const SizedBox(height: 16),

              const Text(
                'Remedify v1.0.0',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFE5E7EB),
                child: ClipOval(
                  child: _profileImagePath != null
                      ? Image.file(
                          File(_profileImagePath!),
                          fit: BoxFit.cover,
                          width: 84,
                          height: 84,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: Color(0xFF9CA3AF),
                            );
                          },
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: Color(0xFF9CA3AF),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showImageSourceDialog,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: kCard, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.username,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kTextMain,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pengguna Remedify',
            style: TextStyle(fontSize: 13, color: kTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildMenuOption(
            icon: Icons.shopping_bag_outlined,
            title: 'Pesanan saya',
            subtitle: 'Lihat riwayat pembelian obat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderListPage()),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildMenuOption(
            icon: Icons.info_outline_rounded,
            title: 'Tentang aplikasi',
            subtitle: 'Informasi tentang Remedify',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Keluar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: kPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: kTextMuted),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
