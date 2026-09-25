import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/book_model.dart';

class BookProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<BookModel> _featuredBooks = [];
  List<BookModel> _books = [];
  List<CategoryModel> _categories = [];
  BookModel? _selectedBook;
  List<BookModel> _relatedBooks = [];

  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedCategoryId;
  String _selectedSort = 'newest';
  String _searchQuery = '';

  List<BookModel> get featuredBooks => _featuredBooks;
  List<BookModel> get books => _books;
  List<CategoryModel> get categories => _categories;
  BookModel? get selectedBook => _selectedBook;
  List<BookModel> get relatedBooks => _relatedBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get selectedCategoryId => _selectedCategoryId;
  String get selectedSort => _selectedSort;
  String get searchQuery => _searchQuery;

  Future<void> fetchHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchFeaturedBooks(),
        fetchCategories(),
        fetchBooks(),
      ]);
    } catch (e) {
      _errorMessage = 'Failed to load bookstore data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeaturedBooks() async {
    try {
      final res = await _apiClient.get(ApiConstants.featuredBooks);
      if (res != null && res['data'] is List) {
        _featuredBooks = (res['data'] as List)
            .map((e) => BookModel.fromJson(e))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> fetchCategories() async {
    try {
      final res = await _apiClient.get(ApiConstants.categories);
      if (res != null && res['data'] is List) {
        _categories = (res['data'] as List)
            .map((e) => CategoryModel.fromJson(e))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> fetchBooks({bool refresh = false}) async {
    if (refresh) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final params = <String, dynamic>{
        'sort': _selectedSort,
      };
      if (_selectedCategoryId != null) {
        params['category_id'] = _selectedCategoryId;
      }
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      final res = await _apiClient.get(ApiConstants.books, queryParams: params);
      if (res != null && res['data'] is List) {
        _books = (res['data'] as List)
            .map((e) => BookModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch catalog books.';
    } finally {
      if (refresh) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchBookDetails(int id) async {
    _isLoading = true;
    _selectedBook = null;
    _relatedBooks = [];
    notifyListeners();

    try {
      final res = await _apiClient.get('${ApiConstants.books}/$id');
      if (res != null && res['data'] != null) {
        _selectedBook = BookModel.fromJson(res['data']);
        if (res['related'] is List) {
          _relatedBooks = (res['related'] as List)
              .map((e) => BookModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      _errorMessage = 'Could not load book details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    fetchBooks(refresh: true);
  }

  void setSort(String sort) {
    _selectedSort = sort;
    fetchBooks(refresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    fetchBooks(refresh: true);
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    _selectedSort = 'newest';
    fetchBooks(refresh: true);
  }
}
