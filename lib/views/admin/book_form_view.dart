import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../models/book_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/book_provider.dart';

class BookFormView extends StatefulWidget {
  final BookModel? book;

  const BookFormView({super.key, this.book});

  @override
  State<BookFormView> createState() => _BookFormViewState();
}

class _BookFormViewState extends State<BookFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;
  late TextEditingController _isbnController;
  late TextEditingController _publisherController;
  late TextEditingController _yearController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverUrlController;
  int? _selectedCategoryId;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titleController = TextEditingController(text: b?.title ?? '');
    _authorController = TextEditingController(text: b?.author ?? '');
    _priceController = TextEditingController(text: b != null ? b.price.toStringAsFixed(2) : '');
    _stockController = TextEditingController(text: b != null ? b.stock.toString() : '10');
    _thresholdController = TextEditingController(text: b != null ? b.lowStockThreshold.toString() : '5');
    _isbnController = TextEditingController(text: b?.isbn ?? '');
    _publisherController = TextEditingController(text: b?.publisher ?? '');
    _yearController = TextEditingController(text: b?.publicationYear?.toString() ?? '');
    _descriptionController = TextEditingController(text: b?.description ?? '');
    _coverUrlController = TextEditingController(text: b?.coverImage ?? '');
    _selectedCategoryId = b?.categoryId;
    _isFeatured = b?.isFeatured ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProv = Provider.of<BookProvider>(context, listen: false);
      if (bookProv.categories.isEmpty) {
        bookProv.fetchCategories().then((_) {
          if (_selectedCategoryId == null && bookProv.categories.isNotEmpty) {
            setState(() => _selectedCategoryId = bookProv.categories.first.id);
          }
        });
      } else if (_selectedCategoryId == null) {
        setState(() => _selectedCategoryId = bookProv.categories.first.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a book category')),
      );
      return;
    }

    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    final success = await adminProv.saveBook(
      id: widget.book?.id,
      categoryId: _selectedCategoryId!,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
      lowStockThreshold: int.tryParse(_thresholdController.text.trim()) ?? 5,
      isbn: _isbnController.text.trim().isNotEmpty ? _isbnController.text.trim() : null,
      publisher: _publisherController.text.trim().isNotEmpty ? _publisherController.text.trim() : null,
      publicationYear: int.tryParse(_yearController.text.trim()),
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      coverImage: _coverUrlController.text.trim().isNotEmpty ? _coverUrlController.text.trim() : null,
      isFeatured: _isFeatured,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.book != null ? 'Book updated successfully' : 'New book added to inventory'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save book'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookProv = Provider.of<BookProvider>(context);
    final adminProv = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.book != null ? 'Edit Book' : 'Add New Book'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Book Title *', hintText: 'e.g. Atomic Habits'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),

              // Author
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author Name *', hintText: 'e.g. James Clear'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Author is required' : null,
              ),
              const SizedBox(height: 14),

              // Category Selector
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: bookProv.categories.map((c) {
                  return DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 14),

              // Price & Stock
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price (USD) *', prefixText: '\$ '),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'Valid price required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock Units *'),
                      validator: (v) => (v == null || int.tryParse(v) == null) ? 'Valid stock required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ISBN & Publisher
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _isbnController,
                      decoration: const InputDecoration(labelText: 'ISBN', hintText: '9780735211292'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _publisherController,
                      decoration: const InputDecoration(labelText: 'Publisher'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Low-Stock Threshold
              TextFormField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Alert Threshold',
                  hintText: 'Alert when stock falls below this number (Default: 5)',
                ),
              ),
              const SizedBox(height: 14),

              // Cover Image URL
              TextFormField(
                controller: _coverUrlController,
                decoration: const InputDecoration(
                  labelText: 'Cover Image URL',
                  hintText: 'https://images.unsplash.com/... or /storage/covers/...',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Synopsis / Description',
                  hintText: 'Detailed summary of the book...',
                ),
              ),
              const SizedBox(height: 14),

              // Featured Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Feature on Home Feed', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Display this title in the featured carousel slider', style: TextStyle(fontSize: 12)),
                value: _isFeatured,
                activeColor: AppTheme.accent,
                onChanged: (val) => setState(() => _isFeatured = val),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: adminProv.isLoading ? null : _handleSave,
                child: adminProv.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.book != null ? 'Update Book' : 'Save Book to Catalog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
