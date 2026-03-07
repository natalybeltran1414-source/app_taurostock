import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias

enum ReportPeriod { daily, weekly, monthly, yearly }

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  late DatabaseService _db;
  
  ReportPeriod _selectedPeriod = ReportPeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  
  double _totalSales = 0;
  double _totalPurchases = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalGain = 0;
  
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService();
    _updateDateRange();
    _loadReport();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case ReportPeriod.weekly:
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case ReportPeriod.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case ReportPeriod.yearly:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
    }
  }

  String _getPeriodName() {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return 'Hoy';
      case ReportPeriod.weekly:
        return 'Últimos 7 días';
      case ReportPeriod.monthly:
        return 'Este mes';
      case ReportPeriod.yearly:
        return 'Este año';
    }
  }

  String _getDateRangeText() {
    return '${_startDate.day}/${_startDate.month}/${_startDate.year} - '
           '${_endDate.day}/${_endDate.month}/${_endDate.year}';
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    try {
      final sales = await _db.getSalesByDateRange(_startDate, _endDate);
      _totalSales = sales.fold<double>(0, (sum, sale) => sum + sale.finalAmount);

      final purchases = await _db.getPurchasesByDateRange(_startDate, _endDate);
      _totalPurchases = purchases.fold<double>(0, (sum, purchase) => sum + purchase.finalAmount);

      final transactions = await _db.getTransactionsByDateRange(_startDate, _endDate);
      _totalIncome = transactions
          .where((t) => t.type == 'ingreso')
          .fold<double>(0, (sum, t) => sum + t.amount);
      _totalExpense = transactions
          .where((t) => t.type == 'gasto')
          .fold<double>(0, (sum, t) => sum + t.amount);

      final totalIngresos = _totalSales + _totalIncome;
      final totalGastos = _totalPurchases + _totalExpense;
      _totalGain = totalIngresos - totalGastos;
      
    } catch (e) {
      print('Error loading report: $e');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Reporte de Ventas',
        showBackButton: true,
      ),
      body: _loading
          ? const custom.CustomLoadingIndicator(message: 'Cargando reporte...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ← MEJORADO: Selector de período con chips
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPeriodChip('Día', ReportPeriod.daily),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPeriodChip('Semana', ReportPeriod.weekly),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPeriodChip('Mes', ReportPeriod.monthly),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPeriodChip('Año', ReportPeriod.yearly),
                        ),
                      ],
                    ),
                  ),
                  
                  // ← MEJORADO: Período seleccionado
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: custom.secondaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: custom.secondaryPurple.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getPeriodName(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: custom.secondaryPurple,
                          ),
                        ),
                        Text(
                          _getDateRangeText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: custom.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ← MEJORADO: Tarjetas de resumen con SummaryCard
                  custom.SummaryCard(
                    title: 'Ingresos Totales',
                    value: '\$${(_totalSales + _totalIncome).toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  
                  custom.SummaryCard(
                    title: 'Gastos Totales',
                    value: '\$${(_totalPurchases + _totalExpense).toStringAsFixed(2)}',
                    icon: Icons.trending_down,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  
                  custom.SummaryCard(
                    title: 'Utilidad Neta',
                    value: '\$${_totalGain.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: _totalGain >= 0 ? Colors.green : Colors.red,
                  ),
                  
                  const SizedBox(height: 32),

                  // ← MEJORADO: Desglose Detallado con SectionHeader
                  custom.SectionHeader(
                    title: 'Desglose Detallado',
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Ventas', _totalSales, Colors.green),
                        const SizedBox(height: 8),
                        if (_totalIncome > 0) ...[
                          _buildDetailRow('Otros Ingresos', _totalIncome, Colors.green),
                          const SizedBox(height: 8),
                        ],
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildDetailRow('Compras', _totalPurchases, Colors.red),
                        const SizedBox(height: 8),
                        if (_totalExpense > 0) ...[
                          _buildDetailRow('Otros Gastos', _totalExpense, Colors.red),
                          const SizedBox(height: 8),
                        ],
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'UTILIDAD NETA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            custom.StatusBadge(
                              label: '\$${_totalGain.toStringAsFixed(2)}',
                              color: _totalGain >= 0 ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ← MEJORADO: Botón actualizar
                  custom.CustomButton(
                    label: 'Actualizar Reporte',
                    onPressed: _loadReport,
                  ),
                ],
              ),
            ),
    );
  }

  // ← MEJORADO: Chip de período
  Widget _buildPeriodChip(String label, ReportPeriod period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _updateDateRange();
          _loadReport();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? custom.secondaryPurple : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? custom.secondaryPurple : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : custom.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ← MEJORADO: Fila de detalle
  Widget _buildDetailRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: custom.textSecondary,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}