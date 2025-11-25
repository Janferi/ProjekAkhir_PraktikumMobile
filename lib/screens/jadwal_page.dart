import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasakhir/utils/notification_service.dart';

class JadwalPage extends StatefulWidget {
  final Map<String, dynamic> obat;

  const JadwalPage({super.key, required this.obat});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  TimeOfDay? selectedTime;
  final TextEditingController _timeController = TextEditingController();

  // Instance notification service
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _timeController.text = "Pilih waktu konsumsi";
    // Inisialisasi notification service
    _initializeNotification();
  }

  // Inisialisasi notifikasi
  Future<void> _initializeNotification() async {
    await _notificationService.initialize();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onSurface: Colors.black87,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        _timeController.text = selectedTime!.format(context);
      });
    }
  }

  // Simpan jadwal minum obat ke SharedPreferences + set notifikasi
  Future<void> _simpanJadwal() async {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon pilih waktu konsumsi terlebih dahulu"),
        ),
      );
      return;
    }

    // Ambil data jadwal yang sudah ada
    final prefs = await SharedPreferences.getInstance();
    List<String> jadwalList = prefs.getStringList('saved_jadwal') ?? [];

    // Format waktu ke HH:mm
    final int hour = selectedTime!.hour;
    final int minute = selectedTime!.minute;
    final String waktu =
        "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";

    // Buat object jadwal
    final jadwalData = {
      "namaObat": widget.obat["nama_obat"],
      "nama_obat": widget.obat["nama_obat"],
      "waktu": waktu,
      "jam": waktu,
      "jumlah": widget.obat["dosis"] ?? "1",
      "satuan": "tablet",
      "frekuensi": "Harian",
      "tanggal_buat": DateTime.now().toIso8601String(),
      "status": "Aktif",
      "link_gambar": widget.obat['link_gambar'],
    };

    // Simpan ke SharedPreferences
    jadwalList.add(jsonEncode(jadwalData));
    await prefs.setStringList('saved_jadwal', jadwalList);

    // Tampilkan notifikasi instant bahwa jadwal berhasil dibuat
    await _notificationService.showInstantNotification(
      title: '✅ Jadwal Berhasil Dibuat!',
      body:
          'Anda baru saja membuat jadwal untuk ${widget.obat["nama_obat"]} pada pukul ${_timeController.text}',
      payload: 'jadwal_created',
    );

    // Schedule notifikasi untuk waktu yang dipilih
    final now = DateTime.now();
    DateTime scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Jika waktu yang dipilih sudah lewat hari ini, jadwalkan untuk besok
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    // Set notifikasi scheduled
    await _notificationService.scheduleNotification(
      id: scheduledDateTime.millisecondsSinceEpoch ~/ 1000,
      title: '💊 Waktunya Minum Obat!',
      body: 'Saatnya konsumsi ${widget.obat["nama_obat"]}',
      scheduledTime: scheduledDateTime,
      payload: 'reminder_${widget.obat["nama_obat"]}',
    );

    // Tampilkan notifikasi sukses
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Jadwal berhasil disimpan!"),
        backgroundColor: Colors.green,
      ),
    );

    // Kembali ke dashboard
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obat = widget.obat;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Buat Jadwal Obat"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Obat yang dijadwalkan:",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      obat['nama_obat'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      obat['anjuran_pemakaian'] ??
                          'Anjuran pemakaian tidak tersedia.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Pilih Waktu Konsumsi:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              readOnly: true,
              onTap: () => _selectTime(context),
              decoration: InputDecoration(
                labelText: "Waktu (Jam:Menit)",
                hintText: "Ketuk untuk memilih",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                prefixIcon: const Icon(
                  Icons.access_time,
                  color: Colors.blueAccent,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.schedule, color: Colors.blueAccent),
                  onPressed: () => _selectTime(context),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                'Anda akan menerima notifikasi saat membuat jadwal dan pengingat saat waktunya minum obat.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _simpanJadwal,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  "Simpan Jadwal",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
