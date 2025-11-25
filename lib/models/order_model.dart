class Order {
  final int? id;
  final String tanggal;
  final double totalHarga;
  final String status;
  final String alamatPengiriman;
  final String namaPenerima;
  final String nomorTelepon;
  final List<OrderItem>? items;

  Order({
    this.id,
    required this.tanggal,
    required this.totalHarga,
    required this.status,
    required this.alamatPengiriman,
    required this.namaPenerima,
    required this.nomorTelepon,
    this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal,
      'total_harga': totalHarga,
      'status': status,
      'alamat_pengiriman': alamatPengiriman,
      'nama_penerima': namaPenerima,
      'nomor_telepon': nomorTelepon,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      tanggal: map['tanggal'],
      totalHarga: map['total_harga'].toDouble(),
      status: map['status'],
      alamatPengiriman: map['alamat_pengiriman'],
      namaPenerima: map['nama_penerima'],
      nomorTelepon: map['nomor_telepon'],
    );
  }
}

class OrderItem {
  final int? id;
  final int orderId;
  final String namaObat;
  final String linkGambar;
  final double harga;
  final int jumlah;

  OrderItem({
    this.id,
    required this.orderId,
    required this.namaObat,
    required this.linkGambar,
    required this.harga,
    required this.jumlah,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'nama_obat': namaObat,
      'link_gambar': linkGambar,
      'harga': harga,
      'jumlah': jumlah,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      namaObat: map['nama_obat'],
      linkGambar: map['link_gambar'],
      harga: map['harga'].toDouble(),
      jumlah: map['jumlah'],
    );
  }

  double get subtotal => harga * jumlah;
}
