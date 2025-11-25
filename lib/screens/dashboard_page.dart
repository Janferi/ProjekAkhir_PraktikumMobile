import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasakhir/screens/lokasi_page.dart';
import 'package:tugasakhir/screens/profil_page.dart';
import 'package:tugasakhir/screens/shop_page.dart';
import 'package:tugasakhir/screens/cart_page.dart';
import 'package:tugasakhir/screens/add_medicine_page.dart';
import 'package:tugasakhir/screens/detail_my_medicine_page.dart';
import 'package:tugasakhir/screens/news_detail_page.dart';
import 'package:tugasakhir/screens/jadwal_page_list.dart';
import 'package:tugasakhir/screens/my_medicines_list_page.dart';
import 'package:tugasakhir/db/database_helper.dart';
import 'package:tugasakhir/models/my_medicine_model.dart';
import 'package:tugasakhir/models/news_model.dart';
import 'package:tugasakhir/services/news_service.dart';
import 'package:intl/intl.dart';

// ===== PALET & STYLE GLOBAL =====
const Color kPrimary = Color(0xFF2563EB);
const Color kPrimarySoft = Color(0xFFE0EAFF);
const Color kPrimaryDark = Color(0xFF1D4ED8);
const Color kBg = Color(0xFFF3F4F6);
const Color kCard = Colors.white;
const Color kTextMain = Color(0xFF0F172A);
const Color kTextMuted = Color(0xFF6B7280);

class DashboardPage extends StatefulWidget {
  final String username;
  final int initialIndex;
  const DashboardPage({
    super.key,
    required this.username,
    this.initialIndex = 0,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _selectedIndex;
  List<MyMedicine> _myMedicines = [];
  List<NewsArticle> _newsArticles = [];
  List<Map<String, dynamic>> _jadwalList = [];
  bool _isLoading = false;
  bool _isLoadingNews = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadMyMedicines();
    _updateCartCount();
    _loadNews();
    _loadJadwal();
  }

  Future<void> _loadMyMedicines() async {
    setState(() => _isLoading = true);
    final medicines = await _dbHelper.getMyMedicines();
    setState(() {
      _myMedicines = medicines;
      _isLoading = false;
    });
  }

  Future<void> _updateCartCount() async {
    final count = await _dbHelper.getCartItemCount();
    setState(() => _cartItemCount = count);
  }

  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);
    try {
      final articles = await NewsService.fetchHealthNews();
      if (mounted) {
        setState(() {
          _newsArticles = articles;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNews = false);
      }
    }
  }

  Future<void> _loadJadwal() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList('saved_jadwal');
    if (data != null && mounted) {
      setState(() {
        _jadwalList = data
            .map((e) => jsonDecode(e) as Map<String, dynamic>)
            .toList();
      });
      // Debug: print jadwal data
      for (var jadwal in _jadwalList) {
        print('Jadwal loaded: ${jadwal.keys.toList()}');
        print('Nama obat: ${jadwal['nama_obat'] ?? jadwal['namaObat']}');
        print('Link gambar: ${jadwal['link_gambar']}');
      }
    }
  }

  // Cek apakah obat sudah boleh diminum (berdasarkan jadwal terakhir)
  Future<bool> _canTakeMedicine(String namaObat, String waktu) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_taken_${namaObat}_$waktu';
    final lastTakenStr = prefs.getString(key);

    // Jika belum pernah minum, boleh
    if (lastTakenStr == null) return true;

    final now = DateTime.now();

    // Parse waktu jadwal (format HH:mm)
    final timeParts = waktu.split(':');
    final scheduledHour = int.parse(timeParts[0]);
    final scheduledMinute = int.parse(timeParts[1]);

    // Buat DateTime untuk jadwal hari ini
    var nextSchedule = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledHour,
      scheduledMinute,
    );

    // Jika jadwal hari ini sudah lewat, set ke besok
    if (nextSchedule.isBefore(now)) {
      nextSchedule = nextSchedule.add(const Duration(days: 1));
    }

    // Jika sudah melewati jadwal berikutnya, bisa minum lagi
    return now.isAfter(nextSchedule) || now.isAtSameMomentAs(nextSchedule);
  }

  // Simpan waktu terakhir minum obat
  Future<void> _markMedicineAsTaken(String namaObat, String waktu) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_taken_${namaObat}_$waktu';
    await prefs.setString(key, DateTime.now().toIso8601String());
  }

  // Tandai obat sudah diminum + kurangi stok
  Future<void> _tandaiSudahMinum(Map<String, dynamic> jadwal, int index) async {
    final String namaObat = jadwal['namaObat'] ?? jadwal['nama_obat'] ?? '';
    final String waktu = jadwal['waktu'] ?? '';

    // Cek apakah sudah boleh minum
    final canTake = await _canTakeMedicine(namaObat, waktu);
    if (!canTake) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.schedule_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Tunggu jadwal berikutnya!'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Cari obat di database
    final medicines = await _dbHelper.getMyMedicines();
    final medicine = medicines.firstWhere(
      (m) => m.namaObat.toLowerCase() == namaObat.toLowerCase(),
      orElse: () => throw Exception('Obat tidak ditemukan'),
    );

    // Cek stok obat
    if (medicine.jumlahStok <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Stok obat habis!'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Kurangi stok obat
    final updatedMedicine = MyMedicine(
      id: medicine.id,
      namaObat: medicine.namaObat,
      linkGambar: medicine.linkGambar,
      deskripsi: medicine.deskripsi,
      komposisi: medicine.komposisi,
      dosis: medicine.dosis,
      jenisObat: medicine.jenisObat,
      jumlahStok: medicine.jumlahStok - 1,
      tanggalKadaluarsa: medicine.tanggalKadaluarsa,
      sumber: medicine.sumber,
      tanggalDitambahkan: medicine.tanggalDitambahkan,
    );

    // Update obat di database
    await _dbHelper.updateMyMedicine(medicine.id!, updatedMedicine);

    // Tandai sudah diminum di SharedPreferences
    await _markMedicineAsTaken(namaObat, waktu);

    // Reload data obat
    await _loadMyMedicines();

    // Refresh UI untuk update status tombol
    if (mounted) {
      setState(() {});
    }

    // Tampilkan notifikasi sukses
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Obat diminum! Stok tersisa: ${updatedMedicine.jumlahStok}',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} menit yang lalu';
        }
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else {
        return DateFormat('dd MMM yyyy', 'id_ID').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildBeranda(context),
      const ShopPage(),
      const LokasiPage(),
      ProfilPage(username: widget.username),
    ];

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: SafeArea(child: pages[_selectedIndex]),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMedicinePage()),
                );
                _loadMyMedicines();
              },
              backgroundColor: kPrimary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Tambah Obat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevation: 4,
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_selectedIndex == 0) {
      return AppBar(
        toolbarHeight: 70,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryDark, kPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
                gradient: const LinearGradient(
                  colors: [Colors.white24, Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${widget.username}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Dashboard kesehatanmu hari ini',
                    style: TextStyle(fontSize: 12, color: Color(0xFFDBEAFE)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_selectedIndex == 1) {
      return AppBar(
        toolbarHeight: 70,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryDark, kPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 16,
        title: const Text(
          'Toko Obat',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                  _updateCartCount();
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    } else {
      return AppBar(
        toolbarHeight: 70,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryDark, kPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 16,
        title: Text(
          _selectedIndex == 2 ? 'Lokasi Apotek' : 'Profil',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      );
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: kPrimary,
          unselectedItemColor: const Color(0xFF9CA3AF),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            _navItem(Icons.dashboard_rounded, 'Beranda', 0),
            _navItem(Icons.shopping_bag_rounded, 'Toko', 1),
            _navItem(Icons.location_on_rounded, 'Lokasi', 2),
            _navItem(Icons.person_rounded, 'Profil', 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? kPrimarySoft.withOpacity(0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive ? kPrimary : const Color(0xFF9CA3AF),
        ),
      ),
      label: label,
    );
  }

  // ================== BERANDA (DESAIN JUARA) ==================

  Widget _buildBeranda(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
        ),
      );
    }

    final int totalObat = _myMedicines.length;
    final int totalJadwal = _jadwalList.length;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadMyMedicines();
        await _loadNews();
        await _loadJadwal();
      },
      color: kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // hero card
            _HeroDashboardCard(totalObat: totalObat, totalJadwal: totalJadwal),
            const SizedBox(height: 24),

            // Jadwal
            _SectionHeader(
              icon: Icons.schedule_rounded,
              title: 'Jadwal Hari Ini',
              subtitle: 'Minum obat tepat waktu biar tetap fit',
              actionLabel: 'Lihat semua',
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const JadwalTersimpanPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildJadwalSection(),
            const SizedBox(height: 24),

            // Berita
            _SectionHeader(
              icon: Icons.article_rounded,
              title: 'Berita Kesehatan',
              subtitle: 'Tetap up-to-date soal kesehatan',
            ),
            const SizedBox(height: 12),
            if (_isLoadingNews)
              _buildNewsLoading()
            else if (_newsArticles.isEmpty)
              _buildNewsEmpty()
            else
              _buildNewsSection(),
            const SizedBox(height: 24),

            // Obat
            _SectionHeader(
              icon: Icons.medical_services_rounded,
              title: 'Obat yang Saya Miliki',
              subtitle: 'Pantau stok & masa kedaluwarsa',
            ),
            const SizedBox(height: 12),
            if (_myMedicines.isEmpty)
              _buildEmptyMedicines()
            else
              _buildMyMedicinesSection(),
          ],
        ),
      ),
    );
  }

  // ================== JADWAL ==================

  Widget _buildJadwalSection() {
    if (_jadwalList.isEmpty) {
      return _GlassCard(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kPrimarySoft.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 34,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum Ada Jadwal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextMain,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Atur jadwal minum obat agar kamu nggak lupa.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kTextMuted),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const JadwalTersimpanPage(),
                  ),
                ).then((_) => _loadJadwal());
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Tambah Jadwal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final displayJadwal = _jadwalList.take(3).toList();

    return Column(
      children: [
        ...displayJadwal.asMap().entries.map((entry) {
          final idx = entry.key;
          final jadwal = entry.value;
          return _buildJadwalCard(jadwal, idx);
        }),
        if (_jadwalList.length > 3) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const JadwalTersimpanPage(),
                  ),
                ).then((_) => _loadJadwal());
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat ${_jadwalList.length - 3} jadwal lainnya',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: kPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> jadwal, int index) {
    final String namaObat = jadwal['namaObat'] ?? jadwal['nama_obat'] ?? 'Obat';
    final String waktu = jadwal['waktu'] ?? jadwal['jam'] ?? '-';

    // Ambil gambar dari data jadwal atau cari di MyMedicines sebagai fallback
    String? linkGambar = jadwal['link_gambar'] as String?;

    // Jika link_gambar kosong atau null, cari di MyMedicines
    if (linkGambar == null || linkGambar.isEmpty) {
      try {
        final medicine = _myMedicines.firstWhere(
          (m) =>
              m.namaObat.toLowerCase().trim() == namaObat.toLowerCase().trim(),
        );
        linkGambar = medicine.linkGambar;
      } catch (e) {
        linkGambar = null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: kPrimary.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: linkGambar != null && linkGambar.isNotEmpty
                  ? Colors.grey[200]
                  : null,
              gradient: linkGambar == null || linkGambar.isEmpty
                  ? const LinearGradient(
                      colors: [kPrimary, Color(0xFF60A5FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: linkGambar != null && linkGambar.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      linkGambar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.medication_liquid_rounded,
                          color: Colors.white,
                          size: 26,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.medication_liquid_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
          ),
          const SizedBox(width: 14),
          // info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        namaObat,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kTextMain,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        jadwal['frekuensi'] ?? 'Harian',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: kTextMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      waktu,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.local_pharmacy_rounded,
                      size: 14,
                      color: kTextMuted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${jadwal['jumlah'] ?? '1'} ${jadwal['satuan'] ?? 'tablet'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kTextMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // button
          FutureBuilder<bool>(
            future: _canTakeMedicine(namaObat, waktu),
            builder: (context, snapshot) {
              final canTake = snapshot.data ?? true;
              final isEnabled = canTake;

              return Material(
                color: isEnabled
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: isEnabled
                      ? () => _tandaiSudahMinum(jadwal, index)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEnabled
                              ? Icons.check_rounded
                              : Icons.schedule_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isEnabled ? 'Sudah' : 'Tunggu',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================== BERITA ==================

  Widget _buildNewsLoading() {
    return _GlassCard(
      height: 180,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
        ),
      ),
    );
  }

  Widget _buildNewsEmpty() {
    return _GlassCard(
      child: Column(
        children: const [
          Icon(Icons.newspaper_rounded, size: 40, color: kPrimary),
          SizedBox(height: 10),
          Text(
            'Berita tidak tersedia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kTextMain,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Saat ini tidak ada berita kesehatan yang bisa ditampilkan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _newsArticles.length > 5 ? 5 : _newsArticles.length,
        itemBuilder: (context, index) {
          final article = _newsArticles[index];
          return _buildNewsCard(article);
        },
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailPage(article: article)),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: article.urlToImage != null
                  ? Image.network(
                      article.urlToImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimary, Color(0xFF60A5FA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.article_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 150,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimary, Color(0xFF60A5FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.article_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            // content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // source & time
                    Row(
                      children: [
                        if (article.sourceName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimarySoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              article.sourceName!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: kTextMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _formatDate(article.publishedAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: kTextMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kTextMain,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Text(
                          'Baca selengkapnya',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: kPrimary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== OBAT SAYA ==================

  Widget _buildEmptyMedicines() {
    return _GlassCard(
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: kPrimarySoft.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 38,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Obat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextMain,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tambahkan obat yang kamu punya atau beli langsung dari toko.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kTextMuted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddMedicinePage(),
                      ),
                    );
                    _loadMyMedicines();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Tambah Obat',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _selectedIndex = 1);
                  },
                  icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                  label: const Text(
                    'Ke Toko',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side: const BorderSide(color: kPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyMedicinesSection() {
    final display = _myMedicines.take(3).toList();

    return Column(
      children: [
        ...display.map((m) => _buildMyMedicineCard(m)),
        if (_myMedicines.length > 3) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyMedicinesListPage(),
                  ),
                ).then((_) => _loadMyMedicines());
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                'Lihat semua (${_myMedicines.length} obat)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMyMedicineCard(MyMedicine medicine) {
    final isLowStock = medicine.jumlahStok < 5;
    final isExpiringSoon =
        medicine.tanggalKadaluarsa != null &&
        DateTime.parse(
              medicine.tanggalKadaluarsa!,
            ).difference(DateTime.now()).inDays <
            30;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailMyMedicinePage(medicine: medicine),
              ),
            );
            if (result == true) _loadMyMedicines();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFF9FAFB),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: medicine.linkGambar != null
                        ? (medicine.linkGambar!.startsWith('http')
                              ? Image.network(
                                  medicine.linkGambar!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.medication_rounded,
                                        size: 28,
                                        color: Color(0xFF94A3B8),
                                      ),
                                )
                              : Image.file(
                                  File(medicine.linkGambar!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.medication_rounded,
                                        size: 28,
                                        color: Color(0xFF94A3B8),
                                      ),
                                ))
                        : const Icon(
                            Icons.medication_rounded,
                            size: 28,
                            color: Color(0xFF94A3B8),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.namaObat,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kTextMain,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (medicine.sumber == 'pembelian'
                                          ? const Color(0xFFDCFCE7)
                                          : kPrimarySoft)
                                      .withOpacity(0.9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              medicine.sumber == 'pembelian'
                                  ? 'Pembelian'
                                  : 'Manual',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: medicine.sumber == 'pembelian'
                                    ? const Color(0xFF15803D)
                                    : kPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (medicine.dosis != null &&
                              medicine.dosis!.isNotEmpty)
                            Expanded(
                              child: Text(
                                medicine.dosis!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kTextMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            size: 15,
                            color: isLowStock
                                ? Colors.red.shade600
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stok: ${medicine.jumlahStok}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isLowStock
                                  ? Colors.red.shade600
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isLowStock || isExpiringSoon)
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  size: 14,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isExpiringSoon
                                      ? 'Segera kedaluwarsa'
                                      : 'Stok menipis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================== WIDGET TAMBAHAN (JUARA STYLE) ==================

class _HeroDashboardCard extends StatelessWidget {
  final int totalObat;
  final int totalJadwal;

  const _HeroDashboardCard({
    required this.totalObat,
    required this.totalJadwal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: kCard,
        border: Border.all(color: Colors.grey.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: kPrimary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kPrimarySoft.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    size: 16,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Ringkasan Hari Ini',
                  style: TextStyle(
                    color: kTextMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Pantau obat, jadwal, dan stok dalam satu tampilan.',
              style: TextStyle(
                color: kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: 'Total Obat',
                    value: '$totalObat',
                    icon: Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryChip(
                    label: 'Jadwal Aktif',
                    value: '$totalJadwal',
                    icon: Icons.event_note_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimarySoft.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimary.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimary.withOpacity(0.15),
            ),
            child: Icon(icon, size: 15, color: kPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: kTextMuted.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: kPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextMain,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 12, color: kTextMuted),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: kPrimary,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;

  const _GlassCard({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: kPrimary.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
