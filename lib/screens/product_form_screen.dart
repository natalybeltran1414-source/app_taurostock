import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom;

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _barcodeController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _newCategoryController;

  String? _selectedCategory;
  File? _imageFile;
  bool _isAddingNewCategory = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    // ← CORREGIDO: Usar salePrice, costPrice y quantity
    _priceController = TextEditingController(text: widget.product?.salePrice.toString() ?? '0.0');
    _costController = TextEditingController(text: widget.product?.costPrice.toString() ?? '0.0');
    _stockController = TextEditingController(text: widget.product?.quantity.toString() ?? '0');
    _minStockController = TextEditingController(text: widget.product?.minStock.toString() ?? '5');
    _newCategoryController = TextEditingController();
    _selectedCategory = widget.product?.category;
    
    if (widget.product?.imagePath != null) {
      _imageFile = File(widget.product!.imagePath!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
      Provider.of<CategoryProvider>(context, listen: false).loadCategories(businessRuc);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar(
        title: widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
        showBackButton: true,
      ),
      body: _isLoading 
        ? const custom.CustomLoadingIndicator(message: 'Guardando producto...')
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  custom.SectionHeader(title: 'Información General'),
                  const SizedBox(height: 12),
                  custom.CustomTextField(
                    label: 'Nombre del Producto',
                    controller: _nameController,
                    prefixIcon: Icons.shopping_bag_outlined,
                    validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  custom.CustomTextField(
                    label: 'Código de Barras',
                    controller: _barcodeController,
                    prefixIcon: Icons.qr_code_scanner,
                  ),
                  
                  const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Consumer<CategoryProvider>(
                    builder: (context, categoryProvider, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _isAddingNewCategory
                              ? custom.CustomTextField(
                                  label: 'Nueva Categoría',
                                  controller: _newCategoryController,
                                  prefixIcon: Icons.category_outlined,
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      isExpanded: true,
                                      hint: const Text('Seleccionar Categoría'),
                                      items: categoryProvider.categories.map((c) {
                                        return DropdownMenuItem(
                                          value: c.name,
                                          child: Text(c.name),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategory = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                          ),
                          const SizedBox(width: 8),
                          if (!_isAddingNewCategory)
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: custom.primaryLilac),
                              onPressed: () => setState(() => _isAddingNewCategory = true),
                            )
                          else ...[
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                final newName = _newCategoryController.text.trim();
                                if (newName.isNotEmpty) {
                                  final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
                                  final success = await categoryProvider.addCategory(
                                    Category(name: newName, businessRuc: businessRuc),
                                    businessRuc,
                                  );
                                  if (success) {
                                    setState(() {
                                      _selectedCategory = newName;
                                      _isAddingNewCategory = false;
                                      _newCategoryController.clear();
                                    });
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => setState(() => _isAddingNewCategory = false),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),

                  custom.SectionHeader(title: 'Precios y Stock'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: custom.CustomTextField(
                          label: 'Costo',
                          controller: _costController,
                          prefixIcon: Icons.money_off_outlined,
                          inputType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: custom.CustomTextField(
                          label: 'Precio Venta',
                          controller: _priceController,
                          prefixIcon: Icons.attach_money,
                          inputType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: custom.CustomTextField(
                          label: 'Stock Actual',
                          controller: _stockController,
                          prefixIcon: Icons.inventory_2_outlined,
                          inputType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: custom.CustomTextField(
                          label: 'Stock Mínimo',
                          controller: _minStockController,
                          prefixIcon: Icons.warning_amber_outlined,
                          inputType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  custom.CustomButton(
                    label: widget.product == null ? 'CREAR PRODUCTO' : 'ACTUALIZAR PRODUCTO',
                    onPressed: _saveProduct,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessRuc = authProvider.currentUser?.businessRuc ?? '0000000000';

    // ← CORREGIDO: Usar salePrice, costPrice y quantity
    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      barcode: _barcodeController.text.trim(),
      salePrice: double.tryParse(_priceController.text) ?? 10.0,
      costPrice: double.tryParse(_costController.text) ?? 5.0,
      category: _selectedCategory ?? 'General',
      quantity: int.tryParse(_stockController.text) ?? 0,
      minStock: int.tryParse(_minStockController.text) ?? 5,
      imagePath: _imageFile?.path,
      businessRuc: businessRuc,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      isActive: widget.product?.isActive ?? true,
    );

    final provider = Provider.of<ProductProvider>(context, listen: false);
    bool success;
    
    if (widget.product == null) {
      success = await provider.addProduct(product);
    } else {
      success = await provider.updateProduct(product);
    }

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el producto'), backgroundColor: Colors.red),
      );
    }
  }
}
