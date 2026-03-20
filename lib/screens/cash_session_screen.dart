import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cash_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom;

class CashSessionScreen extends StatefulWidget {
  const CashSessionScreen({Key? key}) : super(key: key);

  @override
  State<CashSessionScreen> createState() => _CashSessionScreenState();
}

class _CashSessionScreenState extends State<CashSessionScreen> {
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
      Provider.of<CashProvider>(context, listen: false).checkActiveSession(businessRuc);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar(
        title: 'Control de Caja',
        showBackButton: true,
      ),
      body: Consumer<CashProvider>(
        builder: (context, cashProvider, _) {
          if (cashProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cashProvider.isSessionOpen) {
            return _buildClosingUI(cashProvider);
          } else {
            return _buildOpeningUI(cashProvider);
          }
        },
      ),
    );
  }

  Widget _buildOpeningUI(CashProvider cashProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const custom.StatusBadge(label: 'Caja Cerrada', color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Apertura de Caja',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingrese el monto inicial de efectivo disponible en caja.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          custom.CustomTextField(
            label: 'Monto Inicial',
            controller: _amountController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.attach_money,
            hintText: '0.00',
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _handleOpen(cashProvider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: custom.primaryLilac,
              ),
              child: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('ABRIR CAJA', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingUI(CashProvider cashProvider) {
    final session = cashProvider.currentSession!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const custom.StatusBadge(label: 'Caja Abierta', color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Arqueo y Cierre',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Abierta el:', session.openingDate.toString().split('.')[0]),
          _buildInfoRow('Monto Inicial:', '\$${session.openingAmount.toStringAsFixed(2)}'),
          _buildInfoRow('Ventas Efectivo:', '\$${((session.expectedAmount ?? 0.0) - session.openingAmount).toStringAsFixed(2)}'),
          const Divider(height: 32),
          _buildInfoRow('Saldo Esperado:', '\$${(session.expectedAmount ?? 0.0).toStringAsFixed(2)}', isBold: true),
          const SizedBox(height: 32),
          custom.CustomTextField(
            label: 'Monto Real en Caja',
            controller: _amountController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.account_balance_wallet,
            hintText: '0.00',
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _handleClose(cashProvider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange[800],
              ),
              child: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('REALIZAR ARQUEO Y CERRAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOpen(CashProvider cashProvider) async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => _isProcessing = true);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? 0;
    final businessRuc = authProvider.currentUser?.businessRuc ?? '0000000000';
    
    final success = await cashProvider.openSession(amount, userId, businessRuc);
    setState(() => _isProcessing = false);
    
    if (success) {
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Caja abierta correctamente'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _handleClose(CashProvider cashProvider) async {
    if (_amountController.text.isEmpty) return;

    final actualAmount = double.tryParse(_amountController.text) ?? 0.0;
    final expected = cashProvider.currentSession!.expectedAmount ?? 0.0;
    final difference = actualAmount - expected;

    // Mostrar confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cierre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Esperado: \$${expected.toStringAsFixed(2)}'),
            Text('Real: \$${actualAmount.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Diferencia: \$${difference.toStringAsFixed(2)}',
              style: TextStyle(
                color: difference == 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CERRAR CAJA')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
      final success = await cashProvider.closeSession(actualAmount, businessRuc);
      setState(() => _isProcessing = false);
      
      if (success) {
        _amountController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Caja cerrada correctamente'), backgroundColor: Colors.green),
        );
      }
    }
  }
}
