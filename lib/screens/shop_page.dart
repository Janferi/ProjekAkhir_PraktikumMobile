import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tugasakhir/screens/detail_obat_shop_page.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<dynamic> _allObat = [];
  List<dynamic> _filteredObat = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = [
    'Semua',
    'Obat Bebas',
    'Obat Ringan',
    'Obat Keras',
    'Obat Keras Khusus',
    'Obat Narkotika & Psikotropika',
  ];

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _searchObat(String query) {
    var hasil = _allObat.where((obat) {
      final nama = obat['nama_obat'].toString().toLowerCase();
      return nama.contains(query.toLowerCase());
    });

    if (_selectedFilter != 'Semua') {
      hasil = hasil.where((obat) {
        final kategori = obat['kategori']?.toString() ?? '';
        return kategori == _selectedFilter;
      });
    }

    setState(() => _filteredObat = hasil.toList());
  }

  void _applyFilter(String filter) {
    setState(() => _selectedFilter = filter);
    _searchObat(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _searchObat,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Cari obat yang ingin dibeli...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 22,
                  color: Color(0xFF6B7280),
                ),
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
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) => _applyFilter(filter),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF3B82F6).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF3B82F6),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF6B7280),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFE5E7EB),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchDataObat,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                    )
                  : _filteredObat.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 80,
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
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredObat.length,
                      itemBuilder: (context, index) {
                        final obat = _filteredObat[index];
                        // Generate harga random antara 10000 - 200000
                        final harga = 10000 + (index * 5000) % 190000;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailObatShopPage(
                                      obat: obat,
                                      harga: harga.toDouble(),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Gambar Obat
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    child: Container(
                                      height: 140,
                                      width: double.infinity,
                                      color: const Color(0xFFF1F5F9),
                                      child: Image.network(
                                        obat['link_gambar'] ?? '',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    Icons.medication_outlined,
                                                    size: 48,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),

                                  // Info Obat
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
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
                                              fontSize: 14,
                                              color: Color(0xFF1F2937),
                                              height: 1.2,
                                            ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Rp ${harga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF3B82F6),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF3B82F6,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF3B82F6,
                                                      ).withOpacity(0.3),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.add_shopping_cart,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
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
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
