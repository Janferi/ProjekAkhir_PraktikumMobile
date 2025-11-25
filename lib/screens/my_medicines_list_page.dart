import 'package:flutter/material.dart';
import 'package:tugasakhir/db/database_helper.dart';
import 'package:tugasakhir/models/my_medicine_model.dart';
import 'package:tugasakhir/screens/detail_my_medicine_page.dart';

class MyMedicinesListPage extends StatefulWidget {
  const MyMedicinesListPage({super.key});

  @override
  State<MyMedicinesListPage> createState() => _MyMedicinesListPageState();
}

class _MyMedicinesListPageState extends State<MyMedicinesListPage> {
  List<MyMedicine> _myMedicines = [];
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadMyMedicines();
  }

  Future<void> _loadMyMedicines() async {
    setState(() => _isLoading = true);
    final medicines = await _dbHelper.getMyMedicines();
    setState(() {
      _myMedicines = medicines;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Obat yang Saya Miliki',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myMedicines.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myMedicines.length,
              itemBuilder: (context, index) {
                final medicine = _myMedicines[index];
                return _buildMedicineCard(medicine);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              size: 50,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Obat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan obat untuk memulai',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(MyMedicine medicine) {
    final DateTime kadaluarsa = DateTime.parse(
      medicine.tanggalKadaluarsa ?? '2099-12-31',
    );
    final int daysUntilExpired = kadaluarsa.difference(DateTime.now()).inDays;
    final bool isExpiringSoon = daysUntilExpired <= 30 && daysUntilExpired > 0;
    final bool isExpired = daysUntilExpired <= 0;
    final bool isLowStock = medicine.jumlahStok <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? Colors.red.withOpacity(0.3)
              : isExpiringSoon
              ? Colors.orange.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
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
                builder: (_) => DetailMyMedicinePage(medicine: medicine),
              ),
            ).then((_) => _loadMyMedicines());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      medicine.linkGambar != null &&
                          medicine.linkGambar!.isNotEmpty
                      ? Image.network(
                          medicine.linkGambar!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF3B82F6).withOpacity(0.7),
                                    const Color(0xFF2563EB),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.medical_services,
                                color: Colors.white,
                                size: 35,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6).withOpacity(0.7),
                                const Color(0xFF2563EB),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.medical_services,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Medicine Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.namaObat,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          medicine.sumber ?? 'Tambah Manual',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (medicine.dosis != null && medicine.dosis!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            medicine.dosis!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_rounded,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stok: ${medicine.jumlahStok}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isLowStock
                                  ? Colors.orange
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          if (isLowStock) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.warning_rounded,
                              size: 14,
                              color: Colors.orange,
                            ),
                          ],
                        ],
                      ),
                      if (isExpired || isExpiringSoon) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: isExpired ? Colors.red : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isExpired
                                    ? 'Sudah kadaluarsa!'
                                    : 'Kadaluarsa dalam $daysUntilExpired hari',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isExpired ? Colors.red : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
