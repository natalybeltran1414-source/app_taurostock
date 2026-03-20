import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({Key? key, this.transaction}) : super(key: key);

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  
  String _selectedType = 'gasto';
  String _selectedCategory = 'otros';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? ''
    );
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? ''
    );
    _notesController = TextEditingController(
      text: widget.transaction?.notes ?? ''
    );
    
    if (widget.transaction != null) {
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: widget.transaction == null ? 'Nueva Transacción' : 'Editar Transacción',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← MEJORADO: Tipo de transacción con chips mejorados
            const Text(
              'Tipo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeChip('Ingreso', Icons.arrow_upward, 'ingreso'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeChip('Gasto', Icons.arrow_downward, 'gasto'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ← MEJORADO: Campos con CustomTextField
            custom.CustomTextField(
              label: 'Descripción *',
              hint: 'Ej: Pago de alquiler',
              controller: _descriptionController,
              prefixIcon: Icons.description_outlined,
            ),

            custom.CustomTextField(
              label: 'Monto *',
              hint: '0.00',
              controller: _amountController,
              inputType: TextInputType.number,
              prefixIcon: Icons.attach_money,
            ),

            // ← MEJORADO: Categoría con chips
            const Text(
              'Categoría',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.categories.map((category) {
                    return FilterChip(
                      label: Text(category.capitalize()),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                      backgroundColor: custom.backgroundGrey,
                      selectedColor: _selectedType == 'ingreso'
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      checkmarkColor: _selectedType == 'ingreso'
                          ? Colors.green
                          : Colors.red,
                      labelStyle: TextStyle(
                        color: _selectedCategory == category
                            ? (_selectedType == 'ingreso' ? Colors.green : Colors.red)
                            : custom.textSecondary,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // ← MEJORADO: Selector de fecha
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: custom.primaryLilac.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: custom.primaryLilac,
                    size: 20,
                  ),
                ),
                title: const Text('Fecha', style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: custom.primaryLilac,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: custom.primaryLilac,
                  ),
                  child: const Text('Cambiar'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ← MEJORADO: Notas
            custom.CustomTextField(
              label: 'Notas (opcional)',
              hint: 'Información adicional',
              controller: _notesController,
              prefixIcon: Icons.note_outlined,
            ),
            
            const SizedBox(height: 32),

            // ← MEJORADO: Botón guardar
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : custom.CustomButton(
                    label: widget.transaction == null ? 'Guardar Transacción' : 'Actualizar',
                    onPressed: _saveTransaction,
                  ),
          ],
        ),
      ),
    );
  }

  // ← MEJORADO: Chip de tipo con diseño mejorado
  Widget _buildTypeChip(String label, IconData icon, String value) {
    final isSelected = _selectedType == value;
    final color = value == 'ingreso' ? Colors.green : Colors.red;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : custom.backgroundGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : custom.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una descripción'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';

    final transaction = Transaction(
      id: widget.transaction?.id,
      description: _descriptionController.text.trim(),
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
      businessRuc: businessRuc,
    );

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    bool success;
    if (widget.transaction == null) {
      success = await provider.addTransaction(transaction, businessRuc);
    } else {
      success = await provider.updateTransaction(transaction, businessRuc);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transaction == null
                ? '✅ Transacción guardada'
                : '✅ Transacción actualizada',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
