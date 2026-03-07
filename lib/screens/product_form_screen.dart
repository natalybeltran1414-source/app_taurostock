import 'package:flutter/material.dart';
import 'dart:io';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _barcodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _quantityController;
  late TextEditingController _minStockController;
  late TextEditingController _newCategoryController;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  
  String? _selectedCategory;
  bool _isAddingNewCategory = false;
  bool _isLoading = false; // ← NUEVO: estado de carga

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _barcodeController =
        TextEditingController(text: widget.product?.barcode ?? '');
    _costPriceController = TextEditingController(
        text: widget.product?.costPrice.toString() ?? '');
    _salePriceController = TextEditingController(
        text: widget.product?.salePrice.toString() ?? '');
    _quantityController =
        TextEditingController(text: widget.product?.quantity.toString() ?? '');
    _minStockController = TextEditingController(
        text: widget.product?.minStock.toString() ?? '');
    _imageFile = widget.product?.imagePath != null
        ? XFile(widget.product!.imagePath!)
        : null;
    
    _selectedCategory = widget.product?.category;
    _newCategoryController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  // ← MEJORADO: Función para mostrar opciones de imagen
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: custom.secondaryPurple),
                title: const Text('Elegir de la galería'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 600,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    setState(() => _imageFile = picked);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: custom.secondaryPurple),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 600,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    setState(() => _imageFile = picked);
                  }
                },
              ),
              if (_imageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imageFile = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ← MEJORADO: Campos con CustomTextField y alias
            custom.CustomTextField(
              label: 'Nombre del Producto *',
              hint: 'Ej: Arroz',
              controller: _nameController,
              prefixIcon: Icons.inventory_2_outlined,
            ),
            
            custom.CustomTextField(
              label: 'Descripción',
              hint: 'Descripción del producto',
              controller: _descriptionController,
              prefixIcon: Icons.description_outlined,
            ),
            
            Stack(
              children: [
                custom.CustomTextField(
                  label: 'Código de Barras',
                  hint: '1234567890',
                  controller: _barcodeController,
                  prefixIcon: Icons.qr_code_scanner,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: custom.secondaryPurple),
                    onPressed: () async {
                      var result = await BarcodeScanner.scan();
                      if (result.rawContent.isNotEmpty) {
                        _barcodeController.text = result.rawContent;
                      }
                    },
                  ),
                ),
              ],
            ),
            
            // Dropdown de categorías (mejorado)
            _buildCategoryField(),
            
            const SizedBox(height: 16),
            
            // ← MEJORADO: Sección de imagen
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.image, color: custom.secondaryPurple, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Foto del Producto (opcional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  
                  if (_imageFile != null)
                    Stack(
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_imageFile!.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showImagePickerOptions,
                            icon: Icon(
                              _imageFile == null ? Icons.add_a_photo : Icons.edit,
                              color: custom.secondaryPurple,
                            ),
                            label: Text(
                              _imageFile == null ? 'Agregar foto' : 'Cambiar foto',
                              style: TextStyle(color: custom.secondaryPurple),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: custom.secondaryPurple),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: custom.CustomTextField(
                    label: 'Precio de Costo',
                    hint: '0.00',
                    controller: _costPriceController,
                    inputType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: custom.CustomTextField(
                    label: 'Precio de Venta *',
                    hint: '0.00',
                    controller: _salePriceController,
                    inputType: TextInputType.number,
                    prefixIcon: Icons.trending_up,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: custom.CustomTextField(
                    label: 'Cantidad *',
                    hint: '0',
                    controller: _quantityController,
                    inputType: TextInputType.number,
                    prefixIcon: Icons.numbers,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: custom.CustomTextField(
                    label: 'Stock Mínimo',
                    hint: '0',
                    controller: _minStockController,
                    inputType: TextInputType.number,
                    prefixIcon: Icons.warning_amber_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // ← MEJORADO: Botón con estado de carga
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : custom.CustomButton(
                    label: widget.product == null ? 'Crear Producto' : 'Actualizar',
                    onPressed: () async {
                      // Validaciones
                      if (_nameController.text.isEmpty ||
                          _salePriceController.text.isEmpty ||
                          _quantityController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor completa los campos requeridos'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      if (_selectedCategory == null || _selectedCategory!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor selecciona una categoría'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      setState(() => _isLoading = true);
                      
                      try {
                        final product = Product(
                          id: widget.product?.id,
                          name: _nameController.text.trim(),
                          description: _descriptionController.text.trim(),
                          costPrice: double.tryParse(_costPriceController.text) ?? 0,
                          salePrice: double.parse(_salePriceController.text),
                          quantity: int.parse(_quantityController.text),
                          minStock: int.tryParse(_minStockController.text) ?? 0,
                          barcode: _barcodeController.text.trim(),
                          category: _selectedCategory!,
                          imagePath: _imageFile?.path,
                          createdAt: widget.product?.createdAt ?? DateTime.now(),
                          isActive: true,
                        );
                        
                        final productProvider =
                            Provider.of<ProductProvider>(context, listen: false);
                        
                        bool success;
                        if (widget.product == null) {
                          success = await productProvider.addProduct(product);
                        } else {
                          success = await productProvider.updateProduct(product);
                        }
                        
                        if (success && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.product == null
                                    ? '✅ Producto creado exitosamente'
                                    : '✅ Producto actualizado exitosamente',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                productProvider.errorMessage.isNotEmpty
                                    ? productProvider.errorMessage
                                    : 'Error al guardar el producto',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error inesperado: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
  
  // ← MEJORADO: Widget de categoría con estilos unificados
  Widget _buildCategoryField() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final categories = productProvider.categories;
        
        List<DropdownMenuItem<String>> dropdownItems = [];
        
        dropdownItems.addAll(
          categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
        );
        
        if (_selectedCategory != null && 
            _selectedCategory!.isNotEmpty && 
            !categories.contains(_selectedCategory)) {
          dropdownItems.add(
            DropdownMenuItem(
              value: _selectedCategory,
              child: Row(
                children: [
                  Icon(Icons.fiber_new, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCategory!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }
        
        dropdownItems.add(
          DropdownMenuItem(
            value: '__new__',
            child: Row(
              children: [
                Icon(Icons.add, size: 18, color: custom.secondaryPurple),
                const SizedBox(width: 8),
                Text(
                  'Agregar nueva categoría...',
                  style: TextStyle(color: custom.secondaryPurple),
                ),
              ],
            ),
          ),
        );
        
        if (_isAddingNewCategory) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva Categoría',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: custom.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCategoryController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Bebidas, Lácteos, etc.',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: custom.backgroundGrey,
                      ),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: () {
                        if (_newCategoryController.text.isNotEmpty) {
                          setState(() {
                            _selectedCategory = _newCategoryController.text.trim();
                            _isAddingNewCategory = false;
                            _newCategoryController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isAddingNewCategory = false;
                          _newCategoryController.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categoría *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: custom.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: custom.backgroundGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                hint: const Text('Seleccionar categoría'),
                items: dropdownItems,
                onChanged: (value) {
                  if (value == '__new__') {
                    setState(() => _isAddingNewCategory = true);
                  } else {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}