import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../models/provider.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/transaction.dart' as models;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'taurostockv1.db');

    return await openDatabase(
      path,
      version: 5, // ← CAMBIADO: De 4 a 5
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        print('🔄 Actualizando DB de versión $oldVersion a $newVersion');
        
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE products ADD COLUMN imagePath TEXT');
            print('✅ imagePath agregado a products');
          } catch (e) {
            print('⚠️ Error en imagePath: $e');
          }
        }
        
        if (oldVersion < 3) {
          try {
            final tableInfo = await db.rawQuery('PRAGMA table_info(clients)');
            final hasIdentification = tableInfo.any((col) => col['name'] == 'identification');
            
            if (!hasIdentification) {
              await db.execute('ALTER TABLE clients ADD COLUMN identification TEXT');
              print('✅ Columna identification agregada a clients');
            } else {
              print('ℹ️ Columna identification ya existe en clients');
            }
          } catch (e) {
            print('⚠️ Error agregando identification: $e');
          }
        }

        if (oldVersion < 4) {
          try {
            await db.execute('''
              CREATE TABLE transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                description TEXT NOT NULL,
                amount REAL NOT NULL,
                type TEXT NOT NULL,
                category TEXT NOT NULL,
                date TEXT NOT NULL,
                notes TEXT,
                isActive INTEGER DEFAULT 1
              )
            ''');
            print('✅ Tabla transactions creada');
          } catch (e) {
            print('⚠️ Error creando tabla transactions: $e');
          }
        }

        // ← NUEVO: Migración a versión 5 (agregar imagePath a users)
        if (oldVersion < 5) {
          try {
            await db.execute('ALTER TABLE users ADD COLUMN imagePath TEXT');
            print('✅ Columna imagePath agregada a users');
          } catch (e) {
            print('⚠️ Error agregando imagePath a users: $e');
          }
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de usuarios - MODIFICADA: agregado imagePath
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullName TEXT NOT NULL,
        role TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        imagePath TEXT  /* ← NUEVO: Columna para foto de perfil */
      )
    ''');

    // Tabla de productos
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        costPrice REAL NOT NULL,
        salePrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        minStock INTEGER NOT NULL,
        barcode TEXT UNIQUE,
        category TEXT,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Tabla de clientes
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT UNIQUE,
        address TEXT,
        identification TEXT,
        totalPurchases REAL DEFAULT 0,
        accountBalance REAL DEFAULT 0,
        createdAt TEXT NOT NULL,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Tabla de proveedores
    await db.execute('''
      CREATE TABLE providers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT UNIQUE,
        address TEXT,
        city TEXT,
        taxId TEXT,
        totalPurchases REAL DEFAULT 0,
        accountBalance REAL DEFAULT 0,
        createdAt TEXT NOT NULL,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Tabla de ventas
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        total REAL NOT NULL,
        discount REAL DEFAULT 0,
        finalAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        saleDate TEXT NOT NULL,
        status TEXT DEFAULT 'completada',
        notes TEXT,
        FOREIGN KEY (clientId) REFERENCES clients (id)
      )
    ''');

    // Tabla de items de venta
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // Tabla de compras
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        providerId INTEGER NOT NULL,
        total REAL NOT NULL,
        discount REAL DEFAULT 0,
        finalAmount REAL NOT NULL,
        paymentStatus TEXT DEFAULT 'pendiente',
        purchaseDate TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (providerId) REFERENCES providers (id)
      )
    ''');

    // Tabla de items de compra
    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchaseId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        FOREIGN KEY (purchaseId) REFERENCES purchases (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // Tabla de transacciones (ingresos y gastos)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Crear usuario administrador por defecto
    await db.insert('users', {
      'email': 'admin@tauroglosck.com',
      'password': 'admin123',
      'fullName': 'Administrador',
      'role': 'admin',
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': 1,
      'imagePath': null, // ← NUEVO: Inicializar sin foto
    });
    
    print('✅ Base de datos creada con versión $version');
  }

  // ==================== USUARIOS ====================
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? User.fromMap(result.first) : null;
  }

  Future<User?> login(String email, String password) async {
    final user = await getUserByEmail(email);
    if (user != null && user.password == password && user.isActive) {
      return user;
    }
    return null;
  }

  Future<bool> createUser(User user) async {
    try {
      final db = await database;
      await db.insert('users', user.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      final db = await database;
      final count = await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      print('✅ Usuario actualizado: ${user.email}, filas afectadas: $count');
      return count > 0;
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      return false;
    }
  }

  // ==================== PRODUCTOS ====================
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query('products', where: 'isActive = 1');
    
    print('📊 Productos encontrados: ${result.length}');
    
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Product.fromMap(result.first) : null;
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final result =
        await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    return result.isNotEmpty ? Product.fromMap(result.first) : null;
  }

  Future<int> createProduct(Product product) async {
    final db = await database;
    
    final String? barcodeValue = product.barcode.isEmpty ? null : product.barcode;
    
    final Map<String, dynamic> productMap = {
      'name': product.name,
      'description': product.description,
      'costPrice': product.costPrice,
      'salePrice': product.salePrice,
      'quantity': product.quantity,
      'minStock': product.minStock,
      'barcode': barcodeValue,
      'category': product.category,
      'imagePath': product.imagePath,
      'createdAt': product.createdAt.toIso8601String(),
      'isActive': 1,
    };
    
    if (product.id != null) {
      productMap['id'] = product.id;
    }
    
    print('📝 Insertando producto con barcode: ${productMap['barcode'] ?? 'null'}');
    final id = await db.insert('products', productMap);
    print('✅ Producto creado con ID: $id');
    
    return id;
  }

  Future<bool> updateProduct(Product product) async {
    final db = await database;
    
    final String? barcodeValue = product.barcode.isEmpty ? null : product.barcode;
    
    final Map<String, dynamic> productMap = {
      'name': product.name,
      'description': product.description,
      'costPrice': product.costPrice,
      'salePrice': product.salePrice,
      'quantity': product.quantity,
      'minStock': product.minStock,
      'barcode': barcodeValue,
      'category': product.category,
      'imagePath': product.imagePath,
      'createdAt': product.createdAt.toIso8601String(),
      'isActive': 1,
    };
    
    if (product.id != null) {
      productMap['id'] = product.id;
    }
    
    final count = await db.update(
      'products',
      productMap,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    
    print('✅ Producto actualizado: ${product.name}, filas afectadas: $count');
    return count > 0;
  }

  Future<bool> deleteProduct(int id) async {
    final db = await database;
    final count = await db.update(
      'products',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'quantity <= minStock AND isActive = 1',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // ==================== CLIENTES ====================
  Future<List<Client>> getAllClients() async {
    final db = await database;
    final result = await db.query('clients', where: 'isActive = 1');
    
    print('📊 Clientes encontrados: ${result.length}');
    
    return result.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClientById(int id) async {
    final db = await database;
    final result = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Client.fromMap(result.first) : null;
  }

  Future<int> createClient(Client client) async {
    final db = await database;
    
    final Map<String, dynamic> clientMap = {
      'name': client.name,
      'phone': client.phone,
      'email': client.email,
      'address': client.address,
      'identification': client.identification,
      'totalPurchases': client.totalPurchases,
      'accountBalance': client.accountBalance,
      'createdAt': client.createdAt.toIso8601String(),
      'isActive': 1,
    };
    
    if (client.id != null) {
      clientMap['id'] = client.id;
    }
    
    print('📝 Creando cliente: ${client.name}, ID: ${client.identification}');
    final id = await db.insert('clients', clientMap);
    print('✅ Cliente creado con ID: $id');
    
    return id;
  }

  Future<bool> updateClient(Client client) async {
    final db = await database;
    
    final Map<String, dynamic> clientMap = {
      'name': client.name,
      'phone': client.phone,
      'email': client.email,
      'address': client.address,
      'identification': client.identification,
      'totalPurchases': client.totalPurchases,
      'accountBalance': client.accountBalance,
      'createdAt': client.createdAt.toIso8601String(),
      'isActive': 1,
    };
    
    final count = await db.update(
      'clients',
      clientMap,
      where: 'id = ?',
      whereArgs: [client.id],
    );
    
    print('✅ Cliente actualizado: ${client.name}, filas afectadas: $count');
    return count > 0;
  }

  Future<bool> deleteClient(int id) async {
    final db = await database;
    final count = await db.update(
      'clients',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<List<Client>> getClientsWithDebt() async {
    final db = await database;
    final result = await db.query(
      'clients',
      where: 'accountBalance < 0 AND isActive = 1',
    );
    return result.map((map) => Client.fromMap(map)).toList();
  }

  // ==================== PROVEEDORES ====================
  Future<List<ProviderModel>> getAllProviders() async {
    final db = await database;
    final result = await db.query('providers', where: 'isActive = 1');
    return result.map((map) => ProviderModel.fromMap(map)).toList();
  }

  Future<ProviderModel?> getProviderById(int id) async {
    final db = await database;
    final result =
        await db.query('providers', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? ProviderModel.fromMap(result.first) : null;
  }

  Future<int> createProvider(ProviderModel provider) async {
    final db = await database;
    return await db.insert('providers', provider.toMap());
  }

  Future<bool> updateProvider(ProviderModel provider) async {
    final db = await database;
    final count = await db.update(
      'providers',
      provider.toMap(),
      where: 'id = ?',
      whereArgs: [provider.id],
    );
    return count > 0;
  }

  Future<bool> deleteProvider(int id) async {
    final db = await database;
    final count = await db.update(
      'providers',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  // ==================== VENTAS ====================
  Future<int> createSale(Sale sale) async {
    final db = await database;
    final id = await db.insert('sales', sale.toMap());

    if (sale.paymentMethod == 'credito' || sale.status == 'pendiente') {
      await db.rawUpdate(
        'UPDATE clients SET accountBalance = accountBalance - ? WHERE id = ?',
        [sale.finalAmount, sale.clientId],
      );
    }

    return id;
  }

  Future<int> createSaleItem(SaleItem item) async {
    final db = await database;
    return await db.insert('sale_items', item.toMap());
  }

  Future<List<Sale>> getAllSales() async {
    final db = await database;
    final result = await db.query('sales', orderBy: 'saleDate DESC');
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<Sale?> getSaleById(int id) async {
    final db = await database;
    final result = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;

    final sale = Sale.fromMap(result.first);
    final itemsResult =
        await db.query('sale_items', where: 'saleId = ?', whereArgs: [id]);
    sale.items.addAll(
        itemsResult.map((map) => SaleItem.fromMap(map)).toList());
    return sale;
  }

  Future<double> getDailySales(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total FROM sales WHERE date(saleDate) = ?',
      [dateStr],
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'sales',
      where: 'date(saleDate) BETWEEN date(?) AND date(?)',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'saleDate DESC',
    );
    
    List<Sale> sales = [];
    for (var map in result) {
      final sale = Sale.fromMap(map);
      final itemsResult = await db.query(
        'sale_items',
        where: 'saleId = ?',
        whereArgs: [sale.id],
      );
      sale.items.addAll(itemsResult.map((itemMap) => SaleItem.fromMap(itemMap)));
      sales.add(sale);
    }
    
    return sales;
  }

  Future<double> getSalesTotalByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total FROM sales WHERE date(saleDate) BETWEEN date(?) AND date(?)',
      [start.toIso8601String(), end.toIso8601String()]
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  // ==================== COMPRAS ====================
  Future<int> createPurchase(Purchase purchase) async {
    final db = await database;
    final id = await db.insert('purchases', purchase.toMap());
    
    if (purchase.paymentStatus == 'pendiente') {
      await db.rawUpdate(
        'UPDATE providers SET accountBalance = accountBalance + ?, totalPurchases = totalPurchases + ? WHERE id = ?',
        [purchase.finalAmount, purchase.finalAmount, purchase.providerId],
      );
    } else {
      await db.rawUpdate(
        'UPDATE providers SET totalPurchases = totalPurchases + ? WHERE id = ?',
        [purchase.finalAmount, purchase.providerId],
      );
    }
    return id;
  }

  Future<int> createPurchaseItem(PurchaseItem item) async {
    final db = await database;
    return await db.insert('purchase_items', item.toMap());
  }

  Future<List<Purchase>> getAllPurchases() async {
    final db = await database;
    final result = await db.query('purchases', orderBy: 'purchaseDate DESC');
    return result.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<Purchase?> getPurchaseById(int id) async {
    final db = await database;
    final result = await db.query('purchases', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;

    final purchase = Purchase.fromMap(result.first);
    final itemsResult = await db
        .query('purchase_items', where: 'purchaseId = ?', whereArgs: [id]);
    purchase.items.addAll(
        itemsResult.map((map) => PurchaseItem.fromMap(map)).toList());
    return purchase;
  }

  Future<List<Purchase>> getPendingPayments() async {
    final db = await database;
    final result = await db.query(
      'purchases',
      where: 'paymentStatus = ?',
      whereArgs: ['pendiente'],
      orderBy: 'purchaseDate DESC',
    );
    return result.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<bool> updatePurchasePaymentStatus(int purchaseId, String status) async {
    final db = await database;
    final existing = await db.query('purchases', where: 'id = ?', whereArgs: [purchaseId]);
    if (existing.isEmpty) return false;
    final oldPurchase = Purchase.fromMap(existing.first);
    final count = await db.update(
      'purchases',
      {'paymentStatus': status},
      where: 'id = ?',
      whereArgs: [purchaseId],
    );
    if (count > 0) {
      if (oldPurchase.paymentStatus == 'pendiente' && status == 'pagado') {
        await db.rawUpdate(
          'UPDATE providers SET accountBalance = accountBalance - ? WHERE id = ?',
          [oldPurchase.finalAmount, oldPurchase.providerId],
        );
      }
    }
    return count > 0;
  }

  Future<List<Purchase>> getPurchasesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'purchases',
      where: 'date(purchaseDate) BETWEEN date(?) AND date(?)',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'purchaseDate DESC',
    );
    
    List<Purchase> purchases = [];
    for (var map in result) {
      final purchase = Purchase.fromMap(map);
      final itemsResult = await db.query(
        'purchase_items',
        where: 'purchaseId = ?',
        whereArgs: [purchase.id],
      );
      purchase.items.addAll(itemsResult.map((itemMap) => PurchaseItem.fromMap(itemMap)));
      purchases.add(purchase);
    }
    
    return purchases;
  }

  Future<double> getPurchasesTotalByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total FROM purchases WHERE date(purchaseDate) BETWEEN date(?) AND date(?)',
      [start.toIso8601String(), end.toIso8601String()]
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  // ==================== TRANSACCIONES ====================
  Future<List<models.Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    
    final result = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ? AND isActive = 1',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  Future<double> getIncomeTotalByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "ingreso" AND date(date) BETWEEN date(?) AND date(?) AND isActive = 1',
      [start.toIso8601String(), end.toIso8601String()]
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  Future<double> getExpenseTotalByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "gasto" AND date(date) BETWEEN date(?) AND date(?) AND isActive = 1',
      [start.toIso8601String(), end.toIso8601String()]
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  // ==================== PAGOS DE CLIENTES ====================
  Future<bool> recordClientPayment(int clientId, double amount) async {
    final db = await database;
    final count = await db.rawUpdate(
      'UPDATE clients SET accountBalance = accountBalance + ? WHERE id = ?',
      [amount, clientId],
    );
    return count > 0;
  }

  // ==================== UTILIDADES ====================
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('sale_items');
    await db.delete('sales');
    await db.delete('purchase_items');
    await db.delete('purchases');
    await db.delete('clients');
    await db.delete('providers');
    await db.delete('products');
    await db.delete('users');
    await db.delete('transactions');
    print('🗑️ Base de datos limpiada');
  }
  
  Future<void> checkDatabaseStructure() async {
    final db = await database;
    
    print('\n📋 VERIFICANDO ESTRUCTURA DE BASE DE DATOS:');
    
    final clientsInfo = await db.rawQuery('PRAGMA table_info(clients)');
    print('\n📊 Tabla clients:');
    for (var row in clientsInfo) {
      print('  - ${row['name']} (${row['type']})');
    }
    
    final clientsCount = await db.rawQuery('SELECT COUNT(*) as count FROM clients');
    print('\n📊 Clientes en BD: ${clientsCount.first['count']}');
  }
}