import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasakhir/screens/jadwal_page_list.dart';
import 'package:tugasakhir/screens/login_page.dart';
import 'package:tugasakhir/screens/lokasi_page.dart';
import 'package:tugasakhir/screens/profil_page.dart';
import 'package:tugasakhir/screens/detail_obat_page.dart';
import 'package:tugasakhir/screens/saved_obat_page.dart';
import 'package:tugasakhir/screens/saran_page.dart'; // Pastikan file ini ada

class DashboardPage extends StatefulWidget {
  final String username;
  const DashboardPage({super.key, required this.username});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allObat = [];
  List<dynamic> _filteredObat = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDataObat();
  }

  Future<void> _fetchDataObat() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://apimobelmedicine.vercel.app/data_obat.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> listObat = data['data_obat'];

        setState(() {
          _allObat = listObat;
          _filteredObat = listObat;
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data obat');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mengambil data: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _searchObat(String query) {
    final hasil = _allObat.where((obat) {
      final nama = obat['nama_obat'].toString().toLowerCase();
      return nama.contains(query.toLowerCase());
    }).toList();

    setState(() => _filteredObat = hasil);
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildBeranda(context),
      const LokasiPage(),
      const SaranPage(), // Halaman saran baru
      ProfilPage(username: widget.username),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        title: Text(
          _selectedIndex == 0
              ? 'Halo, ${widget.username} 👋'
              : _selectedIndex == 1
              ? 'Lokasi Apotek'
              : _selectedIndex == 2
              ? 'Saran Obat'
              : 'Profil',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        bottom: _selectedIndex == 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(64.0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchObat,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Cari nama obat...',
                      prefixIcon: const Icon(Icons.search, size: 22),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF3B82F6),
            unselectedItemColor: const Color(0xFF6B7280),
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedIndex == 0
                        ? const Color(0xFF3B82F6).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    color: _selectedIndex == 0
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF6B7280),
                    size: 22, // Sedikit diperkecil agar muat 4 item
                  ),
                ),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedIndex == 1
                        ? const Color(0xFF3B82F6).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: _selectedIndex == 1
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF6B7280),
                    size: 22,
                  ),
                ),
                label: 'Lokasi',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedIndex == 2
                        ? const Color(0xFF3B82F6).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.medical_services_rounded,
                    color: _selectedIndex == 2
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF6B7280),
                    size: 22,
                  ),
                ),
                label: 'Saran',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedIndex == 3
                        ? const Color(0xFF3B82F6).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: _selectedIndex == 3
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF6B7280),
                    size: 22,
                  ),
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeranda(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          const Text(
            'Fitur Cepat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _featureCard(
                  color: const Color(0xFF3B82F6),
                  icon: Icons.schedule_rounded,
                  text: "Jadwal Obat",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const JadwalTersimpanPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _featureCard(
                  color: const Color(0xFF10B981),
                  icon: Icons.bookmark_rounded,
                  text: "Obat Disimpan",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiwayatDisimpanPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Daftar Obat Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Obat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                '${_filteredObat.length} obat',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List Obat
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                )
              : _filteredObat.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak ada obat ditemukan',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredObat.length,
                  itemBuilder: (context, index) {
                    final obat = _filteredObat[index];
                    final deskripsi =
                        obat['deskripsi']?.toString() ?? 'Tidak ada data';
                    final teksPendek = deskripsi.length > 100
                        ? '${deskripsi.substring(0, 100)}...'
                        : deskripsi;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailObatPage(obat: obat),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Gambar Obat
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      obat['link_gambar'] ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: const Color(0xFFF1F5F9),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.medication_outlined,
                                                  size: 32,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Info Obat
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        obat['nama_obat'] ?? 'Tanpa Nama',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Color(0xFF1F2937),
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        teksPendek,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color(0xFF6B7280),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'Lihat Detail',
                                            style: TextStyle(
                                              color: const Color(0xFF3B82F6),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 16,
                                            color: const Color(0xFF3B82F6),
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
                  },
                ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required Color color,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
