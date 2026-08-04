class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';

  static const String registerUrl = '$baseUrl/api/auth/register';
  static const String loginUrl = '$baseUrl/api/auth/login';
  static final Uri checkStatusUrl = Uri.parse('$baseUrl/auth/checkStatus');
  static final Uri barangUrl = Uri.parse('$baseUrl/api/barang');
  static const String resetUrl = '$baseUrl/api/auth/resetPassword';
  static const String forgotUrl = '$baseUrl/api/auth/forgotPassword';
  static String get pesananUrl => '$baseUrl/api/pesanan';
  static String get midtransChargeUrl => '$baseUrl/api/midtrans/charge';
  static String midtransStatusUrl(String orderId) =>
      '$baseUrl/api/midtrans/status/$orderId';
}
