class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final String status;
  final int booksCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.status = 'active',
    this.booksCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description']?.toString(),
      status: json['status'] ?? 'active',
      booksCount: json['books_count'] is int
          ? json['books_count']
          : int.tryParse(json['books_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'books_count': booksCount,
    };
  }
}

class BookModel {
  final int id;
  final int categoryId;
  final String title;
  final String author;
  final String? isbn;
  final String? publisher;
  final int? publicationYear;
  final String? description;
  final double price;
  final int stock;
  final int lowStockThreshold;
  final String? coverImage;
  final String coverImageUrl;
  final double rating;
  final int ratingCount;
  final bool isFeatured;
  final String status;
  final CategoryModel? category;

  BookModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.author,
    this.isbn,
    this.publisher,
    this.publicationYear,
    this.description,
    required this.price,
    required this.stock,
    this.lowStockThreshold = 5,
    this.coverImage,
    required this.coverImageUrl,
    this.rating = 4.5,
    this.ratingCount = 10,
    this.isFeatured = false,
    this.status = 'active',
    this.category,
  });

  bool get isLowStock => stock <= lowStockThreshold;
  bool get inStock => stock > 0;

  factory BookModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0;
    }

    double parsedRating = 4.5;
    if (json['rating'] != null) {
      parsedRating = json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating'].toString()) ?? 4.5;
    }

    int parsedStock = 0;
    if (json['stock'] != null) {
      parsedStock = json['stock'] is int
          ? json['stock']
          : int.tryParse(json['stock'].toString()) ?? 0;
    }

    String coverUrl = json['cover_image_url'] ?? '';
    if (coverUrl.isEmpty) {
      coverUrl = json['cover_image'] ?? 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&q=80&w=600';
    }

    return BookModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? '1') ?? 1,
      title: json['title'] ?? 'Untitled Book',
      author: json['author'] ?? 'Unknown Author',
      isbn: json['isbn']?.toString(),
      publisher: json['publisher']?.toString(),
      publicationYear: json['publication_year'] is int
          ? json['publication_year']
          : int.tryParse(json['publication_year']?.toString() ?? ''),
      description: json['description']?.toString(),
      price: parsedPrice,
      stock: parsedStock,
      lowStockThreshold: json['low_stock_threshold'] is int
          ? json['low_stock_threshold']
          : int.tryParse(json['low_stock_threshold']?.toString() ?? '5') ?? 5,
      coverImage: json['cover_image']?.toString(),
      coverImageUrl: coverUrl,
      rating: parsedRating,
      ratingCount: json['rating_count'] is int
          ? json['rating_count']
          : int.tryParse(json['rating_count']?.toString() ?? '10') ?? 10,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      status: json['status'] ?? 'active',
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'publisher': publisher,
      'publication_year': publicationYear,
      'description': description,
      'price': price,
      'stock': stock,
      'low_stock_threshold': lowStockThreshold,
      'cover_image': coverImage,
      'cover_image_url': coverImageUrl,
      'rating': rating,
      'rating_count': ratingCount,
      'is_featured': isFeatured,
      'status': status,
      if (category != null) 'category': category!.toJson(),
    };
  }
}
