class ApiConstants {
  // Default base URL pointing to the Laravel backend on XAMPP or artisan serve
  // For Windows desktop / web: 'http://127.0.0.1:8000/api/v1' or 'http://localhost/bookstore/public/api/v1'
  // For Android emulator: 'http://10.0.2.2:8000/api/v1' or 'http://10.0.2.2/bookstore/public/api/v1'
  static const String defaultBaseUrl = 'http://127.0.0.1/bookstore/public/api/v1';
  static const String fallbackPortBaseUrl = 'http://127.0.0.1:8000/api/v1';

  // SharedPreferences Keys
  static const String keyToken = 'bookverse_token';
  static const String keyUser = 'bookverse_user';
  static const String keyBaseUrl = 'bookverse_base_url';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Catalog Endpoints
  static const String books = '/books';
  static const String featuredBooks = '/books/featured';
  static const String searchBooks = '/books/search';
  static const String categories = '/categories';

  // Customer Endpoints
  static const String cart = '/cart';
  static const String addresses = '/addresses';
  static const String orders = '/orders';
  static const String payments = '/payments';
  static const String generateQr = '/payments/generate-qr';

  // Admin Endpoints
  static const String adminDashboard = '/admin/dashboard';
  static const String adminReports = '/admin/reports';
  static const String adminBooks = '/admin/books';
  static const String adminCategories = '/admin/categories';
  static const String adminInventory = '/admin/inventory';
  static const String adminInventoryAdjust = '/admin/inventory/adjust';
  static const String adminInventoryLogs = '/admin/inventory/logs';
  static const String adminSuppliers = '/admin/suppliers';
  static const String adminOrders = '/admin/orders';
  static const String adminActivityLogs = '/admin/activity-logs';

  // Cambodian Payment Providers
  static const String paymentAbaKhqr = 'ABA_KHQR';
  static const String paymentAcledaKhqr = 'ACLEDA_KHQR';
  static const String paymentBakongKhqr = 'BAKONG_KHQR';
  static const String paymentCard = 'CARD';
  static const String paymentCod = 'CASH_ON_DELIVERY';
}
