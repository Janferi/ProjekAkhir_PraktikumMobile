import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailJadwalPage extends StatefulWidget {
  final Map<String, dynamic> jadwal;

  const DetailJadwalPage({super.key, required this.jadwal});

  @override
  State<DetailJadwalPage> createState() => _DetailJadwalPageState();
}

class _DetailJadwalPageState extends State<DetailJadwalPage> {
  String selectedZone = "WIB";
  String convertedTime = "";
  late TextEditingController hourController;
  late TextEditingController minuteController;

  @override
  void initState() {
    super.initState();
    final jam = widget.jadwal["jam"] ?? "00:00";
    final parts = jam.split(":");
    hourController = TextEditingController(text: parts[0]);
    minuteController = TextEditingController(text: parts[1]);
    _convertTime();
  }

  void _convertTime() {
    final jam = widget.jadwal["jam"];
    if (jam == null || jam.isEmpty) return;

    final parts = jam.split(":");
    if (parts.length != 2) return;

    final int hour = int.tryParse(parts[0]) ?? 0;
    final int minute = int.tryParse(parts[1]) ?? 0;

    DateTime baseTime = DateTime(2025, 1, 1, hour, minute);

    Duration offset;
    switch (selectedZone) {
      case "WITA":
        offset = const Duration(hours: 1);
        break;
      case "WIT":
        offset = const Duration(hours: 2);
        break;
      case "London":
        offset = const Duration(hours: -7);
        break;
      default: // WIB
        offset = const Duration(hours: 0);
    }

    final newTime = baseTime.add(offset);
    setState(() {
      convertedTime =
          "${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')} $selectedZone";
    });
  }

  Future<void> _updateJadwal() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList('saved_jadwal');
    if (data == null) return;

    final List<Map<String, dynamic>> jadwalList = data
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    final index = jadwalList.indexWhere(
      (e) =>
          e["nama_obat"] == widget.jadwal["nama_obat"] &&
          e["jam"] == widget.jadwal["jam"],
    );

    if (index != -1) {
      final int hour = int.tryParse(hourController.text) ?? 0;
      final int minute = int.tryParse(minuteController.text) ?? 0;

      jadwalList[index]["jam"] =
          "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";

      await prefs.setStringList(
        'saved_jadwal',
        jadwalList.map((e) => jsonEncode(e)).toList(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Jadwal berhasil diperbarui!'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _hapusJadwal() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hapus Jadwal'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              final List<String>? data = prefs.getStringList('saved_jadwal');
              if (data == null) return;

              final List<Map<String, dynamic>> jadwalList = data
                  .map((e) => jsonDecode(e) as Map<String, dynamic>)
                  .toList();

              jadwalList.removeWhere(
                (e) =>
                    e["nama_obat"] == widget.jadwal["nama_obat"] &&
                    e["jam"] == widget.jadwal["jam"],
              );

              await prefs.setStringList(
                'saved_jadwal',
                jadwalList.map((e) => jsonEncode(e)).toList(),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Jadwal berhasil dihapus'),
                    ],
                  ),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jadwal = widget.jadwal;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Detail Jadwal',
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
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 22),
            onPressed: _hapusJadwal,
            tooltip: "Hapus Jadwal",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Obat
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication_rounded,
                        color: Color(0xFF3B82F6),
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jadwal["nama_obat"] ?? "Tanpa Nama",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Waktu asli: ${jadwal["jam"] ?? '-'} (WIB)",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Edit Waktu Section
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
                    Text(
                      "Edit Waktu Minum",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Jam",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(0xFFE5E7EB)),
                                ),
                                child: TextField(
                                  controller: hourController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "00",
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          ":",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Menit",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(0xFFE5E7EB)),
                                ),
                                child: TextField(
                                  controller: minuteController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "00",
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Konversi Waktu Section
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
                    Text(
                      "Konversi Zona Waktu",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedZone,
                          icon: Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          isExpanded: true,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                            fontSize: 16,
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: const [
                            DropdownMenuItem(
                              value: "WIB",
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text("WIB (UTC+7)"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "WITA",
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text("WITA (UTC+8)"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "WIT",
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text("WIT (UTC+9)"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "London",
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text("London (UTC+0)"),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedZone = value!;
                              _convertTime();
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF3B82F6).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hasil Konversi:",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            convertedTime,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            // Save Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _updateJadwal,
                icon: Icon(Icons.save_rounded, size: 22),
                label: Text(
                  "Simpan Perubahan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
}
