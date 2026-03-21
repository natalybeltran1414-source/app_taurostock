import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom;

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Presets para iconos y colores
  final List<IconData> _iconPresets = [
    Icons.category, Icons.inventory_2, Icons.shopping_basket, 
    Icons.local_offer, Icons.star, Icons.fastfood, 
    Icons.checkroom, Icons.home_repair_service, Icons.computer,
    Icons.receipt_long, Icons.point_of_sale, Icons.pets,
    Icons.health_and_safety, Icons.sports_soccer, Icons.spa,
    Icons.construction, Icons.brush, Icons.book_outlined,
    Icons.coffee, Icons.cookie, Icons.emoji_events,
    Icons.local_florist, Icons.local_drink, Icons.luggage,
    Icons.smartphone, Icons.watch, Icons.headphones,
    Icons.toys, Icons.child_care, Icons.hotel
  ];

  final List<Color> _colorPresets = [
    custom.primaryLilac, custom.accentPurple, Colors.blue, 
    Colors.teal, Colors.green, Colors.orange, 
    Colors.red, Colors.pink, Colors.brown,
    Colors.indigo, Colors.cyan, Colors.deepPurple,
    Colors.deepOrange, Colors.amber, Colors.lime,
    Colors.lightBlue, Colors.lightGreen, Colors.grey,
    Colors.blueGrey, const Color(0xFF6D4C41), // brown mid
    const Color(0xFF00897B), // teal muted
    const Color(0xFF9C27B0), // purple strong
    const Color(0xFF004D40)  // dark teal
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
      Provider.of<CategoryProvider>(context, listen: false).loadCategories(businessRuc);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar(
        title: 'Gestión de Categorías',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCategoryDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: custom.SearchBar(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              hintText: 'Buscar categoría...',
            ),
          ),
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, _) {
                final filteredCategories = categoryProvider.categories.where((c) => 
                  c.name.toLowerCase().contains(_searchController.text.toLowerCase())
                ).toList();

                if (categoryProvider.isLoading) {
                  return const custom.CustomLoadingIndicator(message: 'Cargando categorías...');
                }

                if (filteredCategories.isEmpty) {
                  return const custom.EmptyState(
                    message: 'No hay categorías registradas',
                    icon: Icons.category_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    return _buildCategoryCard(context, category, categoryProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: custom.primaryLilac,
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category, CategoryProvider provider) {
    return custom.ListItemCard(
      title: category.name,
      subtitle: category.description.isNotEmpty ? category.description : 'Sin descripción',
      amount: '',
      icon: category.icon,
      color: category.color,
      onTap: () => _showCategoryDialog(context, category: category),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey),
            onPressed: () => _showCategoryDialog(context, category: category),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, category, provider),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    int selectedIconCode = category?.iconCode ?? _iconPresets[0].codePoint;
    int selectedColorValue = category?.colorValue ?? _colorPresets[0].value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Nueva Categoría' : 'Editar Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                custom.CustomTextField(
                  label: 'Nombre',
                  controller: nameController,
                  hint: 'Ej: Bebidas, Snacks...',
                ),
                custom.CustomTextField(
                  label: 'Descripción (Opcional)',
                  controller: descController,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Icono', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconPresets.map((icon) {
                    final isSelected = selectedIconCode == icon.codePoint;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIconCode = icon.codePoint),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Color(selectedColorValue).withOpacity(0.2) : Colors.grey[100],
                          border: Border.all(color: isSelected ? Color(selectedColorValue) : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: isSelected ? Color(selectedColorValue) : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorPresets.map((color) {
                    final isSelected = selectedColorValue == color.value;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColorValue = color.value),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final businessRuc = authProvider.currentUser?.businessRuc ?? '0000000000';
                
                final newCategory = Category(
                  id: category?.id,
                  name: nameController.text,
                  description: descController.text,
                  iconCode: selectedIconCode,
                  colorValue: selectedColorValue,
                  businessRuc: businessRuc,
                );

                final provider = Provider.of<CategoryProvider>(context, listen: false);
                bool success;
                if (category == null) {
                  success = await provider.addCategory(newCategory, businessRuc);
                } else {
                  success = await provider.updateCategory(newCategory, businessRuc);
                }

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(category == null ? 'Categoría creada' : 'Categoría actualizada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category, CategoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de que deseas eliminar "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
              final success = await provider.deleteCategory(category.id!, businessRuc);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${category.name} eliminada'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
