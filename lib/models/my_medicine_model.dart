class MyMedicine {
  final int? id;
  final String namaObat;
  final String? linkGambar;
  final String? deskripsi;
  final String? komposisi;
  final String? dosis;
  final String? jenisObat; // Obat Keras, Obat Bebas, dll
  final int jumlahStok;
  final String? tanggalKadaluarsa;
  final String sumber; // 'manual' atau 'pembelian'
  final String tanggalDitambahkan;

  MyMedicine({
    this.id,
    required this.namaObat,
    this.linkGambar,
    this.deskripsi,
    this.komposisi,
    this.dosis,
    this.jenisObat,
    required this.jumlahStok,
    this.tanggalKadaluarsa,
    required this.sumber,
    required this.tanggalDitambahkan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_obat': namaObat,
      'link_gambar': linkGambar,
      'deskripsi': deskripsi,
      'komposisi': komposisi,
      'dosis': dosis,
      'jenis_obat': jenisObat,
      'jumlah_stok': jumlahStok,
      'tanggal_kadaluarsa': tanggalKadaluarsa,
      'sumber': sumber,
      'tanggal_ditambahkan': tanggalDitambahkan,
    };
  }

  factory MyMedicine.fromMap(Map<String, dynamic> map) {
    return MyMedicine(
      id: map['id'],
      namaObat: map['nama_obat'],
      linkGambar: map['link_gambar'],
      deskripsi: map['deskripsi'],
      komposisi: map['komposisi'],
      dosis: map['dosis'],
      jenisObat: map['jenis_obat'],
      jumlahStok: map['jumlah_stok'] ?? 0,
      tanggalKadaluarsa: map['tanggal_kadaluarsa'],
      sumber: map['sumber'],
      tanggalDitambahkan: map['tanggal_ditambahkan'],
    );
  }
}
