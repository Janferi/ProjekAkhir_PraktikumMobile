import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tugasakhir/models/my_medicine_model.dart';
import 'package:tugasakhir/db/database_helper.dart';

class DetailMyMedicinePage extends StatefulWidget {
  final MyMedicine medicine;

  const DetailMyMedicinePage({super.key, required this.medicine});

  @override
  State<DetailMyMedicinePage> createState() => _DetailMyMedicinePageState();
}

class _DetailMyMedicinePageState extends State<DetailMyMedicinePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();
  late MyMedicine _currentMedicine;
  bool _isEditing = false;
  bool _isSaving = false;

  final _stokController = TextEditingController();
  final _catatanController = TextEditingController();
  DateTime? _selectedExpiry;
  File? _selectedImage;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _currentMedicine = widget.medicine;
    _stokController.text = _currentMedicine.jumlahStok.toString();
    _catatanController.text = _currentMedicine.deskripsi ?? '';
    if (_currentMedicine.tanggalKadaluarsa != null) {
      _selectedExpiry = DateTime.parse(_currentMedicine.tanggalKadaluarsa!);
    }
    _imagePath = _currentMedicine.linkGambar;
  }

  @override
  void dispose() {
    _stokController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3B82F6)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedExpiry = picked);
    }
  }

  Future<void> _saveChanges() async {
    if (_stokController.text.isEmpty ||
        int.tryParse(_stokController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok harus berupa angka!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedMedicine = MyMedicine(
        id: _currentMedicine.id,
        namaObat: _currentMedicine.namaObat,
        linkGambar: _imagePath,
        deskripsi: _catatanController.text.trim().isEmpty
            ? null
            : _catatanController.text.trim(),
        komposisi: _currentMedicine.komposisi,
        dosis: _currentMedicine.dosis,
        jenisObat: _currentMedicine.jenisObat,
        jumlahStok: int.parse(_stokController.text),
        tanggalKadaluarsa: _selectedExpiry?.toIso8601String(),
        sumber: _currentMedicine.sumber,
        tanggalDitambahkan: _currentMedicine.tanggalDitambahkan,
      );

      await _dbHelper.updateMyMedicine(_currentMedicine.id!, updatedMedicine);

      setState(() {
        _currentMedicine = updatedMedicine;
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Perubahan berhasil disimpan'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Obat?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${_currentMedicine.namaObat}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteMyMedicine(_currentMedicine.id!);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Obat berhasil dihapus'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon =
        _currentMedicine.tanggalKadaluarsa != null &&
        DateTime.parse(
              _currentMedicine.tanggalKadaluarsa!,
            ).difference(DateTime.now()).inDays <
            30;
    final isLowStock = _currentMedicine.jumlahStok < 5;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _isEditing ? 'Edit Obat' : 'Detail Obat',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.3,
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 350,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (_imagePath != null && _imagePath!.isNotEmpty
                            ? _buildImage(_imagePath!)
                            : Center(
                                child: Icon(
                                  Icons.medication_outlined,
                                  size: screenWidth * 0.25,
                                  color: Colors.grey.shade400,
                                ),
                              )),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Kamera'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.camera);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Galeri'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.gallery);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      backgroundColor: const Color(0xFF3B82F6),
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Obat
                  Text(
                    _currentMedicine.namaObat,
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        text: _currentMedicine.sumber == 'pembelian'
                            ? 'Dari Pembelian'
                            : 'Ditambah Manual',
                        icon: _currentMedicine.sumber == 'pembelian'
                            ? Icons.shopping_bag_rounded
                            : Icons.edit_rounded,
                      ),
                      if (_currentMedicine.jenisObat != null)
                        _buildBadge(
                          text: _currentMedicine.jenisObat!,
                          icon: Icons.category_rounded,
                        ),
                      if (isLowStock)
                        _buildBadge(
                          text: 'Stok Menipis',
                          icon: Icons.warning_amber_rounded,
                        ),
                      if (isExpiringSoon)
                        _buildBadge(
                          text: 'Segera Kadaluarsa',
                          icon: Icons.warning_amber_rounded,
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stok - Editable
                  if (_isEditing)
                    _buildEditField(
                      label: 'Jumlah Stok',
                      controller: _stokController,
                      icon: Icons.inventory_2_rounded,
                      keyboardType: TextInputType.number,
                    )
                  else
                    _buildInfoCard(
                      icon: Icons.inventory_2_rounded,
                      title: 'Jumlah Stok',
                      value: '${_currentMedicine.jumlahStok} unit',
                    ),

                  const SizedBox(height: 12),

                  // Tanggal Kadaluarsa - Editable
                  if (_isEditing)
                    _buildDateField()
                  else if (_currentMedicine.tanggalKadaluarsa != null)
                    _buildInfoCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Tanggal Kadaluarsa',
                      value: _formatDate(_currentMedicine.tanggalKadaluarsa!),
                    ),

                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.access_time_rounded,
                    title: 'Ditambahkan',
                    value: _formatDate(_currentMedicine.tanggalDitambahkan),
                  ),

                  if (_currentMedicine.dosis != null) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Jadwal Makan',
                      icon: Icons.schedule_rounded,
                      content: _currentMedicine.dosis!,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Catatan - Editable
                  if (_isEditing)
                    _buildEditField(
                      label: 'Catatan',
                      controller: _catatanController,
                      icon: Icons.description_rounded,
                      maxLines: 4,
                    )
                  else if (_currentMedicine.deskripsi != null)
                    _buildSection(
                      title: 'Catatan',
                      icon: Icons.description_rounded,
                      content: _currentMedicine.deskripsi!,
                    ),

                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _stokController.text = _currentMedicine
                                    .jumlahStok
                                    .toString();
                                _catatanController.text =
                                    _currentMedicine.deskripsi ?? '';
                                _selectedExpiry =
                                    _currentMedicine.tanggalKadaluarsa != null
                                    ? DateTime.parse(
                                        _currentMedicine.tanggalKadaluarsa!,
                                      )
                                    : null;
                                _imagePath = _currentMedicine.linkGambar;
                                _selectedImage = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Masukkan $label',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: Color(0xFF3B82F6),
            ),
            SizedBox(width: 8),
            Text(
              'Tanggal Kadaluarsa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedExpiry == null
                        ? 'Pilih tanggal'
                        : _formatDate(_selectedExpiry!.toIso8601String()),
                    style: TextStyle(
                      color: _selectedExpiry == null
                          ? Colors.grey.shade400
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imagePath) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.maxWidth * 0.25;
        if (imagePath.startsWith('http://') ||
            imagePath.startsWith('https://')) {
          return Image.network(
            imagePath,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: iconSize,
                color: Colors.grey.shade400,
              ),
            ),
          );
        } else {
          final file = File(imagePath);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: iconSize,
                  color: Colors.grey.shade400,
                ),
              ),
            );
          } else {
            return Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: iconSize,
                color: Colors.grey.shade400,
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildBadge({required String text, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
