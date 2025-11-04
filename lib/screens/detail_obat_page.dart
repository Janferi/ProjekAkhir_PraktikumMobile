import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'jadwal_page.dart';

class DetailObatPage extends StatefulWidget {
  final Map<String, dynamic> obat;

  const DetailObatPage({super.key, required this.obat});

  @override
  State<DetailObatPage> createState() => _DetailObatPageState();
}

class _DetailObatPageState extends State<DetailObatPage> {
  String selectedCurrency = "IDR";
  final Map<String, double> rates = {
    "IDR": 1.0,
    "USD": 0.000063,
    "EUR": 0.000059,
    "JPY": 0.0095,
  };

  late int hargaAsli;

  @override
  void initState() {
    super.initState();
    hargaAsli = _extractHarga(widget.obat['harga']);
  }

  int _extractHarga(String hargaText) {
    final match = RegExp(r'[\d.]+').firstMatch(hargaText);
    if (match != null) {
      String angkaStr = match.group(0)!;
      angkaStr = angkaStr.replaceAll('.', '');
      return int.tryParse(angkaStr) ?? 0;
    }
    return 0;
  }

  String _formatHarga(double value, String currency) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );
    return format.format(value);
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case "USD":
        return "\$";
      case "EUR":
        return "€";
      case "JPY":
        return "¥";
      default:
        return "Rp ";
    }
  }

  Future<void> _simpanInfo() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('saved_obat') ?? [];
    final currentData = jsonEncode(widget.obat);

    if (savedList.contains(currentData)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text("Obat ini sudah disimpan sebelumnya!"),
            ],
          ),
          backgroundColor: Color(0xFF3B82F6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    savedList.add(currentData);
    await prefs.setStringList('saved_obat', savedList);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text("Info obat berhasil disimpan!"),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDetailItem(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final obat = widget.obat;
    double hargaConverted = hargaAsli * rates[selectedCurrency]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Detail Obat",
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Gambar FULL seperti sebelumnya
            Container(
              height: 250,
              width: double.infinity,
              child: ClipRRect(
                child: Image.network(
                  obat['link_gambar'],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    width: double.infinity,
                    color: Color(0xFFEFF6FF),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 60,
                          color: Color(0xFF3B82F6),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gambar tidak tersedia',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Nama obat di bawah gambar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                obat['nama_obat'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Konten utama
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card konversi mata uang
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Konversi Harga",
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatHarga(
                                      hargaConverted,
                                      selectedCurrency,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Dropdown dengan style yang diperbaiki
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(0xFFE5E7EB)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedCurrency,
                                    icon: const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: Color(0xFF3B82F6),
                                        size: 24,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                      fontSize: 16,
                                    ),
                                    dropdownColor: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    items: rates.keys.map((String key) {
                                      return DropdownMenuItem<String>(
                                        value: key,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCurrency = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Detail informasi obat
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Informasi Obat",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailItem(
                            "Deskripsi",
                            obat['deskripsi'] ?? 'Tidak ada data',
                          ),
                          _buildDetailItem(
                            "Kandungan",
                            obat['kandungan'] ?? 'Tidak ada data',
                          ),
                          _buildDetailItem(
                            "Efek Samping",
                            obat['efek_samping'] ?? 'Tidak ada data',
                          ),
                          _buildDetailItem(
                            "Anjuran Pemakaian",
                            obat['anjuran_pemakaian'] ?? 'Tidak ada data',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tombol aksi
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _simpanInfo,
                            icon: const Icon(
                              Icons.bookmark_add_rounded,
                              size: 22,
                            ),
                            label: const Text(
                              "Simpan Info",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 56,
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JadwalPage(obat: widget.obat),
                                ),
                              );
                            },
                            icon: const Icon(Icons.schedule_rounded, size: 22),
                            label: const Text(
                              "Buat Jadwal",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
