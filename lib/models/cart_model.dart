class CartItem {
  final int? id;
  final String namaObat;
  final String linkGambar;
  final double harga;
  final int jumlah;
  final String deskripsi;

  CartItem({
    this.id,
    required this.namaObat,
    required this.linkGambar,
    required this.harga,
    required this.jumlah,
    required this.deskripsi,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_obat': namaObat,
      'link_gambar': linkGambar,
      'harga': harga,
      'jumlah': jumlah,
      'deskripsi': deskripsi,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      namaObat: map['nama_obat'],
      linkGambar: map['link_gambar'],
      harga: map['harga'].toDouble(),
      jumlah: map['jumlah'],
      deskripsi: map['deskripsi'],
    );
  }

  double get subtotal => harga * jumlah;
}
