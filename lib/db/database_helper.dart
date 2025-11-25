import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';
import '../models/my_medicine_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE cart (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_obat TEXT NOT NULL,
          link_gambar TEXT,
          harga REAL NOT NULL,
          jumlah INTEGER NOT NULL,
          deskripsi TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tanggal TEXT NOT NULL,
          total_harga REAL NOT NULL,
          status TEXT NOT NULL,
          alamat_pengiriman TEXT NOT NULL,
          nama_penerima TEXT NOT NULL,
          nomor_telepon TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          nama_obat TEXT NOT NULL,
          link_gambar TEXT,
          harga REAL NOT NULL,
          jumlah INTEGER NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE my_medicines (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_obat TEXT NOT NULL,
          link_gambar TEXT,
          deskripsi TEXT,
          komposisi TEXT,
          dosis TEXT,
          jenis_obat TEXT,
          jumlah_stok INTEGER NOT NULL,
          tanggal_kadaluarsa TEXT,
          sumber TEXT NOT NULL,
          tanggal_ditambahkan TEXT NOT NULL
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_obat TEXT NOT NULL,
        link_gambar TEXT,
        harga REAL NOT NULL,
        jumlah INTEGER NOT NULL,
        deskripsi TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        total_harga REAL NOT NULL,
        status TEXT NOT NULL,
        alamat_pengiriman TEXT NOT NULL,
        nama_penerima TEXT NOT NULL,
        nomor_telepon TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        nama_obat TEXT NOT NULL,
        link_gambar TEXT,
        harga REAL NOT NULL,
        jumlah INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE my_medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_obat TEXT NOT NULL,
        link_gambar TEXT,
        deskripsi TEXT,
        komposisi TEXT,
        dosis TEXT,
        jenis_obat TEXT,
        jumlah_stok INTEGER NOT NULL,
        tanggal_kadaluarsa TEXT,
        sumber TEXT NOT NULL,
        tanggal_ditambahkan TEXT NOT NULL
      )
    ''');
  } // ===== USER METHODS =====

  Future<int> insertUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUser(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  // ===== CART METHODS =====
  Future<int> addToCart(CartItem item) async {
    final db = await database;
    // Check if item already exists
    final existing = await db.query(
      'cart',
      where: 'nama_obat = ?',
      whereArgs: [item.namaObat],
    );

    if (existing.isNotEmpty) {
      // Update quantity
      final currentQty = existing.first['jumlah'] as int;
      return await db.update(
        'cart',
        {'jumlah': currentQty + item.jumlah},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // Insert new item
      return await db.insert('cart', item.toMap());
    }
  }

  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final maps = await db.query('cart');
    return maps.map((map) => CartItem.fromMap(map)).toList();
  }

  Future<int> updateCartItem(int id, int newQuantity) async {
    final db = await database;
    return await db.update(
      'cart',
      {'jumlah': newQuantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCartItem(int id) async {
    final db = await database;
    return await db.delete('cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearCart() async {
    final db = await database;
    return await db.delete('cart');
  }

  Future<int> getCartItemCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(jumlah) as total FROM cart');
    return result.first['total'] as int? ?? 0;
  }

  // ===== ORDER METHODS =====
  // Buat order baru + insert order items
  Future<int> createOrder(Order order, List<CartItem> items) async {
    final db = await database;
    // Insert order dulu, dapat ID-nya
    final orderId = await db.insert('orders', order.toMap());

    // Insert semua order items dengan order_id yang baru
    for (var item in items) {
      final orderItem = OrderItem(
        orderId: orderId,
        namaObat: item.namaObat,
        linkGambar: item.linkGambar,
        harga: item.harga,
        jumlah: item.jumlah,
      );
      await db.insert('order_items', orderItem.toMap());
    }

    return orderId;
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final maps = await db.query('orders', orderBy: 'tanggal DESC');
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  Future<Order?> getOrderById(int id) async {
    final db = await database;
    final maps = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;
    final maps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return maps.map((map) => OrderItem.fromMap(map)).toList();
  }

  Future<int> updateOrderStatus(int orderId, String newStatus) async {
    final db = await database;
    return await db.update(
      'orders',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ===== MY MEDICINES METHODS =====
  Future<int> insertMyMedicine(MyMedicine medicine) async {
    final db = await database;
    return await db.insert('my_medicines', medicine.toMap());
  }

  Future<List<MyMedicine>> getMyMedicines() async {
    final db = await database;
    final maps = await db.query(
      'my_medicines',
      orderBy: 'tanggal_ditambahkan DESC',
    );
    return maps.map((map) => MyMedicine.fromMap(map)).toList();
  }

  Future<int> updateMyMedicine(int id, MyMedicine medicine) async {
    final db = await database;
    return await db.update(
      'my_medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMyMedicine(int id) async {
    final db = await database;
    return await db.delete('my_medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateMedicineStock(int id, int newStock) async {
    final db = await database;
    return await db.update(
      'my_medicines',
      {'jumlah_stok': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
