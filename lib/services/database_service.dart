import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../models/provider.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/kardex.dart';
import '../models/cash_session.dart';
import '../models/category.dart';
import '../models/company_settings.dart';
import '../models/transaction.dart' as mdl;

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
      version: 14, // ↑ bump para ajustar settings.businessRuc en migración
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
        if (oldVersion < 6) {
          try {
            await db.execute('''
              CREATE TABLE kardex (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                productId INTEGER NOT NULL,
                productName TEXT NOT NULL,
                date TEXT NOT NULL,
                type TEXT NOT NULL,
                description TEXT,
                quantity INTEGER NOT NULL,
                previousStock INTEGER NOT NULL,
                newStock INTEGER NOT NULL,
                userId INTEGER,
                FOREIGN KEY (productId) REFERENCES products (id)
              )
            ''');
            print('✅ Tabla kardex creada');
          } catch (e) {
            print('⚠️ Error creando tabla kardex: $e');
          }
        }
        if (oldVersion < 7) {
          try {
            await db.execute('''
              CREATE TABLE sale_payments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                saleId INTEGER NOT NULL,
                method TEXT NOT NULL,
                amount REAL NOT NULL,
                FOREIGN KEY (saleId) REFERENCES sales (id)
              )
            ''');
            print('✅ Tabla sale_payments creada');
          } catch (e) {
            print('⚠️ Error creando tabla sale_payments: $e');
          }
        }

        if (oldVersion < 9) {
          try {
            // Tabla de historial de pagos (para deudas de clientes y proveedores)
            await db.execute('''
              CREATE TABLE payment_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT NOT NULL, /* client_payment, provider_payment */
                entityId INTEGER NOT NULL,
                amount REAL NOT NULL,
                method TEXT NOT NULL,
                date TEXT NOT NULL,
                referenceId INTEGER /* id de venta o compra asociada */
              )
            ''');
            
            // Tabla de sesiones de caja (Fase 3)
            await db.execute('''
              CREATE TABLE cash_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                openingDate TEXT NOT NULL,
                closingDate TEXT,
                openingBalance REAL NOT NULL,
                expectedBalance REAL NOT NULL,
                actualBalance REAL,
                status TEXT NOT NULL, /* open, closed */
                userId INTEGER
              )
            ''');
            print('✅ Tabla payment_history y cash_sessions creadas (v9)');
          } catch (e) {
            print('⚠️ Error en migración v9: $e');
          }
        }

        if (oldVersion < 10) {
          try {
            await db.execute('''
              CREATE TABLE categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                iconCode INTEGER,
                colorValue INTEGER,
                isActive INTEGER DEFAULT 1
              )
            ''');
            print('✅ Tabla categories creada (v10)');
          } catch (e) {
            print('⚠️ Error en migración v10: $e');
          }
        }

        if (oldVersion < 11) {
          try {
            // Tabla de ajustes (v11)
            await db.execute('''
              CREATE TABLE settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                companyName TEXT,
                taxId TEXT,
                address TEXT,
                phone TEXT,
                email TEXT,
                currencySymbol TEXT,
                logoPath TEXT
              )
            ''');
            
            // Insertar ajustes por defecto
            await db.insert('settings', {
              'companyName': 'TauroStock',
              'currencySymbol': '\$',
            });

            // Agregar loyaltyPoints a la tabla clients (v11)
            await db.execute('ALTER TABLE clients ADD COLUMN loyaltyPoints INTEGER DEFAULT 0');
            
            print('✅ Tabla settings creada y loyaltyPoints agregada a clients (v11)');
          } catch (e) {
            print('⚠️ Error en migración v11: $e');
          }
        }

        if (oldVersion < 12) {
          try {
            // Tabla de empresas (Multi-tenant)
            await db.execute('''
              CREATE TABLE businesses (
                ruc TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                address TEXT,
                phone TEXT,
                email TEXT,
                isActive INTEGER DEFAULT 1
              )
            ''');

            // Añadir businessRuc a todas las tablas existentes
            final tables = [
              'users', 'products', 'clients', 'providers', 'sales', 
              'purchase_items', 'purchases', 'transactions', 'kardex', 
              'sale_payments', 'payment_history', 'cash_sessions', 'categories', 'settings'
            ];

            for (var table in tables) {
              await db.execute('ALTER TABLE $table ADD COLUMN businessRuc TEXT DEFAULT "0000000000"');
            }

            // ← NUEVO: Agregar businessName a la tabla users
            await db.execute('ALTER TABLE users ADD COLUMN businessName TEXT DEFAULT "Negocio Inicial"');

            // Crear negocio por defecto para datos existentes
            await db.insert('businesses', {
              'ruc': '0000000000',
              'name': 'Negocio Inicial',
              'isActive': 1,
            });

            print('✅ Migración v12 completada: Soporte Multi-tenant habilitado');
          } catch (e) {
            print('⚠️ Error en migración v12: $e');
          }
        }
        if (oldVersion < 13) {
          try {
            final userTableInfo = await db.rawQuery('PRAGMA table_info(users)');
            final hasBusinessName = userTableInfo.any((col) => col['name'] == 'businessName');
            if (!hasBusinessName) {
              await db.execute('ALTER TABLE users ADD COLUMN businessName TEXT DEFAULT "Negocio Inicial"');
              print('✅ Columna businessName agregada a users (v13)');
            }
          } catch (e) {
            print('⚠️ Error en migración v13: $e');
          }
        }

        // v14: asegurar columna businessRuc en settings para instalaciones previas
        if (oldVersion < 14) {
          try {
            final settingsInfo = await db.rawQuery('PRAGMA table_info(settings)');
            final hasBusinessRuc = settingsInfo.any((col) => col['name'] == 'businessRuc');
            if (!hasBusinessRuc) {
              await db.execute('ALTER TABLE settings ADD COLUMN businessRuc TEXT');
              print('✅ Columna businessRuc agregada a settings (v14)');
            } else {
              print('ℹ️ settings.businessRuc ya existe (v14)');
            }
          } catch (e) {
            print('⚠️ Error en migración v14: $e');
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
        businessRuc TEXT NOT NULL, /* ← NUEVO: v12 */
        businessName TEXT NOT NULL, /* ← NUEVO: v12 */
        createdAt TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        imagePath TEXT  
      )
    ''');

    // Tabla de empresas (v12)
    await db.execute('''
      CREATE TABLE businesses (
        ruc TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        isActive INTEGER DEFAULT 1
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
        businessRuc TEXT, /* ← NUEVO: v12 */
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
        loyaltyPoints INTEGER DEFAULT 0, /* ← NUEVO: v11 */
        businessRuc TEXT, /* ← NUEVO: v12 */
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
        businessRuc TEXT, /* ← NUEVO: v12 */
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
        businessRuc TEXT, /* ← NUEVO: v12 */
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
        businessRuc TEXT, /* ← NUEVO: v12 */
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
        businessRuc TEXT, /* ← NUEVO: v12 */
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Tabla de kardex (Historial de stock)
    await db.execute('''
      CREATE TABLE kardex (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        quantity INTEGER NOT NULL,
        previousStock INTEGER NOT NULL,
        newStock INTEGER NOT NULL,
        userId INTEGER,
        businessRuc TEXT, /* ← NUEVO: v12 */
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // Tabla de pagos de venta (Múltiples métodos)
    await db.execute('''
      CREATE TABLE sale_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        method TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales (id)
      )
    ''');

    // Tabla de historial de pagos (v9)
    await db.execute('''
      CREATE TABLE payment_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        entityId INTEGER NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL,
        date TEXT NOT NULL,
        referenceId INTEGER
      )
    ''');

    // Tabla de sesiones de caja (v9)
    await db.execute('''
      CREATE TABLE cash_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        openingDate TEXT NOT NULL,
        closingDate TEXT,
        openingBalance REAL NOT NULL,
        expectedBalance REAL NOT NULL,
        actualBalance REAL,
        status TEXT NOT NULL,
        userId INTEGER,
        businessRuc TEXT /* ← NUEVO: v12 */
      )
    ''');

    // Tabla de categorías (v10)
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        iconCode INTEGER,
        colorValue INTEGER,
        businessRuc TEXT, /* ← NUEVO: v12 */
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Tabla de ajustes (v11)
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        companyName TEXT,
        taxId TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        currencySymbol TEXT,
        logoPath TEXT,
        businessRuc TEXT
      )
    ''');

    print('✅ Base de datos creada con versión $version (sin datos precargados)');
  }

  // ==================== NEGOCIOS (Multi-tenant) ====================
  Future<bool> createBusiness(String ruc, String name) async {
    try {
      final db = await database;
      await db.insert('businesses', {
        'ruc': ruc,
        'name': name,
        'isActive': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return true;
    } catch (e) {
      print('❌ Error al crear negocio: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getBusinessByRuc(String ruc) async {
    final db = await database;
    final result = await db.query('businesses', where: 'ruc = ?', whereArgs: [ruc]);
    return result.isNotEmpty ? result.first : null;
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
    if (user != null && user.password == password) {
      if (!user.isActive) {
        throw Exception('Cuenta pendiente de aprobación por el administrador.');
      }
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

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  // ==================== CATEGORÍAS ====================
  Future<List<Category>> getAllCategories(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'categories', 
      where: 'isActive = 1 AND businessRuc = ?',
      whereArgs: [businessRuc],
    );
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final result = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Category.fromMap(result.first) : null;
  }

  Future<int> createCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<bool> updateCategory(Category category) async {
    final db = await database;
    final count = await db.update(
      'categories',
      category.toMap(),
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [category.id, category.businessRuc],
    );
    return count > 0;
  }

  Future<bool> deleteCategory(int id, String businessRuc) async {
    final db = await database;
    final count = await db.update(
      'categories',
      {'isActive': 0},
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [id, businessRuc],
    );
    return count > 0;
  }

  // Settings moved to the end of the file to avoid duplicates

  // ==================== PRODUCTOS ====================
  Future<List<Product>> getAllProducts(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'products', 
      where: 'isActive = 1 AND businessRuc = ?',
      whereArgs: [businessRuc],
    );
    
    print('📊 Productos encontrados para $businessRuc: ${result.length}');
    
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'products', 
      where: 'id = ? AND businessRuc = ?', 
      whereArgs: [id, businessRuc],
    );
    return result.isNotEmpty ? Product.fromMap(result.first) : null;
  }

  Future<Product?> getProductByBarcode(String barcode, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'products', 
      where: 'barcode = ? AND businessRuc = ?', 
      whereArgs: [barcode, businessRuc],
    );
    return result.isNotEmpty ? Product.fromMap(result.first) : null;
  }

  Future<int> createProduct(Product product) async {
    final db = await database;
    final id = await db.insert('products', product.toMap());
    print('✅ Producto creado con ID: $id para RUC: ${product.businessRuc}');
    return id;
  }

  Future<bool> updateProduct(Product product) async {
    final db = await database;
    final count = await db.update(
      'products',
      product.toMap(),
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [product.id, product.businessRuc],
    );
    
    print('✅ Producto actualizado: ${product.name}, filas afectadas: $count');
    return count > 0;
  }

  Future<bool> deleteProduct(int id, String businessRuc) async {
    final db = await database;
    final count = await db.update(
      'products',
      {'isActive': 0},
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [id, businessRuc],
    );
    return count > 0;
  }

  Future<List<Product>> getLowStockProducts(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'quantity <= minStock AND isActive = 1 AND businessRuc = ?',
      whereArgs: [businessRuc],
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // ==================== CLIENTES ====================
  Future<List<Client>> getAllClients(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'clients', 
      where: 'isActive = 1 AND businessRuc = ?',
      whereArgs: [businessRuc],
    );
    
    print('📊 Clientes encontrados para $businessRuc: ${result.length}');
    
    return result.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClientById(int id, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'clients', 
      where: 'id = ? AND businessRuc = ?', 
      whereArgs: [id, businessRuc],
    );
    return result.isNotEmpty ? Client.fromMap(result.first) : null;
  }

  Future<int> createClient(Client client) async {
    final db = await database;
    final id = await db.insert('clients', client.toMap());
    print('✅ Cliente creado con ID: $id para RUC: ${client.businessRuc}');
    return id;
  }

  Future<bool> updateClient(Client client) async {
    final db = await database;
    final count = await db.update(
      'clients',
      client.toMap(),
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [client.id, client.businessRuc],
    );
    
    print('✅ Cliente actualizado: ${client.name}, filas afectadas: $count');
    return count > 0;
  }

  Future<bool> deleteClient(int id, String businessRuc) async {
    final db = await database;
    final count = await db.update(
      'clients',
      {'isActive': 0},
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [id, businessRuc],
    );
    return count > 0;
  }

  Future<List<Client>> getClientsWithDebt(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'clients',
      where: 'accountBalance < 0 AND isActive = 1 AND businessRuc = ?',
      whereArgs: [businessRuc],
    );
    return result.map((map) => Client.fromMap(map)).toList();
  }

  // ==================== PROVEEDORES ====================
  Future<List<ProviderModel>> getAllProviders(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'providers', 
      where: 'isActive = 1 AND businessRuc = ?',
      whereArgs: [businessRuc],
    );
    return result.map((map) => ProviderModel.fromMap(map)).toList();
  }

  Future<ProviderModel?> getProviderById(int id, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'providers', 
      where: 'id = ? AND businessRuc = ?', 
      whereArgs: [id, businessRuc],
    );
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
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [provider.id, provider.businessRuc],
    );
    return count > 0;
  }

  Future<bool> deleteProvider(int id, String businessRuc) async {
    final db = await database;
    final count = await db.update(
      'providers',
      {'isActive': 0},
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [id, businessRuc],
    );
    return count > 0;
  }

  // ==================== VENTAS ====================
  Future<int> createSale(Sale sale) async {
    final db = await database;
    final id = await db.insert('sales', sale.toMap());

    for (var payment in sale.payments) {
      final paymentMap = payment.toMap();
      paymentMap['saleId'] = id;
      await db.insert('sale_payments', paymentMap);

      await db.insert('payment_history', {
        'type': 'client_payment',
        'entityId': sale.clientId,
        'amount': payment.amount,
        'method': payment.method,
        'date': sale.saleDate.toIso8601String(),
        'referenceId': id,
        'businessRuc': sale.businessRuc, // ← v12
      });

      if (payment.method != 'credito') {
        await db.insert('transactions', {
          'description': 'Venta #${id} (${payment.method})',
          'amount': payment.amount,
          'type': 'ingreso',
          'category': 'Venta',
          'date': sale.saleDate.toIso8601String().split('T')[0],
          'notes': 'Cliente ID: ${sale.clientId}',
          'businessRuc': sale.businessRuc, // ← v12
          'isActive': 1,
        });
      } else {
        await db.rawUpdate(
          'UPDATE clients SET accountBalance = accountBalance - ? WHERE id = ? AND businessRuc = ?',
          [payment.amount, sale.clientId, sale.businessRuc],
        );
      }
    }

    return id;
  }

  Future<int> createSalePayment(SalePayment payment) async {
    final db = await database;
    return await db.insert('sale_payments', payment.toMap());
  }

  Future<int> createSaleItem(SaleItem item) async {
    final db = await database;
    return await db.insert('sale_items', item.toMap());
  }

  Future<List<Sale>> getAllSales(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'sales', 
      where: 'businessRuc = ?', 
      whereArgs: [businessRuc],
      orderBy: 'saleDate DESC'
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<Sale?> getSaleById(int id, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'sales', 
      where: 'id = ? AND businessRuc = ?', 
      whereArgs: [id, businessRuc]
    );
    if (result.isEmpty) return null;

    final sale = Sale.fromMap(result.first);
    
    // Cargar items
    final itemsResult =
        await db.query('sale_items', where: 'saleId = ?', whereArgs: [id]);
    sale.items.addAll(
        itemsResult.map((map) => SaleItem.fromMap(map)).toList());
    
    // Cargar pagos
    final paymentsResult =
        await db.query('sale_payments', where: 'saleId = ?', whereArgs: [id]);
    sale.payments.addAll(
        paymentsResult.map((map) => SalePayment.fromMap(map)).toList());
        
    return sale;
  }

  Future<double> getDailySales(DateTime date, String businessRuc) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total FROM sales WHERE date(saleDate) = ? AND businessRuc = ?',
      [dateStr, businessRuc],
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'sales',
      where: 'date(saleDate) BETWEEN date(?) AND date(?) AND businessRuc = ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String(), businessRuc],
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

  Future<double> getSalesTotalByDateRange(DateTime start, DateTime end, String businessRuc) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total FROM sales WHERE (date(saleDate) BETWEEN date(?) AND date(?)) AND businessRuc = ?',
      [start.toIso8601String(), end.toIso8601String(), businessRuc]
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  // ==================== COMPRAS ====================
  Future<int> createPurchase(Purchase purchase) async {
    final db = await database;
    final id = await db.insert('purchases', purchase.toMap());
    
    if (purchase.paymentStatus == 'pendiente') {
      await db.rawUpdate(
        'UPDATE providers SET accountBalance = accountBalance + ?, totalPurchases = totalPurchases + ? WHERE id = ? AND businessRuc = ?',
        [purchase.finalAmount, purchase.finalAmount, purchase.providerId, purchase.businessRuc],
      );
    } else {
      await db.rawUpdate(
        'UPDATE providers SET totalPurchases = totalPurchases + ? WHERE id = ? AND businessRuc = ?',
        [purchase.finalAmount, purchase.providerId, purchase.businessRuc],
      );
      
      await db.insert('transactions', {
        'description': 'Compra #${id}',
        'amount': purchase.finalAmount,
        'type': 'gasto',
        'category': 'Compra',
        'date': purchase.purchaseDate.toIso8601String().split('T')[0],
        'notes': 'Proveedor ID: ${purchase.providerId}',
        'businessRuc': purchase.businessRuc, // ← v12
        'isActive': 1,
      });
    }

    if (purchase.paymentStatus == 'pagado') {
      await db.insert('payment_history', {
        'type': 'provider_payment',
        'entityId': purchase.providerId,
        'amount': purchase.finalAmount,
        'method': 'contado',
        'date': purchase.purchaseDate.toIso8601String(),
        'referenceId': id,
        'businessRuc': purchase.businessRuc, // ← v12
      });
    }

    return id;
  }

  Future<int> createPurchaseItem(PurchaseItem item) async {
    final db = await database;
    return await db.insert('purchase_items', item.toMap());
  }

  Future<List<Purchase>> getAllPurchases(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'purchases', 
      where: 'businessRuc = ?', 
      whereArgs: [businessRuc],
      orderBy: 'purchaseDate DESC'
    );
    return result.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<Purchase?> getPurchaseById(int id, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'purchases', 
      where: 'id = ? AND businessRuc = ?', 
      whereArgs: [id, businessRuc]
    );
    if (result.isEmpty) return null;

    final purchase = Purchase.fromMap(result.first);
    final itemsResult = await db
        .query('purchase_items', where: 'purchaseId = ?', whereArgs: [id]);
    purchase.items.addAll(
        itemsResult.map((map) => PurchaseItem.fromMap(map)).toList());
    return purchase;
  }

  Future<List<Purchase>> getPendingPayments(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'purchases',
      where: 'paymentStatus = ? AND businessRuc = ?',
      whereArgs: ['pendiente', businessRuc],
      orderBy: 'purchaseDate DESC',
    );
    return result.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<bool> updatePurchasePaymentStatus(int purchaseId, String status, String businessRuc) async {
    final db = await database;
    final existing = await db.query(
      'purchases', 
      where: 'id = ? AND businessRuc = ?', 
      whereArgs: [purchaseId, businessRuc]
    );
    if (existing.isEmpty) return false;
    final oldPurchase = Purchase.fromMap(existing.first);
    final count = await db.update(
      'purchases',
      {'paymentStatus': status},
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [purchaseId, businessRuc],
    );
    if (count > 0) {
      if (oldPurchase.paymentStatus == 'pendiente' && status == 'pagado') {
        final now = DateTime.now().toIso8601String();

        await db.rawUpdate(
          'UPDATE providers SET accountBalance = accountBalance - ? WHERE id = ? AND businessRuc = ?',
          [oldPurchase.finalAmount, oldPurchase.providerId, businessRuc],
        );

        // ← NUEVO: Trazabilidad e Integración de Caja
        await db.insert('payment_history', {
          'type': 'provider_payment',
          'entityId': oldPurchase.providerId,
          'amount': oldPurchase.finalAmount,
          'method': 'contado',
          'date': now,
          'referenceId': purchaseId,
          'businessRuc': businessRuc, // ← v12
        });

        await db.insert('transactions', {
          'description': 'Pago a Proveedor (Compra #${purchaseId})',
          'amount': oldPurchase.finalAmount,
          'type': 'gasto',
          'category': 'Pago Proveedor',
          'date': now.split('T')[0],
          'notes': 'Liquidación de compra pendiente',
          'businessRuc': businessRuc, // ← v12
          'isActive': 1,
        });
      }
    }
    return count > 0;
  }

  Future<List<Purchase>> getPurchasesByDateRange(DateTime start, DateTime end, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'purchases',
      where: 'date(purchaseDate) BETWEEN date(?) AND date(?) AND businessRuc = ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String(), businessRuc],
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

  Future<double> getPurchasesTotalByDateRange(DateTime start, DateTime end, String businessRuc) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total FROM purchases WHERE (date(purchaseDate) BETWEEN date(?) AND date(?)) AND businessRuc = ?',
      [start.toIso8601String(), end.toIso8601String(), businessRuc]
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  // ==================== TRANSACCIONES ====================
  Future<List<mdl.Transaction>> getTransactionsByDateRange(DateTime start, DateTime end, String businessRuc) async {
    final db = await database;
    
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];
    
    final result = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ? AND isActive = 1 AND businessRuc = ?',
      whereArgs: [startStr, endStr, businessRuc],
      orderBy: 'date DESC',
    );
    
    return result.map((map) => mdl.Transaction.fromMap(map)).toList();
  }

  Future<List<mdl.Transaction>> getAllTransactions(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'isActive = 1 AND businessRuc = ?',
      whereArgs: [businessRuc],
      orderBy: 'date DESC',
    );
    return result.map((map) => mdl.Transaction.fromMap(map)).toList();
  }

  Future<int> createTransaction(mdl.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<bool> updateTransaction(mdl.Transaction transaction) async {
    final db = await database;
    final count = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [transaction.id, transaction.businessRuc],
    );
    return count > 0;
  }

  Future<bool> deleteTransactionStatus(int id, String businessRuc) async {
    final db = await database;
    final count = await db.update(
      'transactions',
      {'isActive': 0},
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [id, businessRuc],
    );
    return count > 0;
  }

  Future<double> getIncomeTotalByDateRange(DateTime start, DateTime end, String businessRuc) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "ingreso" AND (date(date) BETWEEN date(?) AND date(?)) AND isActive = 1 AND businessRuc = ?',
      [start.toIso8601String(), end.toIso8601String(), businessRuc]
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  Future<double> getExpenseTotalByDateRange(DateTime start, DateTime end, String businessRuc) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "gasto" AND (date(date) BETWEEN date(?) AND date(?)) AND isActive = 1 AND businessRuc = ?',
      [start.toIso8601String(), end.toIso8601String(), businessRuc]
    );
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  // ==================== PAGOS DE CLIENTES ====================
  Future<bool> recordClientPayment(int clientId, double amount, String businessRuc) async {
    final db = await database;
    
    final count = await db.rawUpdate(
      'UPDATE clients SET accountBalance = accountBalance + ? WHERE id = ? AND businessRuc = ?',
      [amount, clientId, businessRuc],
    );

    if (count > 0) {
      final now = DateTime.now().toIso8601String();
      
      await db.insert('payment_history', {
        'type': 'client_payment',
        'entityId': clientId,
        'amount': amount,
        'method': 'efectivo',
        'date': now,
        'referenceId': null,
        'businessRuc': businessRuc, // ← v12
      });

      await db.insert('transactions', {
        'description': 'Abono de Cliente ID: ${clientId}',
        'amount': amount,
        'type': 'ingreso',
        'category': 'Cobro',
        'date': now.split('T')[0],
        'notes': 'Pago manual de deuda',
        'businessRuc': businessRuc, // ← v12
        'isActive': 1,
      });
    }

    return count > 0;
  }

  // ==================== KARDEX ====================
  Future<void> createKardexMovement(KardexMovement movement) async {
    final db = await database;
    await db.insert('kardex', movement.toMap());
    print('✅ Movimiento de Kardex registrado para producto: ${movement.productName}');
  }

  Future<List<KardexMovement>> getKardexByProduct(int productId, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'kardex',
      where: 'productId = ? AND businessRuc = ?',
      whereArgs: [productId, businessRuc],
      orderBy: 'date DESC',
    );
    return result.map((map) => KardexMovement.fromMap(map)).toList();
  }

  Future<List<KardexMovement>> getAllKardex(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'kardex', 
      where: 'businessRuc = ?', 
      whereArgs: [businessRuc],
      orderBy: 'date DESC'
    );
    return result.map((map) => KardexMovement.fromMap(map)).toList();
  }

  // ==================== ANULACIÓN DE VENTAS ====================
  Future<bool> annulSale(int saleId, String businessRuc) async {
    final db = await database;
    try {
      return await db.transaction((txn) async {
        final saleResult = await txn.query(
          'sales', 
          where: 'id = ? AND businessRuc = ?', 
          whereArgs: [saleId, businessRuc]
        );
        if (saleResult.isEmpty) return false;
        
        final saleData = saleResult.first;
        if (saleData['status'] == 'anulada') return false;

        final items = await txn.query('sale_items', where: 'saleId = ?', whereArgs: [saleId]);
        
        for (var item in items) {
          final productId = item['productId'] as int;
          final quantity = item['quantity'] as int;
          final productName = item['productName'].toString();

          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ? AND businessRuc = ?',
            [quantity, productId, businessRuc],
          );

          final productResult = await txn.query(
            'products', 
            where: 'id = ? AND businessRuc = ?', 
            whereArgs: [productId, businessRuc]
          );
          final newStock = productResult.first['quantity'] as int;

          await txn.insert('kardex', {
            'productId': productId,
            'productName': productName,
            'date': DateTime.now().toIso8601String(),
            'type': 'entrada',
            'description': 'Anulación de Venta #${saleId}',
            'quantity': quantity,
            'previousStock': newStock - quantity,
            'newStock': newStock,
            'userId': null,
            'businessRuc': businessRuc, // ← v12
          });
        }

        final payments = await txn.query('sale_payments', where: 'saleId = ?', whereArgs: [saleId]);
        for (var p in payments) {
          if (p['method'] == 'credito') {
            await txn.rawUpdate(
              'UPDATE clients SET accountBalance = accountBalance + ? WHERE id = ? AND businessRuc = ?',
              [p['amount'], saleData['clientId'], businessRuc],
            );
          }
        }

        await txn.update(
          'sales', 
          {'status': 'anulada'}, 
          where: 'id = ? AND businessRuc = ?', 
          whereArgs: [saleId, businessRuc]
        );

        await txn.update(
          'transactions',
          {'isActive': 0},
          where: 'description LIKE ? AND businessRuc = ?',
          whereArgs: ['Venta #${saleId}%', businessRuc]
        );

        return true;
      });
    } catch (e) {
      print('❌ Error anulando venta: $e');
      return false;
    }
  }

  // ==================== SESIONES DE CAJA ====================
  Future<int> openCashSession(CashSession session) async {
    final db = await database;
    return await db.insert('cash_sessions', {
      'openingDate': session.openingDate.toIso8601String(),
      'openingBalance': session.openingAmount,
      'expectedBalance': session.openingAmount,
      'status': 'open',
      'userId': session.userId,
      'businessRuc': session.businessRuc,
    });
  }

  Future<bool> closeCashSession(int sessionId, double actualBalance, String businessRuc) async {
    final db = await database;
    final session = await getCashSessionById(sessionId, businessRuc);
    if (session == null) return false;

    final count = await db.update(
      'cash_sessions',
      {
        'closingDate': DateTime.now().toIso8601String(),
        'actualBalance': actualBalance,
        'status': 'closed',
      },
      where: 'id = ? AND businessRuc = ?',
      whereArgs: [sessionId, businessRuc],
    );
    return count > 0;
  }

  Future<CashSession?> getCurrentCashSession(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'cash_sessions',
      where: 'status = ? AND businessRuc = ?',
      whereArgs: ['open', businessRuc],
      orderBy: 'openingDate DESC',
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    
    // Convertir de Map a Modelo manual ya que los nombres difieren un poco en BD y el modelo
    final map = result.first;
    return CashSession(
      id: map['id'] as int,
      openingAmount: map['openingBalance'] as double,
      expectedAmount: map['expectedBalance'] as double,
      closingAmount: map['actualBalance'] != null ? map['actualBalance'] as double : null,
      openingDate: DateTime.parse(map['openingDate'].toString()),
      closingDate: map['closingDate'] != null ? DateTime.parse(map['closingDate'].toString()) : null,
      status: map['status'].toString(),
      userId: map['userId'] as int,
      businessRuc: map['businessRuc']?.toString(),
    );
  }

  Future<CashSession?> getCashSessionById(int id, String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'cash_sessions', 
      where: 'id = ? AND businessRuc = ?', 
      whereArgs: [id, businessRuc]
    );
    if (result.isEmpty) return null;
    
    final map = result.first;
    return CashSession(
      id: map['id'] as int,
      openingAmount: map['openingBalance'] as double,
      expectedAmount: map['expectedBalance'] as double,
      closingAmount: map['actualBalance'] != null ? map['actualBalance'] as double : null,
      openingDate: DateTime.parse(map['openingDate'].toString()),
      closingDate: map['closingDate'] != null ? DateTime.parse(map['closingDate'].toString()) : null,
      status: map['status'].toString(),
      userId: map['userId'] as int,
      businessRuc: map['businessRuc']?.toString(),
    );
  }

  // ==================== AJUSTES ====================
  Future<CompanySettings?> getSettings(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'businessRuc = ?',
      whereArgs: [businessRuc],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return CompanySettings.fromMap(result.first);
  }

  Future<bool> updateSettings(CompanySettings settings, String businessRuc) async {
    final db = await database;
    
    final existing = await getSettings(businessRuc);
    
    if (existing == null) {
      final map = settings.toMap();
      map['businessRuc'] = businessRuc;
      final id = await db.insert('settings', map);
      return id > 0;
    } else {
      final count = await db.update(
        'settings',
        settings.toMap(),
        where: 'businessRuc = ?',
        whereArgs: [businessRuc],
      );
      return count > 0;
    }
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
    await db.delete('kardex');
    await db.delete('payment_history');
    await db.delete('cash_sessions');
    await db.delete('sale_payments');
    await db.delete('businesses');
    await db.delete('settings');
    print('🗑️ Base de datos limpiada por completo (incluyendo Negocios y Ajustes)');
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
  Future<List<User>> getAllUsersByBusiness(String businessRuc) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'businessRuc = ?',
      whereArgs: [businessRuc],
    );
    return result.map((map) => User.fromMap(map)).toList();
  }
}
