import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';

class SearchFilterView extends StatefulWidget {
  const SearchFilterView({super.key});

  @override
  State<SearchFilterView> createState() => _SearchFilterViewState();
}

class _SearchFilterViewState extends State<SearchFilterView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookProv = Provider.of<BookProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Explore & Search'),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, author, or ISBN...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          bookProv.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (query) => bookProv.setSearchQuery(query),
            ),
          ),

          // 2. Sorting & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Sort Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: bookProv.selectedSort,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        icon: const Icon(Icons.sort, size: 18),
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('Sort: Newest First')),
                          DropdownMenuItem(value: 'price_asc', child: Text('Sort: Price: Low to High')),
                          DropdownMenuItem(value: 'price_desc', child: Text('Sort: Price: High to Low')),
                          DropdownMenuItem(value: 'rating', child: Text('Sort: Highest Rated')),
                          DropdownMenuItem(value: 'popular', child: Text('Sort: Most Popular')),
                        ],
                        onChanged: (val) {
                          if (val != null) bookProv.setSort(val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (bookProv.selectedCategoryId != null || bookProv.searchQuery.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _searchController.clear();
                      bookProv.clearFilters();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Category Horizontal Pills
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: bookProv.categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = bookProv.selectedCategoryId == null;
                  return ChoiceChip(
                    label: const Text('All Categories'),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => bookProv.filterByCategory(null),
                  );
                }
                final cat = bookProv.categories[index - 1];
                final isSelected = bookProv.selectedCategoryId == cat.id;
                return ChoiceChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => bookProv.filterByCategory(cat.id),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 4. Results Grid
          Expanded(
            child: bookProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookProv.books.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching books found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try searching for another keyword or clear category filters',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                bookProv.clearFilters();
                              },
                              child: const Text('Reset All Filters'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => bookProv.fetchBooks(refresh: true),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: bookProv.books.length,
                          itemBuilder: (context, index) {
                            return BookCard(book: bookProv.books[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
