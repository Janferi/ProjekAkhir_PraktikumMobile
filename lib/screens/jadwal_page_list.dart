import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasakhir/db/database_helper.dart';
import 'package:tugasakhir/models/my_medicine_model.dart';
import 'detail_jadwal_page.dart';
import 'jadwal_page.dart';

class JadwalTersimpanPage extends StatefulWidget {
  const JadwalTersimpanPage({super.key});

  @override
  State<JadwalTersimpanPage> createState() => _JadwalTersimpanPageState();
}

class _JadwalTersimpanPageState extends State<JadwalTersimpanPage> {
  List<Map<String, dynamic>> jadwalList = [];

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList('saved_jadwal');
    if (data != null) {
      setState(() {
        jadwalList = data
            .map((e) => jsonDecode(e) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  Future<void> _showPilihObatDialog() async {
    final dbHelper = DatabaseHelper.instance;
    final medicines = await dbHelper.getMyMedicines();

    if (medicines.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada obat. Tambahkan obat terlebih dahulu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.medication_rounded, color: Color(0xFF3B82F6)),
                    SizedBox(width: 12),
                    Text(
                      'Pilih Obat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // List obat
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: medicine.linkGambar != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    medicine.linkGambar!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.medical_services_rounded,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.medical_services_rounded,
                                  color: Color(0xFF3B82F6),
                                ),
                        ),
                        title: Text(
                          medicine.namaObat,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        subtitle: Text(
                          'Stok: ${medicine.jumlahStok}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JadwalPage(
                                obat: {
                                  'nama_obat': medicine.namaObat,
                                  'link_gambar': medicine.linkGambar,
                                  'dosis': medicine.dosis,
                                },
                              ),
                            ),
                          );
                          _loadJadwal();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Jadwal Minum Obat',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Color(0xFF3B82F6),
        centerTitle: false,
      ),
      body: jadwalList.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF3B82F6).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${jadwalList.length} jadwal minum obat tersimpan',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // List Jadwal
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: jadwalList.length,
                    itemBuilder: (context, index) {
                      final jadwal = jadwalList[index];
                      return _buildJadwalCard(jadwal, context);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: jadwalList.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showPilihObatDialog,
              backgroundColor: const Color(0xFF3B82F6),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Tambah Jadwal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_rounded,
                size: 50,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Jadwal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat jadwal minum obat pertama Anda\nuntuk mengatur pengobatan dengan baik',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showPilihObatDialog,
                icon: Icon(Icons.add_rounded, size: 22),
                label: Text(
                  'Buat Jadwal Pertama',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> jadwal, BuildContext context) {
    final String? linkGambar = jadwal['link_gambar'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
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
                builder: (_) => DetailJadwalPage(jadwal: jadwal),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Gambar obat atau icon dengan background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: linkGambar != null && linkGambar.isNotEmpty
                        ? Colors.grey[200]
                        : Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    gradient: linkGambar == null || linkGambar.isEmpty
                        ? LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: linkGambar != null && linkGambar.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            linkGambar,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.medication_rounded,
                                color: Color(0xFF3B82F6),
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.medication_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                // Info jadwal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jadwal['nama_obat'] ?? 'Tanpa nama',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Waktu: ${jadwal['jam'] ?? '-'}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (jadwal['hari'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          "Hari: ${jadwal['hari']}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
