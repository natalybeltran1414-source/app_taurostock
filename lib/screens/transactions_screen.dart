import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../providers/transaction_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/purchase_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late TextEditingController _searchController;
  String _selectedFilter = 'todos';
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _dateRangeText = 'Hoy';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _updateDateRange('Hoy');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        Provider.of<TransactionProvider>(context, listen: false).loadTransactions(),
        Provider.of<SaleProvider>(context, listen: false).loadSales(),
        Provider.of<PurchaseProvider>(context, listen: false).loadPurchases(),
      ]);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateDateRange(String range) {
    final now = DateTime.now();
    setState(() {
      _dateRangeText = range;
      
      switch (range) {
        case 'Hoy':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Ayer':
          final yesterday = now.subtract(const Duration(days: 1));
          _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
          break;
        case '7 días':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'Mes':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'Año':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
      }
    });
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _dateRangeText = '${picked.start.day}/${picked.start.month} - ${picked.end.day}/${picked.end.month}';
      });
    }
  }

  List<Map<String, dynamic>> _filterItemsByDate(
    List<Map<String, dynamic>> items,
  ) {
    return items.where((item) {
      final date = item['date'] as DateTime;
      return date.isAfter(_startDate.subtract(const Duration(days: 1))) && 
             date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
  }

  String _getComparisonText(List<Map<String, dynamic>> currentItems) {
    if (_dateRangeText == 'Hoy') {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final yesterdayEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      
      final yesterdayItems = _getCombinedItems(
        Provider.of<TransactionProvider>(context, listen: false),
        Provider.of<SaleProvider>(context, listen: false),
        Provider.of<PurchaseProvider>(context, listen: false),
      ).where((item) {
        final date = item['date'] as DateTime;
        return date.isAfter(yesterdayStart) && date.isBefore(yesterdayEnd);
      }).toList();
      
      final currentTotal = _calculatePeriodTotals(currentItems)['balance']!;
      final yesterdayTotal = _calculatePeriodTotals(yesterdayItems)['balance']!;
      
      if (yesterdayTotal == 0) return '';
      final percentChange = ((currentTotal - yesterdayTotal) / yesterdayTotal.abs()) * 100;
      
      return '${percentChange >= 0 ? '▲' : '▼'} ${percentChange.abs().toStringAsFixed(1)}% vs ayer';
    }
    return '';
  }

  Map<String, double> _calculatePeriodTotals(List<Map<String, dynamic>> items) {
    double income = 0;
    double expense = 0;
    
    for (var item in items) {
      if (item['type'] == 'sale' || 
          (item['type'] == 'transaction' && (item['data'] as Transaction).type == 'ingreso')) {
        if (item['type'] == 'sale') {
          income += (item['data'] as Sale).finalAmount;
        } else {
          income += (item['data'] as Transaction).amount;
        }
      } else {
        if (item['type'] == 'purchase') {
          expense += (item['data'] as Purchase).finalAmount;
        } else {
          expense += (item['data'] as Transaction).amount;
        }
      }
    }
    
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  List<Map<String, dynamic>> _getCombinedItems(
    TransactionProvider transactionProvider,
    SaleProvider saleProvider,
    PurchaseProvider purchaseProvider,
  ) {
    List<Map<String, dynamic>> items = [];

    for (var t in transactionProvider.transactions) {
      items.add({
        'type': 'transaction',
        'data': t,
        'date': t.date,
      });
    }

    for (var s in saleProvider.sales) {
      if (s.status == 'completada' && s.paymentMethod != 'credito') {
        items.add({
          'type': 'sale',
          'data': s,
          'date': s.saleDate,
        });
      }
    }

    for (var p in purchaseProvider.purchases) {
      if (p.paymentStatus == 'pagado') {
        items.add({
          'type': 'purchase',
          'data': p,
          'date': p.purchaseDate,
        });
      }
    }

    items.sort((a, b) => b['date'].compareTo(a['date']));
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Ingresos y Gastos',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: () => _selectCustomRange(context),
          ),
        ],
      ),
      body: Consumer3<TransactionProvider, SaleProvider, PurchaseProvider>(
        builder: (context, transactionProvider, saleProvider, purchaseProvider, _) {
          if (transactionProvider.isLoading || saleProvider.isLoading || purchaseProvider.isLoading) {
            return const custom.CustomLoadingIndicator(
              message: 'Cargando movimientos...',
            );
          }

          var allItems = _getCombinedItems(
            transactionProvider,
            saleProvider,
            purchaseProvider,
          );
          
          var filteredByDate = _filterItemsByDate(allItems);
          
          final periodTotals = _calculatePeriodTotals(filteredByDate);
          final comparisonText = _getComparisonText(filteredByDate);
          
          if (_searchController.text.isNotEmpty) {
            filteredByDate = filteredByDate.where((item) {
              if (item['type'] == 'transaction') {
                final t = item['data'] as Transaction;
                return t.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                       t.category.toLowerCase().contains(_searchController.text.toLowerCase());
              } else if (item['type'] == 'sale') {
                final s = item['data'] as Sale;
                return s.items.any((saleItem) => 
                  saleItem.productName.toLowerCase().contains(_searchController.text.toLowerCase())
                );
              } else {
                final p = item['data'] as Purchase;
                return p.items.any((purchaseItem) => 
                  purchaseItem.productName.toLowerCase().contains(_searchController.text.toLowerCase())
                );
              }
            }).toList();
          }
          
          if (_selectedFilter == 'ventas') {
            filteredByDate = filteredByDate.where((item) => item['type'] == 'sale').toList();
          } else if (_selectedFilter == 'compras') {
            filteredByDate = filteredByDate.where((item) => item['type'] == 'purchase').toList();
          } else if (_selectedFilter == 'extras') {
            filteredByDate = filteredByDate.where((item) => item['type'] == 'transaction').toList();
          }

          return Column(
            children: [
              // ← MEJORADO: Selector de fechas con chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDateChip('Hoy', _dateRangeText == 'Hoy'),
                      const SizedBox(width: 6),
                      _buildDateChip('Ayer', _dateRangeText == 'Ayer'),
                      const SizedBox(width: 6),
                      _buildDateChip('7d', _dateRangeText == '7 días'),
                      const SizedBox(width: 6),
                      _buildDateChip('Mes', _dateRangeText == 'Mes'),
                      const SizedBox(width: 6),
                      _buildDateChip('Año', _dateRangeText == 'Año'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _dateRangeText.contains('-') 
                              ? custom.secondaryPurple.withOpacity(0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _dateRangeText.contains('-')
                                ? custom.secondaryPurple
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.date_range, size: 14, color: custom.secondaryPurple),
                            const SizedBox(width: 4),
                            Text(
                              _dateRangeText.contains('-') ? _dateRangeText : 'Rango',
                              style: TextStyle(
                                fontSize: 12,
                                color: _dateRangeText.contains('-') 
                                    ? custom.secondaryPurple
                                    : custom.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // ← MEJORADO: Resumen del período
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [custom.primaryPurple, custom.secondaryPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: custom.secondaryPurple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _dateRangeText,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                '\$${periodTotals['income']!.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const Text('Ingresos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                '\$${periodTotals['expense']!.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const Text('Gastos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(color: Colors.white30, height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${periodTotals['balance']!.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: periodTotals['balance']! >= 0 ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (comparisonText.isNotEmpty)
                              Text(comparisonText, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),

              // ← MEJORADO: Búsqueda con SearchBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: custom.SearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  hintText: 'Buscar en $_dateRangeText...',
                ),
              ),
              
              const SizedBox(height: 8),
              
              // ← MEJORADO: Filtros por tipo con chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('Todos', 'todos'),
                    _buildFilterChip('Ventas', 'ventas'),
                    _buildFilterChip('Compras', 'compras'),
                    _buildFilterChip('Extras', 'extras'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

              // Lista de items
              Expanded(
                child: filteredByDate.isEmpty
                    ? custom.EmptyState(
                        message: 'No hay movimientos en este período',
                        icon: Icons.receipt_long_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredByDate.length,
                        itemBuilder: (context, index) {
                          final item = filteredByDate[index];
                          if (item['type'] == 'transaction') {
                            return _buildTransactionCard(
                              item['data'] as Transaction,
                              transactionProvider,
                            );
                          } else if (item['type'] == 'sale') {
                            return _buildSaleCard(item['data'] as Sale);
                          } else {
                            return _buildPurchaseCard(item['data'] as Purchase);
                          }
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: custom.secondaryPurple,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TransactionFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ← MEJORADO: Chip de fecha
  Widget _buildDateChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _updateDateRange(
        label == '7d' ? '7 días' : 
        label == 'Año' ? 'Año' : label
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? custom.secondaryPurple : custom.backgroundGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? custom.secondaryPurple : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : custom.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ← MEJORADO: Chip de filtro
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      backgroundColor: custom.backgroundGrey,
      selectedColor: custom.secondaryPurple.withOpacity(0.2),
      checkmarkColor: custom.secondaryPurple,
    );
  }

  // ← MEJORADO: Tarjeta de venta
  Widget _buildSaleCard(Sale sale) {
    return custom.ListItemCard(
      title: 'Venta #${sale.id}',
      subtitle: '${sale.items.length} productos • ${sale.saleDate.day}/${sale.saleDate.month}',
      amount: '\$${sale.finalAmount.toStringAsFixed(2)}',
      icon: Icons.shopping_cart,
      color: Colors.green,
      status: 'Pagado',
    );
  }

  // ← MEJORADO: Tarjeta de compra
  Widget _buildPurchaseCard(Purchase purchase) {
    return custom.ListItemCard(
      title: 'Compra #${purchase.id}',
      subtitle: '${purchase.items.length} productos • ${purchase.purchaseDate.day}/${purchase.purchaseDate.month}',
      amount: '\$${purchase.finalAmount.toStringAsFixed(2)}',
      icon: Icons.inventory,
      color: Colors.red,
      status: 'Pagado',
    );
  }

  // ← MEJORADO: Tarjeta de transacción
  Widget _buildTransactionCard(Transaction transaction, TransactionProvider provider) {
    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        provider.deleteTransaction(transaction.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${transaction.description} eliminada'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: custom.ListItemCard(
        title: transaction.description,
        subtitle: '${transaction.category.capitalize()} • ${transaction.date.day}/${transaction.date.month}',
        amount: '\$${transaction.amount.toStringAsFixed(2)}',
        icon: transaction.icon,
        color: transaction.color,
        status: transaction.type == 'ingreso' ? 'Ingreso extra' : 'Gasto extra',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransactionFormScreen(
                transaction: transaction,
              ),
            ),
          );
        },
      ),
    );
  }
}